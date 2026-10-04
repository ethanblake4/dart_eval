import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'nested generic calls infer from list evidence inside chained extensions',
    () {
      final program = Compiler().compile({
        'nested_context': {
          'main.dart': '''
          class Box<T> {
            final T value;
            Box(this.value);
          }
          class Operation<T, O> {
            final T value;
            Operation(this.value);
          }
          class Pair<T, S> {
            final T first;
            final S second;
            Pair(this.first, this.second);
          }
          Box<R> choose<R>(List<Box<R>> boxes) => boxes.first;
          T first<T>(List<Box<T>> boxes) => choose(boxes).value;
          Box<Pair<A, B>> pair<A, B>(Box<A> left, Box<B> right) =>
              Box<Pair<A, B>>(Pair<A, B>(left.value, right.value));
          extension Combine<T> on Box<T> {
            Box<Pair<T, S>> combine<S>(Box<S> other) =>
                Box<Pair<T, S>>(Pair<T, S>(value, other.value));
            Box<R> map<R>(R Function(T) callback) => Box<R>(callback(value));
          }
          class Group<T> {
            final List<Box<Operation<T, void>>> operations;
            Group(this.operations);
            Box<T> run(Box<T> inner) => inner
                .combine(choose(operations))
                .map((pair) => pair.first);
            Box<T> runExplicit(Box<T> inner) => inner
                .combine<Operation<T, void>>(choose(operations))
                .map((pair) => pair.first);
          }
          int main() {
            final group = Group<int>([
              Box<Operation<int, void>>(Operation<int, void>(11)),
            ]);
            final ordinary = pair(Box<int>(2), choose([Box<String>('value')]));
            if (ordinary is! Box<Pair<int, String>>) return -1;
            return group.run(Box<int>(7)).value +
                group.runExplicit(Box<int>(7)).value +
                first<int>([Box<int>(6)]) + ordinary.value.first;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:nested_context/main.dart', 'main'),
          22,
        );
      }
    },
  );
}
