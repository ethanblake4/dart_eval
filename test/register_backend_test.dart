import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

Object? runSource(
  String source, {
  Map<String, Object?> args = const {},
  bool serialized = false,
}) {
  final program = Compiler().compile({
    'backend_test': {'main.dart': source},
  });
  final runtime = serialized
      ? Runtime(program.write().buffer)
      : Runtime.ofProgram(program);
  final result = runtime.executeLib(
    'package:backend_test/main.dart',
    'main',
    arguments: args,
  );
  return result is $Value ? result : result;
}

void main() {
  test('arithmetic operators execute with their original operand order', () {
    expect(
      runSource(
        'int main(int a, int b) => (a - b) * 3 + a ~/ b;',
        args: {'a': 17, 'b': 4},
      ),
      43,
    );
    expect(runSource('double main() => 9 / 4;'), 2.25);
  });

  test('branch joins select the value from the executed predecessor', () {
    const source = '''
      int main(bool choose) {
        var result = 1;
        if (choose) { result = 10; } else { result = 20; }
        return result + 3;
      }
    ''';
    expect(runSource(source, args: {'choose': true}), 13);
    expect(runSource(source, args: {'choose': false}), 23);
  });

  test('for and do-while continue execute updates and conditions', () {
    expect(
      runSource('''
      int main() {
        var sum = 0;
        for (var i = 0; i < 6; i++) {
          if (i == 2) continue;
          sum += i;
        }
        var remaining = 2;
        do { remaining--; if (remaining > 0) continue; sum += 100; }
        while (remaining > 0);
        return sum;
      }
    '''),
      113,
    );
  });

  test('recursive calls preserve independent frames and return values', () {
    expect(
      runSource('''
      int factorial(int n) {
        if (n <= 1) return 1;
        return n * factorial(n - 1);
      }
      int main() => factorial(6);
    '''),
      720,
    );
  });

  test('optional and named arguments preserve defaults and named order', () {
    const source = '''
      int add(int value, [int amount = 2]) => value + amount;
      int scale(int value, {int factor = 3, int offset = 4}) => value * factor + offset;
      int main() => scale(add(1)) + scale(add(5, 7), offset: 1, factor: 2);
    ''';
    expect(runSource(source), 38);
  });

  test('more than 32 values remain live across a call', () {
    final parameters = [for (var i = 0; i < 48; i++) 'int v$i'].join(', ');
    final arguments = [for (var i = 0; i < 48; i++) '${i + 1}'].join(', ');
    final sum = [for (var i = 0; i < 48; i++) 'v$i'].join(' + ');
    expect(
      runSource('int sum($parameters) => $sum; int main() => sum($arguments);'),
      1176,
    );
  });

  test(
    'serialized bytecode executes the same control flow as in-memory programs',
    () {
      const source = '''
      int twice(int value) => value * 2;
      int main(int count) {
        var sum = 0;
        while (count > 0) { sum += twice(count); count--; }
        return sum;
      }
    ''';
      expect(runSource(source, args: {'count': 5}), 30);
      expect(runSource(source, args: {'count': 5}, serialized: true), 30);
    },
  );

  test('anonymous and local functions receive zero-based boxed arguments', () {
    expect(
      runSource('''
      int main() {
        final plus = (int left, int right) => left + right;
        int twice(int value) => value * 2;
        return twice(plus(3, 4));
      }
    '''),
      14,
    );
  });

  test('top-level tearoffs adapt primitive arguments and named defaults', () {
    expect(
      runSource('''
      int add(int value, {int amount = 3}) => value + amount;
      int main() { final function = add; return function(4) + function(5, amount: 2); }
    '''),
      14,
    );
  });

  test('bound method tearoffs preserve their receiver', () {
    expect(
      runSource('''
      class Counter {
        int value;
        Counter(this.value);
        int add(int amount) { value += amount; return value; }
      }
      int main() {
        final counter = Counter(3);
        final function = counter.add;
        return function(4) + function(2);
      }
    '''),
      16,
    );
  });

  test('class constructors and methods read and update instance fields', () {
    const source = '''
      class Counter {
        int count;
        Counter(this.count);
        int increment(int amount) { count += amount; return count; }
      }
      int main() {
        final counter = Counter(4);
        counter.increment(3);
        return counter.increment(2);
      }
    ''';
    expect(runSource(source), 9);
    expect(runSource(source, serialized: true), 9);
  });
}
