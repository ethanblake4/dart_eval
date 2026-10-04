import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'raw bridge constructors infer callback results and retain contexts',
    () {
      final program = Compiler().compile({
        'bridge_constructor': {
          'main.dart': '''
          List<E> method<E>(E value) => List.generate(2, (i) => value);
          class Holder<E> {
            final E value;
            Holder(this.value);
            List<E> generate() => List.generate(2, (i) => value);
          }
          int main() {
            var matrix = List.generate(2,
                (int i) => List<int>.filled(4, 0, growable: false));
            matrix[0][0] = 7;
            if (matrix is! List<List<int>>) return -1;
            final inferred = List.generate(2, (i) => i + 3);
            if (inferred is! List<int>) return -2;
            final filled = List.filled(2, 5);
            if (filled is! List<int>) return -3;
            final from = List.of([6]);
            if (from is! List<int>) return -4;
            final explicit = List<num>.generate(1, (i) => 8);
            if (explicit is! List<num>) return -5;
            List<num> contextual = List.generate(1, (i) => 9);
            if (contextual is! List<num>) return -6;
            final generic = method<String>('value');
            if (generic is! List<String>) return -7;
            final member = Holder<int>(10).generate();
            if (member is! List<int>) return -8;
            final empty = List.empty(growable: true);
            empty.add('unconstrained');
            if (empty is! List<dynamic>) return -9;
            return matrix[0][0] + inferred.first + filled.first +
                from.first + explicit.first.toInt() +
                contextual.first.toInt() + member.first;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:bridge_constructor/main.dart', 'main'),
          48,
        );
      }
    },
  );
}
