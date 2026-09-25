import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

import '../support/bridge_lib.dart';

const _library = 'package:typed_bridge/main.dart';
const _bridgeLibrary = 'package:bridge_lib/bridge_lib.dart';

Program _compile(String source, {BridgeClassDef? bridge}) {
  final compiler = Compiler()
    ..defineBridgeClasses([bridge ?? $TestClass.$declaration]);
  return compiler.compile({
    'typed_bridge': {'main.dart': source},
  });
}

BridgeClassDef _bridgeWithRequiredArguments() {
  final base = $TestClass.$declaration;
  return BridgeClassDef(
    base.type,
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($TestClass.$type),
          params: [
            BridgeParameter(
              'someNumber',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'extra',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
          namedParams: [
            BridgeParameter(
              'bonus',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
          ],
        ),
      ),
    },
    methods: base.methods,
    getters: base.getters,
    setters: base.setters,
    fields: base.fields,
    bridge: true,
  );
}

Iterable<(String, Runtime)> _runtimes(
  Program program, {
  List<List<Object?>>? constructorArguments,
}) sync* {
  for (final (kind, candidate) in [
    ('fresh', program),
    ('serialized', Program.read(program.write().buffer)),
  ]) {
    final runtime = Runtime.ofProgram(candidate);
    runtime.registerBridgeFuncRegisters(_bridgeLibrary, 'TestClass.', (
      runtime,
      r,
      s,
      c,
    ) {
      constructorArguments?.add([
        (r as $Value).$value,
        (s as $Value).$value,
        (c as $Value).$value,
      ]);
      return $TestClass.$construct(runtime, r, s, c);
    }, isBridge: true);
    yield (kind, runtime);
  }
}

void main() {
  test('bridge super combines forwarded and explicit arguments', () {
    final program = _compile('''
      import 'package:bridge_lib/bridge_lib.dart';

      int trace = 0;
      int mark(int value) {
        trace = trace * 10 + value;
        return value;
      }

      class Guest extends TestClass {
        Guest(super.someNumber, super.extra) : super(bonus: mark(3));
      }

      int main() => Guest(4, 2).someNumber + trace;
    ''', bridge: _bridgeWithRequiredArguments());
    final arguments = <List<Object?>>[];
    for (final (kind, runtime) in _runtimes(
      program,
      constructorArguments: arguments,
    )) {
      expect(runtime.executeLib(_library, 'main'), 7, reason: kind);
    }
    expect(arguments, [
      [4, 2, 3],
      [4, 2, 3],
    ]);
  });

  test('positional super formals reject explicit positional arguments', () {
    expect(
      () => _compile('''
        import 'package:bridge_lib/bridge_lib.dart';
        class Guest extends TestClass {
          Guest(super.someNumber) : super(2);
        }
      '''),
      throwsA(isA<CompileError>()),
    );
  });

  test('named super formals reject duplicate named arguments', () {
    expect(
      () => _compile('''
        import 'package:bridge_lib/bridge_lib.dart';
        class Guest extends TestClass {
          Guest(int first, int second, {required super.bonus})
              : super(first, second, bonus: 3);
        }
      ''', bridge: _bridgeWithRequiredArguments()),
      throwsA(isA<CompileError>()),
    );
  });

  test('implicit bridge super validates required arguments', () {
    expect(
      () => _compile('''
        import 'package:bridge_lib/bridge_lib.dart';
        class Guest extends TestClass {}
      '''),
      throwsA(isA<CompileError>()),
    );
    expect(
      () => _compile('''
        import 'package:bridge_lib/bridge_lib.dart';
        class Guest extends TestClass {
          Guest();
        }
      '''),
      throwsA(isA<CompileError>()),
    );
    expect(
      () => _compile('''
        import 'package:bridge_lib/bridge_lib.dart';
        class Guest extends TestClass {
          Guest(super.someNumber, super.extra);
        }
      ''', bridge: _bridgeWithRequiredArguments()),
      throwsA(
        isA<CompileError>().having(
          (error) => error.message,
          'message',
          contains('Missing required named argument bonus'),
        ),
      ),
    );
  });

  test('plain host bridge values retain runtime type metadata', () {
    final program = _compile('''
      import 'package:bridge_lib/bridge_lib.dart';

      bool inspect(dynamic value, dynamic sameType, dynamic otherType) {
        return value is TestClass &&
            value.runtimeType == sameType.runtimeType &&
            value.runtimeType != otherType.runtimeType;
      }

      bool main() => inspect(TestClass(4), TestClass(9), 4);
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), isTrue, reason: kind);
    }
  });

  test(
    'guest bridge subclass supports named construction fields and super',
    () {
      final program = _compile('''
      import 'package:bridge_lib/bridge_lib.dart';

      class Guest extends TestClass {
        Guest(int value, {int bonus = 0}) : super(value + bonus);

        @override
        bool runTest(int a, {String b = 'guest'}) {
          return super.runTest(a + 2, b: b);
        }
      }

      TestClass build() => Guest(4, bonus: 3);

      int inheritedField() {
        final value = Guest(1, bonus: 2);
        value.someNumber = value.someNumber + 6;
        return value.someNumber;
      }

      bool guestSuperCall() {
        return Guest(4, bonus: 3).runTest(1, b: '123456789');
      }
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        expect(runtime.executeLib(_library, 'inheritedField'), 9, reason: kind);
        expect(
          runtime.executeLib(_library, 'guestSuperCall'),
          isTrue,
          reason: kind,
        );
        final value = runtime.executeLib(_library, 'build') as TestClass;
        expect(value.someNumber, 7, reason: kind);
        expect(value.runTest(1, b: '123456789'), isTrue, reason: kind);
      }
    },
  );

  test('super bridge accessors bypass evaluated overrides', () {
    final program = _compile('''
      import 'package:bridge_lib/bridge_lib.dart';

      class Guest extends TestClass {
        Guest(int value) : super(value);

        @override
        int get someNumber => 99;

        @override
        set someNumber(int value) {}

        int update() {
          super.someNumber = 7;
          return super.someNumber;
        }
      }

      int main() => Guest(2).update();
    ''');
    for (final (kind, runtime) in _runtimes(program)) {
      expect(runtime.executeLib(_library, 'main'), 7, reason: kind);
    }
  });

  test(
    'further guest subclasses dispatch native and async calls to overrides',
    () async {
      final program = _compile('''
      import 'package:bridge_lib/bridge_lib.dart';

      class Guest extends TestClass {
        Guest(int value, {int bonus = 0}) : super(value + bonus);

        @override
        bool runTest(int a, {String b = 'guest'}) {
          return super.runTest(a + 2, b: b);
        }

        @override
        Future<void> runAsyncTest(int a) async {
          await a;
          someNumber = someNumber + a;
        }
      }

      class FurtherGuest extends Guest {
        FurtherGuest(int value) : super(value, bonus: 1);

        @override
        bool runTest(int a, {String b = 'further'}) {
          return super.runTest(a + 1, b: b);
        }
      }

      TestClass build() => FurtherGuest(4);
    ''');
      for (final (kind, runtime) in _runtimes(program)) {
        final value = runtime.executeLib(_library, 'build') as TestClass;
        expect(value.runTest(1, b: '12345678'), isTrue, reason: kind);
        await value.runAsyncTest(6);
        expect(value.someNumber, 11, reason: kind);
      }
    },
  );
}
