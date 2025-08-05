import 'dart:convert';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/cli/utils.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

const defaultImports = '''
// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
''';

void cliBind(
    {bool singleFile = false,
    bool all = false,
    bool generatePlugin = true}) async {
  print('Loading files...');
  final commandRoot = Directory(current);
  final projectRoot = findProjectRoot(commandRoot);

  final bindgen = Bindgen();

  if (FileSystemEntity.typeSync('./.dart_eval/bindings') ==
      FileSystemEntityType.directory) {
    final files = Directory('./.dart_eval/bindings')
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>();

    for (final file in files) {
      print(
          'Found binding file: ${relative(file.path, from: projectRoot.path)}');
      final data = file.readAsStringSync();
      final decoded = (json.decode(data) as Map).cast<String, dynamic>();
      final classList = (decoded['classes'] as List);
      for (final $class in classList.cast<Map>()) {
        bindgen.defineBridgeClass(BridgeClassDef.fromJson($class.cast()));
      }
      for (final $enum in (decoded['enums'] as List).cast<Map>()) {
        bindgen.defineBridgeEnum(BridgeEnumDef.fromJson($enum.cast()));
      }
      for (final $function in (decoded['functions'] as List).cast<Map>()) {
        bindgen.defineBridgeTopLevelFunction(
            BridgeFunctionDeclaration.fromJson($function.cast()));
      }
      (decoded['exportedLibMappings'] as Map)
          .cast<String, String>()
          .forEach((key, value) {
        bindgen.addExportedLibraryMapping(key, value);
      });
    }
  }

  final packageConfig = getPackageConfig(projectRoot);

  final pubspecFile = File(join(projectRoot.path, 'pubspec.yaml'));
  final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());
  final packageName = pubspec.name;

  final version = Version.parse(Platform.version.split(' ').first);
  final formatter = DartFormatter(languageVersion: version);
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
          !filename.endsWith('.eval.dart')) {
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
            final result = formatter.format(defaultImports + ogImport + output,
                uri: Uri.parse(uri));
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
    final outPath = join(projectRoot.path, 'lib', 'dart_eval_bindings.dart');
    final outputFile = File(outPath);
    final result = formatter.format(defaultImports + singleResult,
        uri: Uri.parse('package:$packageName/dart_eval_bindings.dart'));
    outputFile.writeAsStringSync(result);
  }

  if (generatePlugin) {
    final pluginFile = File(join(projectRoot.path, 'lib', 'eval_plugin.dart'));
    final pluginContent = '''
import 'package:dart_eval/dart_eval_bridge.dart';
${[
      ...bindgen.registerClasses,
      ...bindgen.registerEnums
    ].map((e) => e.uri.substring(e.uri.indexOf('/') + 1)).toSet().map((e) => 'import \'${e.replaceAll('.dart', '.eval.dart')}\';').join('\n')}

/// [EvalPlugin] for $packageName
class ${packageName.toPascalCase()}Plugin implements EvalPlugin {
  @override
  String get identifier => 'package:${packageName.toLowerCase()}';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    ${bindgen.registerClasses.map((e) => 'registry.defineBridgeClass(\$${e.name}.\$declaration);').join('\n')}
    ${bindgen.registerEnums.map((e) => 'registry.defineBridgeEnum(\$${e.name}.\$declaration);').join('\n')}
  }

  @override
  void configureForRuntime(Runtime runtime) {
    ${bindgen.registerClasses.map((e) => '\$${e.name}.configureForRuntime(runtime);').join('\n')}
    ${bindgen.registerEnums.map((e) => '\$${e.name}.configureForRuntime(runtime);').join('\n')}
  }
}
''';
    pluginFile.writeAsStringSync(formatter.format(pluginContent,
        uri: Uri.parse('package:$packageName/eval_plugin.dart')));
    print('Generated plugin file: ${pluginFile.path}');
  } else {
    print('Skipping plugin generation.');
  }

  if (numBound == 0) {
    print('No files were bound. You may need to add the @Bind annotation from '
        'the eval_annotation package, or pass the --all flag to bind all classes.');
  } else {
    print('Created bindings for $numBound files.');
  }
}
