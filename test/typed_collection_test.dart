import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'typed': {'main.dart': source},
}, entrypoint: 'package:typed/main.dart');

Set<String> opNames(TypedProgram program) {
  final result = <String>{};
  for (var pc = 0; pc < program.code.length;) {
    final op = TypedOp.instructions[program.code[pc]];
    result.add(op.name);
    pc += op.length;
  }
  return result;
}

void main() {
  test('list length provenance requires every branch to be native', () {
    final program = compile("""
      int main(bool choose) {
        var values = [1];
        if (choose) { values = [2, 3]; }
        return values.length;
      }
    """);
    expect(TypedMachine.run(program, boolArguments: [false]), 1);
    expect(TypedMachine.run(program, boolArguments: [true]), 2);
    final mixed = compile("""
      int main(bool choose, List<int> external) {
        var values = [1];
        if (choose) { values = external; }
        return values.length;
      }
    """);
    expect(opNames(mixed), contains('callVirtual'));
    final runtime = Runtime.ofProgram(
      Compiler().compile({
        'typed': {'main.dart': 'void main() {}'},
      }),
    );
    expect(
      TypedMachine.run(
        mixed,
        boolArguments: [false],
        runtime: runtime,
        objectArguments: [
          $List.wrap([$int(2), $int(3)]),
        ],
      ),
      1,
    );
    expect(
      TypedMachine.run(
        mixed,
        boolArguments: [true],
        runtime: runtime,
        objectArguments: [
          $List.wrap([$int(2), $int(3)]),
        ],
      ),
      2,
    );
  });

  test('canonical list arguments cross calls without reboxing elements', () {
    final program = compile('''
      int read(List<int> values, int index) => values[index] + 2;
      int main(List<int> values, int index) => read(values, index);
    ''');
    final values = $List.wrap([$int(7), $int(11)]);
    expect(
      TypedMachine.run(program, objectArguments: [values], intArguments: [1]),
      13,
    );
    expect(
      () => TypedMachine.run(
        program,
        objectArguments: [values],
        intArguments: [-1],
      ),
      throwsRangeError,
    );
  });
  test('evaluated List subclasses retain their overridden length getter', () {
    expect(
      eval("""
      class Custom implements List<int> {
        int get length => 19;
      }
      int main() => Custom().length;
    """),
      19,
    );
  });
  test('reference backend executes the same String and list intrinsics', () {
    expect(
      eval('''
      int main() {
        final text = 'A' + 'BC';
        final values = [text.length, text[1].length];
        return values.length + values[0] + values[1] + text.codeUnitAt(1);
      }
    '''),
      72,
    );
  });
  test('String intrinsics preserve UTF16 indexing and avoid dynamic calls', () {
    final program = compile('''
      int main(String prefix, String suffix, int index) {
        final text = prefix + suffix;
        return text.length + text[index].length + text.codeUnitAt(index);
      }
    ''');
    expect(
      opNames(program),
      containsAll([
        'rStringConcatS',
        'aStringLengthR',
        'rStringIndexA',
        'aStringCodeUnitR',
      ]),
    );
    expect(opNames(program), isNot(contains('callMethod')));
    final text = 'A\u{1f600}z';
    for (var i = 0; i < text.length; i++) {
      expect(
        TypedMachine.run(
          program,
          objectArguments: ['A\u{1f600}', 'z'],
          intArguments: [i],
        ),
        text.length + 1 + text.codeUnitAt(i),
      );
    }
    expect(
      () => TypedMachine.run(
        program,
        objectArguments: ['A', ''],
        intArguments: [1],
      ),
      throwsRangeError,
    );
  });
  test('list literal mutation and indexed values keep explicit boxing', () {
    final program = compile('''
      int main(int value) {
        final values = [value, value + 1];
        values[0] = value + 2;
        return values.length + values[0] + values[1];
      }
    ''');
    expect(
      opNames(program),
      containsAll([
        'cNewList',
        'listAppendCR',
        'listSetCAR',
        'rListIndexCA',
        'aListLengthR',
      ]),
    );
    expect(TypedMachine.run(program, intArguments: [4]), 13);
    expect(
      TypedMachine.run(
        TypedProgram.read(program.write().buffer),
        intArguments: [8],
      ),
      21,
    );
  });
  test('strings survive calls and repeated operands', () {
    final program = compile('''
      String repeat(String value) => value + value;
      String main(String value) => repeat(value) + value;
    ''');
    expect(TypedMachine.run(program, objectArguments: ['ab']), 'ababab');
  });
}
