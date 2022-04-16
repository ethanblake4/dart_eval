import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'bridge/declaration/class.dart';

dynamic eval(String source,
    {String function = 'main', Function(Compiler)? compilerSettings, Function(Runtime)? runtimeSettings}) {
  final compiler = Compiler();
  compilerSettings?.call(compiler);

  var _source = source;

  if (!RegExp(r'(?:\w* )?' + function + r'\s?\([\s\S]*?\)\s?{').hasMatch(_source)) {
    if (!_source.contains(';')) {
      _source = '$_source;';
      if (!_source.contains('return')) {
        _source = 'return $_source';
      }
    }
    _source = 'dynamic $function() {$_source}';
  }

  final program = compiler.compile({
    'default': {'main.dart': _source}
  });

  File('out.dbc')..writeAsBytesSync(program.write());

  final runtime = Runtime.ofProgram(program);

  runtimeSettings?.call(runtime);

  runtime.printOpcodes();

  runtime.setup();
  final result = runtime.executeNamed(0, function);

  if (result is $Value) {
    return result.$reified;
  }
  return result;
}
