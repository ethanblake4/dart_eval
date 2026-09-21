import 'dart:collection';
import 'dart:math';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show Runtime, TypedRuntimeInterop;
import 'package:dart_eval/stdlib/core.dart';

part 'iterable.dart';
part 'list.dart';
part 'map.dart';
part 'set.dart';

/// Renders an eval collection like [IterableBase.iterableToFullString],
/// using [Runtime.valueToString] so eval objects dispatch to their own
/// `toString` and unboxed values stay wrapped.
$String collectionToString(
  Runtime runtime,
  Iterable<Object?> elements,
  String open,
  String close,
) {
  final buf = StringBuffer(open);
  var first = true;
  for (final e in elements) {
    if (!first) buf.write(', ');
    first = false;
    buf.write(runtime.valueToString(e as $Value?));
  }
  buf.write(close);
  return $String(buf.toString());
}

/// Renders an eval map like [MapBase.mapToString].
$String mapToString(Runtime runtime, Map<Object?, Object?> map) {
  final buf = StringBuffer('{');
  var first = true;
  map.forEach((k, v) {
    if (!first) buf.write(', ');
    first = false;
    buf
      ..write(runtime.valueToString(k as $Value?))
      ..write(': ')
      ..write(runtime.valueToString(v as $Value?));
  });
  buf.write('}');
  return $String(buf.toString());
}
