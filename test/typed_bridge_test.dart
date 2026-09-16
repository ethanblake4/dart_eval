import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import 'bridge_lib.dart';

const _library = 'package:typed_bridge/main.dart';
const _bridgeLibrary = 'package:bridge_lib/bridge_lib.dart';

Program _compile(String source) {
  final compiler = Compiler()..defineBridgeClasses([$TestClass.$declaration]);
  return compiler.compile({
    'typed_bridge': {'main.dart': source},
  });
}

Iterable<(String, Runtime)> _runtimes(Program program) sync* {
  for (final (kind, candidate) in [
    ('fresh', program),
    ('serialized', Program.read(program.write().buffer)),
  ]) {
    final runtime = Runtime.ofProgram(candidate);
    runtime.registerBridgeFunc(
      _bridgeLibrary,
      'TestClass.',
      $TestClass.$construct,
      isBridge: true,
    );
    yield (kind, runtime);
  }
}

void main() {
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
