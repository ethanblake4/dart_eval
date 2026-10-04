import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('static constant dependencies preserve integer arithmetic', () {
    final program = Compiler().compile({
      'static_integer': {
        'main.dart': r'''
const radix = 1000;
class Encoder {
  static const overshoot = (radix + quick + shell + 2);
  static const radix = 2;
  static const quick = 12;
  static const shell = 18;
  final int length = 3;
  int verify() {
    if (length < 2) return 0;
    else {
      var i = length + overshoot;
      if (i & 1 != 0) i++;
      return i;
    }
  }
}
int verify() => Encoder().verify();
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:static_integer/main.dart', 'verify'),
        38,
      );
    }
  });
}
