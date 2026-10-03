import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test(
    'indexed loops preserve guest reads, mutation and receiver reassignment',
    () {
      const source = r'''
class Adjusted implements List<int> {
  Adjusted(this.values);
  final List<int> values;
  int reads = 0;
  int get length => values.length;
  int operator [](int index) { reads++; return values[index] + 100; }
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
}
int weighted(List<int> values, List<int> weights) {
  var total = 0;
  for (var i = 0; i < values.length; i++) total += values[i] * weights[i];
  return total;
}
int replace(List<int> values, List<int> other) {
  var total = 0;
  for (var i = 0; i < values.length; i++) {
    total += values[i];
    values = other;
  }
  return total;
}
int mutate(List<int> values) {
  var total = 0;
  for (var i = 0; i < values.length; i++) {
    total += values[i];
    values[0]++;
  }
  return total;
}
String main() {
  final values = <int>[1, 2, 3];
  final adjusted = Adjusted(values);
  final weights = <int>[2, 3, 4];
  final empty = Adjusted(<int>[]);
  final native = weighted(values, weights);
  final guest = weighted(adjusted, weights);
  final skipped = weighted(empty, weights);
  final replaced = replace(values, <int>[20, 30, 40]);
  final mutated = mutate(values);
  return '$native,$guest,$skipped,$replaced,$mutated,${values[0]},'
      '${adjusted.reads},${empty.reads}';
}
''';
      for (final (mode, result) in runDynamicFixture(source)) {
        expect(
          result,
          const DynamicFixtureResult.value('20,920,0,71,6,4,3,0'),
          reason: mode,
        );
      }
    },
  );
}
