import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
class Base<T> { Type get type => T; }
class Contractive<T> extends Base<Contractive<T>> {}
class FixedInner<T> extends Base<FixedInner<FixedInner<int>>> {}
class NonContractive<T> extends Base<NonContractive<NonContractive<T>>> {}
class Left<U> extends Base<Right<U>> {}
class Right<V> extends Base<Left<V>> {}
class RightNested<V> extends Base<Left<Right<V>>> {}
class Bounded<T extends num> {}
class Recursive<T extends Recursive<T>> {}
Type typeOf<T>() => T;
bool main() =>
    Contractive().type == typeOf<Contractive<dynamic>>() &&
    Contractive<bool>().type == typeOf<Contractive<bool>>() &&
    Contractive<Contractive>().type == typeOf<Contractive<Contractive<dynamic>>>() &&
    FixedInner<bool>().type == typeOf<FixedInner<FixedInner<int>>>() &&
    NonContractive().type == typeOf<NonContractive<NonContractive<dynamic>>>() &&
    NonContractive<bool>().type == typeOf<NonContractive<NonContractive<bool>>>() &&
    NonContractive<NonContractive>().type ==
        typeOf<NonContractive<NonContractive<NonContractive<dynamic>>>>() &&
    Left().type == typeOf<Right<dynamic>>() &&
    RightNested<Left<int>>().type == typeOf<Left<Right<Left<int>>>>() &&
    typeOf<List<Contractive>>() == typeOf<List<Contractive<dynamic>>>() &&
    typeOf<(Contractive, {Contractive? value})>() ==
        typeOf<(Contractive<dynamic>, {Contractive<dynamic>? value})>() &&
    typeOf<Contractive Function(Contractive)>() ==
        typeOf<Contractive<dynamic> Function(Contractive<dynamic>)>() &&
    typeOf<List<Bounded>>() == typeOf<List<Bounded<num>>>() &&
    typeOf<List<Recursive>>() ==
        typeOf<List<Recursive<Recursive<dynamic>>>>() &&
    typeOf<List<Contractive?>>() == typeOf<List<Contractive<dynamic>?>>() &&
    typeOf<List<Bounded<num>>>() != typeOf<List<Bounded<int>>>();
''';

void main() {
  test(
    'nested raw types share the identity of their default instantiation',
    () {
      final program = Compiler().compile({
        'types': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:types/main.dart', 'main'), true);
      }
    },
  );
}
