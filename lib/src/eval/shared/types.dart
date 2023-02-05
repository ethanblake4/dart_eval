import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Bridged runtime type IDs for core Dart types.
class RuntimeTypes {
  /// Bridged runtime type for [void]
  static const int voidType = -1;

  /// Bridged runtime type for [dynamic]
  static const int dynamicType = -2;

  /// Bridged runtime type for [null]
  static const int nullType = -3;

  /// Bridged runtime type for [Object]
  static const int objectType = -4;

  /// Bridged runtime type for [bool]
  static const int boolType = -5;

  /// Bridged runtime type for [num]
  static const int numType = -6;

  /// Bridged runtime type for [String]
  static const int stringType = -7;

  /// Bridged runtime type for [int]
  static const int intType = -8;

  /// Bridged runtime type for [double]
  static const int doubleType = -9;

  /// Bridged runtime type for [Map]
  static const int mapType = -10;

  /// Bridged runtime type for [Function]
  static const int functionType = -12;

  /// Bridged runtime type for [Type]
  static const int typeType = -13;

  /// Bridged runtime type for [Future]
  static const int futureType = -16;

  /// Bridged runtime type for [Duration]
  static const int durationType = -17;

  /// Bridged runtime type for [Enum]
  static const int enumType = -18;
}

/// A map of dart_eval compile-time types to runtime type IDs
final Map<TypeRef, int> runtimeTypeMap = {
  EvalTypes.voidType: RuntimeTypes.voidType,
  EvalTypes.dynamicType: RuntimeTypes.dynamicType,
  EvalTypes.nullType: RuntimeTypes.nullType,
  EvalTypes.objectType: RuntimeTypes.objectType,
  EvalTypes.boolType: RuntimeTypes.boolType,
  EvalTypes.numType: RuntimeTypes.numType,
  EvalTypes.stringType: RuntimeTypes.stringType,
  EvalTypes.intType: RuntimeTypes.intType,
  EvalTypes.doubleType: RuntimeTypes.doubleType,
  EvalTypes.mapType: RuntimeTypes.mapType,
  EvalTypes.functionType: RuntimeTypes.functionType,
  EvalTypes.typeType: RuntimeTypes.typeType,
  EvalTypes.enumType: RuntimeTypes.enumType
};

/// A map of runtime type IDs to dart_eval compile-time types
final Map<int, TypeRef> inverseRuntimeTypeMap = {
  RuntimeTypes.voidType: EvalTypes.voidType,
  RuntimeTypes.dynamicType: EvalTypes.dynamicType,
  RuntimeTypes.nullType: EvalTypes.nullType,
  RuntimeTypes.objectType: EvalTypes.objectType,
  RuntimeTypes.boolType: EvalTypes.boolType,
  RuntimeTypes.numType: EvalTypes.numType,
  RuntimeTypes.stringType: EvalTypes.stringType,
  RuntimeTypes.intType: EvalTypes.intType,
  RuntimeTypes.doubleType: EvalTypes.doubleType,
  RuntimeTypes.mapType: EvalTypes.mapType,
  RuntimeTypes.functionType: EvalTypes.functionType,
  RuntimeTypes.typeType: EvalTypes.typeType
};

class DartTypes {
  static const list = BridgeTypeSpec('dart:core', 'List');
  static const iterator = BridgeTypeSpec('dart:core', 'Iterator');
  static const iterable = BridgeTypeSpec('dart:core', 'Iterable');
}
