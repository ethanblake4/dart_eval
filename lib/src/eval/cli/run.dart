import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';

void cliRun(String path, String library, String function) {
  final evc = File(path).readAsBytesSync();
  final runtime = Runtime(evc.buffer.asByteData());
  var result = runtime.executeLib(library, function);

  if (result != null) {
    if (result is $Value) {
      result = result.$reified;
    }
    print('\nProgram exited with result: $result');
  }
}
