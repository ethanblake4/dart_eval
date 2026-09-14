import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'typed': {'main.dart': source},
}, entrypoint: 'package:typed/main.dart');

void main() {
  test('small loops use relative branches after function relocation', () {
    final program = compile('''
      int sum(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) { result += i; }
        return result;
      }
      int main(int n) => sum(n);
    ''');
    final instructions = <String>[];
    for (var pc = 0; pc < program.code.length;) {
      final instruction = TypedOp.instructions[program.code[pc]];
      instructions.add(instruction.immediate.name);
      pc += instruction.length;
    }
    expect(instructions.contains('shortBranch'), isTrue);
    expect(instructions.contains('branch'), isFalse);
    expect(TypedMachine.run(program, intArguments: [10]), 45);
    expect(
      TypedMachine.run(
        TypedProgram.read(program.write().buffer),
        intArguments: [0],
      ),
      0,
    );
  });
  test('branches widen when a compiled target exceeds signed16 reach', () {
    final body = List.filled(5500, 'n = increment(n);').join();
    final program = compile('''int increment(int n) => n + 1;
      int main(int n, bool run) { if (run) { $body } return n; }
    ''');
    var hasLongBranch = false;
    for (var pc = 0; pc < program.code.length;) {
      final instruction = TypedOp.instructions[program.code[pc]];
      hasLongBranch |= instruction.immediate == TypedImmediate.branch;
      pc += instruction.length;
    }
    expect(hasLongBranch, isTrue);
    expect(
      TypedMachine.run(program, intArguments: [7], boolArguments: [false]),
      7,
    );
    expect(
      TypedMachine.run(program, intArguments: [7], boolArguments: [true]),
      5507,
    );
  });
  test('small integer literals use immediates and preserve signed results', () {
    for (final value in [-32767, -1, 0, 32767]) {
      final program = compile('int main() => $value;');
      expect(program.integers, isEmpty);
      expect(
        TypedOp.instructions[program.code.first].name,
        anyOf('aImmediate', 'bImmediate'),
      );
      expect(TypedMachine.run(program), value);
      expect(
        TypedMachine.run(TypedProgram.read(program.write().buffer)),
        value,
      );
    }
    for (final value in [-32769, -32768, 32768]) {
      final program = compile('int main() => $value;');
      // Unary minus currently lowers as zero minus the positive literal.
      expect(program.integers, contains(value.abs()));
      expect(TypedMachine.run(program), value);
    }
  });
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
  test('unsupported collection construction fails before execution', () {
    expect(() => compile('dynamic main() => [1, 2];'), throwsUnsupportedError);
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
  test('general object identity survives direct calls and caller spills', () {
    final program = compile(
      '''Object choose(Object a, Object b, Object c, Object d, bool first) {
      if (first) return a;
      return d;
    }
    Object main(Object a, Object b, Object c, Object d) {
      var selected = choose(a, b, c, d, false);
      return choose(a, b, c, selected, false);
    }''',
    );
    final values = [
      Object(),
      <int>[1],
      {'x': 2},
      Object(),
    ];
    expect(
      identical(TypedMachine.run(program, objectArguments: values), values[3]),
      isTrue,
    );
    expect(program.functions.first.objectSpillCount, greaterThan(0));
  });
  test('three live object registers rotate across loop phis', () {
    final program = compile(
      '''Object main(Object a, Object b, Object c, int n) {
      var x = a; var y = b; var z = c;
      for (var i = 0; i < n; i++) {
        var previous = x; x = y; y = z; z = previous;
      }
      return x;
    }''',
    );
    final values = [Object(), Object(), Object()];
    for (var count = 0; count < 7; count++) {
      expect(
        identical(
          TypedMachine.run(
            program,
            objectArguments: values,
            intArguments: [count],
          ),
          values[count % 3],
        ),
        isTrue,
      );
    }
  });
  test('nullable references and strings travel in the object bank', () {
    final program = compile('''Object? echo(Object? value) => value;
      Object? main(Object? value) => echo(value);''');
    expect(TypedMachine.run(program, objectArguments: [null]), isNull);
    final value = Object();
    expect(
      identical(TypedMachine.run(program, objectArguments: [value]), value),
      isTrue,
    );
    expect(TypedMachine.run(compile("String main() => 'hello';")), 'hello');
  });
  test('mixed calls retain arbitrary objects and box primitive arguments', () {
    final program = compile(
      '''dynamic choose(int n, Object value, double d, bool keep) {
      if (keep) return value;
      return n;
    }
    dynamic main(int n, Object value, double d, bool keep) => choose(n, value, d, keep);''',
    );
    final value = Object();
    expect(
      identical(
        TypedMachine.run(
          program,
          intArguments: [12],
          objectArguments: [value],
          doubleArguments: [1.5],
          boolArguments: [true],
        ),
        value,
      ),
      isTrue,
    );
    expect(
      TypedMachine.run(
        program,
        intArguments: [12],
        objectArguments: [value],
        doubleArguments: [1.5],
        boolArguments: [false],
      ),
      12,
    );
  });
  test('object equality retains the left receiver semantics', () {
    final program = compile(
      'bool main(Object left, Object right) => left == right;',
    );
    expect(
      TypedMachine.run(program, objectArguments: [_EqualsAnything(), Object()]),
      isTrue,
    );
    expect(
      TypedMachine.run(program, objectArguments: [Object(), _EqualsAnything()]),
      isFalse,
    );
  });
  test('nullable reference branches preserve values', () {
    final program = compile(
      'Object? main(Object? value) { if (value == null) return null; return value; }',
    );
    expect(TypedMachine.run(program, objectArguments: [null]), isNull);
    final value = Object();
    expect(
      identical(TypedMachine.run(program, objectArguments: [value]), value),
      isTrue,
    );
  });
  test('host callback result can return through a primitive bank', () {
    final program = compile(
      'int main(Function callback, dynamic value) => callback(value);',
    );
    expect(
      TypedMachine.run(
        program,
        objectArguments: [(Object? value) => 42, Object()],
      ),
      42,
    );
  });
  test('host callback receives arbitrary positional references', () {
    final program = compile(
      'dynamic main(Function callback, dynamic value) => callback(value);',
    );
    final value = Object();
    expect(
      identical(
        TypedMachine.run(
          program,
          objectArguments: [(Object? argument) => argument, value],
        ),
        value,
      ),
      isTrue,
    );
  });
}

class _EqualsAnything {
  @override
  bool operator ==(Object other) => true;
  @override
  int get hashCode => 0;
}
