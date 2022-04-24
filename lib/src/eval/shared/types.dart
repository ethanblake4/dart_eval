import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

class RuntimeTypes {
  static const int voidType = -1;
  static const int dynamicType = -2;
  static const int nullType = -3;
  static const int objectType = -4;
  static const int boolType = -5;
  static const int numType = -6;
  static const int stringType = -7;
  static const int intType = -8;
  static const int doubleType = -9;
  static const int mapType = -10;
  static const int listType = -11;
  static const int functionType = -12;
  static const int typeType = -13;
  static const int iteratorType = -14;
  static const int iterableType = -15;
  static const int futureType = -16;
  static const int durationType = -17;
}

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
  EvalTypes.listType: RuntimeTypes.listType,
  EvalTypes.functionType: RuntimeTypes.functionType,
  EvalTypes.typeType: RuntimeTypes.typeType
};

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
  RuntimeTypes.listType: EvalTypes.listType,
  RuntimeTypes.functionType: EvalTypes.functionType,
  RuntimeTypes.typeType: EvalTypes.typeType
};
