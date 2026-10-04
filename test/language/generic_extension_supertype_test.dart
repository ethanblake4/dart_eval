import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('generic extensions bind through multiple instantiated supertypes', () {
    final program = Compiler().compile({
      'extension_supertype': {
        'base.dart': '''
          class Value<T> {
            final T value;
            Value(this.value);
          }
          class Middle<A, B> extends Value<List<B>> {
            Middle(List<B> value) : super(value);
          }
          class Leaf<C> extends Middle<String, C> {
            Leaf(List<C> value) : super(value);
          }
          extension Combine<T> on Value<T> {
            Value<List<T>> operator &(Value<T> other) =>
                Value<List<T>>([value, other.value]);
            T read() => value;
            T get item => value;
          }
        ''',
        'main.dart': '''
          import 'base.dart';
          int main() {
            final leaf = Leaf<int>([3]);
            final combined = leaf & Value<List<int>>([7]);
            if (combined is! Value<List<List<int>>>) return -1;
            if (leaf.read() is! List<int> || leaf.item is! List<int>) return -2;
            return combined.value[0].single + combined.value[1].single +
                leaf.read().single + leaf.item.single;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:extension_supertype/main.dart', 'main'),
        16,
      );
    }
  });

  test(
    'generic extensions bind inherited interfaces and prefer narrower on types',
    () {
      final program = Compiler().compile({
        'extension_interface': {
          'main.dart': '''
          abstract class Value<T> { T get value; }
          abstract class Middle<T> implements Value<List<T>> {}
          class Leaf<T> extends Middle<T> {
            final List<T> value;
            Leaf(this.value);
          }
          extension Broad<T> on Value<T> {
            T get item => value;
            int operator &(Value<T> other) => 1;
          }
          extension Narrow<T> on Middle<T> {
            int operator &(Value<List<T>> other) => 2;
          }
          class Own<T> extends Leaf<T> {
            Own(List<T> value) : super(value);
            int operator &(Value<List<T>> other) => 3;
          }
          int main() {
            final leaf = Leaf<int>([7]);
            List<int> values = leaf.item;
            return (leaf & leaf) * 10 +
                (Own<int>([8]) & leaf) + values.single;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:extension_interface/main.dart', 'main'),
          30,
        );
      }
    },
  );
}
