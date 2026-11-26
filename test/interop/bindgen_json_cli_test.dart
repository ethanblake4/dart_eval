import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'bind CLI writes JSON for config and --all without Dart output',
    () async {
      final project = Directory.systemTemp.createTempSync('bindgen_json_cli_');
      addTearDown(() => project.deleteSync(recursive: true));

      final repository = Directory.current;
      final packageConfig = File(
        p.join(repository.path, '.dart_tool', 'package_config.json'),
      );
      final packageConfigData =
          jsonDecode(packageConfig.readAsStringSync()) as Map<String, dynamic>;
      final packages = (packageConfigData['packages'] as List)
          .cast<Map<String, dynamic>>()
          .where((entry) => entry['name'] != 'fixture')
          .toList();
      for (final package in packages) {
        final rootUri = Uri.parse(package['rootUri'] as String);
        if (!rootUri.hasScheme) {
          package['rootUri'] = packageConfig.uri.resolveUri(rootUri).toString();
        }
      }
      packages.add({
        'name': 'fixture',
        'rootUri': Uri.directory(project.path).toString(),
        'packageUri': 'lib/',
        'languageVersion': '3.8',
      });

      File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: fixture
version: 1.0.0
environment:
  sdk: ">=3.8.0 <4.0.0"
''');
      final lib = Directory(p.join(project.path, 'lib'))..createSync();
      File(p.join(lib.path, 'sample.dart')).writeAsStringSync('''
class Sample {
  Sample(this.value);
  final int value;
  int get doubled => value * 2;
}
''');
      File(p.join(lib.path, 'other.dart')).writeAsStringSync('''
class Sample {
  Sample(this.value);
  final int value;
}
''');
      File(
        p.join(project.path, 'plugin_source.dart'),
      ).writeAsStringSync('const int pluginValue = 1;');
      final toolDir = Directory(p.join(project.path, '.dart_tool'))
        ..createSync();
      final projectPackageConfig =
          File(p.join(toolDir.path, 'package_config.json'))..writeAsStringSync(
            jsonEncode({'configVersion': 2, 'packages': packages}),
          );
      final configText = '''
version: 1
libraries:
  - uri: package:fixture/sample.dart
    classes:
      Sample:
        wrapperName: First
        runtimeType: CoreTypes.string
    plugin:
      out: sample_eval_plugin.dart
      class: FixturePlugin
      identifier: package:fixture
      excludeDeclarations: [First]
      evalSources:
        - uri: package:fixture/plugin_source.dart
          file: plugin_source.dart
      extraSources:
        - target: runtime
          expression: "throw StateError('runtime only')"
    registry:
      file: generated_types.dart
  - uri: package:fixture/other.dart
    classes:
      Sample:
        wrapperName: Second
''';
      File(p.join(project.path, 'bindgen.yaml')).writeAsStringSync(configText);

      Future<ProcessResult> runBind(List<String> arguments) =>
          Process.run(Platform.resolvedExecutable, [
            '--packages=${projectPackageConfig.path}',
            p.join(repository.path, 'bin', 'dart_eval.dart'),
            'bind',
            ...arguments,
          ], workingDirectory: lib.path);

      final dartOutError = await runBind(['--out', 'bindings.json']);
      expect(dartOutError.exitCode, isNot(0));
      expect(dartOutError.stderr, contains('--out is only available'));
      final singleFileJsonError = await runBind([
        '--single-file',
        '--format',
        'json',
      ]);
      expect(singleFileJsonError.exitCode, isNot(0));
      expect(
        singleFileJsonError.stderr,
        contains('--single-file cannot be used'),
      );

      final configured = await runBind([
        '--format',
        'json',
        '--config',
        'bindgen.yaml',
        '--out',
        'configured.json',
      ]);
      expect(configured.exitCode, 0, reason: configured.stderr.toString());
      final configuredJson =
          jsonDecode(
                File(
                  p.join(project.path, 'configured.json'),
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(configuredJson['classes'], hasLength(1));
      expect(
        ((configuredJson['classes'] as List).single
            as Map)['type']['type']['unresolved']['name'],
        'Sample',
      );
      expect(
        ((configuredJson['classes'] as List).single
            as Map)['type']['type']['unresolved']['library'],
        'package:fixture/other.dart',
      );
      final sources = configuredJson['sources'] as List;
      expect(
        sources,
        contains(containsPair('uri', 'package:fixture/plugin_source.dart')),
      );
      expect(
        sources,
        contains(containsPair('source', '\nconst int pluginValue = 1;\n')),
      );
      expect(
        sources,
        isNot(contains(containsPair('source', contains('runtime only')))),
      );

      final preservedOutput = File(p.join(project.path, 'preserved.json'))
        ..writeAsStringSync('keep this output');
      final invalidConfig = configText.replaceFirst(
        '''      extraSources:
        - target: runtime''',
        '''      extraSources:
        - target: compile
          expression: "throw StateError('compile expression')"
        - target: runtime''',
      );
      File(
        p.join(project.path, 'invalid_bindgen.yaml'),
      ).writeAsStringSync(invalidConfig);
      final unsupported = await runBind([
        '--format',
        'json',
        '--config',
        'invalid_bindgen.yaml',
        '--out',
        'preserved.json',
      ]);
      expect(unsupported.exitCode, isNot(0));
      expect(unsupported.stderr, contains('cannot evaluate compile-time'));
      expect(preservedOutput.readAsStringSync(), 'keep this output');

      final all = await runBind(['--format', 'json', '--all']);
      expect(all.exitCode, 0, reason: all.stderr.toString());
      final defaultOutput = File(
        p.join(project.path, '.dart_eval', 'bindings', 'fixture.json'),
      );
      expect(defaultOutput.existsSync(), isTrue);
      final allJson =
          jsonDecode(defaultOutput.readAsStringSync()) as Map<String, dynamic>;
      expect(allJson['classes'], hasLength(2));

      final inputBindings = Directory(
        p.join(project.path, '.dart_eval', 'bindings'),
      );
      File(p.join(inputBindings.path, 'dependency.json')).writeAsStringSync(
        jsonEncode({
          'classes': <Object>[],
          'enums': <Object>[],
          'functions': <Object>[],
          'exportedLibMappings': <String, String>{},
        }),
      );
      defaultOutput.writeAsStringSync('not JSON input');
      final rerun = await runBind(['--format', 'json', '--all']);
      expect(rerun.exitCode, 0, reason: rerun.stderr.toString());
      final rerunOutput = rerun.stdout.toString().replaceAll('\\', '/');
      expect(
        rerunOutput,
        contains('Found binding file: .dart_eval/bindings/dependency.json'),
      );
      expect(
        rerunOutput,
        isNot(contains('Found binding file: .dart_eval/bindings/fixture.json')),
      );
      final rerunJson =
          jsonDecode(defaultOutput.readAsStringSync()) as Map<String, dynamic>;
      expect(rerunJson['classes'], hasLength(2));

      expect(
        lib
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.eval.dart')),
        isEmpty,
      );
      expect(File(p.join(lib.path, 'eval_plugin.dart')).existsSync(), isFalse);
      expect(
        File(p.join(lib.path, 'dart_eval_bindings.dart')).existsSync(),
        isFalse,
      );
      final generatedDartFiles = project
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) => !{
              p.normalize(p.join(lib.path, 'sample.dart')),
              p.normalize(p.join(lib.path, 'other.dart')),
              p.normalize(p.join(project.path, 'plugin_source.dart')),
            }.contains(p.normalize(file.path)),
          )
          .where((file) => file.path.endsWith('.dart'));
      expect(generatedDartFiles, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
