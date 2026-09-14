import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_export_adapter.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:test/test.dart';

class _OpaqueInstance implements $Instance {
  @override
  Object get $value =>
      throw StateError('Opaque instances have no native value');
  @override
  Object get $reified => throw StateError('Opaque instances cannot be reified');
  @override
  int $getRuntimeType(Runtime runtime) => 0;
  @override
  $Value? $getProperty(Runtime runtime, String identifier) => null;
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}
}

TypedProgram program(String name, String library, {bool nullable = false}) =>
    TypedProgram(
      Uint8List.fromList([TypedOp.rReturn]),
      functions: const [
        TypedFunction(0, argumentKinds: [TypedArgumentKind.object]),
      ],
      exports: [
        TypedExport(
          'test',
          'main',
          0,
          parameters: [
            TypedExportParameter(
              'value',
              isRequired: true,
              nullable: nullable,
              typeName: name,
              typeLibrary: library,
            ),
          ],
        ),
      ],
    );

void main() {
  test('opaque custom type validation uses the runtime type registry', () {
    final typed = program('Opaque', 'package:opaque/model.dart');
    final envelope = Program(
      {},
      {},
      {
        0: {'Opaque': 0},
      },
      [
        {0},
      ],
      typed,
      {'package:opaque/model.dart': 0},
      {},
      [],
      [],
      [],
      {},
      {},
    );
    final runtime = Runtime.ofProgram(envelope);
    final value = _OpaqueInstance();
    expect(
      identical(
        TypedExportAdapter.bind(typed, typed.exports.single, {
          'value': value,
        }, runtime: runtime).r,
        value,
      ),
      isTrue,
    );
  });

  test('native callback identity survives named public entry and return', () {
    final p = Compiler().compile({
      'test': {'main.dart': 'Object main(Object value) => value;'},
    });
    int callback(int value) => value + 1;
    for (final runtime in [Runtime.ofProgram(p), Runtime(p.write().buffer)]) {
      final result = runtime.executeLib(
        'package:test/main.dart',
        'main',
        arguments: {'value': callback},
      );
      expect(identical(result, callback), isTrue);
      expect((result as int Function(int))(4), 5);
    }
  });

  test(
    'opaque canonical values enter Object and dynamic parameters unchanged',
    () {
      final value = _OpaqueInstance();
      for (final name in ['Object', 'dynamic']) {
        final p = program(name, 'dart:core');
        expect(
          identical(
            TypedExportAdapter.bind(p, p.exports.single, {'value': value}).r,
            value,
          ),
          isTrue,
        );
      }
    },
  );

  test(
    'export types distinguish same-named classes in different libraries',
    () {
      final classes = TypedProgram(
        Uint8List.fromList([TypedOp.returnNull]),
        classes: [
          TypedClass(
            'Record',
            library: 'package:first/model.dart',
            valueCount: 0,
          ),
          TypedClass(
            'Record',
            library: 'package:second/model.dart',
            valueCount: 0,
          ),
          TypedClass(
            'Child',
            library: 'package:first/model.dart',
            valueCount: 0,
          ),
        ],
      );
      final first = TypedInstance(classes, 0);
      final second = TypedInstance(classes, 1);
      final child = TypedInstance(classes, 2, first);
      final original = program('Record', 'package:first/model.dart');
      for (final p in [original, TypedProgram.read(original.write().buffer)]) {
        expect(
          identical(
            TypedExportAdapter.bind(p, p.exports.single, {'value': child}).r,
            child,
          ),
          isTrue,
        );
        expect(
          () => TypedExportAdapter.bind(p, p.exports.single, {'value': second}),
          throwsArgumentError,
        );
      }
    },
  );

  test('collection boundary caches preserve a shared map-list cycle', () {
    final list = <Object?>[];
    final map = <String, Object?>{'list': list};
    list.add(map);
    final first = TypedInterop.boxExternal(map);
    final second = TypedInterop.boxExternal(list);
    final exportedMap = TypedInterop.exportExternal(first) as Map;
    final exportedList = TypedInterop.exportExternal(second) as List;
    expect(identical(exportedMap, map), isTrue);
    expect(identical(exportedList, list), isTrue);
    expect(identical(exportedMap['list'], exportedList), isTrue);
    expect(identical(exportedList.single, exportedMap), isTrue);
  });
}
