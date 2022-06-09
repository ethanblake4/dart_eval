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
      return Variable.alloc(ctx, EvalTypes.intType.copyWith(boxed: false));
    } else if (type == BuiltinValueType.doubleType) {
      ctx.pushOp(PushConstantDouble.make(doubleval!), PushConstantDouble.LEN);
      return Variable.alloc(ctx, EvalTypes.doubleType.copyWith(boxed: false));
    } else if (type == BuiltinValueType.stringType) {
      final op = PushConstant.make(ctx.constantPool.addOrGet(stringval!));
      ctx.pushOp(op, PushConstant.LEN);
      return Variable.alloc(ctx, EvalTypes.stringType.copyWith(boxed: false));
    } else if (type == BuiltinValueType.nullType) {
      final op = PushNull.make();
      ctx.pushOp(op, PushNull.LEN);
      return Variable.alloc(ctx, EvalTypes.nullType.copyWith(boxed: false));
    } else {
      throw CompileError('Cannot push unknown builtin value type $type');
    }
  }

  Variable push(CompilerContext ctx) {
    final V = _push(ctx);
    if (ctx.requireNonlinearAccess) {
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

class KnownField {
  const KnownField(this.fieldType, this.gets, this.sets);

  final ReturnType? fieldType;
  final bool gets;
  final bool sets;
}

class KnownMethodArg {
  const KnownMethodArg(this.name, this.type, this.optional, this.nullable);

  final String name;
  final TypeRef? type;
  final bool optional;
  final bool nullable;
}

class EvalTypes {
  static const TypeRef typeType = TypeRef(dartCoreFile, 'Type', resolved: true);
  static const TypeRef voidType = TypeRef(dartCoreFile, 'void', resolved: true);
  static const TypeRef dynamicType = TypeRef(dartCoreFile, 'dynamic', resolved: true);
  static const TypeRef nullType = TypeRef(dartCoreFile, 'Null', extendsType: dynamicType, resolved: true);
  static const TypeRef objectType = TypeRef(dartCoreFile, 'Object', extendsType: dynamicType, resolved: true);
  static const TypeRef boolType = TypeRef(dartCoreFile, 'bool', extendsType: objectType, resolved: true);
  static const TypeRef numType = TypeRef(dartCoreFile, 'num', extendsType: objectType, resolved: true);
  static const TypeRef intType = TypeRef(dartCoreFile, 'int', extendsType: numType, resolved: true);
  static const TypeRef doubleType = TypeRef(dartCoreFile, 'double', extendsType: numType, resolved: true);
  static const TypeRef stringType = TypeRef(dartCoreFile, 'String', extendsType: objectType, resolved: true);
  static const TypeRef mapType = TypeRef(dartCoreFile, 'Map', extendsType: objectType, resolved: true);
  static const TypeRef iterableType = TypeRef(dartCoreFile, 'Iterable',
      extendsType: objectType, genericParams: [GenericParam('T', null)], resolved: true);
  static const TypeRef listType = TypeRef(dartCoreFile, 'List',
      extendsType: iterableType, genericParams: [GenericParam('T', null)], resolved: true);
  static const TypeRef functionType = TypeRef(dartCoreFile, 'Function', extendsType: objectType, resolved: true);
}

final Map<String, TypeRef> coreDeclarations = {
  'void': EvalTypes.voidType,
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

const numComparisonOp = KnownMethod(
    AlwaysReturnType(EvalTypes.boolType, false), [KnownMethodArg('other', EvalTypes.numType, false, false)], {});

const doubleBinaryOp = KnownMethod(
    AlwaysReturnType(EvalTypes.doubleType, false), [KnownMethodArg('other', EvalTypes.numType, false, false)], {});

final numBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      EvalTypes.doubleType: AlwaysReturnType(EvalTypes.doubleType, false),
    }, paramIndex: 0, fallback: AlwaysReturnType(EvalTypes.numType, false)),
    [KnownMethodArg('other', EvalTypes.numType, false, false)],
    {});

const listIndexOp =
    KnownMethod(TargetTypeArgDependentReturnType(0), [KnownMethodArg('index', EvalTypes.intType, false, false)], {});

const listIndexAssignOp =
    KnownMethod(TargetTypeArgDependentReturnType(0), [KnownMethodArg('index', EvalTypes.intType, false, false)], {});

const toStringOp = KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {});

final _knownObject = <String, KnownMethod>{
  'toString': toStringOp,
};

final Map<TypeRef, Map<String, KnownMethod>> knownMethods = {
  EvalTypes.intType: {
    '+': intBinaryOp,
    '-': intBinaryOp,
    '*': intBinaryOp,
    '/': intBinaryOp,
    '%': intBinaryOp,
    '<': numComparisonOp,
    '>': numComparisonOp,
    '<=': numComparisonOp,
    '>=': numComparisonOp,
    '==': numComparisonOp,
    ..._knownObject
  },
  EvalTypes.doubleType: {
    '+': doubleBinaryOp,
    '-': doubleBinaryOp,
    '*': doubleBinaryOp,
    '/': doubleBinaryOp,
    '%': doubleBinaryOp,
    '<': numComparisonOp,
    '>': numComparisonOp,
    '<=': numComparisonOp,
    '>=': numComparisonOp,
    '==': numComparisonOp,
    ..._knownObject
  },
  EvalTypes.numType: {
    '+': numBinaryOp,
    '-': numBinaryOp,
    '*': numBinaryOp,
    '/': numBinaryOp,
    '%': numBinaryOp,
    '<': numComparisonOp,
    '>': numComparisonOp,
    '<=': numComparisonOp,
    '>=': numComparisonOp,
    '==': numComparisonOp,
    ..._knownObject
  },
  EvalTypes.stringType: {
    '+': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false, false)], {}),
    '==': KnownMethod(
        AlwaysReturnType(EvalTypes.boolType, false), [KnownMethodArg('other', EvalTypes.stringType, false, false)], {}),
    'toLowerCase': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {}),
    'toUpperCase': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {}),
    'substring': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('start', EvalTypes.intType, false, false),
      KnownMethodArg('end', EvalTypes.intType, true, true)
    ], {}),
    ..._knownObject
  },
  EvalTypes.iterableType: {
    'join': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false),
        [KnownMethodArg('separator', EvalTypes.stringType, true, false)], {}),
    ..._knownObject
  },
  EvalTypes.listType: {
    '[]': listIndexOp,
    '[]=': listIndexAssignOp,
    'join': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false),
        [KnownMethodArg('separator', EvalTypes.stringType, true, false)], {}),
    ..._knownObject
  }
};

final Map<TypeRef, Map<String, KnownField>> knownFields = {
  EvalTypes.iterableType: {
    'length': KnownField(AlwaysReturnType(EvalTypes.intType, false), true, false),
  },
  EvalTypes.listType: {'length': KnownField(AlwaysReturnType(EvalTypes.intType, false), true, false)},
  EvalTypes.stringType: {
    'length': KnownField(AlwaysReturnType(EvalTypes.intType, false), true, false),
    'isEmpty': KnownField(AlwaysReturnType(EvalTypes.boolType, false), true, false),
    'isNotEmpty': KnownField(AlwaysReturnType(EvalTypes.boolType, false), true, false)
  }
};

final Set<TypeRef> unboxedAcrossFunctionBoundaries = {
  EvalTypes.intType,
  EvalTypes.doubleType,
  EvalTypes.boolType,
  EvalTypes.listType
};
