import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

const int dartCoreFile = -1;

class BuiltinValue {
  BuiltinValue({this.intval, this.doubleval, this.stringval, this.boolval}) {
    if (intval != null) {
      type = BuiltinValueType.intType;
    } else if (stringval != null) {
      type = BuiltinValueType.stringType;
    } else if (doubleval != null) {
      type = BuiltinValueType.doubleType;
    } else if (boolval != null) {
      type = BuiltinValueType.boolType;
    } else {
      type = BuiltinValueType.nullType;
    }
  }

  late BuiltinValueType type;
  final int? intval;
  final double? doubleval;
  final String? stringval;
  final bool? boolval;

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
    } else if (type == BuiltinValueType.boolType) {
      ctx.pushOp(PushTrue.make(), PushTrue.LEN);
      var value =
          Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
      if (!boolval!) {
        ctx.pushOp(LogicalNot.make(value.scopeFrameOffset), LogicalNot.LEN);
        value = Variable.alloc(ctx, EvalTypes.boolType.copyWith(boxed: false));
      }
      return value;
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

enum BuiltinValueType { intType, stringType, doubleType, boolType, nullType }

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
  const KnownMethodArg(this.name, this.type, this.optional);

  final String name;
  final TypeRef? type;
  final bool optional;
}

class EvalTypes {
  static const TypeRef typeType = TypeRef(dartCoreFile, 'Type', resolved: true);
  static const TypeRef voidType = TypeRef(dartCoreFile, 'void', resolved: true);
  static const TypeRef dynamicType =
      TypeRef(dartCoreFile, 'dynamic', resolved: true);
  static const TypeRef neverType =
      TypeRef(dartCoreFile, 'Never', extendsType: dynamicType, resolved: true);
  static const TypeRef nullType =
      TypeRef(dartCoreFile, 'Null', extendsType: dynamicType, resolved: true);
  static const TypeRef objectType =
      TypeRef(dartCoreFile, 'Object', extendsType: dynamicType, resolved: true);
  static const TypeRef enumType =
      TypeRef(dartCoreFile, 'Enum', extendsType: objectType, resolved: true);
  static const TypeRef boolType =
      TypeRef(dartCoreFile, 'bool', extendsType: objectType, resolved: true);
  static const TypeRef numType =
      TypeRef(dartCoreFile, 'num', extendsType: objectType, resolved: true);
  static const TypeRef intType =
      TypeRef(dartCoreFile, 'int', extendsType: numType, resolved: true);
  static const TypeRef doubleType =
      TypeRef(dartCoreFile, 'double', extendsType: numType, resolved: true);
  static const TypeRef stringType =
      TypeRef(dartCoreFile, 'String', extendsType: objectType, resolved: true);
  static const TypeRef mapType =
      TypeRef(dartCoreFile, 'Map', extendsType: objectType, resolved: true);
  static const TypeRef functionType = TypeRef(dartCoreFile, 'Function',
      extendsType: objectType, resolved: true);

  static TypeRef getListType(CompilerContext ctx) =>
      TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.list));

  static TypeRef getIterableType(CompilerContext ctx) =>
      TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.iterable));

  static TypeRef getIteratorType(CompilerContext ctx) =>
      TypeRef.fromBridgeTypeRef(ctx, BridgeTypeRef(CoreTypes.iterator));
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
  'Function': EvalTypes.functionType
};

final intBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      EvalTypes.doubleType: AlwaysReturnType(EvalTypes.doubleType, false),
      EvalTypes.intType: AlwaysReturnType(EvalTypes.intType, false),
      EvalTypes.numType: AlwaysReturnType(EvalTypes.numType, false)
    }, paramIndex: 0, fallback: AlwaysReturnType(EvalTypes.numType, false)),
    [KnownMethodArg('other', EvalTypes.numType, false)],
    {});

const numComparisonOp = KnownMethod(AlwaysReturnType(EvalTypes.boolType, false),
    [KnownMethodArg('other', EvalTypes.numType, false)], {});

const doubleBinaryOp = KnownMethod(
    AlwaysReturnType(EvalTypes.doubleType, false),
    [KnownMethodArg('other', EvalTypes.numType, false)],
    {});

final numBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      EvalTypes.doubleType: AlwaysReturnType(EvalTypes.doubleType, false),
    }, paramIndex: 0, fallback: AlwaysReturnType(EvalTypes.numType, false)),
    [KnownMethodArg('other', EvalTypes.numType, false)],
    {});

final boolBinaryOp = KnownMethod(AlwaysReturnType(EvalTypes.boolType, false),
    [KnownMethodArg('other', EvalTypes.boolType, false)], {});

const listIndexOp = KnownMethod(TargetTypeArgDependentReturnType(0),
    [KnownMethodArg('index', EvalTypes.intType, false)], {});

const listIndexAssignOp = KnownMethod(TargetTypeArgDependentReturnType(0),
    [KnownMethodArg('index', EvalTypes.intType, false)], {});

const toStringOp =
    KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {});

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
    '!=': numComparisonOp,
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
    '!=': numComparisonOp,
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
    '!=': numComparisonOp,
    ..._knownObject
  },
  EvalTypes.boolType: {
    '&&': boolBinaryOp,
    '||': boolBinaryOp,
    '==': boolBinaryOp,
    '!=': boolBinaryOp
  },
  EvalTypes.stringType: {
    '+': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false)], {}),
    '==': KnownMethod(AlwaysReturnType(EvalTypes.boolType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false)], {}),
    '!=': KnownMethod(AlwaysReturnType(EvalTypes.boolType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false)], {}),
    'codeUnitAt': KnownMethod(AlwaysReturnType(EvalTypes.intType, false),
        [KnownMethodArg('index', EvalTypes.intType, false)], {}),
    'compareTo': KnownMethod(AlwaysReturnType(EvalTypes.intType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false)], {}),
    'contains': KnownMethod(AlwaysReturnType(EvalTypes.intType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false)], {}),
    'endsWith': KnownMethod(AlwaysReturnType(EvalTypes.boolType, false),
        [KnownMethodArg('other', EvalTypes.stringType, false)], {}),
    //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
    'indexOf': KnownMethod(AlwaysReturnType(EvalTypes.intType, false), [
      KnownMethodArg('pattern', EvalTypes.stringType, false),
      KnownMethodArg('start', EvalTypes.intType, true),
    ], {}),
    //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
    'lastIndexOf': KnownMethod(AlwaysReturnType(EvalTypes.intType, false), [
      KnownMethodArg('pattern', EvalTypes.stringType, false),
      KnownMethodArg('start', EvalTypes.intType, true),
    ], {}),
    'padLeft': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('width', EvalTypes.intType, false),
      KnownMethodArg('padding', EvalTypes.stringType, true),
    ], {}),
    'padRight': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('width', EvalTypes.intType, false),
      KnownMethodArg('padding', EvalTypes.stringType, true),
    ], {}),
    //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
    'replaceAll': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('pattern', EvalTypes.stringType, false),
      KnownMethodArg('replace', EvalTypes.stringType, false),
    ], {}),
    //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
    'replaceFirst': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('from', EvalTypes.stringType, false),
      KnownMethodArg('to', EvalTypes.stringType, false),
      KnownMethodArg('startIndex', EvalTypes.intType, true),
    ], {}),
    'replaceRange': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('start', EvalTypes.intType, false),
      KnownMethodArg('end', EvalTypes.intType.copyWith(nullable: true), false),
      KnownMethodArg('replacement', EvalTypes.stringType, false),
    ], {}),
    //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
    'split': KnownMethod(
        BridgedReturnType(BridgeTypeSpec('dart:core', 'List'), false), [
      KnownMethodArg('pattern', EvalTypes.stringType, false),
    ], {}),
    //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
    'startsWith': KnownMethod(AlwaysReturnType(EvalTypes.boolType, false), [
      KnownMethodArg('pattern', EvalTypes.stringType, false),
      KnownMethodArg('index', EvalTypes.intType, true),
    ], {}),
    'substring': KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [
      KnownMethodArg('start', EvalTypes.intType, false),
      KnownMethodArg('end', EvalTypes.intType.copyWith(nullable: true), true)
    ], {}),
    'toLowerCase':
        KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {}),
    'toUpperCase':
        KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {}),
    'trimLeft':
        KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {}),
    'trimRight':
        KnownMethod(AlwaysReturnType(EvalTypes.stringType, false), [], {}),
    ..._knownObject
  },
};

final Map<TypeRef, Map<String, KnownField>> knownFields = {
  EvalTypes.stringType: {
    'length':
        KnownField(AlwaysReturnType(EvalTypes.intType, false), true, false),
    'isEmpty':
        KnownField(AlwaysReturnType(EvalTypes.boolType, false), true, false),
    'isNotEmpty':
        KnownField(AlwaysReturnType(EvalTypes.boolType, false), true, false)
  }
};

late Set<TypeRef> unboxedAcrossFunctionBoundaries;
