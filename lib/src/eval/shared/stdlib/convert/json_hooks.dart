import 'dart:convert';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart';

// Only the SDK's JSON fallback crosses into guest method dispatch. The SDK
// still decides which values need conversion and validates the returned value.
Object? Function(Object?) _defaultToEncodable(Runtime runtime) => (object) {
  if (object is TypedInstance) {
    return TypedInterop.exportExternal(
      object.invoke('toJson', 0, null, null, runtime: runtime),
      runtime: runtime,
    );
  }
  return (object as dynamic).toJson();
};

JsonEncoder nativeJsonEncoder(
  Runtime runtime, [
  Object? Function(Object?)? toEncodable,
]) => JsonEncoder(toEncodable ?? _defaultToEncodable(runtime));

JsonEncoder nativeIndentedJsonEncoder(
  Runtime runtime,
  String indent, [
  Object? Function(Object?)? toEncodable,
]) =>
    JsonEncoder.withIndent(indent, toEncodable ?? _defaultToEncodable(runtime));

JsonUtf8Encoder nativeJsonUtf8Encoder(
  Runtime runtime, [
  String? indent,
  Object? Function(Object?)? toEncodable,
  int? bufferSize,
]) => JsonUtf8Encoder(
  indent,
  toEncodable ?? _defaultToEncodable(runtime),
  bufferSize,
);

JsonCodec nativeJsonCodec(
  Runtime runtime, {
  Object? Function(Object?, Object?)? reviver,
  Object? Function(Object?)? toEncodable,
}) => JsonCodec(
  reviver: reviver,
  toEncodable: toEncodable ?? _defaultToEncodable(runtime),
);

JsonCodec nativeJsonCodecWithReviver(
  Runtime runtime,
  Object? Function(Object?, Object?) reviver,
) => nativeJsonCodec(runtime, reviver: reviver);

$Value? guestJsonEncode(
  Runtime runtime,
  $Value? target,
  List<$Value?> args,
) {
  final callback = args[1];
  final toEncodable = callback == null || callback is $null
      ? _defaultToEncodable(runtime)
      : (Object? object) => TypedInterop.exportExternal(
          (callback as EvalCallable).call(
            runtime,
            null,
            TypedInterop.boxExternal(object, runtime: runtime),
            null,
            1,
          ),
          runtime: runtime,
        );
  return $String(
    jsonEncode(
      TypedInterop.exportExternal(args[0], runtime: runtime),
      toEncodable: toEncodable,
    ),
  );
}
