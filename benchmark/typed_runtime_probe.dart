import 'dart:convert';
import 'dart:io';
import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

// General AOT inspection entry point: bytecode and every argument bank come
// from files, and an optional existing Runtime keeps interop paths reachable.
// Usage: probe typed-program input.json [runtime-program [bridge-library bridge-name]]
// The optional bridge keeps direct register callbacks reachable in AOT too.
void main(List<String> args) {
  final program = TypedProgram.read(File(args[0]).readAsBytesSync().buffer);
  final input =
      jsonDecode(File(args[1]).readAsStringSync()) as Map<String, dynamic>;
  final ints = (input['ints'] as List).cast<int>();
  final doubles = (input['doubles'] as List)
      .map((x) => (x as num).toDouble())
      .toList();
  final bools = (input['bools'] as List).cast<bool>();
  final runtime = args.length > 2
      ? Runtime(File(args[2]).readAsBytesSync().buffer)
      : null;
  if (runtime != null && args.length > 4) {
    runtime.registerBridgeFuncRegisters(
      args[3],
      args[4],
      args.length > 5 ? _add : _identity,
    );
  }
  print(
    TypedMachine.run(
      program,
      intArguments: ints,
      doubleArguments: doubles,
      boolArguments: bools,
      objectArguments: input['objects'] as List<Object?>? ?? const [],
      runtime: runtime,
    ),
  );
}

$Value? _identity(Runtime runtime, Object? r, Object? s, Object? c) =>
    r as $Value?;
$Value? _add(Runtime runtime, Object? r, Object? s, Object? c) =>
    $int((r as $int).$value + (s as $int).$value);
