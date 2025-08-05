import 'package:dart_eval/dart_eval.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('diagnostic mode ignore ignores parse warnings', () async {
    final compiler = Compiler()..diagnosticMode = DiagnosticMode.ignore;
    final source = '''
      /// {@nodoc}
      bool fn(){ 
        return true;
      }
      ''';
    expect(
        () => compiler.compile({
              'my_package': {
                'main.dart': source,
              }
            }),
        prints(isEmpty));
  });

  test('diagnostic mode printErrorsAndWarnings prints parse warnings',
      () async {
    final compiler = Compiler()
      ..diagnosticMode = DiagnosticMode.printErrorsAndWarnings;
    final source = '''
      /// {@nodoc}
      bool fn(){ 
        return true;
      }
      ''';
    expect(
        () => compiler.compile({
              'my_package': {
                'main.dart': source,
              }
            }),
        prints(contains('Parsing warning:')));
  });
}
