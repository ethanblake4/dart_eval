import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

import 'stream_iterator.dart';

// Guest streams need the runtime adapter before entering the SDK iterator.
$Value? streamIterator(Runtime runtime, $Value? _, List<$Value?> args) =>
    $StreamIterator.wrap(
      StreamIterator(TypedInterop.stream(args.first, runtime)),
    );

$Value? streamControllerAdd(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) {
  (target!.$value as StreamController).add((r as $Value?)?.$value);
  return null;
}
