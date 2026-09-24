import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('a typed local supplies the return context for a bare generic call', () {
    expect(
      eval('''
        T choose<T>() => T == int ? 1 as T : 2 as T;
        int main() {
          int value = choose();
          return value;
        }
      '''),
      1,
    );
  });
}
