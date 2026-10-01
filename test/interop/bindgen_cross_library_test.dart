import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';
import 'package:test/test.dart';

void main() {
  test('opaque classes and mixins keep type shapes without members', () async {
    final config = BindgenConfig.parse('''
libraries:
  - uri: package:dart_eval/src/eval/bindgen/config.dart
    classes:
      BindgenConfig:
        opaque: true
  - uri: package:dart_eval/src/eval/compiler/context.dart
    classes:
      ScopeContext:
        opaque: true
''')..resolveDefaults();
    final generator = Bindgen();
    final classSource = (await generator.parseLibrary(
      config.libraries.first.uri,
      config,
      config.libraries.first,
    )).values.single;
    final mixinSource = (await generator.parseLibrary(
      config.libraries.last.uri,
      config,
      config.libraries.last,
    )).values.single;
    expect(classSource, contains('class \$BindgenConfig'));
    expect(classSource, contains('BridgeClassDef('));
    expect(classSource, isNot(contains('fromYaml')));
    expect(mixinSource, contains('class \$ScopeContext'));
    expect(mixinSource, contains('BridgeClassDef('));
    expect(mixinSource, isNot(contains('update(')));

    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_opaque_');
    addTearDown(() => directory.deleteSync(recursive: true));
    File(p.join(directory.path, 'opaque_class.dart')).writeAsStringSync('''
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$classSource
''');
    File(p.join(directory.path, 'opaque_mixin.dart')).writeAsStringSync('''
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$mixinSource
''');
    final analysis = await Process.run(Platform.resolvedExecutable, [
      'analyze',
      '--no-fatal-warnings',
      directory.path,
    ]);
    expect(
      analysis.exitCode,
      0,
      reason: '${analysis.stdout}\n${analysis.stderr}',
    );
  });

  test(
    'discovers supporting signature types without their member APIs',
    () async {
      final config = BindgenConfig.parse('''
libraries:
  - uri: package:dart_eval/src/eval/bindgen/config.dart
    classes: [BindgenConfig]
''')..resolveDefaults();
      final support = await Bindgen().supportingTypes(config);
      expect(
        support,
        contains((
          uri: 'package:dart_eval/src/eval/bindgen/config.dart',
          name: 'BindgenLibraryConfig',
          isEnum: false,
        )),
      );
      expect(support.every((entry) => !entry.name.startsWith('_')), isTrue);
    },
  );

  test(
    'support discovery terminates for self-referential generic bounds',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_bound_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'bound.dart'))
        ..writeAsStringSync('''
class FBound<T extends FBound<T>> {}
class Api<T extends FBound<T>> {
  T? value;
}
''');
      final uri = source.uri.toString();
      final config = BindgenConfig.parse('''
libraries:
  - uri: $uri
    classes: [Api]
''')..resolveDefaults();
      final support = await Bindgen().supportingTypes(config);
      expect(support.map((type) => type.name), contains('FBound'));
    },
  );

  test(
    'opaque F-bound collection values use a compilable erased wrapper',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_fbound_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'fbound.dart'))
        ..writeAsStringSync('''
abstract class FBound<T extends FBound<T>> {}
class Container {
  final Map<Object, FBound<dynamic>> values = {};
}
''');
      final uri = source.uri.toString();
      final config = BindgenConfig.parse('''
libraries:
  - uri: dart:core
    classes:
      Map:
        handMaintained: true
        file: package:dart_eval/stdlib/core.dart
  - uri: $uri
    classes:
      FBound:
        opaque: true
        file: fbound.eval.dart
      Container:
        file: fbound.eval.dart
''')..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'fbound.eval.dart',
        uri,
        false,
        config: config,
        libraryConfig: config.libraries.last,
      ))!;
      expect(generated, contains(r'$FBound.wrap(value)'));
      expect(generated, contains(r'class $FBound implements $Instance'));
      final generatedFile = File(p.join(directory.path, 'fbound.eval.dart'));
      generatedFile.writeAsStringSync('''
import '${source.uri}';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
      final analysis = await Process.run(Platform.resolvedExecutable, [
        'analyze',
        '--no-fatal-warnings',
        generatedFile.path,
      ]);
      expect(
        analysis.exitCode,
        0,
        reason: '${analysis.stdout}\n${analysis.stderr}',
      );
    },
  );

  test('support discovery treats FutureOr as a compiler union', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_future_or_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'future_or.dart'))
      ..writeAsStringSync('''
import 'dart:async';
class AsyncApi { FutureOr<int?>? value; }
''');
    final config = BindgenConfig.parse('''
libraries:
  - uri: ${source.uri}
    classes: [AsyncApi]
''')..resolveDefaults();
    final support = await Bindgen().supportingTypes(config);
    expect(support.map((type) => type.name), isNot(contains('FutureOr')));
  });

  test('preserves generic callback parameters', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_generic_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'generic.dart'))
      ..writeAsStringSync('''
class GenericCallback {
  GenericCallback({required Object Function<T>(T value) callback});
}
''');
    final config = BindgenConfig.parse('''
libraries:
  - uri: package:fixture/generic.dart
    classes: [GenericCallback]
''')..resolveDefaults();
    final generated = (await Bindgen().parse(
      source,
      'generic.dart',
      'package:fixture/generic.dart',
      false,
      config: config,
      libraryConfig: config.libraries.single,
    ))!;
    expect(generated, contains('(_callable) => <T>(T value)'));
  });

  test('omits protected wrapper members unless explicitly included', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_protected_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'protected.dart'))
      ..writeAsStringSync('''
import 'package:meta/meta.dart';
class ProtectedApi {
  @protected
  int internalValue() => 1;
  int publicValue() => 2;
}
''');
    Future<String> generate(String classConfig) async {
      final config = BindgenConfig.parse('''
libraries:
  - uri: package:fixture/protected.dart
    classes:
      ProtectedApi:
$classConfig
''')..resolveDefaults();
      return (await Bindgen().parse(
        source,
        'protected.dart',
        'package:fixture/protected.dart',
        false,
        config: config,
        libraryConfig: config.libraries.single,
      ))!;
    }

    final omitted = await generate('');
    expect(omitted, contains('publicValue'));
    expect(omitted, isNot(contains('internalValue')));
    final included = await generate(
      '        methods:\n          internalValue:\n            include: true',
    );
    expect(included, contains('internalValue'));
  });

  test('optional non-nullable collection uses a non-nullable cast', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_list_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'items.dart'))
      ..writeAsStringSync('''
class Items {
  Items({this.children = const <int>[]});
  final List<int> children;
}
''');
    final config = BindgenConfig.parse('''
libraries:
  - uri: package:fixture/items.dart
    classes: [Items]
''')..resolveDefaults();
    final generated = await Bindgen().parse(
      source,
      'items.dart',
      'package:fixture/items.dart',
      false,
      config: config,
      libraryConfig: config.libraries.single,
    );
    expect(generated, contains('as List).cast<int>()'));
    expect(generated, isNot(contains('as List?)?.cast<int>()')));
  });

  test('reports configured classes missing from a library', () async {
    final config = BindgenConfig.parse('''
libraries:
  - uri: dart:math
    classes: [MissingClass]
''')..resolveDefaults();

    expect(
      () =>
          Bindgen().parseLibrary('dart:math', config, config.libraries.single),
      throwsA(predicate((error) => error.toString().contains('MissingClass'))),
    );
  });

  test('wraps configured types declared in another package library', () async {
    final config = BindgenConfig.parse('''
libraries:
  - uri: package:dart_eval/src/eval/bindgen/context.dart
    outDir: lib/generated/widgets
    classes:
      BindgenContext:
        file: nested/context.dart
  - uri: package:dart_eval/src/eval/bindgen/config.dart
    outDir: lib/generated/types
    classes:
      BindgenConfig:
        file: config.dart
''')..resolveDefaults();
    final collection = AnalysisContextCollection(
      includedPaths: [Directory.current.absolute.path],
    );
    final session = collection
        .contextFor(Directory.current.absolute.path)
        .currentSession;
    final result = await session.getLibraryByUri(
      'package:dart_eval/src/eval/bindgen/config.dart',
    );
    expect(result, isA<LibraryElementResult>());
    final element = (result as LibraryElementResult).element.exportNamespace
        .get2('BindgenConfig')!;
    final ctx =
        BindgenContext(
            'nested/context.dart',
            config.libraries.first.uri,
            all: false,
            bridgeDeclarations: {},
            exportedLibMappings: {},
            config: config,
          )
          ..libraryConfig = config.libraries.first
          ..outputFile = 'nested/context.dart';

    expect(
      wrapVar(ctx, (element as ClassElement).thisType, 'value'),
      r'$BindgenConfig.wrap(value)',
    );
    expect(ctx.imports, contains('../../types/config.dart'));
  });

  test(
    'uses the configured import for a hand-maintained package wrapper',
    () async {
      final config = BindgenConfig.parse('''
libraries:
  - uri: package:dart_eval/src/eval/bindgen/context.dart
    outDir: lib/generated/widgets
    classes: [BindgenContext]
  - uri: package:dart_eval/src/eval/bindgen/config.dart
    outDir: lib/generated/types
    classes:
      BindgenConfig:
        handMaintained: true
        file: package:dart_eval/custom_config_binding.dart
''')..resolveDefaults();
      final collection = AnalysisContextCollection(
        includedPaths: [Directory.current.absolute.path],
      );
      final session = collection
          .contextFor(Directory.current.absolute.path)
          .currentSession;
      final result =
          await session.getLibraryByUri(
                'package:dart_eval/src/eval/bindgen/config.dart',
              )
              as LibraryElementResult;
      final element =
          result.element.exportNamespace.get2('BindgenConfig') as ClassElement;
      final ctx =
          BindgenContext(
              'context.dart',
              config.libraries.first.uri,
              all: false,
              bridgeDeclarations: {},
              exportedLibMappings: {},
              config: config,
            )
            ..libraryConfig = config.libraries.first
            ..outputFile = 'context.dart';

      expect(
        wrapVar(ctx, element.thisType, 'value'),
        r'$BindgenConfig.wrap(value)',
      );
      expect(
        ctx.imports,
        contains('package:dart_eval/custom_config_binding.dart'),
      );
    },
  );
}
