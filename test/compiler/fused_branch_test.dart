import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'typed': {'main.dart': source},
}, entrypoint: 'package:typed/main.dart');

List<String> names(TypedProgram program) {
  final result = <String>[];
  for (var pc = 0; pc < program.code.length;) {
    final op = TypedOp.instructions[program.code[pc]];
    result.add(op.name);
    pc += op.length;
  }
  return result;
}

void main() {
  for (final (suffix, symbol, compare)
      in <(String, String, bool Function(num, num))>[
        ('Eq', '==', (a, b) => a == b),
        ('Ne', '!=', (a, b) => a != b),
        ('Lt', '<', (a, b) => a < b),
        ('Lte', '<=', (a, b) => a <= b),
        ('Gt', '>', (a, b) => a > b),
        ('Gte', '>=', (a, b) => a >= b),
      ]) {
    for (final type in ['int', 'double']) {
      test('$type $suffix fused branch preserves comparison semantics', () {
        final program = compile('''
          int main($type a, $type b) { if (a $symbol b) return 7; return 9; }
        ''');
        expect(
          names(program),
          contains('jumpNot$suffix${type == 'int' ? 'AB' : 'FG'}Short'),
        );
        final values = type == 'int'
            ? <num>[-3, 0, 4]
            : <num>[
                double.nan,
                double.negativeInfinity,
                -0.0,
                0.0,
                3.5,
                double.infinity,
              ];
        final decoded = TypedProgram.read(program.write().buffer);
        for (final a in values) {
          for (final b in values) {
            expect(
              TypedMachine.run(
                decoded,
                intArguments: type == 'int' ? [a as int, b as int] : [],
                doubleArguments: type == 'double'
                    ? [a as double, b as double]
                    : [],
              ),
              compare(a, b) ? 7 : 9,
              reason: '$a $symbol $b',
            );
          }
        }
      });
    }
  }
  test('nested branches and loop backedges retain successor copies', () {
    final program = compile('''
      int main(int n) {
        var sum = 0;
        for (var i = 0; i < n; i++) {
          if (i < 3) { if (i == 1) sum += 10; else sum += i; }
          else sum += 2;
        }
        return sum;
      }
    ''');
    expect(
      names(program).where((name) => name.startsWith('jumpNot')).length,
      greaterThanOrEqualTo(3),
    );
    expect(TypedMachine.run(program, intArguments: [0]), 0);
    expect(TypedMachine.run(program, intArguments: [7]), 20);
  });
  test('materialized boolean reused in successors remains available', () {
    final program = compile('''
      int main(int a, int b) {
        final saved = a < b;
        var sum = 0;
        if (saved) sum = 3;
        if (saved) sum += 7; else sum += 11;
        return sum;
      }
    ''');
    expect(names(program), contains('eLtAB'));
    expect(TypedMachine.run(program, intArguments: [1, 2]), 10);
    expect(TypedMachine.run(program, intArguments: [2, 1]), 11);
  });
  test('comparison operand side effects and exception paths keep order', () {
    final program = Compiler().compile({
      'typed': {
        'main.dart': '''
      int state = 0;
      int left() { state = state * 10 + 1; return 1; }
      int right() { state = state * 10 + 2; return 2; }
      int main() {
        try {
          if (left() < right()) throw 3;
        } catch (error) { state = state * 10 + 3; }
        finally { state = state * 10 + 4; }
        return state;
      }
    ''',
      },
    });
    expect(
      Runtime.ofProgram(program).executeLib('package:typed/main.dart', 'main'),
      1234,
    );
  });
  test('fused numeric branches widen beyond signed16 reach', () {
    final body = List.filled(12000, 'n = increment(n);').join();
    final program = compile('''
      int increment(int n) => n + 1;
      int main(int n, int limit) { if (n < limit) { $body } return n; }
    ''');
    expect(names(program), contains('jumpNotLtAB'));
    expect(TypedMachine.run(program, intArguments: [7, 0]), 7);
    expect(TypedMachine.run(program, intArguments: [7, 9]), 12007);
  });
  test('six boolean parameters preserve mixed live values through calls', () {
    final program = compile('''
      int count(bool a, bool b, bool c, bool d, bool e, bool f) =>
        (a ? 1 : 0) + (b ? 2 : 0) + (c ? 4 : 0) +
        (d ? 8 : 0) + (e ? 16 : 0) + (f ? 32 : 0);
      int main(bool a, bool b, bool c, bool d, bool e, bool f) =>
        count(f, e, d, c, b, a) + count(a, b, c, d, e, f);
    ''');
    for (var bits = 0; bits < 64; bits++) {
      final flags = List.generate(6, (i) => (bits & (1 << i)) != 0);
      var reversed = 0;
      for (var i = 0; i < 6; i++) {
        if (flags[i]) reversed += 1 << (5 - i);
      }
      expect(TypedMachine.run(program, boolArguments: flags), bits + reversed);
    }
  });
}
