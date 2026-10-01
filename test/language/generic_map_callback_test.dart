import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test(
    'dynamic map checks generic callbacks before constructing lazy results',
    () {
      final program = Compiler().compile({
        'callbacks': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:callbacks/main.dart', 'witness'),
          true,
        );
      }
    },
  );
}

const _source = r'''
class Mapper<E> {
  T generic<T>(Object? value) => value as T;
  int ordinary(int value) => value + 1;
}

int invocations = 0;
T generic<T>(Object? value) {
  invocations++;
  return value as T;
}

bool rejectsBeforeIteration(Function callback) {
  dynamic empty = <int>[];
  try {
    empty.map(callback);
    return false;
  } on TypeError {
    return invocations == 0;
  }
}

bool witness() {
  final mapper = Mapper<String>();
  dynamic dynamicMapper = mapper;
  final int Function(int) instantiated = generic;
  final int Function(int) explicit = generic<int>;
  dynamic values = <int>[1, 2];
  return rejectsBeforeIteration(generic) &&
      rejectsBeforeIteration(mapper.generic) &&
      rejectsBeforeIteration(dynamicMapper.generic) &&
      values.map(instantiated).toList().toString() == '[1, 2]' &&
      values.map(explicit).toList().toString() == '[1, 2]' &&
      values.map(mapper.ordinary).toList().toString() == '[2, 3]';
}

void main() {
  if (!witness()) throw StateError('generic map callback contract');
}
''';
