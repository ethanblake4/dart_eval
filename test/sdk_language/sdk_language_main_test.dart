import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';

import 'sdk_language.dart';

void main() {
  for (final (name, source) in [
    ('unary', 'void main(List<String> args) { check(args); }'),
    (
      'binary',
      'void main(List<String> args, message) { check(args, message); }',
    ),
    ('optional unary', 'void main([List<String>? args]) { check(args); }'),
    (
      'optional binary',
      '''
void main([List<String>? args, message = 'default', extra = 'extra']) {
  check(args, message);
  if (extra != 'extra') throw StateError('extra default');
}
''',
    ),
    (
      'named defaults',
      '''
void main(List<String> args, {String named = 'default'}) {
  check(args);
  if (named != 'default') throw StateError('named default');
}
''',
    ),
    (
      'named only',
      '''
void main({String named = 'default'}) {
  if (named != 'default') throw StateError('named default');
}
''',
    ),
  ]) {
    test('SDK launcher $name fresh and serialized', () async {
      final sdkTest = SdkTest(
        'main_${name.replaceAll(' ', '_')}.dart',
        TestKind.runnable,
      );
      final sources = [DartSource(sdkTest.uri, '$source\n$_check')];
      final compiler = Compiler();
      setSdkEntrypoints(compiler, sdkTest, sources);
      final program = compiler.compileSources(sources);
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        await executeSdkMain(runtime, sdkTest, sources);
      }
    });
  }

  test('SDK launcher finds main in a part, not an imported library', () async {
    final sdkTest = SdkTest('part_main.dart', TestKind.runnable);
    final sources = [
      DartSource(sdkTest.uri, '''
import 'imported_main.dart' as imported;
part 'main_part.dart';
'''),
      DartSource(
        'package:sdk_language/imported_main.dart',
        "void main({String unrelated = 'import'}) {}",
      ),
      DartSource('package:sdk_language/main_part.dart', '''
part of 'part_main.dart';
void main(List<String> args, message) { check(args, message); }
$_check
'''),
    ];
    final compiler = Compiler();
    setSdkEntrypoints(compiler, sdkTest, sources);
    final program = compiler.compileSources(sources);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      await executeSdkMain(runtime, sdkTest, sources);
    }
  });
}

const _check = '''
void check(List<String>? args, [message]) {
  if (args == null || args.isNotEmpty) throw StateError('launcher args');
  if (message != null) throw StateError('launcher message');
}
''';
