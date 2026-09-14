import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _bridge = 'package:external/bridge.dart';
const _library = 'package:external/main.dart';

BridgeFunctionDeclaration _function(
  String name,
  int arity, {
  bool objects = false,
}) => BridgeFunctionDeclaration(
  _bridge,
  name,
  BridgeFunctionDef(
    returns: BridgeTypeAnnotation(
      BridgeTypeRef(objects ? CoreTypes.dynamic : CoreTypes.int),
    ),
    params: [
      for (var i = 0; i < arity; i++)
        BridgeParameter(
          'a$i',
          BridgeTypeAnnotation(
            BridgeTypeRef(objects ? CoreTypes.dynamic : CoreTypes.int),
          ),
          false,
        ),
    ],
  ),
);

Program _compile(String source, Iterable<BridgeFunctionDeclaration> functions) {
  final compiler = Compiler();
  for (final function in functions) {
    compiler.defineBridgeTopLevelFunction(function);
  }
  return compiler.compile({
    'external': {'main.dart': "import '$_bridge'; $source"},
  });
}

class _Opaque implements $Instance {
  @override
  Object get $value => throw StateError('Opaque instance was unwrapped');
  @override
  Object get $reified => throw StateError('Opaque instance was reified');
  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      throw UnimplementedError();
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      throw UnimplementedError();
}

void main() {
  test('external calls require a Runtime and a registered bridge', () {
    final program = _compile('int main() => absent();', [
      _function('absent', 0),
    ]);
    expect(
      () => TypedMachine.run(program.typedProgram),
      throwsA(isA<StateError>()),
    );
    expect(
      () => Runtime.ofProgram(program).executeLib(_library, 'main'),
      throwsA(
        predicate((error) => error.toString().contains('registerBridgeFunc')),
      ),
    );
  });

  for (final registers in [false, true]) {
    test(
      '${registers ? 'register' : 'legacy'} bridge distinguishes provided null from omitted defaults',
      () {
        const nullable = BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.object),
          nullable: true,
        );
        const dynamicType = BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.dynamic),
        );
        final program = _compile(
          '''dynamic main() => optional();
        dynamic explicitNull() => optional(null);
        dynamic nullableEntry(Object? value) => optional(value);
        dynamic dynamicEntry(dynamic value) => optional(value);
        dynamic namedNull() => named(second: null);
        dynamic namedValue() => named(first: 7);
      ''',
          [
            const BridgeFunctionDeclaration(
              _bridge,
              'optional',
              BridgeFunctionDef(
                returns: dynamicType,
                params: [BridgeParameter('value', nullable, true)],
              ),
            ),
            const BridgeFunctionDeclaration(
              _bridge,
              'named',
              BridgeFunctionDef(
                returns: dynamicType,
                namedParams: [
                  BridgeParameter('first', nullable, true),
                  BridgeParameter('second', nullable, true),
                ],
              ),
            ),
          ],
        );
        for (final candidate in [
          program,
          Program.read(program.write().buffer),
        ]) {
          final runtime = Runtime.ofProgram(candidate);
          final observed = <List<Object?>>[];
          $Value? optional(Object? value) {
            observed.add([value]);
            return value == null ? $int(41) : value as $Value;
          }

          $Value? named(Object? first, Object? second) {
            observed.add([first, second]);
            return first == null ? $int(41) : first as $Value;
          }

          if (registers) {
            runtime.registerBridgeFuncRegisters(
              _bridge,
              'optional',
              (runtime, r, s, c) => optional(r),
            );
            runtime.registerBridgeFuncRegisters(
              _bridge,
              'named',
              (runtime, r, s, c) => named(r, s),
            );
          } else {
            runtime.registerBridgeFunc(
              _bridge,
              'optional',
              (runtime, target, args) => optional(args.single),
            );
            runtime.registerBridgeFunc(
              _bridge,
              'named',
              (runtime, target, args) => named(args[0], args[1]),
            );
          }
          expect(runtime.executeLib(_library, 'main'), 41);
          expect(observed.removeLast(), [null]);
          expect(runtime.executeLib(_library, 'explicitNull'), isNull);
          expect(observed.removeLast().single, isA<$null>());
          for (final entry in ['nullableEntry', 'dynamicEntry']) {
            expect(
              runtime.executeLib(_library, entry, arguments: {'value': null}),
              isNull,
            );
            expect(observed.removeLast().single, isA<$null>());
            expect(
              runtime.executeLib(_library, entry, arguments: {'value': 9}),
              9,
            );
            expect(observed.removeLast().single, isA<$int>());
          }
          expect(runtime.executeLib(_library, 'namedNull'), 41);
          final explicitNamed = observed.removeLast();
          expect(explicitNamed[0], isNull);
          expect(explicitNamed[1], isA<$null>());
          expect(runtime.executeLib(_library, 'namedValue'), 7);
          final providedNamed = observed.removeLast();
          expect(providedNamed[0], isA<$int>());
          expect(providedNamed[1], isNull);
        }
      },
    );
  }

  for (final arity in [0, 1, 2, 3, 6]) {
    test(
      'external legacy callback preserves $arity arguments after serialization',
      () {
        final args = List.generate(arity, (i) => '${i + 1}').join(',');
        final program = _compile('int main() => capture($args);', [
          _function('capture', arity),
        ]);
        for (final candidate in [
          program,
          Program.read(program.write().buffer),
        ]) {
          final runtime = Runtime.ofProgram(candidate);
          runtime.registerBridgeFunc(_bridge, 'capture', (
            runtime,
            target,
            args,
          ) {
            expect(target, isNull);
            expect(
              args.map((arg) => (arg as $int).$value),
              List.generate(arity, (i) => i + 1),
            );
            return $int(arity);
          });
          expect(runtime.executeLib(_library, 'main'), arity);
          expect(
            candidate.typedProgram.externalCalls.single.argumentCount,
            arity,
          );
        }
      },
    );
    test('external register callback uses R/S/C for $arity arguments', () {
      final args = List.generate(arity, (i) => '${i + 1}').join(',');
      final runtime = Runtime.ofProgram(
        _compile('int main() => capture($args);', [
          _function('capture', arity),
        ]),
      );
      runtime.registerBridgeFuncRegisters(_bridge, 'capture', (
        runtime,
        r,
        s,
        c,
      ) {
        if (arity > 0) expect((r as $int).$value, 1);
        if (arity > 1) expect((s as $int).$value, 2);
        if (arity == 3) expect((c as $int).$value, 3);
        if (arity > 3) {
          expect(
            (c as List<Object?>)
                .take(arity - 2)
                .map((arg) => (arg as $int).$value),
            [3, 4, 5, 6],
          );
        } else {
          expect(c, isNot(isA<List<Object?>>()));
        }
        return $int(arity);
      });
      expect(runtime.executeLib(_library, 'main'), arity);
    });
  }

  for (final arity in [0, 1]) {
    test(
      '$arity-argument register calls tolerate unused native object slots',
      () {
        final runtime = Runtime.ofProgram(
          _compile(
            'int main(int a, int b, int c, int d, int e) { '
            'capture(${arity == 0 ? '' : 'a'}); return a+b+c+d+e; }',
            [_function('capture', arity)],
          ),
        );
        var called = false;
        runtime.registerBridgeFuncRegisters(_bridge, 'capture', (
          runtime,
          r,
          s,
          c,
        ) {
          called = true;
          expect(c, isA<int>());
          return $int(0);
        });
        expect(
          runtime.executeLib(
            _library,
            'main',
            arguments: {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5},
          ),
          15,
        );
        expect(called, isTrue);
      },
    );
  }

  test(
    'external calls preserve repeated operand order and live caller integers',
    () {
      final program = _compile(
        '''int main(int x, int y) {
      var first = capture(y, x, y, x, y, x);
      var second = capture(x, y, x, y, x, y);
      return first + second + x + y;
    }''',
        [_function('capture', 6)],
      );
      final retained = <List<$Value?>>[];
      final runtime = Runtime.ofProgram(program);
      runtime.registerBridgeFunc(_bridge, 'capture', (runtime, target, args) {
        retained.add(args);
        return $int((args.first as $int).$value);
      });
      expect(
        runtime.executeLib(_library, 'main', arguments: {'x': 7, 'y': 11}),
        36,
      );
      expect(retained[0].map((v) => (v as $int).$value), [11, 7, 11, 7, 11, 7]);
      expect(retained[1].map((v) => (v as $int).$value), [7, 11, 7, 11, 7, 11]);
      expect(identical(retained[0], retained[1]), isFalse);
      expect(program.typedProgram.externalCalls, hasLength(1));
    },
  );

  test('mixed arguments and opaque instances retain canonical identity', () {
    final opaque = _Opaque();
    final runtime = Runtime.ofProgram(
      _compile(
        '''dynamic main(dynamic opaque) =>
      capture(3, 2.5, true, 'text', opaque, opaque);''',
        [_function('capture', 6, objects: true)],
      ),
    );
    runtime.registerBridgeFunc(_bridge, 'capture', (runtime, target, args) {
      expect(args[0], isA<$int>());
      expect(args[1], isA<$double>());
      expect(args[2], isA<$bool>());
      expect(args[3], isA<$String>());
      expect(identical(args[4], opaque), isTrue);
      expect(identical(args[5], opaque), isTrue);
      return $bool(true);
    });
    expect(
      runtime.executeLib(_library, 'main', arguments: {'opaque': opaque}),
      isTrue,
    );
  });

  test(
    'external callback reentry preserves caller values and legacy snapshots',
    () {
      final runtime = Runtime.ofProgram(
        _compile(
          '''int nested() => capture(1,2,3,4,5,6);
      int main(int x) { var result = capture(x,2,3,4,5,6); return result + x; }''',
          [_function('capture', 6)],
        ),
      );
      var inside = false;
      List<$Value?>? retained;
      runtime.registerBridgeFunc(_bridge, 'capture', (runtime, target, args) {
        if (inside) return $int(9);
        retained = args;
        inside = true;
        final nested = runtime.executeLib(_library, 'nested');
        inside = false;
        expect(args.map((v) => (v as $int).$value), [17, 2, 3, 4, 5, 6]);
        return $int(nested as int);
      });
      expect(runtime.executeLib(_library, 'main', arguments: {'x': 17}), 26);
      expect(retained!.map((v) => (v as $int).$value), [17, 2, 3, 4, 5, 6]);
    },
  );
}
