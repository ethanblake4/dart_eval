import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
Type argumentType<T>() => T;
T context<T>(T value) {
  if (T != argumentType<num?>()) throw StateError('wrong nullable context');
  return value;
}
String? stringValue() => null;
Never fail() => throw StateError('never');
int keyCalls = 0;
int valueCalls = 0;
int? key(bool present) { keyCalls++; return present ? 2 : null; }
String? value(bool present) { valueCalls++; return present ? 'two' : null; }
Null absentKey() { keyCalls++; return null; }
Null absentValue() { valueCalls++; return null; }
List<num> numeric<T extends num?>(T value) => [?value];
List<num> chained<T extends num?, U extends T>(U value) => [?value];
int main() {
  final list = [?stringValue()];
  if (list is! List<String> || list.isNotEmpty) return -1;
  final set = {?stringValue()};
  if (set is! Set<String> || set.isNotEmpty) return -2;
  final map = {?stringValue(): 1};
  if (map is! Map<String, int> || map.isNotEmpty) return -3;
  final values = {1: ?stringValue()};
  if (values is! Map<int, String> || values.isNotEmpty) return -4;
  final typed = <num>[?context(null), ?context(3)];
  if (typed.length != 1 || typed[0] != 3) return -5;
  final skipped = <int, String>{?key(false): value(true)!};
  if (skipped.isNotEmpty || keyCalls != 1 || valueCalls != 0) return -6;
  final kept = <int, String>{?key(true): ?value(true)};
  if (kept[2] != 'two' || keyCalls != 2 || valueCalls != 1) return -7;
  final skippedValue = <int, String>{key(true)!: ?value(false)};
  if (skippedValue.isNotEmpty || keyCalls != 3 || valueCalls != 2) return -8;
  final bottomList = [if (true) ?null, for (final item in <Null>[null]) ?item];
  if (bottomList is! List<Never> || bottomList.isNotEmpty) return -9;
  final bottomSet = {if (true) ?null};
  if (bottomSet is! Set<Never> || bottomSet.isNotEmpty) return -10;
  final bottomMap = {if (true) ?null: 1};
  if (bottomMap is! Map<Never, int> || bottomMap.isNotEmpty) return -11;
  List<Object?> widened = bottomList;
  try { widened.add(1); return -12; } on TypeError {}
  final conditionalThrow = [if (false) fail()];
  if (conditionalThrow.isNotEmpty) return -13;
  final emptyLoopThrow = [for (final item in <int>[]) fail()];
  if (emptyLoopThrow.isNotEmpty) return -14;
  try { [?fail()]; return -15; } on StateError {}
  try { <int, String>{?key(false): fail()}; } on StateError { return -16; }
  if (keyCalls != 4) return -17;
  final nonNull = [?3];
  if (nonNull is! List<int> || nonNull[0] != 3) return -18;
  final knownAbsentKey = {?absentKey(): value(true)!};
  if (knownAbsentKey is! Map<Never, String> || knownAbsentKey.isNotEmpty ||
      keyCalls != 5 || valueCalls != 2) return -19;
  final knownAbsentValue = {key(true)!: ?absentValue()};
  if (knownAbsentValue is! Map<int, Never> || knownAbsentValue.isNotEmpty ||
      keyCalls != 6 || valueCalls != 3) return -20;
  int? changingKey = 7;
  String changeKey() { changingKey = null; return 'seven'; }
  final capturedKey = <int, String>{?changingKey: changeKey()};
  if (capturedKey[7] != 'seven' || changingKey != null) return -21;
  int ordinaryKey = 8;
  final capturedOrdinary = {ordinaryKey: (ordinaryKey = 9).toString()};
  if (capturedOrdinary[8] != '9' || ordinaryKey != 9) return -22;
  String? changingText = 'old';
  int changeText() { changingText = 'new'; return 1; }
  final capturedText = <String, int>{?changingText: changeText()};
  if (capturedText['old'] != 1 || changingText != 'new') return -23;
  if (numeric<num?>(null).isNotEmpty || numeric<num?>(4).single != 4) return -24;
  if (chained<num?, int?>(null).isNotEmpty ||
      chained<num?, int?>(5).single != 5) return -25;
  return 0;
}
''';

void main() {
  test(
    'null-aware elements infer non-null types and evaluate entries in order',
    () {
      final program = Compiler().compile({
        'null_aware_inference': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:null_aware_inference/main.dart', 'main'),
          0,
        );
      }
    },
  );
}
