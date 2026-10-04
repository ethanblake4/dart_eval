import 'dart:developer';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// Keep the callback's canonical guest result, including its Future ownership.
/// Exporting then wrapping an erased T would lose guest FutureOr semantics.
$Value? guestTimelineTimeSync(
  Runtime runtime,
  $Value? target,
  List<$Value?> args,
) {
  final arguments = args.length > 2 ? args[2]?.$reified as Map? : null;
  final flow = args.length > 3 ? args[3]?.$value as Flow? : null;
  return Timeline.timeSync<$Value?>(
    (args[0] as $String).$value,
    () => (args[1] as EvalCallable).call(runtime, null, null, null, 0),
    arguments: arguments,
    flow: flow,
  );
}
