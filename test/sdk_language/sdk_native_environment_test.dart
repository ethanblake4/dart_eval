import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'sdk_native_environment.dart';

void main() {
  test(
    'SDK native re-entry resolves packages and permits only its executable',
    () async {
      final checkout = Directory.systemTemp.createTempSync(
        'dart_eval_native_sdk_',
      );
      addTearDown(() => checkout.deleteSync(recursive: true));
      final expectPackage = Directory(p.join(checkout.path, 'pkg', 'expect'));
      Directory(p.join(expectPackage.path, 'lib')).createSync(recursive: true);
      File(
        p.join(expectPackage.path, 'pubspec.yaml'),
      ).writeAsStringSync("name: expect\nenvironment:\n  sdk: '^3.13.0'\n");
      File(
        p.join(expectPackage.path, 'lib', 'expect.dart'),
      ).writeAsStringSync("const message = 'native child';\n");
      final script = File(
        p.join(checkout.path, 'tests', 'language', 'child.dart'),
      );
      script.parent.createSync(recursive: true);
      script.writeAsStringSync('''
import 'package:expect/expect.dart';
void main(List<String> arguments) {
  if (arguments.single != '--child') throw StateError('child arguments');
  print(message);
}
''');
      final program = Compiler().compile({
        'native_sdk': {
          'main.dart': '''
import 'dart:io';
Future<String> main() async {
  final result = await Process.run(Platform.executable, [
    Platform.script.toFilePath(), '--child',
  ]);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        runtime.addPlugin(SdkNativeEnvironment(script.absolute.uri, checkout));
        final result = await runtime.executeLib(
          'package:native_sdk/main.dart',
          'main',
        );
        expect(result is $Value ? result.$reified : result, 'native child');
        expect(
          runtime.checkPermission('process:run', Platform.executable),
          true,
        );
        expect(
          runtime.checkPermission(
            'process:run',
            '${Platform.executable}.other',
          ),
          false,
        );
      }
    },
  );
}
