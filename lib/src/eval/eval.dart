import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

/// Evaluate the Dart [source] code. If the source is a raw expression such as "2 + 2" it will be evaluated directly
/// and the result will be returned; otherwise, the function [function] will be called with arguments specified
/// by [args]. You can use the [compilerSettings] and [runtimeSettings] callbacks to configure bridge classes.
dynamic eval(String source,
    {String function = 'main',
    List args = const [],
    Function(Compiler)? compilerSettings,
    Function(Runtime)? runtimeSettings}) {
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

  File('out.dbc').writeAsBytesSync(program.write());

  final runtime = Runtime.ofProgram(program);

  runtimeSettings?.call(runtime);

  runtime.printOpcodes();

  runtime.setup();
  runtime.args = args;
  final result = runtime.executeLib('package:default/main.dart', function);

  if (result is $Value) {
    return result.$reified;
  }
  return result;
}
