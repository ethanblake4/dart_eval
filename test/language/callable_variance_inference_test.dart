import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';

const _source = r'''
// @dart=3.0
Type observedT = Object;
Type observedU = Object;
class NullableIdentity {
  T? call<T>(T? value) { observedT = T; return value; }
}
class NumericIdentity {
  T call<T extends num>(T value) { observedT = T; return value; }
}
class DependentIdentity {
  U call<T extends num, U extends T>(U value) {
    observedT = T; observedU = U; return value;
  }
}
class ComparableIdentity {
  T call<T extends Comparable<T>>(T value) { observedT = T; return value; }
}
class RepeatedIdentity {
  T call<T>(T first, T second) { observedT = T; return first; }
}
class NestedIdentity {
  T call<T>(Iterable<T> Function(T) callback, T value) {
    observedT = T; callback(value); return value;
  }
}
class Producer {
  T call<T extends num>() { observedT = T; return 55 as T; }
}
String main() {
  final reports = <String>[];
  String? Function(String?) nullable = NullableIdentity();
  if (nullable(null) != null || observedT != String) throw StateError('nullable result');
  reports.add('nullable:$observedT');
  Object Function(int) numeric = NumericIdentity();
  if (numeric(1) != 1 || observedT != int) throw StateError('numeric result');
  reports.add('num-bound:$observedT');
  Object Function(int) dependent = DependentIdentity();
  if (dependent(2) != 2 || observedT != num || observedU != int) throw StateError('dependent result');
  reports.add('dependent:$observedT/$observedU');
  Object Function(String) comparable = ComparableIdentity();
  if (comparable('s') != 's' || observedT != String) throw StateError('comparable result');
  reports.add('f-bound:$observedT');
  Object Function(int, double) repeated = RepeatedIdentity();
  if (repeated(3, 4.0) != 3 || observedT != num) throw StateError('repeated result');
  reports.add('repeated:$observedT');
  Object Function(List<String> Function(String), String) nested = NestedIdentity();
  if (nested((s) => <String>[s], 's') != 's' || observedT != String) throw StateError('nested result');
  reports.add('nested:$observedT');
  Object Function() producer = Producer();
  if (producer() != 55 || observedT != num) throw StateError('producer result');
  reports.add('return-only:$observedT');
  return reports.join('\n');
}
''';

const _invalidBound = r'''
// @dart=3.0
class NumericIdentity {
  T call<T extends num>(T value) => value;
}
void main() {
  String Function(String) invalid = NumericIdentity();
  print(invalid('s'));
}
''';

void main() {
  test('callable inference rejects a lower solution outside its bound', () {
    expect(
      () => Compiler().compile({
        'bounds': {'main.dart': _invalidBound},
      }),
      throwsA(isA<CompileError>()),
    );
  });
  test('callable variance retains native inferred type arguments', () {
    final program = Compiler().compile({
      'variance': {'main.dart': _source},
    });
    final fresh = Runtime.ofProgram(
      program,
    ).executeLib('package:variance/main.dart', 'main');
    final restored = Runtime(
      program.write().buffer,
    ).executeLib('package:variance/main.dart', 'main');
    expect(restored, fresh);
  });
}
