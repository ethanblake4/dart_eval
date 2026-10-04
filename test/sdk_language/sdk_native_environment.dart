import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Native re-entry uses the original SDK source and its own package resolution.
final class SdkNativeEnvironment extends EvalPlugin {
  SdkNativeEnvironment(this.script, Directory checkout) {
    final config = File(
      p.join(checkout.path, '.dart_tool', 'package_config.json'),
    );
    if (!config.existsSync()) {
      final manifest =
          loadYaml(
                File(
                  p.join(checkout.path, 'pkg', 'expect', 'pubspec.yaml'),
                ).readAsStringSync(),
              )
              as YamlMap;
      final environment = manifest['environment'] as YamlMap;
      final sdk = environment['sdk'] as String;
      final languageVersion = RegExp(r'\d+\.\d+').firstMatch(sdk)!.group(0)!;
      config.parent.createSync(recursive: true);
      config.writeAsStringSync(
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'expect',
              'rootUri': '../pkg/expect/',
              'packageUri': 'lib/',
              'languageVersion': languageVersion,
            },
          ],
        }),
      );
    }
  }

  final Uri script;

  @override
  String get identifier => 'sdk-native-environment';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {}

  @override
  void configureForRuntime(Runtime runtime) {
    runtime.grant(
      ProcessRunPermission(RegExp('^${RegExp.escape(Platform.executable)}\$')),
    );
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.script*g',
      (runtime, r, s, c) => $Uri.wrap(script),
    );
  }
}
