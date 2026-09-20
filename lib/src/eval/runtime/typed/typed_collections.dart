import 'dart:collection';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'typed_instance.dart';
import 'typed_interop.dart';

/// Creates collection backing stores with Dart guest equality semantics.
abstract final class TypedCollections {
  static Map<Object?, Object?> newMap(Runtime? runtime) =>
      LinkedHashMap<Object?, Object?>(
        equals: (left, right) => _equals(runtime, left, right),
        hashCode: (value) => _hash(runtime, value),
        isValidKey: (_) => true,
      );

  static Set<Object?> newSet(Runtime? runtime) => LinkedHashSet<Object?>(
    equals: (left, right) => _equals(runtime, left, right),
    hashCode: (value) => _hash(runtime, value),
    isValidKey: (_) => true,
  );

  static bool _equals(Runtime? runtime, Object? left, Object? right) {
    if (identical(left, right)) return true;
    if (left == null || right == null) return false;
    if (_isScalar(left) && _isScalar(right)) {
      return (left as $Value).$value == (right as $Value).$value;
    }
    if (left is TypedInstance) {
      return TypedInterop.toBool(
        left.invoke('==', 1, right, null, runtime: left.runtime ?? runtime),
      );
    }
    if (left.runtimeType == $Object) {
      return (left as $Object).$value ==
          TypedInterop.exportExternal(right, runtime: runtime);
    }
    return left == right;
  }

  static int _hash(Runtime? runtime, Object? value) {
    if (value == null) return null.hashCode;
    if (_isScalar(value)) return (value as $Value).$value.hashCode;
    if (value is TypedInstance) {
      return TypedInterop.toInt(
        value.getProperty('hashCode', runtime: value.runtime ?? runtime),
      );
    }
    if (value.runtimeType == $Object) return (value as $Object).$value.hashCode;
    return value.hashCode;
  }

  static bool _isScalar(Object value) =>
      value is $int ||
      value is $double ||
      value is $bool ||
      value is $String ||
      value is $null;
}
