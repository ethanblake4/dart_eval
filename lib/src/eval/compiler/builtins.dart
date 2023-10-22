import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

var dartCoreFile = -1;

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
      final type = CoreTypes.int.ref(ctx).copyWith(boxed: false);
      return Variable.alloc(ctx, type, concreteTypes: [type]);
    } else if (type == BuiltinValueType.doubleType) {
      ctx.pushOp(PushConstantDouble.make(doubleval!), PushConstantDouble.LEN);
      final type = CoreTypes.double.ref(ctx).copyWith(boxed: false);
      return Variable.alloc(
        ctx,
        type,
        concreteTypes: [type],
      );
    } else if (type == BuiltinValueType.stringType) {
      final op = PushConstant.make(ctx.constantPool.addOrGet(stringval!));
      ctx.pushOp(op, PushConstant.LEN);
      final type = CoreTypes.string.ref(ctx).copyWith(boxed: false);
      return Variable.alloc(ctx, type, concreteTypes: [type]);
    } else if (type == BuiltinValueType.boolType) {
      ctx.pushOp(PushTrue.make(), PushTrue.LEN);
      final type = CoreTypes.bool.ref(ctx).copyWith(boxed: false);
      var value = Variable.alloc(ctx, type, concreteTypes: [type]);
      if (!boolval!) {
        ctx.pushOp(LogicalNot.make(value.scopeFrameOffset), LogicalNot.LEN);
        value = Variable.alloc(ctx, type, concreteTypes: [type]);
      }
      return value;
    } else if (type == BuiltinValueType.nullType) {
      final op = PushNull.make();
      ctx.pushOp(op, PushNull.LEN);
      final type = CoreTypes.nullType.ref(ctx).copyWith(boxed: false);
      return Variable.alloc(ctx, type, concreteTypes: [type]);
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

Map<TypeRef, Map<String, KnownMethod>>? _knownMethods;

Map<TypeRef, Map<String, KnownMethod>> getKnownMethods(ctx) {
  if (_knownMethods != null) {
    return _knownMethods!;
  }

  final boolBinaryOp = KnownMethod(
      AlwaysReturnType(CoreTypes.bool.ref(ctx), false),
      [KnownMethodArg('other', CoreTypes.bool.ref(ctx), false)],
      {});

  final objectComparisonOp = KnownMethod(
      AlwaysReturnType(CoreTypes.bool.ref(ctx), false),
      [KnownMethodArg('other', CoreTypes.object.ref(ctx), false)],
      {});

  final toStringOp =
      KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [], {});

  final _knownObject = <String, KnownMethod>{
    '==': objectComparisonOp,
    'toString': toStringOp,
  };

  final intBinaryOp = KnownMethod(
      ParameterTypeDependentReturnType({
        CoreTypes.double.ref(ctx):
            AlwaysReturnType(CoreTypes.double.ref(ctx), false),
        CoreTypes.int.ref(ctx): AlwaysReturnType(CoreTypes.int.ref(ctx), false),
        CoreTypes.num.ref(ctx): AlwaysReturnType(CoreTypes.num.ref(ctx), false)
      },
          paramIndex: 0,
          fallback: AlwaysReturnType(CoreTypes.num.ref(ctx), false)),
      [KnownMethodArg('other', CoreTypes.num.ref(ctx), false)],
      {});

  final intBitwiseOp = KnownMethod(
      AlwaysReturnType(CoreTypes.int.ref(ctx), false),
      [KnownMethodArg('other', CoreTypes.int.ref(ctx), false)],
      {});

  final numComparisonOp = KnownMethod(
      AlwaysReturnType(CoreTypes.bool.ref(ctx), false),
      [KnownMethodArg('other', CoreTypes.num.ref(ctx), false)],
      {});

  final numCompareToOp = KnownMethod(
      AlwaysReturnType(CoreTypes.int.ref(ctx), false),
      [KnownMethodArg('other', CoreTypes.num.ref(ctx), false)],
      {});

  final doubleBinaryOp = KnownMethod(
      AlwaysReturnType(CoreTypes.double.ref(ctx), false),
      [KnownMethodArg('other', CoreTypes.num.ref(ctx), false)],
      {});

  final numBinaryOp = KnownMethod(
      ParameterTypeDependentReturnType({
        CoreTypes.double.ref(ctx):
            AlwaysReturnType(CoreTypes.double.ref(ctx), false),
      },
          paramIndex: 0,
          fallback: AlwaysReturnType(CoreTypes.num.ref(ctx), false)),
      [KnownMethodArg('other', CoreTypes.num.ref(ctx), false)],
      {});

  return _knownMethods = {
    CoreTypes.nullType.ref(ctx): {..._knownObject},
    CoreTypes.int.ref(ctx): {
      ..._knownObject,
      '+': intBinaryOp,
      '-': intBinaryOp,
      '*': intBinaryOp,
      '/': intBinaryOp,
      '%': intBinaryOp,
      '|': intBitwiseOp,
      '&': intBitwiseOp,
      '<<': intBitwiseOp,
      '>>': intBitwiseOp,
      '^': intBitwiseOp,
      '<': numComparisonOp,
      '>': numComparisonOp,
      '<=': numComparisonOp,
      '>=': numComparisonOp,
      '==': numComparisonOp,
      '!=': numComparisonOp,
      'compareTo': numCompareToOp
    },
    CoreTypes.double.ref(ctx): {
      ..._knownObject,
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
      'compareTo': numCompareToOp
    },
    CoreTypes.num.ref(ctx): {
      ..._knownObject,
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
      'compareTo': numCompareToOp
    },
    CoreTypes.bool.ref(ctx): {
      '&&': boolBinaryOp,
      '||': boolBinaryOp,
      '==': boolBinaryOp,
      '!=': boolBinaryOp
    },
    CoreTypes.string.ref(ctx): {
      ..._knownObject,
      '+': KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false),
          [KnownMethodArg('other', CoreTypes.string.ref(ctx), false)], {}),
      '==': KnownMethod(AlwaysReturnType(CoreTypes.bool.ref(ctx), false),
          [KnownMethodArg('other', CoreTypes.string.ref(ctx), false)], {}),
      '!=': KnownMethod(AlwaysReturnType(CoreTypes.bool.ref(ctx), false),
          [KnownMethodArg('other', CoreTypes.string.ref(ctx), false)], {}),
      'codeUnitAt': KnownMethod(AlwaysReturnType(CoreTypes.int.ref(ctx), false),
          [KnownMethodArg('index', CoreTypes.int.ref(ctx), false)], {}),
      'compareTo': KnownMethod(AlwaysReturnType(CoreTypes.int.ref(ctx), false),
          [KnownMethodArg('other', CoreTypes.string.ref(ctx), false)], {}),
      'contains': KnownMethod(AlwaysReturnType(CoreTypes.int.ref(ctx), false),
          [KnownMethodArg('other', CoreTypes.string.ref(ctx), false)], {}),
      'endsWith': KnownMethod(AlwaysReturnType(CoreTypes.bool.ref(ctx), false),
          [KnownMethodArg('other', CoreTypes.string.ref(ctx), false)], {}),
      //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
      'indexOf': KnownMethod(AlwaysReturnType(CoreTypes.int.ref(ctx), false), [
        KnownMethodArg('pattern', CoreTypes.string.ref(ctx), false),
        KnownMethodArg('start', CoreTypes.int.ref(ctx), true),
      ], {}),
      //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
      'lastIndexOf':
          KnownMethod(AlwaysReturnType(CoreTypes.int.ref(ctx), false), [
        KnownMethodArg('pattern', CoreTypes.string.ref(ctx), false),
        KnownMethodArg('start', CoreTypes.int.ref(ctx), true),
      ], {}),
      'padLeft':
          KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [
        KnownMethodArg('width', CoreTypes.int.ref(ctx), false),
        KnownMethodArg('padding', CoreTypes.string.ref(ctx), true),
      ], {}),
      'padRight':
          KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [
        KnownMethodArg('width', CoreTypes.int.ref(ctx), false),
        KnownMethodArg('padding', CoreTypes.string.ref(ctx), true),
      ], {}),
      //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
      'replaceAll':
          KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [
        KnownMethodArg('pattern', CoreTypes.string.ref(ctx), false),
        KnownMethodArg('replace', CoreTypes.string.ref(ctx), false),
      ], {}),
      //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
      'replaceFirst':
          KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [
        KnownMethodArg('from', CoreTypes.string.ref(ctx), false),
        KnownMethodArg('to', CoreTypes.string.ref(ctx), false),
        KnownMethodArg('startIndex', CoreTypes.int.ref(ctx), true),
      ], {}),
      'replaceRange':
          KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [
        KnownMethodArg('start', CoreTypes.int.ref(ctx), false),
        KnownMethodArg(
            'end', CoreTypes.int.ref(ctx).copyWith(nullable: true), false),
        KnownMethodArg('replacement', CoreTypes.string.ref(ctx), false),
      ], {}),
      //TODO: needs to be fixed to not use stringType but instead EvalTypes.patternType once its available
      'startsWith':
          KnownMethod(AlwaysReturnType(CoreTypes.bool.ref(ctx), false), [
        KnownMethodArg('pattern', CoreTypes.string.ref(ctx), false),
        KnownMethodArg('index', CoreTypes.int.ref(ctx), true),
      ], {}),
      'substring':
          KnownMethod(AlwaysReturnType(CoreTypes.string.ref(ctx), false), [
        KnownMethodArg('start', CoreTypes.int.ref(ctx), false),
        KnownMethodArg(
            'end', CoreTypes.int.ref(ctx).copyWith(nullable: true), true)
      ], {}),
      'toLowerCase': KnownMethod(
          AlwaysReturnType(CoreTypes.string.ref(ctx), false), [], {}),
      'toUpperCase': KnownMethod(
          AlwaysReturnType(CoreTypes.string.ref(ctx), false), [], {}),
      'trimLeft': KnownMethod(
          AlwaysReturnType(CoreTypes.string.ref(ctx), false), [], {}),
      'trimRight': KnownMethod(
          AlwaysReturnType(CoreTypes.string.ref(ctx), false), [], {}),
    },
    CoreTypes.enumType.ref(ctx): {..._knownObject}
  };
}

Map<TypeRef, Map<String, KnownField>> getKnownFields(CompilerContext ctx) => {
      CoreTypes.string.ref(ctx): {
        'length': KnownField(
            AlwaysReturnType(CoreTypes.int.ref(ctx), false), true, false),
        'isEmpty': KnownField(
            AlwaysReturnType(CoreTypes.bool.ref(ctx), false), true, false),
        'isNotEmpty': KnownField(
            AlwaysReturnType(CoreTypes.bool.ref(ctx), false), true, false)
      }
    };

late Set<TypeRef> unboxedAcrossFunctionBoundaries;
