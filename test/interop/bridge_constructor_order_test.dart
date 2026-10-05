import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _host = 'package:constructor_order/host.dart';
const _guest = 'package:constructor_order/main.dart';
const _type = BridgeTypeRef(BridgeTypeSpec(_host, 'Base'));
const _int = BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int));

int _record(List<String> events, int value) {
  events.add('guest $value');
  return value;
}

class _Base {
  _Base(List<String> events, this.seed) {
    events.add('allocate $seed');
  }
  final int seed;
  int compute(int value) => seed + value;
}

class _NativeGuest extends _Base {
  _NativeGuest(List<String> events)
    : extra = _record(events, 1),
      super(events, _record(events, 2)) {
    _record(events, 3);
  }
  final int extra;
}

class _NativeParameter extends _Base {
  _NativeParameter(List<String> events, int seed) : super(events, seed) {
    seed = 4;
    _record(events, seed);
    _record(events, this.seed);
  }
}

class _Bridge extends _Base with $Bridge<_Base> {
  _Bridge(super.events, super.seed);

  @override
  int compute(int value) => $_invoke('compute', [$int(value)]) as int;

  @override
  $Value? $bridgeGet(String identifier) => switch (identifier) {
    'seed' => $int(super.seed),
    'compute' => $Function(
      (_, _, value, _, _) =>
          $int(super.compute((value as $Value).$reified as int)),
    ),
    _ => throw StateError('Unknown native member $identifier'),
  };

  @override
  void $bridgeSet(String identifier, $Value value) =>
      throw StateError('No native setter for $identifier');
}

class _Fixture {
  final events = <String>[];
  final allocations = <_Bridge>[];
  final failure = StateError('constructor failure');

  Program compile(String source) {
    final compiler = Compiler()
      ..defineBridgeClasses([
        const BridgeClassDef(
          BridgeClassType(_type),
          constructors: {
            '': BridgeConstructorDef(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(_type),
                params: [BridgeParameter('seed', _int, false)],
              ),
            ),
          },
          methods: {
            'compute': BridgeMethodDef(
              BridgeFunctionDef(
                returns: _int,
                params: [BridgeParameter('value', _int, false)],
              ),
            ),
          },
          fields: {'seed': BridgeFieldDef(_int)},
          bridge: true,
        ),
      ])
      ..defineBridgeTopLevelFunction(
        const BridgeFunctionDeclaration(
          _host,
          'record',
          BridgeFunctionDef(
            returns: _int,
            params: [BridgeParameter('value', _int, false)],
          ),
        ),
      )
      ..defineBridgeTopLevelFunction(
        const BridgeFunctionDeclaration(
          _host,
          'fail',
          BridgeFunctionDef(returns: _int),
        ),
      )
      ..defineBridgeTopLevelFunction(
        const BridgeFunctionDeclaration(
          _host,
          'nativeCall',
          BridgeFunctionDef(
            returns: _int,
            params: [
              BridgeParameter('receiver', BridgeTypeAnnotation(_type), false),
              BridgeParameter('value', _int, false),
            ],
          ),
        ),
      );
    return compiler.compile({
      'constructor_order': {'main.dart': "import 'host.dart';\n$source"},
    });
  }

  Runtime runtime(Program program, bool encoded, {bool throwInSuper = false}) {
    final runtime = encoded
        ? Runtime(program.write().buffer)
        : Runtime.ofProgram(program);
    runtime.registerBridgeFuncRegisters(_host, 'Base.', (_, value, _, _) {
      final seed = (value as $Value).$reified as int;
      if (throwInSuper) {
        events.add('allocate $seed');
        throw failure;
      }
      final native = _Bridge(events, seed);
      allocations.add(native);
      return native;
    }, isBridge: true);
    runtime.registerBridgeFuncRegisters(
      _host,
      'record',
      (_, value, _, _) =>
          $int(_record(events, (value as $Value).$reified as int)),
    );
    runtime.registerBridgeFuncRegisters(
      _host,
      'fail',
      (_, _, _, _) => throw failure,
    );
    runtime.registerBridgeFuncRegisters(_host, 'nativeCall', (
      _,
      receiver,
      value,
      _,
    ) {
      final native = (receiver as $Value).$reified as _Base;
      expect(native, same(allocations.single));
      return $int(native.compute((value as $Value).$reified as int));
    });
    return runtime;
  }
}

void main() {
  for (final encoded in [false, true]) {
    final mode = encoded ? 'encoded' : 'fresh';
    test(
      '$mode bridge constructor matches native initializer/super/body order',
      () {
        final nativeEvents = <String>[];
        _NativeGuest(nativeEvents);
        expect(nativeEvents, ['guest 1', 'guest 2', 'allocate 2', 'guest 3']);
        final fixture = _Fixture();
        final program = fixture.compile('''
class Guest extends Base {
  final int extra;
  Guest() : extra = record(1), super(record(2)) { record(3); }
}
Base main() => Guest();
''');
        final result = fixture
            .runtime(program, encoded)
            .executeLib(_guest, 'main');
        expect(fixture.events, nativeEvents);
        expect(result, same(fixture.allocations.single));
      },
    );

    test(
      '$mode native parent and virtual dispatch are usable in child bodies',
      () {
        final fixture = _Fixture();
        final program = fixture.compile('''
class Guest extends Base {
  final int extra;
  Guest() : extra = record(1), super(record(2)) {
    record(super.compute(extra));
    final bound = compute;
    record(bound(4));
    record(nativeCall(this, 4));
  }
  int compute(int value) => super.compute(value) + extra;
}
class Child extends Guest {
  Child() : super() { record(compute(5)); }
  int compute(int value) => super.compute(value) + 10;
}
Base main() => Child();
''');
        final result = fixture
            .runtime(program, encoded)
            .executeLib(_guest, 'main');
        expect(fixture.events, [
          'guest 1',
          'guest 2',
          'allocate 2',
          'guest 3',
          'guest 17',
          'guest 17',
          'guest 18',
        ]);
        expect(result, same(fixture.allocations.single));
        expect((result as _Base).compute(6), 19);
      },
    );

    test('$mode body parameter reassignment cannot change super arguments', () {
      final nativeEvents = <String>[];
      final native = _NativeParameter(nativeEvents, 2);
      final fixture = _Fixture();
      final program = fixture.compile('''
class Guest extends Base {
  Guest(int seed) : super(seed) {
    seed = 4;
    record(seed);
    record(this.seed);
  }
}
Base main() => Guest(2);
''');
      final result =
          fixture.runtime(program, encoded).executeLib(_guest, 'main') as _Base;
      expect(fixture.events, nativeEvents);
      expect(result.seed, native.seed);
    });

    for (final phase in ['initializer', 'argument', 'super', 'body']) {
      test('$mode throwing $phase preserves preceding allocation effects', () {
        final fixture = _Fixture();
        final initializer = phase == 'initializer' ? 'fail()' : 'record(1)';
        final argument = phase == 'argument' ? 'fail()' : 'record(2)';
        final body = phase == 'body' ? 'fail();' : 'record(3);';
        final program = fixture.compile('''
class Guest extends Base {
  final int extra;
  Guest() : extra = $initializer, super($argument) { $body }
}
Base main() => Guest();
''');
        final runtime = fixture.runtime(
          program,
          encoded,
          throwInSuper: phase == 'super',
        );
        expect(
          () => runtime.executeLib(_guest, 'main'),
          throwsA(
            isA<RuntimeException>().having(
              (error) => error.caughtException,
              'original exception',
              same(fixture.failure),
            ),
          ),
        );
        expect(fixture.events, switch (phase) {
          'initializer' => <String>[],
          'argument' => ['guest 1'],
          _ => ['guest 1', 'guest 2', 'allocate 2'],
        });
        expect(fixture.allocations.length, phase == 'body' ? 1 : 0);
      });
    }
  }
}
