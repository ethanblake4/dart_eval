import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/cli/bind.dart';
import 'package:dart_eval/src/eval/cli/compile.dart';
import 'package:dart_eval/src/eval/cli/run.dart';

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

  final bindCmd = parser.addCommand('bind');
  bindCmd.addFlag('help', abbr: 'h');
  bindCmd.addFlag('single-file', abbr: 's');
  bindCmd.addFlag('all', abbr: 'a');
  bindCmd.addFlag('plugin', defaultsTo: true);

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
    print('   bind Generate bindings for a Dart project (experimental)');
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

    var outputName = command['out'];
    if (outputName == null) {
      if (!command.options.contains('path')) {
        outputName = 'program.evc';
      } else {
        var cmdPath = command['path'] as String;
        final cmdFilename = cmdPath.split('.')[0];
        if (cmdFilename.isEmpty) {
          outputName = 'program.evc';
        }
        outputName = '$cmdFilename.evc';
      }
    }

    cliCompile(outputName);
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
      if (command['help']) {
        print('\nNote that bindings are not supported in the run command.');
      }
      exit(command['help'] ? 0 : 1);
    }
    if (command['library'] == null) {
      print(
          'You must pass the library parameter with the name of the library to run.');
      print(
          'Example: dart_eval run program.evc --library package:my_package/main.dart');
      exit(1);
    }
    cliRun(command.rest[0], command['library'], command['function'] ?? 'main');
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
    runtime.printOpcodes();
  } else if (command.name == 'bind') {
    if (command['help']!) {
      print('bind: Generate bindings for a Dart project');
      print('Usage:');
      print(
          '   dart_eval bind [-h, --help] [-a, --all] [-s, --single-file] [--[no-]plugin]');
      exit(0);
    }

    cliBind(
        singleFile: command['single-file'],
        all: command['all'],
        generatePlugin: command['plugin']);
  }
}
