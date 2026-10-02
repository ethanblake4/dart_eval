import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
bool main() {
  var marker = 41;
  try {
    E.selected = E.redirected;
  } catch (_) {
    return false;
  }
  E<int> inferred = E.inferred;
  E<int> named = E.fromNamed;
  return marker == 41 && E.explicit is E<int> && inferred is E<int> && named is E<int> &&
      E.redirected is E<int> && Default.first is Default<num> &&
      E.widened is E<num> && E.widened is! E<int> &&
      E.explicitDouble is E<double> && E.explicitDouble.value is double &&
      E.inferredDouble is E<double> &&
      E.selected.value == 1 && inferred.value == 2 && named.value == 3 &&
      E.redirected.value == 4 && inferred.accepts(2) && !inferred.accepts(2.5) &&
      identical(Link.forward.other, Link.inferred) &&
      identical(SelfRef.second.previous, SelfRef.first);
}

enum E<T extends num> {
  explicit<int>(1), inferred(2), fromNamed.named(3), redirected<int>.redirect(4),
  widened<num>(5), explicitDouble<double>(6), inferredDouble(7.5);
  const E(this.value);
  const E.named(this.value);
  const E.redirect(T value) : this.named(value);
  final T value;
  static E<int> get selected => explicit;
  static set selected(E<int> value) {}
  bool accepts(Object value) => value is T;
}

enum Default<T extends num> { first; }

enum Link<T extends num> {
  forward<int>.link(), inferred(2);
  const Link(this.value) : other = null;
  const Link.link() : value = 0 as T, other = Link.inferred;
  final T value;
  final Link<int>? other;
}

enum SelfRef {
  first, second.withPrevious();
  const SelfRef() : previous = null;
  const SelfRef.withPrevious() : previous = SelfRef.first;
  final SelfRef? previous;
}
''';

void main() {
  test('enum constants retain explicit and inferred constructor types', () {
    final program = Compiler().compile({
      'generic_enum': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:generic_enum/main.dart', 'main'),
        true,
      );
    }
  });
}
