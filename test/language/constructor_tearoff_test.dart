import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  void check(String name, String source, Object expected) {
    test(name, () {
      final program = Compiler().compile({
        'tearoff': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:tearoff/main.dart', 'main'),
          expected,
        );
      }
    });
  }

  check('constructor tear-offs preserve defaults and canonical identity', '''
    class Box {
      final int value;
      Box([this.value = 3]);
      Box.named({this.value = 5});
      factory Box.factory(int value) => Box(value);
      Box.redirect(int value) : this(value);
    }
    int main() {
      var unnamed = Box.new;
      var named = Box.named;
      var factory = Box.factory;
      var redirect = Box.redirect;
      if (!identical(Box.new, Box.new)) return -1;
      if (Box.new == Box.named) return -2;
      return unnamed().value + named().value + named(value: 7).value +
          factory(11).value + redirect(13).value;
    }
  ''', 39);

  check('constructor tear-offs instantiate generic class arguments', '''
    class Box<T> {
      final T value;
      Box(this.value);
      factory Box.factory(T value) => Box<T>(value);
    }
    int main() {
      var generic = Box.new;
      var explicit = Box<int>.new;
      Box<int> Function(int) contextual = Box.new;
      var factory = Box<int>.factory;
      if (generic<int>(2) is! Box<int>) return -1;
      if (explicit(3) is! Box<int>) return -2;
      if (contextual(5) is! Box<int>) return -3;
      return explicit(3).value + contextual(5).value + factory(7).value;
    }
  ''', 15);

  check('implicit constructors can be torn off', '''
    class Empty<T> {}
    int main() {
      var create = Empty.new;
      return create<int>() is Empty<int> ? 1 : 0;
    }
  ''', 1);

  check('constructor tear-off defaults use inherited and constant values', '''
    class Value {
      final int value;
      const Value(this.value);
    }
    class Base {
      final Value value;
      final double number;
      Base({this.value = const Value(7), this.number = 2});
    }
    class Derived extends Base {
      Derived({super.value, super.number});
    }
    double main() {
      var create = Derived.new;
      final value = create();
      return value.value.value + value.number;
    }
  ''', 9.0);
}
