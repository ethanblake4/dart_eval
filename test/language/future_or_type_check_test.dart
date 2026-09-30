import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
import 'dart:async';
bool identity(bool value) => value;
bool matches(Object? value) => switch (value) {
  FutureOr<int>() => true,
  _ => false,
};
bool nullable(Object? value) => switch (value) {
  FutureOr<int?>() => true,
  _ => false,
};
FutureOr<int> assign(dynamic value) => value;
bool rejects(void Function() body) {
  try { body(); } on TypeError { return true; }
  return false;
}
bool main() {
  final future = Future<int>.value(3);
  if (!matches(1) || !matches(future) || matches(identity) || matches('wrong') ||
      matches(null) || !nullable(null) || !nullable(1) || nullable('wrong')) {
    throw StateError('wrong union pattern membership');
  }
  dynamic bad = identity;
  if (bad is FutureOr<int> || !(bad is! FutureOr<int>) ||
      !rejects(() { bad as FutureOr<int>; }) ||
      !rejects(() { assign(bad); }) ||
      !rejects(() { var FutureOr<int>() = bad; })) {
    throw StateError('wrong union checked conversion');
  }
  dynamic one = 1;
  dynamic later = future;
  return assign(one) == 1 && identical(assign(later), future) &&
      (one as FutureOr<int>) == 1 && identical(later as FutureOr<int>, future);
}
''';

void main() {
  test('FutureOr patterns and casts test both union members', () {
    final program = Compiler().compile({
      'future_or_checks': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:future_or_checks/main.dart', 'main'),
        true,
      );
    }
  });
}
