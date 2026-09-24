import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('callable facts merge and clear when a binding changes target', () {
    expect(
      eval('''
      int afterBranch(bool replace) {
        Function selected = () => 1;
        if (replace) selected = () => 'ok';
        return selected().length;
      }
      int afterLoop() {
        Function selected = () => 1;
        for (var i = 0; i < 1; i++) {
          selected = () => 'loop';
        }
        return selected().length;
      }
      bool main() => afterBranch(true) == 2 && afterLoop() == 4;
    '''),
      true,
    );
  });

  test('captured promotions retain the binding declared write type', () {
    expect(
      eval('''
      bool main() {
        Object value = 1;
        if (value is int) {
          final replace = () { value = 'updated'; };
          replace();
        }
        return value == 'updated';
      }
    '''),
      true,
    );
  });

  test(
    'captured final bindings reject writes after value metadata changes',
    () {
      expect(
        () => eval('''
      int main() {
        final Object value = 1;
        final replace = () { value = 'updated'; };
        replace();
        return 0;
      }
    '''),
        throwsA(
          isA<CompileError>().having(
            (error) => error.message,
            'message',
            contains('final variable value'),
          ),
        ),
      );
    },
  );

  test('a loop binding keeps its declared type independently of its value', () {
    expect(
      eval('''
      bool main() {
        for (Object value in [1]) {
          value = 'updated';
          if (value != 'updated') return false;
        }
        return true;
      }
    '''),
      true,
    );
  });

  test('indexed compound assignment evaluates each operand once', () {
    expect(
      eval('''
      List<int> values = [1];
      int reads = 0;
      List<int> receiver() { reads += 1; return values; }
      int index() { reads += 10; return 0; }
      int operand() { reads += 100; return 2; }
      bool main() {
        receiver()[index()] += operand();
        return reads == 111 && values[0] == 3;
      }
    '''),
      true,
    );
  });
}
