import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _source = '''
Iterable<List<T>> zip<T>(Iterable<Iterable<T>> values) sync* {
  final iterators = values.map((e) => e.iterator).toList(growable: false);
  while (iterators.every((e) => e.moveNext())) {
    yield iterators.map((e) => e.current).toList(growable: false);
  }
}
class Box<T> {
  Box(this.value);
  final T value;
}
bool main(dynamic nativeCheck) {
  final mixed = zip([['a', 'b'], [1, 2]]).toList();
  if (mixed is! List<List<Object>> || mixed[0][0] != 'a' ||
      mixed[1][1] != 2) return false;
  final nested = zip<List<int>>(<Iterable<List<int>>>[
    <List<int>>[<int>[1]], <List<int>>[<int>[2]]
  ]).toList();
  if (nested is! List<List<List<int>>> || nested.single[1].single != 2) return false;
  final box = Box<int>(3);
  final guest = zip<Box<int>>(<Iterable<Box<int>>>[
    <Box<int>>[box]
  ]).toList();
  if (guest is! List<List<Box<int>>> || !identical(guest.single.single, box)) return false;
  final rows = zip<int>(<Iterable<int>>[<int>[4], <int>[5]]).toList();
  if (!rows.every(nativeCheck)) return false;
  dynamic mutable = mixed;
  try { mutable.add(<String>['valid covariance']); } on TypeError { return false; }
  try { mutable.add(<int>[6]); } on TypeError { return false; }
  try { mutable.add('wrong'); return false; } on TypeError {}
  return true;
}
bool native(dynamic values) {
  final rows = zip<int>(values).toList();
  return rows is List<List<int>> && rows.single[0] == 7 && rows.single[1] == 8;
}
bool rejectsNative(dynamic values) {
  try { zip<int>(values).toList(); return false; } on TypeError { return true; }
}
bool rejectsGuest() {
  dynamic wrong = <Box<String>>[Box<String>('wrong')];
  final lazy = <int>[1].map<List<Box<int>>>((e) => wrong);
  try { lazy.toList(); return false; } on TypeError {}
  dynamic wrongInput = <Iterable<String>>[<String>['wrong']];
  try { zip<int>(wrongInput).toList(); return false; } on TypeError {}
  return true;
}
bool rejectsNativeCallback(dynamic callback) {
  final lazy = <int>[1].map<int>(callback);
  try { lazy.toList(); return false; } on TypeError { return true; }
}
''';

void main() {
  final program = Compiler().compile({
    'probe': {'main.dart': _source},
  });
  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('encoded', Runtime(program.write().buffer)),
  ]) {
    test('$mode nested generator and callback witnesses', () {
      expect(
        runtime.executeLib(
          'package:probe/main.dart',
          'main',
          arguments: {
            'nativeCheck': (List<Object?> row) =>
                row.length == 2 && row.every((value) => value is int),
          },
        ),
        isTrue,
      );
      expect(runtime.bridgeCallTypeArguments, isEmpty);
    });

    test('$mode native nested schema checks remain strict', () {
      // Initialize the runtime type table before constructing native witnesses.
      runtime.executeLib('package:probe/main.dart', 'rejectsGuest');
      final intType = runtime.lookupType(CoreTypes.int);
      final listType = runtime.internParameterizedType(CoreTypes.list, [
        intType,
      ]);
      final iterableType = runtime.internParameterizedType(CoreTypes.iterable, [
        listType,
      ]);
      final backing = <Object?>[
        <Object?>[7],
        <Object?>[8],
      ];
      final values = $Iterable.wrap(
        backing,
        runtime: runtime,
        runtimeTypeId: iterableType,
      );
      expect(
        runtime.executeLib(
          'package:probe/main.dart',
          'native',
          arguments: {'values': values},
        ),
        isTrue,
      );
      (backing.first as List<Object?>)[0] = 'wrong';
      expect(
        runtime.executeLib(
          'package:probe/main.dart',
          'rejectsNative',
          arguments: {'values': values},
        ),
        isTrue,
      );
      final wrongType = runtime.internParameterizedType(CoreTypes.iterable, [
        runtime.internParameterizedType(CoreTypes.list, [
          runtime.lookupType(CoreTypes.string),
        ]),
      ]);
      expect(
        runtime.executeLib(
          'package:probe/main.dart',
          'rejectsNative',
          arguments: {
            'values': $Iterable.wrap(
              <List<String>>[
                ['wrong'],
              ],
              runtime: runtime,
              runtimeTypeId: wrongType,
            ),
          },
        ),
        isTrue,
      );
    });

    test('$mode wrong guest collection and callback result are rejected', () {
      expect(
        runtime.executeLib('package:probe/main.dart', 'rejectsGuest'),
        isTrue,
      );
      var calls = 0;
      expect(
        runtime.executeLib(
          'package:probe/main.dart',
          'rejectsNativeCallback',
          arguments: {
            'callback': (int value) {
              calls++;
              return 'wrong';
            },
          },
        ),
        isTrue,
      );
      expect(calls, 1);
    });
  }
}
