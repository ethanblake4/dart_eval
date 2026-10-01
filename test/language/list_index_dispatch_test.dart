import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
import 'dart:collection';

class Values extends ListBase<int> {
  final List<int> data = [3, 7, 9];
  int reads = 0;
  int get length => data.length;
  set length(int value) { data.length = value; }
  int operator [](int index) { reads++; return data[index]; }
  void operator []=(int index, int value) { data[index] = value; }
}
class GenericValues<K, E> extends ListBase<E> {
  final List<E> data;
  GenericValues(this.data);
  int get length => data.length;
  set length(int value) { data.length = value; }
  E operator [](int index) => data[index];
  void operator []=(int index, E value) { data[index] = value; }
}
int readList(List<int> value) => value[0] + value[2];
bool readObject(Object value) {
  if (value is List<int>) return value[0] == 3 && value[2] == 9;
  return false;
}
bool readDynamic(dynamic value) => value[0] == 3 && value[2] == 9;
bool main() {
  final values = Values();
  if (values[0] != 3 || values[2] != 9 || values.reads != 2) {
    throw StateError('direct indexing bypassed guest operator');
  }
  if (readList(values) != 12 || !readObject(values) || !readDynamic(values) ||
      values.reads != 8) {
    throw StateError('widened indexing bypassed guest operator');
  }
  values[1] += 2;
  if (values[1] != 9 || values.reads != 10) {
    throw StateError('compound index assignment failed');
  }
  if (readList(<int>[3, 7, 9]) != 12 ||
      !readObject(<int>[3, 7, 9]) || !readDynamic(<int>[3, 7, 9])) {
    throw StateError('unknown native list indexing failed');
  }
  final reordered = GenericValues<String, int>([3, 7, 9]);
  reordered[1] += 2;
  if (readList(reordered) != 12 || reordered[1] != 9) {
    throw StateError('inherited element type used the wrong type argument');
  }
  final native = <int>[3, 7, 9];
  return native[0] == 3 && native[2] == 9;
}
''';

void main() {
  test('list indexing respects guest operators and boxed result values', () {
    final program = Compiler().compile({
      'list_index': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:list_index/main.dart', 'main'), true);
    }
  });
}
