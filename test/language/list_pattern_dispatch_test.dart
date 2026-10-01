import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
class ObservedList implements List<int> {
  final events = <String>[];
  int get length { events.add('length'); return 3; }
  int operator [](int index) { events.add('index $index'); return index + 1; }
  List<int> sublist(int start, [int? end]) {
    events.add('slice $start $end');
    return <int>[1, 2, 3].sublist(start, end);
  }
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('unused');
}
String throughObject(Object value) {
  if (value case <int>[var first, ...var middle, var last]) {
    return '$first:${middle.join(',')}:$last';
  }
  return 'no match';
}
String throughList(List<int> value) {
  if (value case [var first, ...var middle, var last]) {
    return '$first:${middle.join(',')}:$last';
  }
  return 'no match';
}
String throughDynamic(dynamic value) {
  if (value case <int>[var first, ...var middle, var last]) {
    return '$first:${middle.join(',')}:$last';
  }
  return 'no match';
}
String throughNested(Object value) {
  if (value case [<int>[var first, ...var middle, var last]]) {
    return '$first:${middle.join(',')}:$last';
  }
  return 'no match';
}
bool rejectedPrefix(Object value) {
  return switch (value) {
    <int>[0, ...var middle, var last] => false,
    _ => true,
  };
}
bool main() {
  final value = ObservedList();
  for (final read in <String Function(ObservedList)>[
    throughObject, throughList, throughDynamic,
  ]) {
    value.events.clear();
    if (read(value) != '1:2:3' ||
        value.events.join(',') != 'length,index 0,slice 1 2,index 2') {
      throw StateError('guest list access order');
    }
  }
  value.events.clear();
  if (throughNested(<Object>[value]) != '1:2:3' ||
      value.events.join(',') != 'length,index 0,slice 1 2,index 2') {
    throw StateError('nested guest list dispatch');
  }
  value.events.clear();
  if (!rejectedPrefix(value) || value.events.join(',') != 'length,index 0') {
    throw StateError('failed prefix read the remainder');
  }
  if (<int>[1, 2, 3] case [var first, ...var middle, var last]) {
    if (first != 1 || middle.single != 2 || last != 3) return false;
  } else { return false; }
  return true;
}
''';

void main() {
  test('unknown list pattern subjects dispatch guest operators in order', () {
    final program = Compiler().compile({
      'list_dispatch': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:list_dispatch/main.dart', 'main'),
        true,
      );
    }
  });
}
