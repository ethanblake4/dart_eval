import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

const int dartCoreFile = -1;

class BuiltinValue {
  BuiltinValue({this.intval, this.doubleval, this.stringval}) {
    if (intval != null) {
      type = BuiltinValueType.intType;
    } else if (stringval != null) {
      type = BuiltinValueType.stringType;
    } else if (doubleval != null) {
      type = BuiltinValueType.doubleType;
    } else {
      type = BuiltinValueType.nullType;
    }
  }

  late BuiltinValueType type;
  final int? intval;
  final double? doubleval;
  final String? stringval;

  Variable _push(CompilerContext ctx) {
    if (type == BuiltinValueType.intType) {
      ctx.pushOp(PushConstantInt.make(intval!), PushConstantInt.LEN);
      return Variable.alloc(ctx, EvalTypes.intType, boxed: false);
    } else if (type == BuiltinValueType.stringType) {
      final op = PushConstantString.make(stringval!);
      ctx.pushOp(op, PushConstantString.len(op));
      return Variable.alloc(ctx, EvalTypes.stringType, boxed: false);
    } else if (type == BuiltinValueType.nullType) {
      final op = PushNull.make();
      ctx.pushOp(op, PushNull.LEN);
      return Variable.alloc(ctx, EvalTypes.nullType, boxed: false);
    } else {
      throw CompileError('Cannot push unknown builtin value type $type');
    }
  }

  Variable push(CompilerContext ctx) {
    final V = _push(ctx);
    if (ctx.inNonlinearAccessContext.last) {
      return V.unboxIfNeeded(ctx);
    }
    return V;
  }
}

enum BuiltinValueType { intType, stringType, doubleType, nullType }

class KnownMethod {
  const KnownMethod(this.returnType, this.args, this.namedArgs);

  final ReturnType? returnType;
  final List<KnownMethodArg> args;
  final Map<String, KnownMethodArg> namedArgs;
}

class KnownMethodArg {
  const KnownMethodArg(this.name, this.type, this.optional, this.nullable);

  final String name;
  final TypeRef? type;
  final bool optional;
  final bool nullable;
}

class EvalTypes {
  static const TypeRef voidType = TypeRef(dartCoreFile, 'void');
  static const TypeRef dynamicType = TypeRef(dartCoreFile, 'dynamic');
  static const TypeRef nullType = TypeRef(dartCoreFile, 'Null', extendsType: dynamicType);
  static const TypeRef objectType = TypeRef(dartCoreFile, 'Object', extendsType: dynamicType);
  static const TypeRef boolType = TypeRef(dartCoreFile, 'bool', extendsType: objectType);
  static const TypeRef numType = TypeRef(dartCoreFile, 'num', extendsType: objectType);
  static const TypeRef intType = TypeRef(dartCoreFile, 'int', extendsType: numType);
  static const TypeRef doubleType = TypeRef(dartCoreFile, 'double', extendsType: numType);
  static const TypeRef stringType = TypeRef(dartCoreFile, 'String', extendsType: objectType);
  static const TypeRef mapType = TypeRef(dartCoreFile, 'Map', extendsType: objectType);
  static const TypeRef listType = TypeRef(dartCoreFile, 'List', extendsType: objectType);
  static const TypeRef functionType = TypeRef(dartCoreFile, 'Function', extendsType: objectType);
}

final Map<String, TypeRef> coreDeclarations = {
  'dynamic': EvalTypes.dynamicType,
  'Null': EvalTypes.nullType,
  'Object': EvalTypes.objectType,
  'bool': EvalTypes.boolType,
  'num': EvalTypes.numType,
  'String': EvalTypes.stringType,
  'int': EvalTypes.intType,
  'double': EvalTypes.doubleType,
  'Map': EvalTypes.mapType,
  'List': EvalTypes.listType,
  'Function': EvalTypes.functionType
};

final intBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      EvalTypes.doubleType: AlwaysReturnType(EvalTypes.doubleType, false),
      EvalTypes.intType: AlwaysReturnType(EvalTypes.intType, false),
      EvalTypes.numType: AlwaysReturnType(EvalTypes.numType, false)
    }, paramIndex: 0, fallback: AlwaysReturnType(EvalTypes.numType, false)),
    [KnownMethodArg('other', EvalTypes.numType, false, false)],
    {});

final numComparisonOp =
    KnownMethod(AlwaysReturnType(EvalTypes.boolType, false), [KnownMethodArg('other', EvalTypes.numType, false, false)], {});

final doubleBinaryOp =
    KnownMethod(AlwaysReturnType(EvalTypes.doubleType, false), [KnownMethodArg('other', EvalTypes.numType, false, false)], {});

final numBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      EvalTypes.doubleType: AlwaysReturnType(EvalTypes.doubleType, false),
    }, paramIndex: 0, fallback: AlwaysReturnType(EvalTypes.numType, false)),
    [KnownMethodArg('other', EvalTypes.numType, false, false)],
    {});

final Map<TypeRef, Map<String, KnownMethod>> knownMethods = {
  EvalTypes.intType: {
    '+': intBinaryOp,
    '-': intBinaryOp,
    '/': intBinaryOp,
    '%': intBinaryOp,
    '<': numComparisonOp,
    '>': numComparisonOp,
  },
  EvalTypes.doubleType: {
    '+': doubleBinaryOp,
    '-': doubleBinaryOp,
    '/': doubleBinaryOp,
    '%': doubleBinaryOp,
    '<': numComparisonOp,
    '>': numComparisonOp,
  },
  EvalTypes.numType: {
    '+': numBinaryOp,
    '-': numBinaryOp,
    '/': numBinaryOp,
    '%': numBinaryOp,
    '<': numComparisonOp,
    '>': numComparisonOp,
  }
};

final Set<TypeRef> unboxedAcrossFunctionBoundaries = {EvalTypes.intType, EvalTypes.doubleType, EvalTypes.boolType};
