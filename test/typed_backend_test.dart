import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'typed': {'main.dart': source},
}, entrypoint: 'package:typed/main.dart');

void main() {
  test('source arithmetic lowers to fixed operand bytecodes', () {
    final program = compile('int main(int x, int y) => x - y;');
    expect(TypedMachine.run(program, intArguments: [27, 8]), 19);
    expect(TypedMachine.run(program, intArguments: [8, 27]), -19);
    expect(program.code, contains(anyOf(TypedOp.aSubB, TypedOp.bSubA)));
  });
  test('duplicate operands remain two physical instruction inputs', () {
    final program = compile('int main(int x) => x + x;');
    expect(TypedMachine.run(program, intArguments: [23]), 46);
  });
  test('destructive operation preserves both live inputs', () {
    final program = compile('''int main(int x, int y) {
      var z = x - y;
      return z + x + y;
    }''');
    expect(TypedMachine.run(program, intArguments: [23, 7]), 46);
    expect(program.functions.first.intSpillCount, greaterThan(0));
  });
  test('branch phi preserves either reaching assignment', () {
    final program = compile('''int main(int x, int y) {
      var value = x;
      if (x < y) { value = y - x; } else { value = x - y; }
      return value;
    }''');
    expect(TypedMachine.run(program, intArguments: [8, 23]), 15);
    expect(TypedMachine.run(program, intArguments: [23, 8]), 15);
  });
  test('loop carries accumulator and counter under register pressure', () {
    final program = compile('''int main(int n) {
      var sum = 0;
      for (var i = 0; i < n; i++) { sum += i; }
      return sum;
    }''');
    expect(TypedMachine.run(program, intArguments: [10]), 45);
    expect(TypedMachine.run(program, intArguments: [0]), 0);
  });
  test('continue reaches update and preserves accumulator', () {
    final program = compile('''int main(int n) {
      var sum = 0;
      for (var i = 0; i < n; i++) {
        if (i < 3) continue;
        sum += i;
      }
      return sum;
    }''');
    expect(TypedMachine.run(program, intArguments: [10]), 42);
  });
  test('boolean arguments use their own bank', () {
    final program = compile('bool main(bool value) => !value;');
    expect(TypedMachine.run(program, boolArguments: [true]), false);
    expect(TypedMachine.run(program, boolArguments: [false]), true);
  });
  test('unsupported dynamic behavior fails before execution', () {
    expect(
      () => compile('dynamic main(dynamic x) => x.foo();'),
      throwsUnsupportedError,
    );
  });
  test('direct recursive calls preserve caller values in typed spills', () {
    final program = compile('''
      int fib(int n) { if (n < 2) return n; return fib(n - 1) + fib(n - 2); }
      int main(int n) => fib(n);
    ''');
    expect(TypedMachine.run(program, intArguments: [10]), 55);
    expect(
      TypedMachine.run(
        TypedProgram.read(program.write().buffer),
        intArguments: [8],
      ),
      21,
    );
  });
  test('calls keep integer double and boolean argument banks separate', () {
    final program = compile('''
      double choose(int n, double x, bool plus, double y) {
        if (plus) return x + y;
        return x - y;
      }
      double main(int n, double x, double y) => choose(n, x, n < 3, y);
    ''');
    expect(
      TypedMachine.run(
        program,
        intArguments: [2],
        doubleArguments: [9.5, 1.25],
      ),
      10.75,
    );
    expect(
      TypedMachine.run(
        program,
        intArguments: [4],
        doubleArguments: [9.5, 1.25],
      ),
      8.25,
    );
  });
  test('many arguments are staged independently of register capacity', () {
    final arguments = List.generate(12, (i) => 'int a$i').join(', ');
    final sum = List.generate(12, (i) => 'a$i').join(' + ');
    final values = List.generate(12, (i) => '${i + 1}').join(', ');
    final program = compile(
      'int sum($arguments) => $sum; int main() => sum($values);',
    );
    expect(TypedMachine.run(program), 78);
  });
}
