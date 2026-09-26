import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

Program compile(String source) => Compiler().compile({
  'conditions': {'main.dart': source},
});

void expectResult(
  Program program,
  Object? expected, [
  Map<String, Object?> arguments = const {},
]) {
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(
      runtime.executeLib(
        'package:conditions/main.dart',
        'main',
        arguments: arguments,
      ),
      expected,
    );
  }
}

Iterable<TypedInstruction> instructions(TypedProgram program) =>
    program.instructions.map((e) => e.$2);

void main() {
  test('throwing guards retain only promotions on continuing paths', () {
    final program = compile('''
      Never reject() => throw 9;
      int direct(Object x) {
        x is String || reject();
        return x.length;
      }
      int both(bool choose, Object x) {
        choose ? (x is String || (throw 1)) : (x is String || (throw 2));
        return x.length;
      }
      int conjunction(String? text) {
        text == null && (throw 3);
        return text.length;
      }
      int main(bool choose) {
        var result = both(choose, 'abc') + conjunction('four') + direct('ab');
        try { both(choose, 42); } catch (e) { result += e as int; }
        return result;
      }
    ''');
    expectResult(program, 10, {'choose': true});
    expectResult(program, 11, {'choose': false});
    expect(
      () => compile('''
        int main(bool choose, Object x) {
          choose ? (x is String || (throw 1)) : true;
          return x.length;
        }
      '''),
      throwsA(isA<CompileError>()),
    );
  });

  test('nested scalar conditional joins do not box their results', () {
    final program = compile('''
      int main(int a, int b) {
        final low = a < b ? a : b;
        final high = a > b ? a : b;
        return (a == b ? low : (a < b ? high : low)) + low + high;
      }
    ''');
    expect(
      instructions(program.typedProgram).where(
        (op) =>
            op.name.contains('Box') ||
            op.name.contains('FromR') ||
            op.name.contains('FromS') ||
            op.name.contains('FromC'),
      ),
      isEmpty,
    );
    expectResult(program, 17, {'a': 3, 'b': 7});
    expectResult(program, 13, {'a': 7, 'b': 3});
    expectResult(program, 15, {'a': 5, 'b': 5});
  });

  test('nullable scalar arms stay nullable in either order', () {
    final program = compile('''
      class Item { final int value; Item(this.value); }
      int main(bool choose) {
        Item? item = null;
        final left = choose ? item?.value : 3;
        final right = choose ? 5 : item?.value;
        return (left ?? 7) * 10 + (right ?? 9);
      }
    ''');
    expectResult(program, 75, {'choose': true});
    expectResult(program, 39, {'choose': false});
  });

  test(
    'conditional joins preserve mixed values, local state and throwing arms',
    () {
      final program = compile('''
      int main(bool choose) {
        var value = 3;
        final selected = choose ? value : (value = 7);
        final doubleValue = choose ? 1.5 : 2.5;
        final boolValue = choose ? true : value == 7;
        final text = choose ? 'yes' : 'no';
        final mixed = choose ? 4 : 'text';
        final nullable = choose ? null : 2;
        var caught = 0;
        try {
          final result = choose ? (throw 'left') : selected;
          caught += result as int;
          final other = choose ? selected : (throw 'right');
          caught += other as int;
        } catch (e) { caught += 10; }
        return selected * 10000 + value * 1000 + doubleValue.toInt() * 100 +
            (boolValue ? 10 : 0) + text.length +
            (mixed is int ? 1 : 2) + (nullable ?? 0) + caught;
      }
    ''');
      expectResult(program, 33124, {'choose': true});
      expectResult(program, 77233, {'choose': false});
    },
  );

  test('compound numeric conditions branch without boolean temporaries', () {
    final program = compile('''
      int main(int a, int b, int c) {
        if ((a < b && b < c) || !(a < c)) return 7;
        return 9;
      }
    ''');
    final ops = instructions(program.typedProgram).toList();
    expect(ops.where((op) => op.outputs.contains(TypedRegister.e)), isEmpty);
    expect(
      ops.where(
        (op) =>
            op.inputs.length == 2 &&
            (op.immediate == TypedImmediate.branch ||
                op.immediate == TypedImmediate.shortBranch),
      ),
      hasLength(3),
    );
    expectResult(program, 7, {'a': 1, 'b': 2, 'c': 3});
    expectResult(program, 9, {'a': 1, 'b': 4, 'c': 3});
    expectResult(program, 7, {'a': 4, 'b': 2, 'c': 3});
  });

  test('if and ternary conditions preserve short circuit order', () {
    final program = compile('''
      int effects = 0;
      bool mark(int n, bool value) { effects = effects * 10 + n; return value; }
      int main(bool a, bool b, bool c) {
        var result = 0;
        if (mark(1, a) && (mark(2, b) || !mark(3, c))) result = 1;
        result += (mark(4, a) || mark(5, b)) ? 10 : 20;
        return effects * 100 + result;
      }
    ''');
    for (final a in [false, true]) {
      for (final b in [false, true]) {
        for (final c in [false, true]) {
          var effects = 0;
          bool mark(int n, bool value) {
            effects = effects * 10 + n;
            return value;
          }

          var result = 0;
          if (mark(1, a) && (mark(2, b) || !mark(3, c))) result = 1;
          result += (mark(4, a) || mark(5, b)) ? 10 : 20;
          expectResult(program, effects * 100 + result, {
            'a': a,
            'b': b,
            'c': c,
          });
        }
      }
    }
  });

  test('loop conditions preserve assignments, updates and continue edges', () {
    final program = compile('''
      int main() {
        var n = 0;
        var sum = 0;
        while (n < 5 && (n = n + 1) < 5) {
          if (n == 2 || n == 3) continue;
          sum += n;
        }
        for (var i = 0; i < 5 && n > 0; i++) {
          if (i < 2 || i == 4) continue;
          sum += i;
        }
        do {
          n--;
          if (n > 2 && sum > 0) continue;
          sum += n;
        } while (n > 0 && !(sum < 0));
        return sum * 10 + n;
      }
    ''');
    expectResult(program, 130);
  });

  test('skipped exceptions and finally on continue preserve control flow', () {
    final program = compile('''
      bool fail() { throw 7; }
      int main() {
        var sum = 0;
        if (false && fail()) sum += 100;
        if (true || fail()) sum++;
        for (var i = 0; i < 3 && sum > 0; i++) {
          try { if (i < 2 || fail()) continue; }
          catch (e) { sum += 10; }
          finally { sum++; }
        }
        return sum;
      }
    ''');
    expectResult(program, 14);
  });

  test('collection conditions use the same short circuit control flow', () {
    final program = compile('''
      int main() {
        final values = [for (var i = 0; i < 6 && i != 5; i++)
          if (i < 2 || i > 3) i else -i];
        var sum = 0;
        for (final value in values) sum += value;
        return sum;
      }
    ''');
    expectResult(program, 0);
  });

  test('dynamic leaves retain boolean runtime checks', () {
    final program = compile('''
      int main(dynamic value, bool skip) {
        if (skip || value) return 7;
        return 9;
      }
    ''');
    expectResult(program, 7, {'value': 3, 'skip': true});
    expectResult(program, 7, {'value': true, 'skip': false});
    expectResult(program, 9, {'value': false, 'skip': false});
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        () => runtime.executeLib(
          'package:conditions/main.dart',
          'main',
          arguments: {'value': 3, 'skip': false},
        ),
        throwsA(isA<Exception>()),
      );
    }
  });

  test('type test conditions retain existing promotion', () {
    final program = compile('''
      int main(dynamic value) {
        if (value is int && value > 0) return value + 1;
        return 0;
      }
    ''');
    expectResult(program, 4, {'value': 3});
    expectResult(program, 0, {'value': 'text'});
  });

  test('NaN negation branches on unordered comparisons', () {
    final program = compile('''
      int main(double a, double b) {
        return !(a < b) && !(a >= b) ? 7 : 9;
      }
    ''');
    expectResult(program, 7, {'a': double.nan, 'b': 1.0});
    expectResult(program, 9, {'a': 1.0, 'b': 2.0});
    expectResult(program, 9, {'a': 2.0, 'b': 1.0});
  });
}
