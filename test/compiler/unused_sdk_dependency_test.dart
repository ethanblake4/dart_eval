import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  final sources = {
    'facade.dart': "export 'ordinary.dart'; export 'parallel.dart';",
    'ordinary.dart': 'int ordinary() => 42;',
    'parallel.dart': '''
      import 'dart:isolate';
      Future<int> parallel() => Isolate.run(() => 7);
    ''',
  };

  test('unused exported SDK-dependent library needs no runtime binding', () {
    final program = Compiler().compile({
      'sources': {
        ...sources,
        'main.dart': "import 'facade.dart'; int main() => ordinary();",
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:sources/main.dart', 'main'), 42);
    }
  });

  test('reachable SDK-dependent declaration reports its missing import', () {
    expect(
      () => Compiler().compile({
        'sources': {
          ...sources,
          'main.dart': "import 'facade.dart'; main() => parallel();",
        },
      }),
      throwsA(
        isA<CompileError>().having(
          (error) => error.toString(),
          'diagnostic',
          contains("Cannot find import 'dart:isolate'"),
        ),
      ),
    );
  });

  test('missing package imports still fail in an unused library', () {
    expect(
      () => Compiler().compile({
        'sources': {
          ...sources,
          'parallel.dart':
              "import 'package:absent/absent.dart'; int unused() => 0;",
          'main.dart': "import 'facade.dart'; int main() => ordinary();",
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('unsupported SDK import in the entrypoint still fails', () {
    expect(
      () => Compiler().compile({
        'sources': {'main.dart': "import 'dart:isolate'; int main() => 42;"},
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('extension namespace keeps its SDK dependency required', () {
    expect(
      () => Compiler().compile({
        'sources': {
          'main.dart': "import 'extension.dart'; int main() => 42.answer;",
          'extension.dart': '''
            import 'dart:isolate';
            extension Answer on int { int get answer => this; }
          ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
