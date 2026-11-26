import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'package:dart_eval/src/eval/bindgen/runtime_type.dart';
import 'package:test/test.dart';

void main() {
  group('resolveRuntimeTypeSpec', () {
    late _Fixture fixture;
    var fixtureCreated = false;

    setUpAll(() async {
      fixture = await _Fixture.create();
      fixtureCreated = true;
    });
    tearDownAll(() {
      if (fixtureCreated) fixture.dispose();
    });

    test('resolves direct literals and standard type registries', () async {
      final context = fixture.context();

      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          "BridgeTypeSpec('package:example/direct.dart', 'Direct')",
        ),
        _isSpec('package:example/direct.dart', 'Direct'),
      );
      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'CoreTypes.string',
        ),
        _isSpec('dart:core', 'String'),
      );
      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'AsyncTypes.timer',
        ),
        _isSpec('dart:async', 'Timer'),
      );
      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'CoreTypes.nullType',
        ),
        _isSpec('dart:core', 'Null'),
      );
    });

    test('resolves imported const fields and top-level consts', () async {
      final context = fixture.context()
        ..imports.add(fixture.specsUri)
        ..libraryConfig = BindgenLibraryConfig(
          uri: 'package:example/owner.dart',
          imports: ["import '${fixture.specsUri}' as specs;"],
        )
        ..classConfig = BindgenClassConfig(
          name: 'Widget',
          imports: [fixture.specsUri],
        );

      expect(
        await resolveRuntimeTypeSpec(fixture.session, context, 'topLevelSpec'),
        _isSpec('package:example/imported.dart', 'TopLevel'),
      );
      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'specs.UserTypes.custom',
        ),
        _isSpec('package:example/imported.dart', 'Custom'),
      );
      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'UserTypes.custom',
        ),
        _isSpec('package:example/imported.dart', 'Custom'),
      );
    });

    test('resolves generated registry entries from bindgen config', () async {
      final library = BindgenLibraryConfig(
        uri: 'package:example/widgets.dart',
        registry: const BindgenRegistryConfig(
          file: 'widget_types.dart',
          className: 'WidgetTypes',
          extra: {'dynamic': 'dynamic'},
        ),
        classes: {'Widget': const BindgenClassConfig(name: 'Widget')},
      );
      final config = BindgenConfig(
        defaults: const BindgenDefaults(),
        libraries: [library],
      );
      final context = fixture.context(config: config)
        ..classConfig = const BindgenClassConfig(name: 'Widget');

      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'WidgetTypes.widget',
        ),
        _isSpec('package:example/widgets.dart', 'Widget'),
      );
      expect(
        await resolveRuntimeTypeSpec(
          fixture.session,
          context,
          'WidgetTypes.dynamic',
        ),
        _isSpec('package:example/widgets.dart', 'dynamic'),
      );
    });

    test(
      'configured registries take precedence over stale analyzer constants',
      () async {
        final library = BindgenLibraryConfig(
          uri: 'package:example/configured_types.dart',
          registry: const BindgenRegistryConfig(
            file: 'types.dart',
            className: 'CoreTypes',
            extra: {'string': 'ConfiguredString'},
          ),
        );
        final context = fixture.context(
          config: BindgenConfig(
            defaults: const BindgenDefaults(),
            libraries: [library],
          ),
        );

        // The analyzer can resolve CoreTypes.string from the checked-in
        // standard registry, but generation will use the configured registry.
        expect(
          await resolveRuntimeTypeSpec(
            fixture.session,
            context,
            'CoreTypes.string',
          ),
          _isSpec('package:example/configured_types.dart', 'ConfiguredString'),
        );
      },
    );

    test('rejects arbitrary constants and expressions with context', () async {
      final context = fixture.context()
        ..imports.add(fixture.specsUri)
        ..classConfig = const BindgenClassConfig(name: 'Widget');

      await expectLater(
        resolveRuntimeTypeSpec(fixture.session, context, 'fakeMap'),
        throwsA(
          isA<BindingGenerationError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('fakeMap'),
              contains('package:example/owner.dart::Widget'),
            ),
          ),
        ),
      );
      await expectLater(
        resolveRuntimeTypeSpec(fixture.session, context, 'makeSpec()'),
        throwsA(isA<BindingGenerationError>()),
      );
    });
  });
}

Matcher _isSpec(String library, String name) => predicate<BridgeTypeSpec>(
  (spec) => spec.library == library && spec.name == name,
  'BridgeTypeSpec($library, $name)',
);

class _Fixture {
  _Fixture(this.directory, this.session, this.owner, this.specsUri);

  final Directory directory;
  final AnalysisSession session;
  final LibraryElement owner;
  final String specsUri;

  static Future<_Fixture> create() async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_runtime_type_');
    try {
      final specsFile =
          File('${directory.path}${Platform.pathSeparator}specs.dart')
            ..writeAsStringSync('''
import 'package:dart_eval/dart_eval_bridge.dart';

const topLevelSpec = BridgeTypeSpec('package:example/imported.dart', 'TopLevel');
const fakeMap = {'library': 'package:fake', 'name': 'Fake'};

class UserTypes {
  static const custom = BridgeTypeSpec('package:example/imported.dart', 'Custom');
  static const fake = {'library': 'package:fake', 'name': 'Fake'};
}
''');
      final ownerFile = File(
        '${directory.path}${Platform.pathSeparator}owner.dart',
      )..writeAsStringSync('class Owner {}\n');
      final collection = AnalysisContextCollection(
        includedPaths: [Directory.current.absolute.path],
      );
      final session = collection
          .contextFor(Directory.current.absolute.path)
          .currentSession;
      final result = await session.getResolvedLibrary(ownerFile.absolute.path);
      if (result is! ResolvedLibraryResult) {
        throw StateError(
          'Could not analyze the owner test library: ${result.runtimeType}',
        );
      }
      return _Fixture(
        directory,
        session,
        result.element,
        Uri.file(specsFile.absolute.path).toString(),
      );
    } catch (_) {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      rethrow;
    }
  }

  BindgenContext context({BindgenConfig? config}) => BindgenContext(
    'owner.dart',
    'package:example/owner.dart',
    all: false,
    bridgeDeclarations: const {},
    exportedLibMappings: const {},
    config: config,
  )..libraryElement = owner;

  void dispose() => directory.deleteSync(recursive: true);
}
