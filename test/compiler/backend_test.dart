import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'typed': {'main.dart': source},
}, entrypoint: 'package:typed/main.dart');

List<String> callSetup(TypedProgram program) {
  final entry = program.functions[program.entryFunction].entry;
  final result = <String>[];
  for (final (pc, instruction) in program.instructions) {
    if (pc < entry) continue;
    if (instruction.name == 'call') return result;
    result.add(instruction.name);
  }
  throw StateError('Expected a direct call');
}

void main() {
  for (final closureCall in [false, true]) {
    test('generic exports retain separate owners with '
        '${closureCall ? 'closure' : 'direct'} calls', () {
      final program = Compiler().compile({
        'generic': {
          'main.dart':
              '''
            Type selected<T>(T value) => T;
            Type outer<U>(U value) {
              ${closureCall ? 'final select = selected;' : ''}
              return ${closureCall ? 'select<U>' : 'selected<U>'}(value);
            }
            bool main() => outer<int>(1) == int;
          ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:generic/main.dart', 'main'), true);
      }
    });
  }

  test('inferred generic return type retains the declared callee ABI', () {
    final program = Compiler().compile({
      'generic': {
        'main.dart': '''
          T larger<T extends num>(T a, T b) => a > b ? a : b;
          int main() => larger(2, 5) + 1;
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:generic/main.dart', 'main'), 6);
    }
  });

  test('small loops use relative branches after function relocation', () {
    final program = compile('''
      int sum(int n) {
        var result = 0;
        for (var i = 0; i < n; i++) { result += i; }
        return result;
      }
      int main(int n) => sum(n);
    ''');
    final immediates = <String>[];
    for (final (pc, instruction) in program.instructions) {
      immediates.add(instruction.immediate.name);
      if (instruction.immediate == TypedImmediate.shortBranch) {
        final encoded = program.code[pc + 1] | (program.code[pc + 2] << 8);
        final displacement = encoded >= 0x8000 ? encoded - 0x10000 : encoded;
        final target = pc + instruction.length + displacement;
        expect(
          program.code[target],
          isNot(isIn([TypedOp.jump, TypedOp.jumpShort])),
          reason: 'Loop branches should bypass jump-only blocks',
        );
      }
    }
    expect(immediates.contains('shortBranch'), isTrue);
    expect(immediates.contains('branch'), isFalse);
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
    final body = List.filled(12000, 'n = increment(n);').join();
    final program = compile('''int increment(int n) => n + 1;
      int main(int n, bool run) { if (run) { $body } return n; }
    ''');
    final hasLongBranch = program.instructions.any(
      (e) => e.$2.immediate == TypedImmediate.branch,
    );
    expect(hasLongBranch, isTrue);
    expect(
      TypedMachine.run(program, intArguments: [7], boolArguments: [false]),
      7,
    );
    expect(
      TypedMachine.run(program, intArguments: [7], boolArguments: [true]),
      12007,
    );
  });
  test('small integer literals use immediates and preserve signed results', () {
    for (final value in [-32767, -1, 0, 32767]) {
      final program = compile('int main() => $value;');
      expect(program.integers, isEmpty);
      expect(
        program.instructions.first.$2.name,
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
    expect(program.instructions.map((e) => e.$2.family), contains('Sub'));
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
  test('loop phi preserves an unboxed string assigned from a bridge call', () {
    final program = Compiler().compile({
      'typed': {
        'main.dart': '''
          String main() {
            var value = 'a-a';
            for (var i = 0; i < 2; i++) {
              value = value.replaceAll('a', i.toString());
            }
            return value;
          }
        ''',
      },
    });
    for (final candidate in [program, Program.read(program.write().buffer)]) {
      expect(
        Runtime.ofProgram(
          candidate,
        ).executeLib('package:typed/main.dart', 'main'),
        '0-0',
      );
    }
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
  test('map construction executes through the typed backend', () {
    final program = compile('dynamic main() => {1: 2};');
    expect(TypedMachine.run(program), {1: 2});
    expect(TypedMachine.run(TypedProgram.read(program.write().buffer)), {1: 2});
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
  test('register calls preserve reversed arguments and live caller values', () {
    final program = compile('''int difference(int x, int y) => x - y;
      int main(int x, int y) {
        var reversed = difference(y, x);
        return reversed + x + y;
      }''');
    expect(TypedMachine.run(program, intArguments: [13, 4]), 8);
    expect(
      TypedMachine.run(
        TypedProgram.read(program.write().buffer),
        intArguments: [13, 4],
      ),
      8,
    );
    expect(callSetup(program), contains('aBSwap'));
    expect(program.functions.first.objectOutgoingCount, 0);
    expect(program.functions.last.objectOutgoingCount, 0);
  });
  for (final (type, swap) in [('int', 'aBSwap'), ('double', 'fGSwap')]) {
    test('$type reversed call arguments swap without spilling', () {
      final program = compile('''
        $type difference($type a, $type b) => a - b;
        $type main($type a, $type b) => difference(b, a);
      ''');
      expect(callSetup(program), [swap]);
      for (final executable in [
        program,
        TypedProgram.read(program.write().buffer),
      ]) {
        expect(
          TypedMachine.run(
            executable,
            intArguments: type == 'int' ? [13, 4] : [],
            doubleArguments: type == 'double' ? [13.5, 4.25] : [],
          ),
          type == 'int' ? -9 : -9.25,
        );
      }
    });
  }
  test('three object call arguments rotate with two swaps', () {
    final values = [
      Object(),
      <int>[1, 2],
      {'value': 3},
    ];
    for (final order in [
      [1, 2, 0],
      [2, 0, 1],
    ]) {
      final arguments = order.map((index) => ['a', 'b', 'c'][index]).join(', ');
      final program = compile('''
        Object select(Object a, Object b, Object c, int index) {
          if (index == 0) return a;
          if (index == 1) return b;
          return c;
        }
        Object main(Object a, Object b, Object c, int index) =>
            select($arguments, index);
      ''');
      final setup = callSetup(program);
      expect(setup.where((name) => name.endsWith('Swap')), hasLength(2));
      expect(
        setup.where(
          (name) => name.endsWith('Spill') || name.endsWith('Reload'),
        ),
        isEmpty,
      );
      for (final executable in [
        program,
        TypedProgram.read(program.write().buffer),
      ]) {
        for (var index = 0; index < 3; index++) {
          expect(
            TypedMachine.run(
              executable,
              intArguments: [index],
              objectArguments: values,
            ),
            same(values[order[index]]),
          );
        }
      }
    }
  });
  test('repeated call arguments occupy separate incoming registers', () {
    final program = compile('''int combine(int x, int y) => x + y;
      int main(int x) => combine(x, x);''');
    expect(TypedMachine.run(program, intArguments: [17]), 34);
    expect(program.functions.first.objectOutgoingCount, 0);
  });
  test('unused parameters retain their positions in the register ABI', () {
    final program = compile(
      '''int last(int unused, int second, int third) => third;
      int main(int unused, int second, int third) => last(unused, second, third);''',
    );
    expect(TypedMachine.run(program, intArguments: [3, 7, 19]), 19);
    expect(
      program.functions.first.argumentKinds,
      List.filled(3, TypedArgumentKind.integer),
    );
    expect(program.functions.first.objectOutgoingCount, 0);
    expect(
      program.functions.last.argumentKinds,
      List.filled(3, TypedArgumentKind.integer),
    );
  });
  test('more than 32 values remain live across a call', () {
    final parameters = [for (var i = 0; i < 48; i++) 'int v$i'].join(', ');
    final arguments = [for (var i = 0; i < 48; i++) '${i + 1}'].join(', ');
    final sum = [for (var i = 0; i < 48; i++) 'v$i'].join(' + ');
    final program = compile(
      'int sum($parameters) => $sum; int main() => sum($arguments);',
    );
    expect(TypedMachine.run(program), 1176);
    expect(TypedMachine.run(TypedProgram.read(program.write().buffer)), 1176);
  });
  test('incoming register definitions emit no argument loads', () {
    final program = compile(
      'int main(int first, int second) => second - first;',
    );
    final names = [for (final e in program.instructions) e.$2.name];
    expect(names.any((name) => name.endsWith('Argument')), isFalse);
    expect(TypedMachine.run(program, intArguments: [6, 21]), 15);
  });
  test('excess double and boolean arguments use spare object registers', () {
    final program = compile('''double choose(double a, bool x, double b,
          bool y, double c, bool z) {
        if (x) return a;
        if (y) return b;
        if (z) return c;
        return 0.0;
      }
      double main(double a, double b, double c, bool x, bool y, bool z) =>
          choose(c, z, a, x, b, y);''');
    expect(
      TypedMachine.run(
        program,
        doubleArguments: [2.5, 7.5, 9.5],
        boolArguments: [false, true, false],
      ),
      7.5,
    );
    expect(program.functions.first.objectOutgoingCount, 0);
  });
  test(
    'string and boxed parameters share object registers and one overflow list',
    () {
      final program = compile('''String choose(String a, Object b, String c,
          Object d) => c;
      String main(String a, Object b, String c, Object d) =>
          choose(c, d, a, b);''');
      expect(
        TypedMachine.run(
          program,
          objectArguments: ['first', Object(), 'third', Object()],
        ),
        'first',
      );
      expect(program.functions.first.objectOutgoingCount, 2);
      expect(program.functions.first.argumentKinds, [
        TypedArgumentKind.string,
        TypedArgumentKind.object,
        TypedArgumentKind.string,
        TypedArgumentKind.object,
      ]);
    },
  );
  test('five integer arguments fit dedicated and object registers', () {
    final program = compile('''int sum(int a, int b, int c, int d, int e) =>
          a + b + c + d + e;
      int main() => sum(1, 2, 3, 4, 5);''');
    expect(TypedMachine.run(program), 15);
    expect(program.functions.first.objectOutgoingCount, 0);
    final names = [for (final e in program.instructions) e.$2.name];
    expect(names, contains(anyOf('rFromA', 'rFromB')));
    expect(names.any((name) => name.startsWith('rBox')), isFalse);
    expect(names, isNot(contains('cLoadOutgoing')));
  });
  test('six integer arguments preserve overflow across recursive calls', () {
    final program = compile(
      '''int recur(int n, int a, int b, int c, int d, int e) {
        if (n == 0) return a + b + c + d + e;
        return recur(n - 1, e, d, c, b, a) + a + e;
      }
      int main(int n) => recur(n, 1, 2, 3, 4, 5);''',
    );
    expect(TypedMachine.run(program, intArguments: [2]), 27);
    expect(TypedMachine.run(program, intArguments: [3]), 33);
    expect(program.functions.first.objectOutgoingCount, 2);
    expect(program.functions.last.objectOutgoingCount, 2);
  });
  test('one C list carries mixed primitive excess arguments', () {
    final program = compile('''double choose(Object first, Object second,
          double a, double b, double c, bool x, bool y, bool z) {
        if (z) return c;
        return a;
      }
      double main(Object first, Object second,
          double a, double b, double c, bool x, bool y, bool z) =>
          choose(second, first, a, b, c, x, y, z);''');
    expect(
      TypedMachine.run(
        program,
        objectArguments: [Object(), Object()],
        doubleArguments: [1.5, 2.5, 9.5],
        boolArguments: [false, false, true],
      ),
      9.5,
    );
    expect(program.functions.first.objectOutgoingCount, 3);
  });
  test('only arguments beyond register capacity use outgoing slots', () {
    final arguments = List.generate(12, (i) => 'int a$i').join(', ');
    final sum = List.generate(12, (i) => 'a$i').join(' + ');
    final values = List.generate(12, (i) => '${i + 1}').join(', ');
    final program = compile(
      'int sum($arguments) => $sum; int main() => sum($values);',
    );
    expect(TypedMachine.run(program), 78);
    expect(program.functions.first.objectOutgoingCount, 8);
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
