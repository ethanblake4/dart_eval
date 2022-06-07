import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dcli/dcli.dart' as cli;

void main(List<String> args) {
  final parser = ArgParser();

  final compileCmd = parser.addCommand('compile');
  compileCmd.addOption('path', mandatory: true);
  compileCmd.addOption('out', abbr: 'o');

  final runCmd = parser.addCommand('run');
  runCmd.addOption('path', abbr: 'p', mandatory: true);

  final dumpCmd = parser.addCommand('dump');
  dumpCmd.addOption('path', abbr: 'p', mandatory: true);

  final result = parser.parse(args);
  final command = result.command!;

  if (command.name == 'compile') {
    final compiler = Compiler();

    print('Loading files...');
    var commandRoot = Directory(cli.absolute('.'));
    var projectRoot = commandRoot;
    while (true) {
      final files = projectRoot.listSync();
      if (files.any((file) => (file is File && file.path.endsWith('pubspec.yaml')))) {
        break;
      }
      projectRoot = projectRoot.parent;
    }

    final pubspec = cli.PubSpec.fromFile(projectRoot.uri.resolve('pubspec.yaml').path);
    final packageName = pubspec.name;

    final filePaths = cli.find('*.dart').toList();
    final data = <String, String>{};

    String? firstFile;
    String? firstData;

    var sourceLength = 0;

    for (final path in filePaths) {
      final _data = File(path).readAsStringSync();
      sourceLength += _data.length;

      final p = cli.relative(path, from: projectRoot.path);
      if (cli.canonicalize(cli.join(commandRoot.path, command['path'])) == cli.canonicalize(path)) {
        firstFile = p;
        firstData = _data;
      } else {
        data[p] = _data;
      }
    }

    if (firstFile == null) {
      throw ArgumentError('Unable to find the specified file');
    }

    print('Compiling program...');

    final ts = DateTime.now().millisecondsSinceEpoch;

    final compileData = <String, String>{};
    compileData[firstFile] = firstData!;

    final programSource = compiler.compile({packageName!: compileData});
    var outputName = command['out'];
    if (outputName == null) {
      var _path = command['path'] as String?;
      if (_path == null) {
        outputName = 'program.dbc';
      } else {
        final _filename = _path.split('.')[0];
        if (_filename.isEmpty) {
          outputName = 'program.dbc';
        }
        outputName = _filename + '.dbc';
      }
    }

    final _out = programSource.write();

    File(outputName).writeAsBytesSync(_out);

    final timeElapsed = DateTime.now().millisecondsSinceEpoch - ts;
    print('Compiled $sourceLength characters Dart to ${_out.length} bytes DBC in $timeElapsed ms: $outputName');
  } else if (command.name == 'run') {
    final dbc = File(command['path']!).readAsBytesSync();
    final runtime = Runtime(dbc.buffer.asByteData());
    runtime.setup();
    // ignore: deprecated_member_use_from_same_package
    var result = runtime.executeNamed(0, 'main');

    if (result != null) {
      if (result is $Value) {
        result = result.$reified;
      }
      print('\nProgram exited with result: $result');
    }
  } else if (command.name == 'dump') {
    final dbc = File(command['path']!).readAsBytesSync();
    final runtime = Runtime(dbc.buffer.asByteData());
    runtime.setup();
    runtime.printOpcodes();
  }
}
