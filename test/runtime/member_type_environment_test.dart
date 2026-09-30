import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
class Base {
  T echo<T>(T value) => value;
  T Function() remember<T>(T value) => () => value;
  int increment(int value) => value + 1;
  bool actual<T>() => this is Derived<T>;
}
class Derived<T> extends Base {}
class Generic<T> {
  Generic(this.value);
  final T value;
  T read() => value;
  Type own() => T;
}
mixin Forward<T> on Generic<T> {
  T forward() => super.read();
  Type captured() {
    Type getType() => T;
    return getType();
  }
}
class Applied extends Generic<String> with Forward<String> {
  Applied() : super('value');
}
bool main() {
  final derived = Derived<int>();
  final remembered = derived.remember<String>('kept');
  if (derived.increment(2) != 3 || derived.echo<int>(4) != 4 ||
      derived.echo<String>('text') != 'text' || !derived.actual<int>() ||
      derived.actual<String>() || remembered() != 'kept' ||
      remembered is! String Function()) {
    throw StateError('nongeneric owner lost method arguments or actual type');
  }
  final applied = Applied();
  if (applied.read() != 'value' || applied.forward() != 'value' ||
      applied.own() != String || applied.captured() != String) {
    throw StateError('generic declaring owner lost its environment');
  }
  return true;
}
''';

void main() {
  test('method arguments and generic mixin owners keep their environments', () {
    final program = Compiler().compile({
      'member_env': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:member_env/main.dart', 'main'), true);
    }
  });
}
