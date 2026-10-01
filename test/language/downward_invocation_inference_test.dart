import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
final reports = <String>[];
T identity<T>(T value) { reports.add('$T'); return value; }
T bounded<T extends num>(T value) { reports.add('$T'); return value; }
List<T> singleton<T>(T value) { reports.add('$T'); return <T>[value]; }
List<List<T>> nested<T>(T value) { reports.add('$T'); return <List<T>>[<T>[value]]; }
T named<T>({required T value}) { reports.add('$T'); return value; }
T lexical<T>(T value) => identity(value);
({X fixed, Y loose}) pair<X, Y>(X first, Y second) {
  reports.add('pair:$X/$Y'); return (fixed: first, loose: second);
}
String main() {
  num? nullable = identity(null);
  num? numeral = identity(3);
  num scalar = identity(3);
  Object object = identity(3);
  Object? objectQuestion = identity(3);
  dynamic dynamicValue = identity(3);
  List<num> list = singleton(3);
  List<List<num>> nestedList = nested(3);
  Object clamped = bounded(3);
  int? nullableBoundedInt = bounded(3);
  num? nullableBoundedNum = bounded(3);
  Object? nullableBoundedObject = bounded(3);
  final collection = <num>[?identity(null), ?identity(3), ?named(value: 4)];
  final fromLexical = lexical<num?>(null);
  ({num fixed, dynamic loose}) partial = pair(3, 's');
  if (nullable != null || numeral != 3 || scalar != 3 || object != 3 ||
      objectQuestion != 3 || dynamicValue != 3 || list.single != 3 ||
      nestedList.single.single != 3 || clamped != 3 ||
      nullableBoundedInt != 3 || nullableBoundedNum != 3 ||
      nullableBoundedObject != 3 ||
      collection.length != 2 || collection[0] != 3 || collection[1] != 4 ||
      fromLexical != null || partial.fixed != 3 || partial.loose != 's') {
    throw StateError('downward inference values changed');
  }
  return reports.join('\n');
}
''';

const _expected =
    'num?\nnum?\nnum\nObject\nObject?\nint\nnum\nnum\nnum\nint\nnum\nnum\n'
    'num?\nnum?\nnum?\nnum?\npair:num/dynamic';

void main() {
  test('known downward arguments survive upward invocation inference', () {
    final program = Compiler().compile({
      'downward': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:downward/main.dart', 'main'),
        _expected,
      );
    }
  });
}
