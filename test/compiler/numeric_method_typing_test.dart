import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('remainder and clamp preserve their numeric static result types', () {
    expect(
      eval('''
        num n = 7;
        int main() {
          int integer = 7.remainder(3);
          double fractional = n.remainder(2.5);
          int clampedInt = integer.clamp(0, 3);
          double clampedDouble = fractional.clamp(0.0, 1.0);
          return clampedInt + clampedDouble.toInt();
        }
      '''),
      2,
    );
  });

  test('numeric method arguments use the result context', () {
    expect(
      eval('''
        T contextType<T>(Object value) => value as T;
        int main() {
          int remainder = 7.remainder(contextType(3));
          int clamped = remainder.clamp(contextType(0), contextType(2));
          return clamped;
        }
      '''),
      1,
    );
  });
}
