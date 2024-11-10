import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/cli/utils.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

const defaultImports = '''
// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import


import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
''';

void cliBind([bool singleFile = false, bool all = false]) async {
  print('Loading files...');
  final commandRoot = Directory(current);
  final projectRoot = findProjectRoot(commandRoot);

  final packageConfig = getPackageConfig(projectRoot);

  final pubspecFile = File(join(projectRoot.path, 'pubspec.yaml'));
  final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
  final packageName = pubspec.name;

  final bindgen = Bindgen();
  final formatter = DartFormatter();
  for (final package in packageConfig.packages) {
    if (package.name == packageName) {
      bindgen.inject(package: package);
      break;
    }
  }

  var singleResult = '';
  var numBound = 0;

  Future<void> bindLoop(String pkg, Directory dir, String root) async {
    if (!dir.existsSync()) return;
    for (final file in dir.listSync()) {
      final filename = basename(file.path);
      if (file is File &&
          filename.endsWith('.dart') &&
          filename.split('.').length == 2) {
        final p = relative(file.path, from: root).replaceAll('\\', '/');
        final uri = 'package:${posix.join(packageName, p)}';
        final output = await bindgen.parse(file, filename, uri, all);
        if (output != null) {
          print('Bound ${file.path}');
          numBound++;
          if (singleFile) {
            final ogImport = "import '$uri';\n";
            singleResult = ogImport + singleResult + output;
          } else {
            final ogImport = "import '$filename';\n";
            final outputFilename = filename.replaceAll('.dart', '.eval.dart');
            final outputFile = File(join(dir.path, outputFilename));
            final result = formatter.format(defaultImports + ogImport + output);
            outputFile.writeAsStringSync(result);
          }
        }
      } else if (file is Directory) {
        await bindLoop(pkg, file, root);
      }
    }
  }

  await bindLoop(packageName, Directory(join(projectRoot.path, 'lib')),
      join(projectRoot.path, 'lib'));

  if (singleFile) {
    final outputFile =
        File(join(projectRoot.path, 'lib', 'dart_eval_bindings.dart'));
    final result = formatter.format(defaultImports + singleResult);
    outputFile.writeAsStringSync(result);
  }

  if (numBound == 0) {
    print('No files were bound. You may need to add the @Bind annotation from '
        'the eval_annotation package, or pass the --all flag to bind all classes.');
  } else {
    print('Created bindings for $numBound files.');
  }
}
