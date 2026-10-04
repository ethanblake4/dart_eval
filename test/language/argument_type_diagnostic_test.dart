import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('delayed diagnostic retains the failed generic invocation type', () {
    final program = Compiler().compile({
      'delayed_error': {
        'main.dart': r'''
T checked<T>(dynamic value) => value as T;
String main() {
  Object? failure;
  try { checked<int>('text'); } catch (error) { failure = error; }
  checked<String>('valid');
  return failure.toString();
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:delayed_error/main.dart', 'main'),
        "type 'String' is not a subtype of type 'int'",
      );
    }
  });
  for (final receiver in ['final target = Bar();', 'dynamic target = Bar();']) {
    for (final nullable in [false, true]) {
      test(
        'argument diagnostics retain source order: $receiver nullable=$nullable',
        () {
          final program = Compiler().compile({
            'argument_error': {
              'main.dart':
                  '''
var bodyCalls = 0;
class Bar {
  call({${nullable ? 'int? i, String? a' : 'required int i, required String a'}}) {
    bodyCalls++;
  }
}
String main() {
  $receiver
  dynamic wrongInt = 'text';
  dynamic wrongString = 3;
  try { target.call(i: wrongInt, a: wrongString); }
  catch (error) {
    if (error is! TypeError || bodyCalls != 0) return 'wrong failure';
    return error.toString();
  }
  return 'no failure';
}
''',
            },
          });
          for (final runtime in [
            Runtime.ofProgram(program),
            Runtime(program.write().buffer),
          ]) {
            expect(
              runtime.executeLib('package:argument_error/main.dart', 'main'),
              "type 'String' is not a subtype of type 'int${nullable ? '?' : ''}'",
            );
          }
        },
      );
    }
  }
}
