import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

const _boxSetOrMapElements = true;

Variable compileSetOrMapLiteral(SetOrMapLiteral l, CompilerContext ctx) {
  TypeRef? specifiedKeyType, specifiedValueType;
  final typeArgs = l.typeArguments;
  if (typeArgs != null) {
    if (typeArgs.length == 1) {
      throw CompileError('Sets are not currently supported');
    }
    specifiedKeyType = TypeRef.fromAnnotation(ctx, ctx.library, typeArgs.arguments[0]);
    specifiedValueType = TypeRef.fromAnnotation(ctx, ctx.library, typeArgs.arguments[1]);
  }

  Variable? _collection;

  final elements = l.elements;

  ctx.beginAllocScope();
  final keyResultTypes = <TypeRef>[];
  final valueResultTypes = <TypeRef>[];
  for (final e in elements) {
    final _result =
        compileSetOrMapElement(e, _collection, ctx, specifiedKeyType, specifiedValueType, _boxSetOrMapElements);
    _collection = _result.first;
    keyResultTypes.addAll(_result.second.map((e) => e.first));
    valueResultTypes.addAll(_result.second.map((e) => e.second));
  }
  ctx.endAllocScope(popAdjust: -1);
  ctx.scopeFrameOffset++;
  ctx.allocNest.last++;

  if (specifiedValueType == null) {
    return Variable(
        _collection!.scopeFrameOffset,
        _collection.type.copyWith(boxed: false, specifiedTypeArgs: [
          TypeRef.commonBaseType(ctx, keyResultTypes.toSet()),
          TypeRef.commonBaseType(ctx, valueResultTypes.toSet())
        ]));
  }

  return _collection!;
}

Pair<Variable, List<Pair<TypeRef, TypeRef>>> compileSetOrMapElement(CollectionElement e, Variable? setOrMap,
    CompilerContext ctx, TypeRef? specifiedKeyType, TypeRef? specifiedValueType, bool box) {
  final isMap = setOrMap?.type.resolveTypeChain(ctx).isAssignableTo(ctx, EvalTypes.mapType);

  if (e is Expression) {
    throw CompileError('Sets are not currently supported');
  } else if (e is MapLiteralEntry) {
    if (setOrMap == null) {
      ctx.pushOp(PushMap.make(), PushMap.LEN);
      setOrMap = Variable.alloc(
          ctx,
          EvalTypes.mapType.copyWith(specifiedTypeArgs: [
            specifiedKeyType ?? EvalTypes.dynamicType,
            specifiedValueType ?? EvalTypes.dynamicType,
          ], boxed: false));
    }

    var _key = compileExpression(e.key, ctx);

    if (specifiedKeyType != null && !_key.type.isAssignableTo(ctx, specifiedKeyType)) {
      throw CompileError('Cannot use key of type ${_key.type} in map of type <$specifiedKeyType, $specifiedValueType>');
    }

    var _value = compileExpression(e.value, ctx);

    if (specifiedValueType != null && !_value.type.isAssignableTo(ctx, specifiedValueType)) {
      throw CompileError(
          'Cannot use value of type ${_value.type} in map of type <$specifiedKeyType, $specifiedValueType>');
    }

    if (box) {
      _key = _key.boxIfNeeded(ctx);
      _value = _value.boxIfNeeded(ctx);
    }

    ctx.pushOp(MapSet.make(setOrMap.scopeFrameOffset, _key.scopeFrameOffset, _value.scopeFrameOffset), MapSet.LEN);

    return Pair(setOrMap, [Pair(_key.type, _value.type)]);
  }

  throw CompileError('Unknown set or map collection element ${e.runtimeType}');
}
