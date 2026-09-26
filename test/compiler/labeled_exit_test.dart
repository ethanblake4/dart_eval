import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:labeled_exit/main.dart';

void _expectResult(String source, Object expected) {
  final program = Compiler().compile({
    'labeled_exit': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('nested break targets run finally before the selected exit', () {
    _expectResult(r'''
      String route(bool leaveOuter) {
        var trace = '';
        var count = 0;
        void mark(String text, int amount) {
          trace += text;
          count += amount;
        }
        outer: {
          inner: {
            try {
              try {
                if (leaveOuter) break outer;
                break inner;
              } finally {
                mark('A', 1);
              }
            } finally {
              mark('B', 10);
            }
          }
          trace += 'I';
        }
        return '${trace}O:$count';
      }
      bool main() =>
          route(false) == 'ABIO:11' && route(true) == 'ABO:11';
    ''', true);
  });

  test('break reaches its label while return still leaves the function', () {
    _expectResult('''
      int marker = 0;
      int run(bool leaveByBreak) {
        marker = 0;
        label: {
          try {
            if (leaveByBreak) break label;
            return marker;
          } finally {
            marker += 1;
          }
        }
        return marker * 10 + 1;
      }
      bool main() {
        final broken = run(true);
        final returned = run(false);
        return broken == 11 && returned == 0 && marker == 1;
      }
    ''', true);
  });

  test('break reaches its label while throw escapes after finally', () {
    _expectResult('''
      int marker = 0;
      int run(bool shouldThrow) {
        marker = 0;
        label: {
          try {
            if (shouldThrow) throw 'failed';
            break label;
          } finally {
            marker += 4;
          }
        }
        return marker;
      }
      bool main() {
        if (run(false) != 4) return false;
        try {
          run(true);
        } catch (error) {
          return error == 'failed' && marker == 4;
        }
        return false;
      }
    ''', true);
  });

  test('a break only to the outer label leaves inner code unreachable', () {
    _expectResult('''
      int main() {
        var count = 0;
        outer: {
          inner: {
            try {
              break outer;
            } finally {
              count += 1;
            }
            count += 1000;
          }
          count += 100;
        }
        return count;
      }
    ''', 1);
  });
}
