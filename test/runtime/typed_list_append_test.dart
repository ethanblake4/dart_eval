import 'dart:typed_data';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart' show RuntimeException;
import 'package:dart_eval/src/eval/runtime/typed/typed_host_collections.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_native_list.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

final class _ObservedList extends $List<$Value?> {
  _ObservedList() : super.wrap([]);

  int calls = 0;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier != 'add') return super.$getProperty(runtime, identifier);
    return $Function((runtime, target, r, s, c) {
      calls++;
      return null;
    });
  }
}

void main() {
  final program = Compiler().compile({
    'list_append': {'main.dart': _source},
  });
  final core = program.bridgeLibraryMappings['dart:core']!;
  final listNominal = program.typeIds[core]!['List']!;
  final intNominal = program.typeIds[core]!['int']!;
  int listType(bool nullable) => program.typeDescriptors.indexWhere(
    (row) =>
        row.length == 3 &&
        row[0] == listNominal &&
        program.typeDescriptors[row[2]][0] == intNominal &&
        program.typeDescriptors[row[2]][1] == (nullable ? 1 : 0),
  );
  final intList = listType(false);
  final nullableIntList = listType(true);
  final runtimes = [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ];
  for (final runtime in runtimes) {
    runtime.executeLib('package:list_append/main.dart', 'main');
  }
  void append(Runtime runtime, $List values, $Value? value) {
    runtime.executeLib(
      'package:list_append/main.dart',
      'append',
      arguments: {'values': values, 'value': value},
    );
  }

  test('trusted append preserves values, aliases and virtual fallback', () {
    for (final runtime in runtimes) {
      expect(
        runtime.executeLib('package:list_append/main.dart', 'verify'),
        true,
      );
      final backing = <$Value?>[];
      final trusted = TypedNativeList.wrap(backing);
      final value = $int(3);
      append(runtime, trusted, value);
      append(runtime, trusted, null);
      append(runtime, trusted, const $null());
      expect(backing[0], same(value));
      expect(backing[1], isNull);
      expect(backing[2], isNull);
      final untrustedBacking = <Object?>[];
      final untrusted = $List.wrap(untrustedBacking);
      append(runtime, untrusted, const $null());
      expect(untrustedBacking, [isNull]);
      final observed = _ObservedList();
      append(runtime, observed, value);
      expect(observed.calls, 1);
      expect(observed.$value, isEmpty);
      final host = <Object?>[];
      final boxed = TypedHostCollections.box(host, runtime) as $List;
      append(runtime, boxed, value);
      expect(host, [3]);
      expect(TypedHostCollections.box(host, runtime), same(boxed));
      expect(
        TypedHostCollections.export(boxed.$value, boxed, runtime),
        same(host),
      );
      final adopted =
          TypedHostCollections.adoptRuntimeType(boxed, runtime, intList)
              as $List;
      expect(
        () => append(runtime, adopted, $String('bad')),
        throwsA(
          isA<RuntimeException>().having(
            (e) => e.caughtException,
            'cause',
            isA<TypeError>(),
          ),
        ),
      );
      expect(host, [3]);
      append(runtime, adopted, $int(4));
      expect(host, [3, 4]);
    }
  });

  test('cached checks preserve defining runtime and precede mutation', () {
    expect(intList, isNonNegative);
    expect(nullableIntList, isNonNegative);
    final backing = <$Value?>[];
    final trusted = TypedNativeList.wrap(
      backing,
      runtimeTypeId: intList,
      runtime: runtimes.first,
    );
    for (final runtime in [runtimes.first, runtimes.last, runtimes.first]) {
      append(runtime, trusted, $int(1));
      final length = backing.length;
      for (final invalid in [$String('bad'), null, const $null()]) {
        expect(
          () => append(runtime, trusted, invalid),
          throwsA(
            isA<RuntimeException>().having(
              (e) => e.caughtException,
              'cause',
              isA<TypeError>(),
            ),
          ),
        );
        expect(backing, hasLength(length));
      }
    }
    final nullableBacking = <$Value?>[];
    final nullable = TypedNativeList.wrap(
      nullableBacking,
      runtimeTypeId: nullableIntList,
      runtime: runtimes.first,
    );
    append(runtimes.last, nullable, null);
    append(runtimes.last, nullable, const $null());
    expect(nullableBacking, hasLength(2));
  });

  test('append opcode validates exact member shape', () {
    TypedProgram candidate(TypedCallSite site) => TypedProgram(
      Uint8List.fromList([TypedOp.callAppend, 0, 0, TypedOp.rReturn]),
      callSites: [site],
    );
    final valid = candidate(const TypedCallSite('add', argumentCount: 1));
    expect(TypedProgram.read(valid.write().buffer).callSites, hasLength(1));
    for (final site in const [
      TypedCallSite('addAll', argumentCount: 1),
      TypedCallSite('add', argumentCount: 0),
      TypedCallSite('add', argumentCount: 2),
      TypedCallSite('add', argumentCount: 1, kind: TypedMemberKind.setter),
      TypedCallSite(
        'add',
        argumentCount: 1,
        positionalCount: 0,
        namedNames: ['value'],
      ),
    ]) {
      expect(
        () => candidate(site),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Invalid list-append call site'),
          ),
        ),
      );
    }
  });
}

const _source = r'''
import 'dart:collection';
class Values extends ListBase<int> {
  final List<int> data = [];
  int get length => data.length;
  set length(int value) { data.length = value; }
  int operator [](int index) => data[index];
  void operator []=(int index, int value) { data[index] = value; }
  void add(int value) { data.add(value + 10); }
}
void append(dynamic values, dynamic value) { values.add(value); }
int accept(List<int> values) => values.length;
int acceptNullable(List<int?> values) => values.length;
bool verify() {
  dynamic values = <int>[];
  values.add(1);
  try { values.add('bad'); return false; } on TypeError {}
  if (values.length != 1 || values[0] != 1) return false;
  dynamic guest = Values();
  guest.add(2);
  if (guest[0] != 12) return false;
  dynamic set = <int>{};
  if (set.add(3) != true || set.add(3) != false) return false;
  return set.length == 1;
}
void main() { if (!verify()) throw StateError('checked append'); }
''';
