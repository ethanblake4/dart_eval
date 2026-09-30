import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('plain and contextual calls reuse frames without leaking state', () {
    final program = Compiler().compile({
      'calls': {
        'main.dart': '''
T identity<T>(T value) => value;
int increment(int value) => value + 1;
int factorial(int value) => value <= 1 ? 1 : value * factorial(value - 1);
T capture<T>(T value) {
  T read() => value;
  final result = read();
  increment(1);
  return result;
}
T fail<T extends Object>(T value) => throw value;
class Box<T> {
  final T value;
  Box(this.value);
  T read() => value;
}
int main() {
  int sum = 0;
  for (int i = 0; i < 20; i++) {
    final int value = identity<int>(i);
    sum += increment(value);
    final box = Box<int>(value);
    sum += box.read();
    if (identity<String>('value') != Box<String>('value').read()) return -1;
    sum += increment(capture<int>(i));
    try { fail<String>('failure'); } catch (error) {
      if (error != 'failure') return -2;
    }
    sum += increment(0);
  }
  return sum + factorial(5);
}
''',
      },
    });
    final operations = program.typedProgram.instructions.map(
      (entry) => entry.$2.name,
    );
    expect(operations, contains('callPlain'));
    expect(operations, contains('call'));
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:calls/main.dart', 'main'), 750);
    }
  });
}
