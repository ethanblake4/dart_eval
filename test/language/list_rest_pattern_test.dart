import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
String describe(Object value) => switch (value) {
  <int>[var first, ...var middle, var last] =>
    '$first:${middle.join(',')}:$last',
  _ => 'no match',
};
bool nested(Object value) => switch (value) {
  [1, ...[2, 3], 4] => true,
  _ => false,
};
bool main() {
  if (describe(<int>[1, 2, 3, 4]) != '1:2,3:4' ||
      describe(<int>[1, 4]) != '1::4' ||
      describe(<int>[1]) != 'no match' ||
      describe(<String>['one', 'two']) != 'no match' ||
      !nested(<int>[1, 2, 3, 4]) || nested(<int>[1, 2, 4])) {
    throw StateError('rest matching or minimum length failed');
  }
  var [first, ...middle, last] = <int>[1, 2, 3, 4];
  first.check<Exactly<int>>();
  middle.check<Exactly<List<int>>>();
  last.check<Exactly<int>>();
  [first, ...middle, last] = <int>[5, 6, 7];
  if (first != 5 || middle.single != 6 || last != 7) {
    throw StateError('rest assignment failed');
  }
  var [...Iterable<int> all] = [1, 2, 3];
  all.check<Exactly<Iterable<int>>>();
  if (all.length != 3) throw StateError('rest context failed');
  var [void Function(int) narrowInt, void Function(double) narrowDouble] = [
    (n) { n.check<Exactly<num>>(); },
    (n) { n.check<Exactly<num>>(); },
  ];
  narrowInt(1);
  narrowDouble(2.5);
  try {
    dynamic short = <int>[1];
    var [a, b] = short;
    throw StateError('accepted short list');
  } on StateError catch (e) {
    if (e.message == 'accepted short list') rethrow;
  }
  try {
    dynamic wrong = <String>['wrong'];
    var <dynamic>[int a] = wrong;
    throw StateError('accepted wrong element type');
  } on StateError catch (e) {
    if (e.message == 'accepted wrong element type') rethrow;
  }
  return true;
}
''';

const _customSource = r'''
class ObservedList implements List<int> {
  int lengthReads = 0, indexReads = 0, slices = 0;
  int get length { lengthReads++; return 3; }
  int operator [](int index) { indexReads++; return index + 1; }
  List<int> sublist(int start, [int? end]) {
    slices++;
    return <int>[1, 2, 3].sublist(start, end);
  }
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('unused');
}
bool main() {
  final value = ObservedList();
  if (value case [...]) {} else { return false; }
  if (value case [..._]) {} else { return false; }
  if (value.lengthReads != 0 || value.indexReads != 0 || value.slices != 0) {
    throw StateError('plain rest evaluated list members');
  }
  if (value case [_, ..., _]) {} else { return false; }
  if (value.lengthReads != 1 || value.indexReads != 0 || value.slices != 0) {
    throw StateError('wildcards read list elements');
  }
  if (value case [...var rest]) {
    if (rest.join(',') != '1,2,3') return false;
  } else { return false; }
  if (value.lengthReads != 1 || value.indexReads != 0 || value.slices != 1) {
    return false;
  }
  if (value case [var first, ...var middle, var last]) {
    if (first != 1 || middle.single != 2 || last != 3) return false;
  } else { return false; }
  return value.lengthReads == 2 && value.indexReads == 2 && value.slices == 2;
}
''';

void main() {
  for (final entry in {'rest': _source, 'observed': _customSource}.entries) {
    test(
      'list ${entry.key} patterns preserve matching and evaluation order',
      () {
        final program = Compiler().compile({
          'list_rest': {'main.dart': entry.value},
        });
        for (final runtime in [
          Runtime.ofProgram(program),
          Runtime(program.write().buffer),
        ]) {
          expect(
            runtime.executeLib('package:list_rest/main.dart', 'main'),
            true,
          );
        }
      },
    );
  }
}
