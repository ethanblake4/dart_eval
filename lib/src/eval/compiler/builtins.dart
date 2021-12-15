import 'package:dart_eval/dart_eval.dart';
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

  Variable push(CompilerContext ctx) {
    if (type == BuiltinValueType.intType) {
      ctx.pushOp(PushConstantInt.make(intval!), PushConstantInt.LEN);
      return Variable.alloc(ctx, intType, boxed: false);
    } else if (type == BuiltinValueType.stringType) {
      final op = PushConstantString.make(stringval!);
      ctx.pushOp(op, PushConstantString.len(op));
      return Variable.alloc(ctx, stringType, boxed: false);
    } else if (type == BuiltinValueType.nullType) {
      final op = PushNull.make();
      ctx.pushOp(op, PushNull.LEN);
      return Variable.alloc(ctx, nullType, boxed: false);
    } else {
      throw CompileError('Cannot push unknown builtin value type $type');
    }
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

const TypeRef dynamicType = TypeRef(dartCoreFile, 'dynamic');
const TypeRef nullType = TypeRef(dartCoreFile, 'Null', extendsType: dynamicType);
const TypeRef objectType = TypeRef(dartCoreFile, 'Object', extendsType: dynamicType);
const TypeRef numType = TypeRef(dartCoreFile, 'num', extendsType: objectType);
final TypeRef intType = TypeRef(dartCoreFile, 'int', extendsType: numType);
final TypeRef doubleType = TypeRef(dartCoreFile, 'double', extendsType: numType);
const TypeRef stringType = TypeRef(dartCoreFile, 'String', extendsType: objectType);
const TypeRef mapType = TypeRef(dartCoreFile, 'Map', extendsType: objectType);
const TypeRef listType = TypeRef(dartCoreFile, 'List', extendsType: objectType);
const TypeRef functionType = TypeRef(dartCoreFile, 'Function', extendsType: objectType);

final Map<String, TypeRef> coreDeclarations = {
  'dynamic': dynamicType,
  'Null': nullType,
  'Object': objectType,
  'num': numType,
  'String': stringType,
  'int': intType,
  'double': doubleType,
  'Map': mapType,
  'List': listType,
  'Function': functionType
};

final intBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      doubleType: AlwaysReturnType(doubleType, false),
      intType: AlwaysReturnType(intType, false),
      numType: AlwaysReturnType(numType, false)
    }, paramIndex: 0, fallback: AlwaysReturnType(numType, false)),
    [KnownMethodArg('other', numType, false, false)],
    {});

final doubleBinaryOp =
KnownMethod(AlwaysReturnType(doubleType, false), [KnownMethodArg('other', numType, false, false)], {});

final numBinaryOp = KnownMethod(
    ParameterTypeDependentReturnType({
      doubleType: AlwaysReturnType(doubleType, false),
    }, paramIndex: 0, fallback: AlwaysReturnType(numType, false)),
    [KnownMethodArg('other', numType, false, false)],
    {});

final Map<TypeRef, Map<String, KnownMethod>> knownMethods = {
  intType: {
    '+': intBinaryOp,
    '-': intBinaryOp,
    '/': intBinaryOp,
    '%': intBinaryOp,
  },
  doubleType: {
    '+': doubleBinaryOp,
    '-': doubleBinaryOp,
    '/': doubleBinaryOp,
    '%': doubleBinaryOp,
  },
  numType: {
    '+': numBinaryOp,
    '-': numBinaryOp,
    '/': numBinaryOp,
    '%': numBinaryOp,
  }
};

final Set<TypeRef> unboxedAcrossFunctionBoundaries = {intType, doubleType};