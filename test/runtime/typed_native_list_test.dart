import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_host_collections.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show RuntimeException, TypedRuntimeInterop;
import 'package:dart_eval/src/eval/runtime/typed/typed_native_list.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

final class _ObservedList extends $List<$Value?> {
  _ObservedList() : super.wrap([]);

  int reads = 0;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier != '[]') return super.$getProperty(runtime, identifier);
    reads++;
    return $Function((runtime, target, r, s, c) => $int(91));
  }
}

void main() {
  final program = Compiler().compile({
    'native_list': {
      'main.dart': '''
        int accept(List<int> values) => values.length;
        dynamic read(dynamic values, dynamic index) => values[index];
        dynamic readInt(dynamic values, int index) => values[index];
        class Item {}
        Item make() => Item();
        int main() => 0;
      ''',
    },
  });

  test('compiled dynamic indexing retains native and overridden behavior', () {
    expect(
      program.typedProgram.instructions.map((entry) => entry.$2.name),
      contains('callIndexInt'),
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.executeLib('package:native_list/main.dart', 'main');
      Object? read($Instance values, $Value index) => runtime.executeLib(
        'package:native_list/main.dart',
        'read',
        arguments: {'values': values, 'index': index},
      );
      Object? readInt($Instance values, int index) => runtime.executeLib(
        'package:native_list/main.dart',
        'readInt',
        arguments: {'values': values, 'index': index},
      );
      final item =
          runtime.executeLib('package:native_list/main.dart', 'make') as $Value;
      final backing = <$Value?>[item, const $null(), null];
      final trusted = TypedNativeList.wrap(backing);
      expect(trusted.$value, same(backing));
      expect(read(trusted, $int(0)), same(item));
      expect(read(trusted, $int(1)), isNull);
      expect(read(trusted, $int(2)), isNull);
      expect(
        () => read(trusted, $int(3)),
        throwsA(
          isA<RuntimeException>().having(
            (error) => error.caughtException,
            'cause',
            isA<RangeError>(),
          ),
        ),
      );
      expect(
        () => read(trusted, $String('bad')),
        throwsA(
          isA<RuntimeException>().having(
            (error) => error.caughtException,
            'cause',
            isA<TypeError>(),
          ),
        ),
      );
      final observed = _ObservedList();
      expect(observed, isNot(isA<TypedNativeList>()));
      expect(read(observed, $int(0)), 91);
      expect(observed.reads, 1);
      final host = <Object?>[4, null];
      final hostWrapper = TypedHostCollections.box(host, runtime) as $List;
      expect(read(hostWrapper, $int(0)), 4);
      host[0] = 8;
      expect(read(hostWrapper, $int(0)), 8);
      expect(read(hostWrapper, $int(1)), isNull);
      final mapped = $List.view<Object?>(
        host,
        (value) =>
            value == null || value == -1 ? const $null() : $int(value as int),
      );
      expect(read(mapped, $int(0)), 8);
      expect(readInt(mapped, 0), 8);
      host[0] = 9;
      expect(readInt(mapped, 0), 9);
      expect(read(mapped, $int(1)), isNull);
      expect(readInt(mapped, 1), isNull);
      host[0] = -1;
      expect(readInt(mapped, 0), isNull);
    }
  });
  final core = program.bridgeLibraryMappings['dart:core']!;
  final listNominal = program.typeIds[core]!['List']!;
  final intNominal = program.typeIds[core]!['int']!;
  final intList = program.typeDescriptors.indexWhere(
    (row) =>
        row.length == 3 &&
        row[0] == listNominal &&
        program.typeDescriptors[row[2]][0] == intNominal,
  );

  test('host List boxing retains cache, export identity and writeback', () {
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.executeLib('package:native_list/main.dart', 'main');
      final host = <Object?>[1, null];
      final boxed = TypedHostCollections.box(host, runtime) as $List;
      expect(boxed, isA<TypedNativeList>());
      expect(TypedHostCollections.box(host, runtime), same(boxed));
      TypedInterop.invoke(runtime, boxed, '[]=', 2, $int(1), $int(8));
      expect(host, [1, 8]);
      expect(
        TypedHostCollections.export(boxed.$value, boxed, runtime),
        same(host),
      );
    }
  });

  test(
    'trusted List contracts retain defining runtime and reject invalid writes',
    () {
      expect(intList, isNonNegative);
      final first = Runtime.ofProgram(program);
      final second = Runtime(program.write().buffer);
      for (final runtime in [first, second]) {
        runtime.executeLib('package:native_list/main.dart', 'main');
      }
      final backing = <$Value?>[$int(1)];
      final trusted = TypedNativeList.wrap(
        backing,
        runtimeTypeId: intList,
        runtime: first,
      );
      expect(second.isTypedValueType(trusted, intList), isTrue);
      expect(
        second.executeLib(
          'package:native_list/main.dart',
          'read',
          arguments: {'values': trusted, 'index': $int(0)},
        ),
        1,
      );
      expect(
        () => TypedInterop.invoke(
          second,
          trusted,
          'add',
          1,
          $String('bad'),
          null,
        ),
        throwsA(isA<TypeError>()),
      );
      expect(backing, hasLength(1));
      final adopted =
          TypedHostCollections.adoptRuntimeType(
                $List.wrap(backing),
                second,
                intList,
              )
              as $List;
      expect(adopted, isA<TypedNativeList>());
      expect(adopted.$value[0], same(backing[0]));
      expect(
        () => TypedInterop.invoke(
          second,
          adopted,
          '[]=',
          2,
          $int(0),
          $String('bad'),
        ),
        throwsA(isA<TypeError>()),
      );
      expect((backing[0] as $int).$value, 1);
    },
  );
}
