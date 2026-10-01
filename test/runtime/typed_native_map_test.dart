import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_collections.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_host_collections.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_native_map.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

final class ObservedMap extends $Map<$Value?, $Value?> {
  ObservedMap() : super.wrap({});
  int reads = 0;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier != '[]') return super.$getProperty(runtime, identifier);
    reads++;
    return $Function((runtime, target, r, s, c) => $int(73));
  }
}

void main() {
  final program = Compiler().compile({
    'native_map': {
      'main.dart': '''
        int accept(Map<int, String> values) => values.length;
        dynamic read(dynamic values, dynamic key) => values[key];
        class Item {}
        Item make() => Item();
        dynamic literal(Item item) => <Object?, Object?>{null: item, 1: null};
        class Key {
          Key(this.id, {this.reject = false});
          final int id;
          final bool reject;
          int get hashCode {
            if (reject) throw StateError('query');
            return id;
          }
          bool operator ==(Object other) => other is Key && other.id == id;
        }
        int guardedLookup() {
          final values = <Key, int>{Key(1): 9};
          try {
            values[Key(1, reject: true)];
          } on StateError {
            return values[Key(1)] ?? -1;
          }
          return -2;
        }
        int main() => 0;
      ''',
    },
  });

  test('compiled Map reads retain null keys, identity and custom dispatch', () {
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.executeLib('package:native_map/main.dart', 'main');
      expect(
        runtime.executeLib('package:native_map/main.dart', 'guardedLookup'),
        9,
      );
      Object? read($Map values, $Value? key) => runtime.executeLib(
        'package:native_map/main.dart',
        'read',
        arguments: {'values': values, 'key': key},
      );
      final item =
          runtime.executeLib('package:native_map/main.dart', 'make') as $Value;
      final literal = TypedHostCollections.box(
        runtime.executeLib(
          'package:native_map/main.dart',
          'literal',
          arguments: {'item': item},
        ),
        runtime,
      ) as $Map;
      // Export returns a cached host view that restores this VM-owned wrapper.
      expect(literal, isA<TypedNativeMap>());
      expect(read(literal, null), same(item));
      expect(read(literal, $int(1)), isNull);
      expect(read(literal, $int(2)), isNull);
      final backing = TypedCollections.newMap(runtime)
        ..[const $null()] = item
        ..[$int(1)] = const $null()
        ..[$int(2)] = null;
      final trusted = TypedNativeMap.wrap(backing);
      expect(trusted.$value, same(backing));
      expect(read(trusted, null), same(item));
      expect(read(trusted, const $null()), same(item));
      expect(read(trusted, $int(1)), isNull);
      expect(read(trusted, $int(2)), isNull);
      expect(read(trusted, $int(3)), isNull);
      expect(read(trusted, $String('wrong type')), isNull);
      final observed = ObservedMap();
      expect(observed, isNot(isA<TypedNativeMap>()));
      expect(read(observed, null), 73);
      expect(observed.reads, 1);
      final host = <Object?, Object?>{null: 4, 'empty': null};
      final boxed = TypedHostCollections.box(host, runtime) as $Map;
      expect(boxed, isA<TypedNativeMap>());
      expect(read(boxed, null), 4);
      host[null] = 8;
      expect(read(boxed, const $null()), 8);
      expect(read(boxed, $String('empty')), isNull);
      expect(read(boxed, $String('missing')), isNull);
      expect(TypedHostCollections.box(host, runtime), same(boxed));
      TypedInterop.invoke(runtime, boxed, '[]=', 2, $String('added'), $int(9));
      expect(host['added'], 9);
      expect(
        TypedHostCollections.export(boxed.$value, boxed, runtime),
        same(host),
      );
    }
  });

  test('trusted Map contracts retain owner and checked adopted writes', () {
    final core = program.bridgeLibraryMappings['dart:core']!;
    final mapNominal = program.typeIds[core]!['Map']!;
    final intNominal = program.typeIds[core]!['int']!;
    final stringNominal = program.typeIds[core]!['String']!;
    final mapType = program.typeDescriptors.indexWhere(
      (row) =>
          row.length == 4 &&
          row[0] == mapNominal &&
          program.typeDescriptors[row[2]][0] == intNominal &&
          program.typeDescriptors[row[3]][0] == stringNominal,
    );
    expect(mapType, isNonNegative);
    final first = Runtime.ofProgram(program);
    final second = Runtime(program.write().buffer);
    for (final runtime in [first, second]) {
      runtime.executeLib('package:native_map/main.dart', 'main');
    }
    final value = $String('identity');
    final backing = TypedCollections.newMap(first)..[$int(1)] = value;
    final trusted = TypedNativeMap.wrap(
      backing,
      runtimeTypeId: mapType,
      runtime: first,
    );
    expect(second.isTypedValueType(trusted, mapType), isTrue);
    expect(
      second.executeLib(
        'package:native_map/main.dart',
        'read',
        arguments: {'values': trusted, 'key': $int(1)},
      ),
      'identity',
    );
    expect(
      () => TypedInterop.invoke(second, trusted, '[]=', 2, $int(1), $int(2)),
      throwsA(isA<TypeError>()),
    );
    final adopted =
        TypedHostCollections.adoptRuntimeType(
              $Map.wrap(backing),
              second,
              mapType,
            )
            as $Map;
    expect(adopted, isA<TypedNativeMap>());
    expect(adopted.$value[$int(1)], same(value));
    expect(
      () => TypedInterop.invoke(
        second,
        adopted,
        '[]=',
        2,
        $String('bad key'),
        value,
      ),
      throwsA(isA<TypeError>()),
    );
    expect(backing, hasLength(1));
    expect(backing[$int(1)], same(value));
  });
}
