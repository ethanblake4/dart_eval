import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _source = r'''typedef Exactly<T> = T Function(T);
extension Check<T> on T { T check<R extends Exactly<T>>() => this; }
Iterable<T> items<T>(List<T> values) => values;
int main() {
  var sum = 0;
  for (var value in [1, 2, 3]) {
    value.check<Exactly<int>>();
    sum += value;
  }
  for (var value in {4, 5}) {
    value.check<Exactly<int>>();
    sum += value;
  }
  for (var value in items([8])) {
    value.check<Exactly<int>>();
    sum += value;
  }
  final projected = [for (var value in [1, 2]) value + 1];
  projected.check<Exactly<List<int>>>();
  List<dynamic> values = [6, 7];
  for (int value in values) sum += value;
  values = ['bad'];
  try {
    for (int value in values) sum += value;
    return -1;
  } on TypeError {}
  return sum == 36 && projected[0] == 2 ? 0 : -2;
}
''';

const _asyncSource = r'''import 'dart:async';
typedef Exactly<T> = T Function(T);
extension Check<T> on T { T check<R extends Exactly<T>>() => this; }
Future<int> main() async {
  var sum = 0;
  await for (var value in Stream.fromIterable([1, 2, 3])) {
    value.check<Exactly<int>>();
    sum += value;
  }
  return sum == 6 ? 0 : -1;
}
''';

void main() {
  test(
    'inferred foreach variables retain element types and explicit casts',
    () {
      final program = Compiler().compile({
        'foreach_inference': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:foreach_inference/main.dart', 'main'),
          0,
        );
      }
    },
  );

  test('await foreach infers the stream element type', () async {
    final program = Compiler().compile({
      'foreach_inference': {'main.dart': _asyncSource},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        await runtime.executeLib('package:foreach_inference/main.dart', 'main'),
        $int(0),
      );
    }
  });
}
