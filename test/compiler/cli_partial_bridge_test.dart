import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test(
    'CLI collects unbridged siblings and honors metadata source replacements',
    () async {
      final workspace = Directory.current;
      final project = Directory.systemTemp.createTempSync(
        'eval_partial_bridge_',
      );
      addTearDown(() => project.deleteSync(recursive: true));
      void write(String path, String contents) {
        final file = File('${project.path}/$path');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(contents);
      }

      write(
        'pubspec.yaml',
        'name: fixture\nenvironment:\n  sdk: ">=3.3.0 <4.0.0"\n',
      );
      write(
        'lib/main.dart',
        "import 'package:dependency/dependency.dart'; int main() => helper() + replacement();",
      );
      write(
        'dependency/lib/dependency.dart',
        "export 'bridged.dart'; export 'helper.dart'; export 'replacement.dart';",
      );
      write('dependency/lib/helper.dart', 'int helper() => 7;');
      // Both files must be excluded before parsing in favor of their metadata.
      write('dependency/lib/bridged.dart', 'not valid Dart syntax');
      write('dependency/lib/replacement.dart', 'not valid Dart syntax');
      write(
        '.dart_tool/package_config.json',
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'fixture',
              'rootUri': '../',
              'packageUri': 'lib/',
              'languageVersion': '3.3',
            },
            {
              'name': 'dependency',
              'rootUri': '../dependency/',
              'packageUri': 'lib/',
              'languageVersion': '3.3',
            },
          ],
        }),
      );
      write(
        '.dart_eval/bindings/dependency.json',
        jsonEncode({
          'classes': [],
          'enums': [],
          'functions': [
            const BridgeFunctionDeclaration(
              'package:dependency/bridged.dart',
              'host',
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              ),
            ).toJson(),
          ],
          'sources': [
            {
              'uri': 'package:dependency/replacement.dart',
              'source': 'int replacement() => 11;',
            },
          ],
        }),
      );

      final result = await Process.run(Platform.resolvedExecutable, [
        '--packages=${workspace.path}/.dart_tool/package_config.json',
        '${workspace.path}/bin/dart_eval.dart',
        'compile',
        '-o',
        'program.evc',
      ], workingDirectory: project.path);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      final runtime = Runtime(
        File('${project.path}/program.evc').readAsBytesSync().buffer,
      );
      expect(runtime.executeLib('package:fixture/main.dart', 'main'), 18);
    },
  );
}
