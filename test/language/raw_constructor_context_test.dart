import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('raw constructor contexts use generic bounds', () {
    final program = Compiler().compile({
      'raw_context': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:raw_context/main.dart', 'verify'),
        true,
      );
    }
  });
}

const _source = r'''
class A {}
class AA extends A {}
class Box<T extends A> {
  Box(this.value);
  final T value;
  bool accepts(Object value) => value is T;
}
class Dependent<S extends A, T extends S> {
  Dependent(this.first, this.second);
  final S first;
  final T second;
}
abstract class View<T extends A> {}
class Implementation<T extends A> implements View<T> {
  Implementation(this.value);
  final T value;
}
Box returnRaw() => Box(AA());
Box<AA> returnExplicit() => Box(AA());
Box<AA> identity(Box<AA> value) => value;
Box rawParameter(Box value) => value;
class Holder {
  Box field = Box(AA());
}
bool verify() {
  Box raw = Box(AA());
  if (raw is Box<AA> || !raw.accepts(A())) return false;
  Box<AA> explicit = Box(AA());
  if (explicit is! Box<AA> || explicit.accepts(A())) return false;
  var upward = Box(AA());
  if (upward is! Box<AA>) return false;
  Object broad = Box(AA());
  if (broad is! Box<AA>) return false;
  if (returnRaw() is Box<AA> || Holder().field is Box<AA>) return false;
  if (returnExplicit() is! Box<AA> || identity(Box(AA())).accepts(A())) return false;
  if (rawParameter(Box(AA())) is Box<AA>) return false;
  Dependent dependent = Dependent(AA(), AA());
  if (dependent is! Dependent<A, A> || dependent is Dependent<AA, AA>) return false;
  View view = Implementation(AA());
  if (view is! Implementation<A> || view is Implementation<AA>) return false;
  return true;
}
void main() {
  if (!verify()) throw StateError('raw constructor context');
}
''';
