import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'imported super formals use instantiated superclass parameter types',
    () {
      final program = Compiler().compile({
        'super_formal': {
          'parent.dart': '''
          class Box<V> {
            final V value;
            Box(this.value);
          }
          class Parent<R, S> {
            final Iterable<Box<R>> children;
            final S label;
            Parent(Iterable<Box<R>> children, {required S label})
                : children = children, label = label;
            Parent.named(Iterable<Box<R>> children, {required S label})
                : children = children, label = label;
          }
        ''',
          'child.dart': '''
          import 'parent.dart';
          class Child<T> extends Parent<T, List<T>> {
            Child(super.children, {required super.label});
            Child.named(super.children, {required super.label}) : super.named();
          }
          class Grandchild<U> extends Child<U> {
            Grandchild(super.children, {required super.label});
          }
          Child<T> make<T>(T value) => Child([Box(value)], label: [value]);
        ''',
          'main.dart': '''
          import 'parent.dart';
          import 'child.dart';
          int main() {
            final inferred = Child([Box(3)], label: [4]);
            final named = Child<int>.named([Box(5)], label: [6]);
            final nested = Grandchild<int>([Box(7)], label: [8]);
            final lexical = make<int>(9);
            if (inferred is! Child<int>) return -1;
            if (lexical is! Parent<int, List<int>>) return -2;
            return inferred.children.first.value + inferred.label.first +
                named.children.first.value + named.label.first +
                nested.children.first.value + nested.label.first +
                lexical.children.first.value;
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:super_formal/main.dart', 'main'),
          42,
        );
      }
    },
  );
}
