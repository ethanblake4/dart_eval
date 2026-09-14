import 'dart:typed_data';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_export_adapter.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

TypedExportParameter parameter(
  String name,
  String type, {
  bool required = true,
  bool nullable = false,
  Object? defaultValue,
  String library = 'dart:core',
}) => TypedExportParameter(
  name,
  isRequired: required,
  nullable: nullable,
  typeName: type,
  typeLibrary: library,
  defaultValue: defaultValue,
);

final class _HostPayload {}

void main() {
  test(
    'collection wrappers and writes use their runtime conversion context',
    () {
      final program = Compiler().compile({
        'test': {'main.dart': 'int main() => 0;'},
      });
      final first = Runtime.ofProgram(program)
        ..addTypeAutowrapper(
          (value) => value is _HostPayload ? $String('first') : null,
        );
      final second = Runtime.ofProgram(program)
        ..addTypeAutowrapper(
          (value) => value is _HostPayload ? $String('second') : null,
        );
      final host = <Object?>[_HostPayload()];
      final firstBox = TypedInterop.boxExternal(host, runtime: first) as $List;
      final secondBox =
          TypedInterop.boxExternal(host, runtime: second) as $List;
      expect(identical(firstBox, secondBox), isFalse);
      expect((firstBox.$value.single as $String).$value, 'first');
      expect((secondBox.$value.single as $String).$value, 'second');
      expect(identical(TypedInterop.exportExternal(firstBox), host), isTrue);
      expect(identical(TypedInterop.exportExternal(secondBox), host), isTrue);
      final values = <$Value?>[];
      final owner = $List.wrap(values);
      final firstView =
          TypedInterop.exportExternal(owner, runtime: first) as List<Object?>;
      final secondView =
          TypedInterop.exportExternal(owner, runtime: second) as List<Object?>;
      expect(identical(firstView, secondView), isFalse);
      firstView.add(_HostPayload());
      secondView.add(_HostPayload());
      expect(values.map((value) => (value as $String).$value), [
        'first',
        'second',
      ]);
      expect(
        identical(TypedInterop.boxExternal(firstView, runtime: first), owner),
        isTrue,
      );
      expect(
        identical(TypedInterop.boxExternal(secondView, runtime: second), owner),
        isTrue,
      );
    },
  );
  test('nullable doubles distinguish null and coerce numeric defaults', () {
    TypedExport declaration(Object? defaultValue) => TypedExport(
      'package:test/main.dart',
      'main',
      0,
      parameters: [
        parameter(
          'value',
          'double',
          required: false,
          nullable: true,
          defaultValue: defaultValue,
        ),
      ],
    );
    TypedProgram program(TypedExport declaration) => TypedProgram(
      Uint8List.fromList([TypedOp.returnNull]),
      functions: const [
        TypedFunction(
          0,
          argumentKinds: [TypedArgumentKind.object],
          resultKind: null,
        ),
      ],
      exports: [declaration],
    );
    final numeric = declaration(3);
    final compiled = program(numeric);
    final defaulted = TypedExportAdapter.bind(compiled, numeric, {});
    expect((defaulted.r as $double).$value, 3.0);
    expect(
      TypedExportAdapter.bind(compiled, numeric, {'value': null}).r,
      isNull,
    );
    expect(
      (TypedExportAdapter.bind(compiled, numeric, {'value': $int(4)}).r
              as $double)
          .$value,
      4.0,
    );
    final nullable = declaration(null);
    expect(TypedExportAdapter.bind(program(nullable), nullable, {}).r, isNull);
    final invalid = declaration('bad');
    expect(
      () => TypedExportAdapter.bind(program(invalid), invalid, {}),
      throwsArgumentError,
    );
  });

  test('bridge exports expose the native backing object', () {
    final date = DateTime.utc(2026, 9, 14);
    expect(
      identical(TypedInterop.exportExternal($DateTime.wrap(date)), date),
      isTrue,
    );
  });
  test(
    'map binding distinguishes absence, defaults, null, and argument errors',
    () {
      final declaration = TypedExport(
        'package:test/main.dart',
        'main',
        0,
        parameters: [
          parameter('count', 'int'),
          parameter(
            'label',
            'String',
            required: false,
            nullable: true,
            defaultValue: 'default',
          ),
        ],
      );
      final program = TypedProgram(
        Uint8List.fromList([TypedOp.returnNull]),
        functions: const [
          TypedFunction(
            0,
            argumentKinds: [
              TypedArgumentKind.integer,
              TypedArgumentKind.object,
            ],
            resultKind: null,
          ),
        ],
        exports: [declaration],
      );
      final defaulted = TypedExportAdapter.bind(program, declaration, {
        'count': 4,
      });
      expect(defaulted.a, 4);
      expect((defaulted.r as $String).$value, 'default');
      final explicitNull = TypedExportAdapter.bind(program, declaration, {
        'label': null,
        'count': $int(5),
      });
      expect(explicitNull.a, 5);
      expect(explicitNull.r, isNull);
      expect(
        () => TypedExportAdapter.bind(program, declaration, {}),
        throwsArgumentError,
      );
      expect(
        () => TypedExportAdapter.bind(program, declaration, {'count': null}),
        throwsArgumentError,
      );
      expect(
        () => TypedExportAdapter.bind(program, declaration, {'count': '4'}),
        throwsArgumentError,
      );
      expect(
        () => TypedExportAdapter.bind(program, declaration, {
          'count': 4,
          'unknown': 1,
        }),
        throwsArgumentError,
      );
    },
  );

  test(
    'source-order binding fills all register banks and one overflow list',
    () {
      final declaration = TypedExport(
        'package:test/main.dart',
        'main',
        0,
        parameters: [
          parameter('a', 'int'),
          parameter('b', 'int'),
          parameter('third', 'int'),
          parameter('text', 'String'),
          parameter('flag', 'bool'),
          parameter('other', 'bool'),
          parameter('value', 'Object'),
          parameter('tail', 'String', nullable: true),
        ],
      );
      final program = TypedProgram(
        Uint8List.fromList([TypedOp.returnNull]),
        functions: const [
          TypedFunction(
            0,
            argumentKinds: [
              TypedArgumentKind.integer,
              TypedArgumentKind.integer,
              TypedArgumentKind.integer,
              TypedArgumentKind.string,
              TypedArgumentKind.boolean,
              TypedArgumentKind.boolean,
              TypedArgumentKind.object,
              TypedArgumentKind.object,
            ],
            resultKind: null,
          ),
        ],
        exports: [declaration],
      );
      final entry = TypedExportAdapter.bind(program, declaration, {
        'tail': null,
        'value': 42,
        'other': false,
        'flag': true,
        'text': 'text',
        'third': 3,
        'b': 2,
        'a': 1,
      });
      expect(
        [entry.a, entry.b, entry.r, entry.s, entry.e, entry.x],
        [1, 2, 3, 'text', true, false],
      );
      final overflow = entry.c as List<Object?>;
      expect((overflow.first as $int).$value, 42);
      expect(overflow.last, isNull);
    },
  );

  test(
    'raw host collection inputs retain aliases and bidirectional mutation',
    () {
      final host = <Object?>[1];
      host.add(host);
      final boxed = TypedInterop.boxExternal(host) as $List;
      expect(identical(TypedInterop.boxExternal(host), boxed), isTrue);
      expect(identical(boxed.$value[1], boxed), isTrue);
      expect(identical(TypedInterop.exportExternal(boxed), host), isTrue);
      boxed.$value[0] = $int(2);
      expect(host[0], 2);
      host[0] = 3;
      expect((boxed.$value[0] as $int).$value, 3);
      final map = <String, Object?>{'a': 1};
      final boxedMap = TypedInterop.boxExternal(map) as $Map;
      boxedMap.$value[$String('a')] = $int(4);
      expect(map['a'], 4);
      final typedList = <int>[1, 4];
      final typedBox = TypedInterop.boxExternal(typedList) as $List;
      typedBox.$value.insertAll(1, [$int(2), $int(3)]);
      typedBox.$value.replaceRange(2, 4, [$int(5)]);
      expect(typedList, [1, 2, 5]);
      final set = <int>{1};
      final boxedSet = TypedInterop.boxExternal(set) as $Set;
      boxedSet.$value.add($int(2));
      expect(set, {1, 2});
    },
  );

  test(
    'evaluated collection exports are cached native views and reenter unchanged',
    () {
      final backing = <$Value?>[$int(1)];
      final boxed = $List.wrap(backing);
      backing.add(boxed);
      final host = TypedInterop.exportExternal(boxed) as List<Object?>;
      expect(host[0], 1);
      expect(identical(host[1], host), isTrue);
      expect(identical(TypedInterop.exportExternal(boxed), host), isTrue);
      expect(identical(TypedInterop.boxExternal(host), boxed), isTrue);
      host[0] = 7;
      expect((backing[0] as $int).$value, 7);
      backing[0] = $int(9);
      expect(host[0], 9);
      final map = $Map.wrap(<$Value?, $Value?>{$String('a'): $int(1)});
      final mapView = TypedInterop.exportExternal(map) as Map<Object?, Object?>;
      expect(mapView['a'], 1);
      mapView['a'] = 2;
      expect((map.$value[$String('a')] as $int).$value, 2);
      final set = $Set.wrap(<$Value?>{$int(1)});
      final setView = TypedInterop.exportExternal(set) as Set<Object?>;
      setView.add(2);
      expect(setView, {1, 2});
      expect(set.$value, contains($int(2)));
    },
  );
}
