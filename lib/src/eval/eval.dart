import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';

/// Evaluate the Dart [source] code. If the source is a raw expression such as
/// "2 + 2" it will be evaluated directly and the result will be returned;
/// otherwise, the function [function] will be called with arguments specified
/// by [args]. You can use [plugins] to configure bridge classes and
/// [permissions] to grant permissions to the runtime.
/// You can also specify [outputFile] to write the generated EVC bytecode to a
/// file.
///
/// The eval() function automatically unboxes return values for convenience.
dynamic eval(String source,
    {String function = 'main',
    List args = const [],
    List<EvalPlugin> plugins = const [],
    List<Permission> permissions = const [],
    String? outputFile}) {
  final compiler = Compiler();
  for (final plugin in plugins) {
    plugin.configureForCompile(compiler);
  }

  var _source = source;

  if (!RegExp(r'(?:\w* )?' + function + r'\s?\([\s\S]*?\)\s?({|=>)')
      .hasMatch(_source)) {
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

  if (outputFile != null) {
    File(outputFile).writeAsBytesSync(program.write());
  }

  final runtime = Runtime.ofProgram(program);
  for (final plugin in plugins) {
    plugin.configureForRuntime(runtime);
  }

  for (final permission in permissions) {
    runtime.grant(permission);
  }

  runtime.setup();
  runtime.args = args;
  final result = runtime.executeLib('package:default/main.dart', function);

  if (result is $Value) {
    return result.$reified;
  }
  return result;
}
