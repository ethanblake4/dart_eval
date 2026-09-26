import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

TypedProgram compileNumeric(String source) => Compiler().compileTyped({
  'numeric': {'main.dart': source},
}, entrypoint: 'package:numeric/main.dart');

void main() {
  test(
    'commutative operands use one opcode without swapping resident inputs',
    () {
      final program = compileNumeric('int main(int a, int b) => b * a;');
      expect(
        program.instructions.map((e) => e.$2.family),
        ['Mul', 'Return'],
      );
      expect(TypedMachine.run(program, intArguments: [7, 11]), 77);

      final live = compileNumeric('int main(int a, int b) => b * a + a;');
      expect(TypedMachine.run(live, intArguments: [7, 11]), 84);
    },
  );

  test('canonical double arithmetic retains signed zeros and NaNs', () {
    final sum = compileNumeric('double main(double a, double b) => b + a;');
    final product = compileNumeric('double main(double a, double b) => b * a;');
    expect(
      (TypedMachine.run(sum, doubleArguments: [-0.0, -0.0]) as double)
          .isNegative,
      isTrue,
    );
    expect(
      (TypedMachine.run(product, doubleArguments: [-0.0, 2.0]) as double)
          .isNegative,
      isTrue,
    );
    expect(TypedMachine.run(sum, doubleArguments: [double.nan, 1.0]), isNaN);
    expect(
      TypedMachine.run(product, doubleArguments: [1.0, double.nan]),
      isNaN,
    );
  });

  test(
    'integer multiplication division and modulo preserve signed semantics',
    () {
      final program = compileNumeric(
        'int main(int x, int y) => x * y + x ~/ y + x % y;',
      );
      for (final (left, right) in [(17, 4), (-17, 4), (17, -4), (-17, -4)]) {
        expect(
          TypedMachine.run(program, intArguments: [left, right]),
          left * right + left ~/ right + left % right,
        );
      }
    },
  );

  test('floating arithmetic keeps three live parameters in the double bank', () {
    final program = compileNumeric(
      'double main(double a, double b, double c) => (a - b) * (b + c) / (a + c);',
    );
    expect(
      TypedMachine.run(program, doubleArguments: [7.5, 2.5, 1.5]),
      closeTo(20 / 9, 1e-12),
    );
    expect(program.functions.first.doubleSpillCount, greaterThan(0));
  });

  test('floating division preserves infinity and NaN', () {
    final program = compileNumeric('double main(double a, double b) => a / b;');
    expect(
      TypedMachine.run(program, doubleArguments: [1.0, 0.0]),
      double.infinity,
    );
    expect(TypedMachine.run(program, doubleArguments: [0.0, 0.0]), isNaN);
  });

  test('floating comparisons retain IEEE NaN behavior and operand order', () {
    final operators = <String, bool Function(double, double)>{
      '<': (a, b) => a < b,
      '<=': (a, b) => a <= b,
      '>': (a, b) => a > b,
      '>=': (a, b) => a >= b,
      '==': (a, b) => a == b,
      '!=': (a, b) => a != b,
    };
    for (final entry in operators.entries) {
      final program = compileNumeric(
        'bool main(double a, double b) => a ${entry.key} b;',
      );
      for (final (left, right) in [
        (2.0, 3.0),
        (3.0, 2.0),
        (2.0, 2.0),
        (double.nan, 2.0),
      ]) {
        expect(
          TypedMachine.run(program, doubleArguments: [left, right]),
          entry.value(left, right),
          reason: '$left ${entry.key} $right',
        );
      }
    }
  });

  test('integer equality feeds a branch without boxing', () {
    final program = compileNumeric('''
      int main(int a, int b) {
        if (a == b) return a * 2;
        if (a != b) return a - b;
        return 0;
      }
    ''');
    expect(TypedMachine.run(program, intArguments: [4, 4]), 8);
    expect(TypedMachine.run(program, intArguments: [4, 9]), -5);
  });

  test('loop phis keep integer counters separate from double accumulators', () {
    final program = compileNumeric('''
      double main(int count, double step) {
        var value = 0.0;
        while (count > 0) { value = value + step; count--; }
        return value;
      }
    ''');
    expect(
      TypedMachine.run(program, intArguments: [7], doubleArguments: [0.25]),
      1.75,
    );
    expect(
      TypedMachine.run(program, intArguments: [0], doubleArguments: [0.25]),
      0.0,
    );
  });

  test('unused integer division still throws on zero', () {
    final program = compileNumeric(
      'int main(int divisor) { 7 ~/ divisor; return 1; }',
    );
    expect(
      () => TypedMachine.run(program, intArguments: [0]),
      throwsA(isA<Exception>()),
    );
    expect(TypedMachine.run(program, intArguments: [2]), 1);
  });
}
