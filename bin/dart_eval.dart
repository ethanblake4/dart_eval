import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

void main(List<String> args) {
  final parser = ArgParser();

  final compileCmd = parser.addCommand('compile');
  compileCmd.addOption('out', abbr: 'o');
  compileCmd.addFlag('help', abbr: 'h');

  final runCmd = parser.addCommand('run');
  runCmd.addOption('library', abbr: 'l');
  runCmd.addOption('function', abbr: 'f', defaultsTo: 'main');
  runCmd.addFlag('help', abbr: 'h');

  final dumpCmd = parser.addCommand('dump');
  dumpCmd.addFlag('help', abbr: 'h');

  // ignore: unused_local_variable
  final helpCmd = parser.addCommand('help');

  final result = parser.parse(args);
  final command = result.command;

  if (command == null || command.name == 'help') {
    print('The dart_eval CLI tool.');
    print('Available commands:');
    print('   compile Compile a Dart project to EVC bytecode.');
    print('   run Run EVC bytecode in the dart_eval VM.');
    print('   dump Dump op codes from an EVC file.');
    print('   help Print this help message.');
    print('');
    print(
        'For more information, use dart_eval <command> --help on an individual command.');
    exit(1);
  }

  if (command.name == 'compile') {
    if (command['help']!) {
      print('compile: Compile a Dart project to EVC bytecode.');
      print('Usage:');
      print('   dart_eval compile [-o, --out <outfile>] [-h, --help]');
      exit(0);
    }

    final compiler = Compiler();

    print('Loading files...');
    var commandRoot = Directory('.');
    var projectRoot = commandRoot;
    while (true) {
      final files = projectRoot.listSync();
      if (files.any(
          (file) => (file is File && file.path.endsWith('pubspec.yaml')))) {
        break;
      }
      projectRoot = projectRoot.parent;
    }

    final bridgedPackages = <String>[];

    if (FileSystemEntity.typeSync('./.dart_eval/bindings') ==
        FileSystemEntityType.directory) {
      final files = Directory('./.dart_eval/bindings')
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>();

      for (final file in files) {
        print(
            'Found binding file: ${relative(file.path, from: projectRoot.path)}');
        final _data = file.readAsStringSync();
        final decoded = (json.decode(_data) as Map).cast<String, dynamic>();
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
              BridgeFunctionDeclaration.fromJson($function.cast()));
        }
      }

      for (final lib in compiler.bridgedLibraries) {
        if (lib.startsWith('package:')) {
          final packageName = lib.split('/')[0].substring(8);
          if (!bridgedPackages.contains(packageName)) {
            bridgedPackages.add(packageName);
          }
        }
      }
    }

    final pubspecFile = File(join(projectRoot.uri.path, 'pubspec.yaml'));
    final pubspec = Pubspec.parse(pubspecFile.readAsStringSync());

    final packageName = pubspec.name;
    compiler.version = pubspec.version?.canonicalizedVersion;

    final data = <String, Map<String, String>>{};
    var sourceLength = 0;

    // Recursively add dart files in the lib directory
    final libDir = Directory(join(projectRoot.path, 'lib'));

    void addFiles(String pkg, Directory dir, String root) {
      if (!data.containsKey(pkg)) {
        data[pkg] = {};
      }
      for (final file in dir.listSync()) {
        if (file is File && file.path.endsWith('.dart')) {
          final _data = file.readAsStringSync();
          sourceLength += _data.length;

          final p = relative(file.path, from: root).replaceAll('\\', '/');
          data[pkg]![p] = _data;
        } else if (file is Directory) {
          addFiles(pkg, file, root);
        }
      }
    }

    addFiles(packageName, libDir, libDir.path);

    final packageConfigFile =
        File(join(projectRoot.uri.path, '.dart_tool', 'package_config.json'))
            .readAsStringSync();
    final packageConfig = PackageConfig.parseString(
        packageConfigFile, Uri.parse(join(projectRoot.uri.path, '.dart_tool')));

    for (final package in packageConfig.packages) {
      if (bridgedPackages.contains(package.name)) {
        print('Skipped package ${package.name} because it is bridged.');
        continue;
      }

      print('Adding package ${package.name} from pubspec...');

      final pkgDir = Directory(package.packageUriRoot.path);
      addFiles(package.name, pkgDir, pkgDir.path);
    }

    print('Compiling package $packageName...');

    final ts = DateTime.now().millisecondsSinceEpoch;

    final programSource = compiler.compile(data);
    var outputName = command['out'];
    if (outputName == null) {
      if (!command.options.contains('path')) {
        outputName = 'program.evc';
      } else {
        var _path = command['path'] as String;
        final _filename = _path.split('.')[0];
        if (_filename.isEmpty) {
          outputName = 'program.evc';
        }
        outputName = '$_filename.evc';
      }
    }

    final _out = programSource.write();

    File(outputName).writeAsBytesSync(_out);

    final timeElapsed = DateTime.now().millisecondsSinceEpoch - ts;
    print(
        'Compiled $sourceLength characters Dart to ${_out.length} bytes EVC in $timeElapsed ms: $outputName');
  } else if (command.name == 'run') {
    if (command['help']! || command.rest.length != 1) {
      if (command['help']) {
        print('run: Run EVC bytecode in the dart_eval VM.');
      } else {
        print('You must pass the name of the EVC file to run.');
      }

      print('Usage:');
      print(
          '   dart_eval run <file> [-l, --library <library>] [-f, --function <function>] [-h, --help]');
      if (command['help'])
        print('\nNote that bindings are not supported in the run command.');
      exit(command['help'] ? 0 : 1);
    }
    if (command['library'] == null) {
      print(
          'You must pass the library parameter with the name of the library to run.');
      print(
          'Example: dart_eval run program.evc --library package:my_package/main.dart');
      exit(1);
    }
    final evc = File(command.rest[0]).readAsBytesSync();
    final runtime = Runtime(evc.buffer.asByteData());
    runtime.setup();
    var result = runtime.executeLib(command['library']!, command['function']!);

    if (result != null) {
      if (result is $Value) {
        result = result.$reified;
      }
      print('\nProgram exited with result: $result');
    }
  } else if (command.name == 'dump') {
    if (command['help']! || command.rest.length != 1) {
      if (command['help']) {
        print('dump: Dump op codes from an EVC file.');
      } else {
        print('You must pass the name of the EVC file to dump.');
      }

      print('Usage:');
      print('   dart_eval dump <file> [-h, --help]');
      exit(command['help'] ? 0 : 1);
    }
    final evc = File(command.rest[0]).readAsBytesSync();
    final runtime = Runtime(evc.buffer.asByteData());
    runtime.setup();
    runtime.printOpcodes();
  }
}
