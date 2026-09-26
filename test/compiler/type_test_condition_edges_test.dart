import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:condition_edges/main.dart';

void expectResult(String source, Object? expected) {
  final program = Compiler().compile({
    'condition_edges': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('negative type guard skips String member on wrong types', () {
    expectResult('''
      int length(Object? value) {
        if (value is! String || value.isEmpty) return 0;
        return value.length;
      }
      int main() => length(4) + length(null) + length('') + length('dart');
    ''', 4);
  });

  test('nested negation and mixed operators promote on each RHS edge', () {
    expectResult('''
      int classify(Object? value) {
        if (!(value is String && !value.isEmpty) ||
            (value is String && value.startsWith('skip'))) return 0;
        if (value.length > 3 &&
            (value.startsWith('a') || value.endsWith('z'))) return 2;
        return 1;
      }
      int main() => classify(7) * 1000 + classify('') * 100 +
          classify('alpha') * 10 + classify('buzz');
    ''', 22);
  });

  test('RHS String calls and side effects follow short-circuit order', () {
    expectResult('''
      int trace = 0;
      bool mark(int digit, bool result) {
        trace = trace * 10 + digit;
        return result;
      }
      bool check(Object? value) {
        return (mark(1, true) && value is String &&
                mark(2, value.startsWith('a'))) ||
            (mark(3, true) && value is String &&
                mark(4, value.endsWith('z')));
      }
      int main() {
        final first = check(3);
        final second = check('apple');
        final third = check('buzz');
        return trace * 10 + (first ? 1 : 0) +
            (second ? 2 : 0) + (third ? 4 : 0);
      }
    ''', 131212346);
  });

  test('OR join does not retain either distinct type promotion', () {
    expectResult('''
      int inspect(Object? value) {
        if ((value is String && value.isNotEmpty) ||
            (value is List<String> && value.isNotEmpty)) {
          if (value is String) return value.length;
          return (value as List<String>).length * 10;
        }
        return 0;
      }
      int main() => inspect('cat') * 100 + inspect(<String>['a', 'b']) +
          inspect(9) + inspect(<String>[]);
    ''', 320);
  });

  test('generic T type checks preserve RHS promotion and negation', () {
    expectResult('''
      int select<T>(Object? value) {
        if (value is T && !(value is String && value.isEmpty)) return 1;
        return 0;
      }
      int main() => select<String>('ok') * 1000 +
          select<String>('') * 100 + select<int>(7) * 10 +
          select<int>('wrong');
    ''', 1010);
  });

  test('assignment between type tests invalidates an earlier promotion', () {
    expectResult('''
      bool main() {
        Object value = 1;
        if (value is int && (value = 1.5) == 1.5 && value is int) {
          return true;
        }
        return false;
      }
    ''', false);
  });

  test('a new type test promotes the value assigned on an earlier edge', () {
    expectResult('''
      bool main() {
        Object value = 1;
        if (value is int && (value = 1.5) == 1.5 &&
            value is double && value > 1.0) {
          return true;
        }
        return false;
      }
    ''', true);
  });

  test('OR and inverted guards see assignments on their continuing edges', () {
    expectResult('''
      bool main() {
        Object left = 1;
        if (!(left is! int || (left = 1.5) == 0.0 || left is int)) {
          Object right = 1;
          if ((right is int && (right = 1.5) == 0.0) ||
              (right is double && right > 1.0)) return true;
        }
        return false;
      }
    ''', true);
  });
}
