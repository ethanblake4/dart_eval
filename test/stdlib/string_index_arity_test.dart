import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('dynamic string indexing and captured methods reject wrong arity', () {
    final program = Compiler().compile({
      'string_arity': {
        'main.dart': r'''
int main() {
  dynamic text = 'foo';
  final method = text.codeUnitAt;
  var failures = 0;
  try { text.codeUnitAt(1, 4); } catch (error) {
    if (error is NoSuchMethodError) failures++;
  }
  try { text.codeUnitAt(); } catch (error) {
    if (error is NoSuchMethodError) failures++;
  }
  try { method(1, 4); } catch (error) {
    if (error is NoSuchMethodError) failures++;
  }
  try { method(); } catch (error) {
    if (error is NoSuchMethodError) failures++;
  }
  int direct = text.codeUnitAt(1);
  int captured = method(1);
  return failures * 1000 + direct + captured;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:string_arity/main.dart', 'main'),
        4222,
      );
    }
  });
}
