import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

String _source(String version) {
  final afterGuard = version == '3.8' ? 'int?' : 'int';
  return '''
// @dart = $version
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
class C {
  final int? _value;
  C(this._value);
}
int? nullable(C? c) {
  c?._value!;
  c?._value.check<Exactly<int?>>();
  return c?._value;
}
int main() {
  final c = C(1);
  if (c._value != null) {
    c?._value.check<Exactly<$afterGuard>>();
    c?.._value.check<Exactly<int>>();
  }
  c?._value!;
  c._value.check<Exactly<$afterGuard>>();
  c._value!;
  c._value.check<Exactly<int>>();
  final d = C(2);
  d?.._value!.._value.check<Exactly<int>>();
  d._value.check<Exactly<$afterGuard>>();
  final result = (C(3)?.._value!.._value.check<Exactly<int>>())
      ._value.check<Exactly<$afterGuard>>();
  return c._value! + d._value! + result! + (nullable(null) ?? 0) +
      (nullable(C(4)) ?? 0);
}
''';
}

void main() {
  for (final version in ['3.8', '3.9']) {
    test('Dart $version null-aware access retains versioned field facts', () {
      final program = Compiler().compile({
        'field_flow': {'main.dart': _source(version)},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:field_flow/main.dart', 'main'), 10);
      }
    });
  }
}
