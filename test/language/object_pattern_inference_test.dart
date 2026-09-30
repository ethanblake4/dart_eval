import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  void check(String name, String source) {
    test(name, () {
      final program = Compiler().compile({
        'patterns': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:patterns/main.dart', 'main'), true);
      }
    });
  }

  check('omitted arguments follow the subject superclass', '''
Type elementType<T>(List<T> values) => T;
class Base<T> {}
class Child<T> extends Base<T> {
  final T value;
  Child(this.value);
  List<T> get values => [value];
}
bool match(Base<num> input) {
  if (input case Child(values: var values)) {
    return elementType(values) == num;
  }
  return false;
}
bool main() => match(Child<int>(3));
''');

  check('explicit arguments determine getters without widening promotion', '''
Type elementType<T>(List<T> values) => T;
Type staticType<T>(T value) => T;
class Base<T> {}
class Child<T> extends Base<T> {
  final T value;
  Child(this.value);
  List<T> get values => [value];
}
bool match(Base<int> input) {
  if (input case Child<num>(values: var values)) {
    return elementType(values) == num && staticType(input) == Base<int>;
  }
  return false;
}
bool main() => match(Child<int>(3));
''');

  check('unconstrained and dependent arguments use their declared bounds', '''
Type elementType<T>(List<T> values) => T;
class Unbounded<T> {
  final T value;
  Unbounded(this.value);
  List<T> get values => [value];
}
class Bounded<T extends num> {
  final T value;
  Bounded(this.value);
  List<T> get values => [value];
}
class Derived<T, U extends Set<T>> extends Unbounded<T> {
  final U other;
  Derived(super.value, this.other);
  List<U> get others => [other];
}
bool unbounded(Object input) {
  if (input case Unbounded(values: var values)) return elementType(values) == dynamic;
  return false;
}
bool bounded(Object input) {
  if (input case Bounded(values: var values)) return elementType(values) == num;
  return false;
}
bool dependent(Unbounded<int> input) {
  if (input case Derived(values: var values, others: var others)) {
    return elementType(values) == int && elementType(others) == Set<int>;
  }
  return false;
}
bool main() => unbounded(Unbounded<int>(1)) && bounded(Bounded<int>(2)) &&
    dependent(Derived<int, Set<int>>(3, {3})) && !dependent(Unbounded<int>(4));
''');

  check('recursive bounds close unfilled parameters to Object nullable', '''
Type elementType<T>(List<T> values) => T;
class Recursive<T extends Recursive<T>> {
  late final T value;
  List<T> get values => [value];
}
class Leaf extends Recursive<Leaf> {
  Leaf() { value = this; }
}
bool match(Object input) {
  if (input case Recursive(values: var values)) {
    return elementType(values) == Recursive<Object?>;
  }
  return false;
}
bool main() => match(Leaf()) && !match(3);
''');

  check('inference keeps enclosing class parameters distinct by identity', '''
Type elementType<T>(List<T> values) => T;
class Pair<T, U> {
  final T first;
  final U second;
  Pair(this.first, this.second);
  List<T> get firsts => [first];
  List<U> get seconds => [second];
  bool match(Pair<Set<U>, Set<T>> input) {
    if (input case Pair(firsts: var firsts, seconds: var seconds)) {
      return elementType(firsts) == (Set<U>) && elementType(seconds) == (Set<T>);
    }
    return false;
  }
}
bool main() => Pair<int, String>(1, 'one').match(
    Pair<Set<String>, Set<int>>({'one'}, {1}));
''');

  check('interface and function aliases retain their own bounds', '''
Type elementType<T>(List<T> values) => T;
class Pair<T, U> {
  final T first;
  final U second;
  Pair(this.first, this.second);
  List<T> get firsts => [first];
  List<U> get seconds => [second];
}
typedef NumericPair<T extends num> = Pair<T, String>;
typedef Describe<T extends num> = String Function(T);
bool pair(Object input) {
  if (input case NumericPair(firsts: var firsts, seconds: var seconds)) {
    return elementType(firsts) == num && elementType(seconds) == String;
  }
  return false;
}
bool function(Object input) => switch (input) {
  Describe() => true,
  _ => false,
};
bool main() => pair(Pair<int, String>(1, 'one')) &&
    !pair(Pair<Object, String>(Object(), 'one')) &&
    function((num value) => value.toString()) &&
    !function((int value) => value.toString());
''');
}
