import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

BridgeClassDef _classNamed(Map<String, dynamic> metadata, String name) {
  for (final entry in (metadata['classes'] as List).cast<Map>()) {
    final definition = BridgeClassDef.fromJson(entry.cast<String, dynamic>());
    if (definition.type.type.spec?.name == name) return definition;
  }
  throw StateError('Missing bridge class $name');
}

void main() {
  test(
    'direct metadata matches declarations emitted by generated Dart bindings',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_json_parity_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class Rich<T extends num?> {
  Rich(this.value, {required this.label, this.count = 2});

  final T? value;
  String label;
  int count;

  R transform<R extends Object?>(
    R value,
    R Function(R) convert, {
    required String tag,
    int repetitions = 1,
  }) => convert(value);

  Object? choose(Object? value, {required Object? selector}) => value;

  String get description => label;
  set description(String value) => label = value;

  int operator +(int other) => count + other;

  static const int compactValue = 9;
  static const String compactLabel = 'rich';
}

mixin Stamp<T extends Object?> {
  T? get stamp;
}

enum Tone { warm, cool }

Object? selectValue(Object? value, {required int selector}) => value;
''');
      final uri = source.uri.toString();
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: "$uri"
    classes:
      Rich:
        include: true
        compactStaticConstants: true
        constructors:
          "":
            params:
              label:
                type: String?
              count:
                optional: false
        methods:
          transform:
            rename: mapValue
            params:
              repetitions:
                optional: true
          choose:
            returns:
              dependsOn:
                index: 0
                param: selector
                cases:
                  int: String?
                fallback: Object?
          "+":
            rename: plus
        getters:
          description:
            rename: summary
        setters:
          description:
            rename: updateSummary
        synthetic:
          - kind: method
            name: syntheticValue
            returns: int
            params:
              - name: amount
                type: int
                named: true
                optional: true
                default: 4
      Stamp:
        include: true
        opaque: true
      Tone:
        include: true
    functions:
      selectValue:
        include: true
        params:
          selector:
            type: int?
            optional: true
        returns:
          dependsOn:
            param: selector
            cases:
              int: String?
            fallback: Object?
''')..resolveDefaults();
      final libraryConfig = config.libraries.single;

      final direct = BridgeSerializer();
      final directSource = await Bindgen().parse(
        source,
        'native.dart',
        uri,
        false,
        config: config,
        libraryConfig: libraryConfig,
        generateDart: false,
        declarations: direct,
      );
      expect(directSource, isNull);

      final generated = (await Bindgen().parse(
        source,
        'native.dart',
        uri,
        false,
        config: config,
        libraryConfig: libraryConfig,
      ))!;
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
      File(p.join(directory.path, 'serialize.dart')).writeAsStringSync(r'''
import 'dart:convert';

import 'native.eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/serializer.dart';

void main() {
  final serializer = BridgeSerializer()
    ..defineBridgeClass($Rich.$declaration)
    ..defineBridgeClass($Stamp.$declaration)
    ..defineBridgeEnum($Tone.$declaration)
    ..defineBridgeTopLevelFunction($selectValueFn.$declaration);
  print(jsonEncode(serializer.serialize()));
}
''');
      final serialized = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'serialize.dart'),
      ]);
      expect(
        serialized.exitCode,
        0,
        reason: '${serialized.stdout}\n${serialized.stderr}',
      );
      final generatedMetadata =
          jsonDecode(serialized.stdout as String) as Map<String, dynamic>;
      expect(generatedMetadata, direct.serialize());
      for (final metadata in [direct.serialize(), generatedMetadata]) {
        final dependency = _classNamed(
          metadata,
          'Rich',
        ).methods['choose']!.functionDescriptor.returnTypeDependency!;
        expect(dependency.paramIndex, 0);
        expect(dependency.paramName, isNull);
      }

      final json =
          jsonDecode(jsonEncode(direct.serialize())) as Map<String, dynamic>;
      final compiler = Compiler();
      for (final definition in (json['classes'] as List).cast<Map>()) {
        compiler.defineBridgeClass(
          BridgeClassDef.fromJson(definition.cast<String, dynamic>()),
        );
      }
      for (final definition in (json['enums'] as List).cast<Map>()) {
        compiler.defineBridgeEnum(
          BridgeEnumDef.fromJson(definition.cast<String, dynamic>()),
        );
      }
      for (final definition in (json['functions'] as List).cast<Map>()) {
        compiler.defineBridgeTopLevelFunction(
          BridgeFunctionDeclaration.fromJson(
            definition.cast<String, dynamic>(),
          ),
        );
      }
      final program = compiler.compile({
        'main': {
          'main.dart':
              '''
import '$uri';

void checkMetadata() {
  final rich = Rich<int>(1, label: 'label', count: 2);
  rich.mapValue<String>('value', (value) => value, tag: 'mapped');
  rich.choose('selected', selector: 1);
  selectValue('top level', selector: 1);
}
''',
        },
      });
      expect(program, isNotNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'generateDart false returns no wrapper source for runtime-only hooks',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_json_no_source_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class Hooked {
  int value(int input) => input;
}
''');
      final uri = source.uri.toString();
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: "$uri"
    classes:
      Hooked:
        include: true
        methods:
          value:
            hook: missingRuntimeHook
''')..resolveDefaults();
      final serializer = BridgeSerializer();
      final output = await Bindgen().parse(
        source,
        'native.dart',
        uri,
        false,
        config: config,
        libraryConfig: config.libraries.single,
        generateDart: false,
        declarations: serializer,
      );

      expect(output, isNull);
      expect(serializer.serialize()['classes'], hasLength(1));
    },
  );

  test(
    'direct bridge metadata dispatches guest overrides through generated bridge',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_json_bridge_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
abstract class Host {
  Host();

  int invoke(int value) => transform(value);
  int transform(int value);
}
''');
      final uri = source.uri.toString();
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: "$uri"
    classes:
      Host:
        include: true
        mode: bridge
''')..resolveDefaults();
      final direct = BridgeSerializer();
      final directSource = await Bindgen().parse(
        source,
        'native.dart',
        uri,
        false,
        config: config,
        libraryConfig: config.libraries.single,
        generateDart: false,
        declarations: direct,
      );
      expect(directSource, isNull);
      final directMetadata = direct.serialize();
      final definition = _classNamed(directMetadata, 'Host');
      expect(definition.bridge, isTrue);
      expect(definition.wrap, isFalse);
      expect(definition.type.isMixinClass, isFalse);

      final generated = (await Bindgen().parse(
        source,
        'native.dart',
        uri,
        false,
        config: config,
        libraryConfig: config.libraries.single,
      ))!;
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(
        r"""
import 'dart:convert';

import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

const metadataJson = __METADATA_JSON__;

void main() {
  final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
  final definition = BridgeClassDef.fromJson(
    (metadata['classes'] as List).single as Map<String, dynamic>,
  );
  if (!definition.bridge || definition.wrap || definition.type.isMixinClass) {
    throw StateError('Direct metadata lost bridge class shape');
  }
  final compiler = Compiler()
    ..entrypoints.add('package:main/main.dart')
    ..defineBridgeClass(definition);
  final program = compiler.compile({
    'main': {
      'main.dart': '''
import '__NATIVE_URI__';

class Guest extends Host {
  Guest();
  int transform(int value) => value * 3;
}

int main() => Guest().invoke(14);
''',
    },
  });
  final encodedProgram = program.write();
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(encodedProgram.buffer),
  ]) {
    $Host$bridge.configureForRuntime(runtime);
    final result = runtime.executeLib('package:main/main.dart', 'main');
    if (result != 42) throw StateError('Guest override returned $result');
  }
}
"""
            .replaceAll(
              '__METADATA_JSON__',
              jsonEncode(jsonEncode(directMetadata)).replaceAll(r'$', r'\$'),
            )
            .replaceAll('__NATIVE_URI__', uri),
      );
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'library metadata includes SDK source units and forwards mappings only',
    () async {
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: dart:collection
    typedefs: [IterableBase, IterableMixin]
    sourceExtensions: [IterableExtensions]
    sourceClasses: [ListBase]
''')..resolveDefaults();
      final generator = Bindgen();
      generator
        ..defineBridgeClass(
          const BridgeClassDef(
            BridgeClassType(
              BridgeTypeRef(
                BridgeTypeSpec('package:input/model.dart', 'InputModel'),
              ),
            ),
            constructors: {},
            wrap: true,
          ),
        )
        ..addExportedLibraryMapping(
          'dart:collection',
          'package:public/collection.dart',
        );
      final serializer = BridgeSerializer();
      final output = await generator.parseLibrary(
        'dart:collection',
        config,
        config.libraries.single,
        generateDart: false,
        declarations: serializer,
      );

      expect(output, isEmpty);
      final metadata = serializer.serialize();
      expect(metadata['classes'], isEmpty);
      expect(metadata['enums'], isEmpty);
      expect(metadata['functions'], isEmpty);
      expect(metadata['exportedLibMappings'], {
        'dart:collection': 'package:public/collection.dart',
      });
      final sources = (metadata['sources'] as List).cast<Map>();
      expect(sources, hasLength(3));
      expect(
        sources.every((source) => (source['source'] as String).isNotEmpty),
        isTrue,
      );
      expect(sources.map((source) => source['uri']).toSet(), {
        'dart:collection',
      });
    },
  );
}
