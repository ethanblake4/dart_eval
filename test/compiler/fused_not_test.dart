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
      final fused = 'jumpNot$suffix${type == 'int' ? 'AB' : 'FG'}Short';
      test('negated $type $suffix swaps branch edges', () {
        final program = compile('''
          int main($type a, $type b) { if (!(a $symbol b)) return 7; return 9; }
        ''');
        expect(names(program), contains(fused));
        expect(names(program), isNot(contains('eNot')));
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
              compare(a, b) ? 9 : 7,
              reason: '!($a $symbol $b)',
            );
          }
        }
      });
    }
  }
  test('comparison and negation values survive other successor uses', () {
    for (final saved in ['a < b', '!(a < b)']) {
      final program = compile('''
        int main(int a, int b) {
          final saved = $saved;
          var result = 0;
          if (!saved) result = 3;
          if (saved) result += 7; else result += 11;
          return result;
        }
      ''');
      expect(names(program), contains('eLtAB'));
      expect(
        TypedMachine.run(program, intArguments: [1, 2]),
        saved == 'a < b' ? 7 : 14,
      );
      expect(
        TypedMachine.run(program, intArguments: [2, 1]),
        saved == 'a < b' ? 14 : 7,
      );
    }
  });
  for (final operator in ['&&', '||']) {
    for (final negate in [false, true]) {
      test('$operator preserves RHS side effects with negate=$negate', () {
        final predicate = negate ? '!(a < b)' : 'a < b';
        final program = Compiler().compile({
          'typed': {
            'main.dart':
                '''
          int state = 0;
          bool right() { state++; return true; }
          int main(int a, int b) {
            final result = ($predicate) $operator right();
            return state * 10 + (result ? 1 : 0);
          }
        ''',
          },
        });
        for (final (a, b) in [(1, 2), (2, 1)]) {
          final left = negate ? !(a < b) : a < b;
          final calls = operator == '&&' ? left : !left;
          final value = operator == '&&' ? left : true;
          expect(
            Runtime.ofProgram(program).executeLib(
              'package:typed/main.dart',
              'main',
              arguments: {'a': a, 'b': b},
            ),
            (calls ? 10 : 0) + (value ? 1 : 0),
          );
        }
      });
    }
  }
  test('short circuit double NaN preserves negated result', () {
    final program = compile('''
      int main(double a, double b) {
        if (!(a < b) && !(a >= b)) return 7;
        return 9;
      }
    ''');
    expect(TypedMachine.run(program, doubleArguments: [double.nan, 1.0]), 7);
    expect(TypedMachine.run(program, doubleArguments: [1.0, 2.0]), 9);
    expect(TypedMachine.run(program, doubleArguments: [2.0, 1.0]), 9);
  });
}
