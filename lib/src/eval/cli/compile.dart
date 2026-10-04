import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/cli/utils.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

void cliCompile(String outputName) {
  final compiler = Compiler()
    ..diagnosticMode = DiagnosticMode.throwErrorPrintAll;

  print('Loading files...');
  var commandRoot = Directory(current);
  var projectRoot = findProjectRoot(commandRoot);

  if (FileSystemEntity.typeSync('./.dart_eval/bindings') ==
      FileSystemEntityType.directory) {
    final files = Directory('./.dart_eval/bindings')
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>();

    for (final file in files) {
      print(
        'Found binding file: ${relative(file.path, from: projectRoot.path)}',
      );
      final data0 = file.readAsStringSync();
      final decoded = (json.decode(data0) as Map).cast<String, dynamic>();
      final classList = (decoded['classes'] as List);
      for (final $class in classList.cast<Map>()) {
        compiler.defineBridgeClass(BridgeClassDef.fromJson($class.cast()));
      }
      for (final $enum in (decoded['enums'] as List).cast<Map>()) {
        compiler.defineBridgeEnum(BridgeEnumDef.fromJson($enum.cast()));
      }
      for (final $source in (decoded['sources'] as List).cast<Map>()) {
        compiler.addSource(DartSource($source['uri'], $source['source']));
      }
      for (final $function in (decoded['functions'] as List).cast<Map>()) {
        compiler.defineBridgeTopLevelFunction(
          BridgeFunctionDeclaration.fromJson($function.cast()),
        );
      }
    }
  }

  // Bindings replace their exact libraries, while unbridged package files
  // remain available for imports and exports.
  final replacedLibraries = {
    ...compiler.bridgedLibraries.map(Uri.parse),
    ...compiler.additionalSources.map((source) => source.uri),
  };

  final pubspecFile = File(join(projectRoot.path, 'pubspec.yaml'));
  final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());

  final packageName = pubspec.name;
  compiler.version = pubspec.version?.canonicalizedVersion;

  final data = <String, Map<String, String>>{};
  var sourceLength = 0;

  // Recursively add dart files in the lib and bin directory
  final libDir = Directory(join(projectRoot.path, 'lib'));
  final binDir = Directory(join(projectRoot.path, 'bin'));

  void addFiles(String pkg, Directory dir, String root) {
    if (!dir.existsSync()) return;
    if (!data.containsKey(pkg)) {
      data[pkg] = {};
    }
    for (final file in dir.listSync()) {
      if (file is File && file.path.endsWith('.dart')) {
        final p = relative(file.path, from: root).replaceAll('\\', '/');
        if (replacedLibraries.contains(Uri.parse('package:$pkg/$p'))) continue;
        final fileData = file.readAsStringSync();
        sourceLength += fileData.length;

        data[pkg]![p] = fileData;
      } else if (file is Directory) {
        addFiles(pkg, file, root);
      }
    }
  }

  addFiles(packageName, libDir, libDir.path);
  addFiles(packageName, binDir, binDir.path);

  final packageConfig = getPackageConfig(projectRoot);

  if (packageConfig.packages.length > 1) {
    print('Adding packages from package config:');
  }
  for (final package in packageConfig.packages) {
    if (packageName == package.name) {
      continue;
    }

    stdout.write('${package.name} ');

    String filepath;
    try {
      filepath = package.packageUriRoot.toFilePath();
    } catch (e) {
      filepath = package.packageUriRoot.toString();
    }

    final pkgDir = Directory(filepath);
    addFiles(package.name, pkgDir, pkgDir.path);
  }

  stdout.write('\n');

  print('\nCompiling package $packageName...');

  final ts = DateTime.now().millisecondsSinceEpoch;

  final languageVersions = {
    for (final package in packageConfig.packages)
      package.name: switch (package.languageVersion) {
        null => null,
        final version => Version(version.major, version.minor, 0),
      },
  };
  final programSource = compiler.compileSources(
    data.entries.expand(
      (package) => package.value.entries.map(
        (file) => DartSource(
          'package:${package.key}/${file.key}',
          file.value,
          languageVersion: languageVersions[package.key],
        ),
      ),
    ),
  );

  final out = programSource.write();

  File(outputName).writeAsBytesSync(out);

  final timeElapsed = DateTime.now().millisecondsSinceEpoch - ts;
  print(
    'Compiled $sourceLength characters Dart to ${out.length} bytes EVC in $timeElapsed ms: $outputName',
  );
}
