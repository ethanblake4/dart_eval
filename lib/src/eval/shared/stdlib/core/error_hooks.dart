import 'package:dart_eval/dart_eval_bridge.dart';

import 'errors.dart';

$Value? assertionError(Runtime runtime, $Value? _, List<$Value?> args) {
  final value = args.isEmpty ? null : args.first;
  Object? message;
  if (value != null) {
    try {
      message = value.$reified;
    } catch (_) {
      // Guest instances can provide a message without a host representation.
      message = value.toString();
    }
  }
  return $AssertionError.wrap(AssertionError(message));
}
