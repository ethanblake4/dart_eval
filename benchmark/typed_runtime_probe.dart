import 'dart:convert';
import 'dart:io';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed.dart';

// General AOT inspection entry point: bytecode and every argument bank come
// from files, and an optional existing Runtime keeps interop paths reachable.
// Usage: probe typed-program input.json [reference-runtime-program]
void main(List<String> args) {
  final program = TypedProgram.read(File(args[0]).readAsBytesSync().buffer);
  final input =
      jsonDecode(File(args[1]).readAsStringSync()) as Map<String, dynamic>;
  final ints = (input['ints'] as List).cast<int>();
  final doubles = (input['doubles'] as List)
      .map((x) => (x as num).toDouble())
      .toList();
  final bools = (input['bools'] as List).cast<bool>();
  print(
    TypedMachine.run(
      program,
      intArguments: ints,
      doubleArguments: doubles,
      boolArguments: bools,
      objectArguments: input['objects'] as List<Object?>? ?? const [],
      runtime: args.length > 2
          ? Runtime(File(args[2]).readAsBytesSync().buffer)
          : null,
    ),
  );
}
