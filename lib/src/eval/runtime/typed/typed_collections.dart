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

  /// Backing stores for `const` collections. Const keys are evaluated
  /// objects: the VM refuses const keys that override `hashCode`, so lookups
  /// hash by identity and never dispatch to guest `hashCode`/`==`.
  static Map<Object?, Object?> newConstMap(Runtime? runtime) =>
      LinkedHashMap<Object?, Object?>(
        equals: (left, right) => _constKeyEquals(runtime, left, right),
        hashCode: _constKeyHash,
        isValidKey: (_) => true,
      );

  /// [newConstMap] for sets.
  static Set<Object?> newConstSet(Runtime? runtime) => LinkedHashSet<Object?>(
    equals: (left, right) => _constKeyEquals(runtime, left, right),
    hashCode: _constKeyHash,
    isValidKey: (_) => true,
  );

  /// Copies [m]'s entries into a canonical-key map ([newConstMap]).
  static Map<Object?, Object?> canonicalizeMap(
    Map<dynamic, dynamic> m,
    Runtime? runtime,
  ) => newConstMap(runtime)..addAll(m);

  /// [canonicalizeMap] for sets.
  static Set<Object?> canonicalizeSet(Set<dynamic> s, Runtime? runtime) =>
      newConstSet(runtime)..addAll(s);

  static bool _constKeyEquals(Runtime? runtime, Object? left, Object? right) {
    if (left is $null) left = null;
    if (right is $null) right = null;
    if (identical(left, right)) return true;
    if (left is TypedInstance ||
        right is TypedInstance ||
        left is EvalFunction ||
        right is EvalFunction) {
      return false;
    }
    if (left is $Value && right is $Value) {
      return (left.runtimeType == $Object && right.runtimeType == $Object) ||
          TypedInterop.equals(runtime, left, right);
    }
    return left == right;
  }

  static int _constKeyHash(Object? k) => switch (k) {
    null || $null() => null.hashCode,
    TypedInstance() || EvalFunction() => identityHashCode(k),
    $int p => p.$value.hashCode,
    $double p => p.$value.hashCode,
    $bool p => p.$value.hashCode,
    $String p => p.$value.hashCode,
    _ => k.hashCode,
  };

  static bool _equals(Runtime? runtime, Object? left, Object? right) {
    // `null` may arrive either as the host null or boxed as `$null`
    // depending on the value representation that produced it.
    if (left is $null) left = null;
    if (right is $null) right = null;
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
