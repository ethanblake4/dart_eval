import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';

import 'expando.dart';

Object _expandoKey($Value key) =>
    key is TypedInstance ? key.dispatchRoot : key.$reified as Object;

$Value? expandoGet(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) {
  final expando = (target! as $Expando).$value;
  return runtime.wrapAlways(expando[_expandoKey(r! as $Value)]);
}

$Value? expandoSet(
  Runtime runtime,
  $Value? target,
  Object? r,
  Object? s,
  Object? c,
) {
  final expando = (target! as $Expando).$value;
  final value = s! as $Value;
  expando[_expandoKey(r! as $Value)] = value is TypedInstance
      ? value.dispatchRoot
      : value.$reified;
  return null;
}
