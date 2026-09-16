import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:globals/main.dart';
Program _compile(String source) => Compiler().compile({
  'globals': {'main.dart': source},
});

void main() {
  for (final encoded in [false, true]) {
    Program program(String source) {
      final result = _compile(source);
      return encoded ? Program.read(result.write().buffer) : result;
    }

    test('lazy globals initialize once, encoded=$encoded', () {
      final p = program('''int count = 0; int value = initialize();
        int initialize() { count++; return 9; }
        int main() => count; int read() => value;
      ''');
      final runtime = Runtime.ofProgram(p);
      expect(runtime.executeLib(_library, 'main'), 0);
      expect(runtime.executeLib(_library, 'read'), 9);
      expect(runtime.executeLib(_library, 'read'), 9);
      expect(runtime.executeLib(_library, 'main'), 1);
      expect(
        p.typedProgram.globals.where((g) => g.name == 'value').single.kind,
        TypedArgumentKind.integer,
      );
    });
    test(
      'bridge initializers stay lazy across compiler instances, encoded=$encoded',
      () {
        _compile('int main() => 0;');
        const bridge = 'package:globals/host.dart';
        final compiler = Compiler()
          ..defineBridgeTopLevelFunction(
            const BridgeFunctionDeclaration(
              bridge,
              'initializeFromHost',
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              ),
            ),
          );
        final compiled = compiler.compile({
          'globals': {
            'main.dart':
                '''
        import '$bridge';
        int value = initializeFromHost();
        int main() => value;
      ''',
          },
        });
        final runtime = Runtime.ofProgram(
          encoded ? Program.read(compiled.write().buffer) : compiled,
        );
        var attempts = 0;
        runtime.registerBridgeFunc(bridge, 'initializeFromHost', (
          runtime,
          target,
          args,
        ) {
          attempts++;
          if (attempts == 1) throw StateError('Retry initialization');
          return $int(23);
        });
        expect(attempts, 0);
        expect(() => runtime.executeLib(_library, 'main'), throwsA(anything));
        expect(runtime.executeLib(_library, 'main'), 23);
        expect(runtime.executeLib(_library, 'main'), 23);
        expect(attempts, 2);
      },
    );
    test(
      'write before first read suppresses initialization, encoded=$encoded',
      () {
        final runtime = Runtime.ofProgram(
          program('''int count = 0; int value = initialize();
        int initialize() { count++; return 9; }
        int main() { value = 17; return value; } int calls() => count;
      '''),
        );
        expect(runtime.executeLib(_library, 'main'), 17);
        expect(runtime.executeLib(_library, 'calls'), 0);
      },
    );
    test(
      'forward dependencies choose stable native storage, encoded=$encoded',
      () {
        final p = program('''var first = second + 2; var second = 5;
        int main() => first;
      ''');
        final runtime = Runtime.ofProgram(p);
        expect(runtime.executeLib(_library, 'main'), 7);
        expect(
          p.typedProgram.globals.where((g) => g.name == 'first').single.kind,
          TypedArgumentKind.integer,
        );
        expect(
          p.typedProgram.globals.where((g) => g.name == 'second').single.kind,
          TypedArgumentKind.integer,
        );
      },
    );
    test(
      'cyclic initialization throws and can retry after a write, encoded=$encoded',
      () {
        final runtime = Runtime.ofProgram(
          program('''int first = second + 1;
        int second = first + 1;
        int main() => first; void repair() { second = 4; }
      '''),
        );
        expect(() => runtime.executeLib(_library, 'main'), throwsA(anything));
        runtime.executeLib(_library, 'repair');
        expect(runtime.executeLib(_library, 'main'), 5);
      },
    );
    test(
      'failed initializer retries without an explicit slot write, encoded=$encoded',
      () {
        final runtime = Runtime.ofProgram(
          program('''int attempts = 0; int divisor = 0;
        int value = initialize(); int initialize() { attempts++; return 7 ~/ divisor; }
        int main() => value; int calls() => attempts;
        void repair() { divisor = 1; }
      '''),
        );
        expect(() => runtime.executeLib(_library, 'main'), throwsA(anything));
        runtime.executeLib(_library, 'repair');
        expect(runtime.executeLib(_library, 'main'), 7);
        expect(runtime.executeLib(_library, 'main'), 7);
        expect(runtime.executeLib(_library, 'calls'), 2);
      },
    );
    test(
      'explicit initializer writes survive failure and final return wins, encoded=$encoded',
      () {
        final runtime = Runtime.ofProgram(
          program('''int value = initialize();
        int divisor = 0; int initialize() { value = 5; return 1 ~/ divisor; }
        int main() => value;
      '''),
        );
        expect(() => runtime.executeLib(_library, 'main'), throwsA(anything));
        expect(runtime.executeLib(_library, 'main'), 5);
        final successful = Runtime.ofProgram(
          program('''int value = initialize();
        int initialize() { value = 5; return 7; } int main() => value;
      '''),
        );
        expect(successful.executeLib(_library, 'main'), 7);
      },
    );
    test(
      'globals and escaping closures retain their owning runtime, encoded=$encoded',
      () {
        final p = program('''int value = 0;
        dynamic main() => () { value++; return value; }; int read() => value;
      ''');
        final first = Runtime.ofProgram(p), second = Runtime.ofProgram(p);
        final closure = first.executeLib(_library, 'main') as EvalCallable;
        expect((closure.call(second, null, []) as $int).$value, 1);
        expect(first.executeLib(_library, 'read'), 1);
        expect(second.executeLib(_library, 'read'), 0);
      },
    );
    test(
      'returned instances and method tearoffs retain their runtime, encoded=$encoded',
      () {
        final p = program('''int value = 0;
        class State { int next() { value++; return value; } }
        dynamic main() => State(); int read() => value;
      ''');
        final first = Runtime.ofProgram(p), second = Runtime.ofProgram(p);
        final instance = first.executeLib(_library, 'main') as $Instance;
        final method = instance.$getProperty(second, 'next') as EvalCallable;
        expect((method.call(second, null, []) as $int).$value, 1);
        expect(first.executeLib(_library, 'read'), 1);
        expect(second.executeLib(_library, 'read'), 0);
      },
    );
    test(
      'static fields read and write through lazy native globals, encoded=$encoded',
      () {
        final runtime = Runtime.ofProgram(
          program('''class State {
        static int value = 4;
        static double fraction = 1.5;
        static bool enabled = true;
        static String label = 'old';
        static int increment() { value++; return value; }
      }
      int main() { State.value = 8; return State.increment(); }
      double fraction() { State.fraction = 2.5; return State.fraction; }
      bool enabled() { State.enabled = false; return State.enabled; }
      String label() { State.label = 'new'; return State.label; }
      '''),
        );
        expect(runtime.executeLib(_library, 'main'), 9);
        expect(runtime.executeLib(_library, 'fraction'), 2.5);
        expect(runtime.executeLib(_library, 'enabled'), false);
        expect(runtime.executeLib(_library, 'label'), 'new');
      },
    );
    test(
      'global initializer conversions preserve lists and primitive kinds, encoded=$encoded',
      () {
        final p = program('''List<int> numbers = [2, 3];
        double ratio = 1; var enabled = !false;
        double forward = later; double later = 1 + 2;
        int main() => numbers[0]; double readRatio() => ratio;
        double readForward() => forward;
        bool readEnabled() => enabled;
      ''');
        final runtime = Runtime.ofProgram(p);
        expect(runtime.executeLib(_library, 'main'), 2);
        expect(runtime.executeLib(_library, 'readRatio'), 1.0);
        expect(runtime.executeLib(_library, 'readForward'), 3.0);
        expect(runtime.executeLib(_library, 'readEnabled'), true);
        expect(
          p.typedProgram.globals.where((g) => g.name == 'ratio').single.kind,
          TypedArgumentKind.doublePrecision,
        );
        expect(
          p.typedProgram.globals.where((g) => g.name == 'enabled').single.kind,
          TypedArgumentKind.boolean,
        );
      },
    );
    test(
      'quotient storage inference and integer bitwise globals, encoded=$encoded',
      () {
        final p = program('''var quotient = 7.0 ~/ 2;
        var bits = (6 & 3) | (8 ^ 1);
        var shifted = (3 << 2) + (16 >> 2);
        int main() => quotient; int readBits() => bits;
        int readShifted() => shifted;
      ''');
        final runtime = Runtime.ofProgram(p);
        // Double ~/ execution is not implemented; verify its inferred storage
        // while exercising the supported integer operators below.
        expect(runtime.executeLib(_library, 'readBits'), 11);
        expect(runtime.executeLib(_library, 'readShifted'), 16);
        for (final name in ['quotient', 'bits', 'shifted']) {
          expect(
            p.typedProgram.globals.where((g) => g.name == name).single.kind,
            TypedArgumentKind.integer,
          );
        }
      },
    );
    test(
      'nullable and late final globals distinguish null from uninitialized, encoded=$encoded',
      () {
        final runtime = Runtime.ofProgram(
          program('''Object? empty;
        late final int once;
        dynamic main() => empty; int read() => once;
        void write() { once = 12; }
      '''),
        );
        expect(runtime.executeLib(_library, 'main'), isNull);
        expect(() => runtime.executeLib(_library, 'read'), throwsA(anything));
        runtime.executeLib(_library, 'write');
        expect(runtime.executeLib(_library, 'read'), 12);
        expect(() => runtime.executeLib(_library, 'write'), throwsA(anything));
      },
    );
  }
}
