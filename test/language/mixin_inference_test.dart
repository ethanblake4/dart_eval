import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('omitted mixin arguments use the superclass and previous mixins', () {
    final program = Compiler().compile({
      'mixin_inference': {'main.dart': _source, 'support.dart': _supportSource},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:mixin_inference/main.dart', 'verify'),
        true,
      );
    }
  });
}

const _source = r'''
import 'support.dart' as support;

abstract class A<T> {
  T f(T value) => value;
}

class B {}

mixin M<T> on A<T> {
  T g(T value) => value;
  Type parameterType() => T;
  bool accepts(Object? value) => value is T;
}

class Direct extends A<B> with M {}
class Alias = A<B> with M;
class Generic<T> extends A<List<T>> with M {}

mixin Carrier implements A<B> {}
class Previous extends Object with Carrier, M {
  B f(B value) => value;
}

class Explicit extends A<B> with M<B> {}
mixin Free<T> {
  Type parameterType() => T;
}
class Unconstrained with Free {}

mixin Bounds<S extends num, T extends S> {
  Type firstType() => S;
  Type secondType() => T;
  T keep(T value) => value;
}
class Bounded with Bounds {}
class Imported extends support.ImportedBase<int> with support.ImportedMixin {}
mixin Marker {}
class ThroughAlias<T> = support.ImportedChain<T> with Marker;

bool verify() {
  final value = B();
  final direct = Direct();
  final alias = Alias();
  final previous = Previous();
  final explicit = Explicit();
  final generic = Generic<int>();
  final imported = Imported();
  final throughAlias = ThroughAlias<int>();
  final bounded = Bounded();
  B Function(B) directCall = direct.g;
  B Function(B) aliasCall = alias.g;
  B Function(B) previousCall = previous.g;
  List<int> Function(List<int>) genericCall = generic.g;
  final list = <int>[1, 2];
  return direct.parameterType() == B &&
      alias.parameterType() == B &&
      previous.parameterType() == B &&
      explicit.parameterType() == B &&
      generic.parameterType() == (List<int>) &&
      Unconstrained().parameterType() == dynamic &&
      direct.accepts(value) &&
      !direct.accepts('wrong') &&
      generic.accepts(list) &&
      !generic.accepts(<String>['wrong']) &&
      imported.importedType() == int &&
      imported.importedKeep(4) == 4 &&
      imported.importedAccepts(4) &&
      !imported.importedAccepts('wrong') &&
      throughAlias.importedType() == (List<int>) &&
      identical(throughAlias.importedKeep(list), list) &&
      bounded.firstType() == num &&
      bounded.secondType() == num &&
      bounded.keep(2.5) == 2.5 &&
      identical(directCall(value), value) &&
      identical(aliasCall(value), value) &&
      identical(previousCall(value), value) &&
      identical(genericCall(list), list);
}

void main() {
  if (!verify()) throw StateError('omitted mixin arguments');
  print('omitted mixin inference passed');
}

''';

const _supportSource = r'''
abstract class ImportedBase<T> {}

mixin ImportedMixin<T> on ImportedBase<T> {
  T importedKeep(T value) => value;
  Type importedType() => T;
  bool importedAccepts(Object? value) => value is T;
}

class ImportedChain<T> = ImportedBase<List<T>> with ImportedMixin;

''';
