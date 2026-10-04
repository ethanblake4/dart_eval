import 'dart:collection';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/src/eval/runtime/typed/typed_collections.dart';

export '../core/collection.dart' show iterableWhereType;

bool Function(Object?) _validKey(Runtime runtime, BridgeTypeSpec spec) {
  final owner = runtime.bridgeConstructorTypeId ?? runtime.lookupType(spec);
  final keyType = runtime.runtimeTypeArgumentAt(owner, 0);
  return (key) =>
      keyType == null ||
      runtime.isTypedValueType(
        TypedCollections.boxNativeKey(runtime, key),
        keyType,
      );
}

HashMap<Object?, Object?> nativeHashMap(
  Runtime runtime, {
  bool Function(Object?, Object?)? equals,
  int Function(Object?)? hashCode,
  bool Function(Object?)? isValidKey,
}) => HashMap<Object?, Object?>(
  equals:
      equals ??
      (left, right) => TypedCollections.nativeKeyEquals(runtime, left, right),
  hashCode:
      hashCode ?? (value) => TypedCollections.nativeKeyHash(runtime, value),
  isValidKey: isValidKey ?? _validKey(runtime, CollectionTypes.hashMap),
);

LinkedHashMap<Object?, Object?> nativeLinkedHashMap(
  Runtime runtime, {
  bool Function(Object?, Object?)? equals,
  int Function(Object?)? hashCode,
  bool Function(Object?)? isValidKey,
}) => LinkedHashMap<Object?, Object?>(
  equals:
      equals ??
      (left, right) => TypedCollections.nativeKeyEquals(runtime, left, right),
  hashCode:
      hashCode ?? (value) => TypedCollections.nativeKeyHash(runtime, value),
  isValidKey: isValidKey ?? _validKey(runtime, CollectionTypes.linkedHashMap),
);

HashSet<Object?> nativeHashSet(
  Runtime runtime, {
  bool Function(Object?, Object?)? equals,
  int Function(Object?)? hashCode,
  bool Function(Object?)? isValidKey,
}) => HashSet<Object?>(
  equals:
      equals ??
      (left, right) => TypedCollections.nativeKeyEquals(runtime, left, right),
  hashCode:
      hashCode ?? (value) => TypedCollections.nativeKeyHash(runtime, value),
  isValidKey: isValidKey ?? _validKey(runtime, CollectionTypes.hashSet),
);

LinkedHashSet<Object?> nativeLinkedHashSet(
  Runtime runtime, {
  bool Function(Object?, Object?)? equals,
  int Function(Object?)? hashCode,
  bool Function(Object?)? isValidKey,
}) => LinkedHashSet<Object?>(
  equals:
      equals ??
      (left, right) => TypedCollections.nativeKeyEquals(runtime, left, right),
  hashCode:
      hashCode ?? (value) => TypedCollections.nativeKeyHash(runtime, value),
  isValidKey: isValidKey ?? _validKey(runtime, CollectionTypes.linkedHashSet),
);
