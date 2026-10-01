import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _source = r'''// @dart=3.10
import 'dart:async';
typedef Exactly<T> = T Function(T);
extension Check<T> on T { T check<R extends Exactly<T>>() => this; }
Future<int> main() async {
  final values = [1, 2];
  var sum = 0;
  await for (var value in .fromIterable(values)) {
    value.check<Exactly<int>>();
    sum += value;
  }
  for (var value in .castFrom(values)) {
    if (value != 1 && value != 2) return -1;
  }
  await for (num value in .fromIterable(values)) {
    value.check<Exactly<num>>();
    sum += value.toInt();
  }
  return sum == 6 ? 0 : -2;
}
''';

void main() {
  test(
    'foreach shorthand constructors infer holes and retain declared context',
    () async {
      final program = Compiler().compile({
        'shorthand_foreach': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          await runtime.executeLib(
            'package:shorthand_foreach/main.dart',
            'main',
          ),
          $int(0),
        );
      }
    },
  );
}
