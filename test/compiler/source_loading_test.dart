import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';
import 'package:test/test.dart';

Iterable<Runtime> _runtimes(Program program) sync* {
  yield Runtime.ofProgram(program);
  yield Runtime(program.write().buffer);
}

void main() {
  test('a failed file parse can be repaired using the same source', () {
    final directory = Directory.systemTemp.createTempSync(
      'eval_source_loading_',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/main.dart')
      ..writeAsStringSync('int main() => ;');
    final source = DartSource.file('package:sources/main.dart', file);
    final compiler = Compiler();
    expect(
      () => compiler.compileSources([source]),
      throwsA(isA<CompileError>()),
    );
    file.writeAsStringSync('int main() => 4;');
    for (final runtime in _runtimes(compiler.compileSources([source]))) {
      expect(runtime.executeLib('package:sources/main.dart', 'main'), 4);
    }
  });

  test('custom source loaders keep the original load contract', () {
    final compiler = Compiler();
    final source = _CustomSource();
    for (var i = 0; i < 2; i++) {
      for (final runtime in _runtimes(compiler.compileSources([source]))) {
        expect(runtime.executeLib('package:sources/main.dart', 'main'), 42);
      }
    }
  });

  test('inactive syntax is skipped until its source becomes selected', () {
    final compiler = Compiler();
    final files = {
      'main.dart': '''
        import 'inactive.dart' if (dart.library.io) 'active.dart';
        int main() => value;
      ''',
      'active.dart': 'const value = 7;',
      'inactive.dart': 'int value = ;',
      'unused.dart': 'This is not Dart source.',
    };
    for (var i = 0; i < 2; i++) {
      for (final runtime in _runtimes(compiler.compile({'sources': files}))) {
        expect(runtime.executeLib('package:sources/main.dart', 'main'), 7);
      }
    }
    files['main.dart'] = "import 'inactive.dart'; int main() => value;";
    expect(
      () => compiler.compile({'sources': files}),
      throwsA(isA<CompileError>()),
    );
    files['inactive.dart'] = 'const value = 9;';
    for (final runtime in _runtimes(compiler.compile({'sources': files}))) {
      expect(runtime.executeLib('package:sources/main.dart', 'main'), 9);
    }
  });

  test('an unimported override part roots its own library', () {
    for (final partOf in ["'owner.dart'", 'shared.name']) {
      final compiler = Compiler();
      final packages = {
        'sources': {
          'main.dart': 'void main() {}',
          'owner.dart': '''
            library shared.name;
            part '' 'override_part.dart';
            const _value = 29;
          ''',
          'other.dart': '''
            library shared.name;
            part 'other_part.dart';
            const _value = 'wrong owner';
          ''',
          'override_part.dart':
              '''
            part of $partOf;
            @RuntimeOverride('#source_loading')
            int callback() => _value;
          ''',
          'other_part.dart': 'part of shared.name; String unused() => _value;',
        },
      };
      for (var i = 0; i < 2; i++) {
        compiler.compile(packages);
        expect(compiler.functionNames.values, contains('callback()'));
      }
      packages['sources']!['override_part.dart'] =
          '''
        part of $partOf;
        @RuntimeOverride('#source_loading', wrong: 'annotation')
        int callback() => _value;
      ''';
      expect(() => compiler.compile(packages), throwsA(isA<CompileError>()));
    }
  });

  test('selected duplicate source URIs retain order and diagnostics', () {
    final compiler = Compiler();
    final main = DartSource(
      'package:sources/main.dart',
      "import 'value.dart'; int main() => value;",
    );
    final earlier = DartSource(
      'package:sources/value.dart',
      'const value = 1;',
    );
    final later = DartSource('package:sources/value.dart', 'const value = 2;');
    for (final runtime in _runtimes(
      compiler.compileSources([main, earlier, later]),
    )) {
      expect(runtime.executeLib('package:sources/main.dart', 'main'), 1);
    }
    expect(
      () => compiler.compileSources([
        main,
        DartSource('package:sources/value.dart', 'const value = ;'),
        later,
      ]),
      throwsA(isA<CompileError>()),
    );
  });
}

class _CustomSource extends DartSource {
  _CustomSource() : super('package:sources/main.dart', '');

  @override
  DartCompilationUnit load(DiagnosticMode diagnosticMode) =>
      DartSource(uri.toString(), 'int main() => 42;').load(diagnosticMode);

  @override
  String toString() => throw StateError('Use the custom load method');
}
