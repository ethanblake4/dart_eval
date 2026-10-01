import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'extensions preserve lexical receiver parameters and dynamic bounds',
    () {
      final program = Compiler().compile({
        'extension_bounds': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:extension_bounds/main.dart', 'verify'),
          true,
        );
      }
    },
  );
}

const _source = r'''
extension Echo<T> on T {
  T Function(T) get echo => (_) => this;
  T repeat(T other) => this;
}
class Bounded<S extends num> {
  bool check(S value) {
    S Function(S) fn = value.echo;
    if (fn(value) != value || value.repeat(value) != value) return false;
    if (value is int) {
      S Function(S) promoted = value.echo;
      if (promoted(value) != value || value.repeat(value) != value) return false;
    }
    return true;
  }
}
class Unbounded<S> {
  bool check(S value) {
    S Function(S) fn = value.echo;
    if (fn(value) != value || value.repeat(value) != value) return false;
    if (value is int) {
      S Function(S) promoted = value.echo;
      if (promoted(value) != value || value.repeat(value) != value) return false;
    }
    return true;
  }
}
class DynamicBound<S extends dynamic> {
  bool check(S value) {
    var getterRejected = false;
    try { value.echo; } on NoSuchMethodError { getterRejected = true; }
    var methodRejected = false;
    try { value.repeat(value); } on NoSuchMethodError { methodRejected = true; }
    if (!getterRejected || !methodRejected) return false;
    if (value is int) {
      S Function(S) promoted = value.echo;
      if (promoted(value) != value || value.repeat(value) != value) return false;
    }
    return true;
  }
}
class Instance {
  String get echo => 'instance';
}
String instanceWins<S extends Instance>(S value) => value.echo;
String? nullableInstanceWins<S extends Instance>(S? value) => value?.echo;
bool nullableBound<S extends num>(S? value) {
  S? Function(S?) fn = value.echo;
  return fn(value) == value;
}
bool chained<S extends U, U extends num>(S value) {
  S Function(S) fn = value.echo;
  return fn(value) == value;
}
bool verify() => Bounded<int>().check(2) && Bounded<num>().check(3.5) &&
  Unbounded<int>().check(4) && Unbounded<String?>().check(null) &&
  DynamicBound<int>().check(5) && instanceWins(Instance()) == 'instance' &&
  nullableInstanceWins<Instance>(null) == null &&
  nullableInstanceWins(Instance()) == 'instance' &&
  nullableBound<int>(null) && nullableBound<int>(7) &&
  chained<int, num>(6);
void main() { if (!verify()) throw StateError('extension bounds'); }
''';
