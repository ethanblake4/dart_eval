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
    specifiedKeyType =
        TypeRef.fromAnnotation(ctx, ctx.library, typeArgs.arguments[0]);
    if (typeArgs.arguments.length > 1) {
      specifiedValueType =
          TypeRef.fromAnnotation(ctx, ctx.library, typeArgs.arguments[1]);
    }
  }

  Variable? collection;

  final elements = l.elements;

  ctx.beginAllocScope();
  final keyResultTypes = <TypeRef>[];
  final valueResultTypes = <TypeRef>[];
  for (final e in elements) {
    final result = compileSetOrMapElement(e, collection, ctx, specifiedKeyType,
        specifiedValueType, _boxSetOrMapElements);
    collection = result.first;
    keyResultTypes.addAll(result.second.map((e) => e.first));
    valueResultTypes.addAll(result.second.map((e) => e.second));
  }

  if (specifiedKeyType == null && keyResultTypes.isNotEmpty) {
    specifiedKeyType = TypeRef.commonBaseType(ctx, keyResultTypes.toSet());
  }
  if (specifiedValueType == null && valueResultTypes.isNotEmpty) {
    specifiedValueType = TypeRef.commonBaseType(ctx, valueResultTypes.toSet());
  }

  final collectionKeyType = (_boxSetOrMapElements
          ? specifiedKeyType?.copyWith(boxed: true)
          : specifiedKeyType) ??
      CoreTypes.dynamic.ref(ctx);

  final collectionValueType = (_boxSetOrMapElements
          ? specifiedValueType?.copyWith(boxed: true)
          : specifiedValueType) ??
      CoreTypes.dynamic.ref(ctx);

  var isEmpty = false;
  if (collection == null) {
    isEmpty = true;
    if (specifiedValueType != null ||
        (specifiedKeyType == null && specifiedValueType == null)) {
      // make an empty Map
      ctx.pushOp(PushMap.make(), PushMap.LEN);
      collection = Variable.alloc(
          ctx,
          CoreTypes.map.ref(ctx).copyWith(specifiedTypeArgs: [
            collectionKeyType,
            collectionValueType,
          ], boxed: false));
    } else {
      // make an empty Set
      ctx.pushOp(PushSet.make(), PushSet.LEN);
      collection = Variable.alloc(
          ctx,
          CoreTypes.set.ref(ctx).copyWith(specifiedTypeArgs: [
            collectionKeyType,
          ], boxed: false));
    }
  }

  ctx.endAllocScope(popAdjust: -1);
  ctx.scopeFrameOffset++;
  ctx.allocNest.last++;

  if (specifiedValueType == null && !isEmpty) {
    return Variable(
        collection.scopeFrameOffset,
        collection.type.copyWith(boxed: false, specifiedTypeArgs: [
          TypeRef.commonBaseType(ctx, keyResultTypes.toSet()),
          TypeRef.commonBaseType(ctx, valueResultTypes.toSet())
        ]));
  }

  return collection;
}

Pair<Variable, List<Pair<TypeRef, TypeRef>>> compileSetOrMapElement(
    CollectionElement e,
    Variable? setOrMap,
    CompilerContext ctx,
    TypeRef? specifiedKeyType,
    TypeRef? specifiedValueType,
    bool box) {
  if (e is Expression) {
    if (setOrMap == null) {
      ctx.pushOp(PushSet.make(), PushSet.LEN);
      setOrMap = Variable.alloc(
          ctx,
          CoreTypes.set.ref(ctx).copyWith(specifiedTypeArgs: [
            specifiedKeyType ?? CoreTypes.dynamic.ref(ctx),
          ], boxed: false));
    }

    var value = compileExpression(e, ctx, specifiedKeyType);

    if (specifiedKeyType != null &&
        !value.type.isAssignableTo(ctx, specifiedKeyType)) {
      throw CompileError(
          'Cannot use value of type ${value.type} in set of type <$specifiedKeyType>');
    }

    if (box) {
      value = value.boxIfNeeded(ctx);
    }

    ctx.pushOp(SetAdd.make(setOrMap.scopeFrameOffset, value.scopeFrameOffset),
        SetAdd.LEN);

    return Pair(setOrMap, [Pair(value.type, CoreTypes.nullType.ref(ctx))]);
  } else if (e is MapLiteralEntry) {
    if (setOrMap == null) {
      ctx.pushOp(PushMap.make(), PushMap.LEN);
      setOrMap = Variable.alloc(
          ctx,
          CoreTypes.map.ref(ctx).copyWith(specifiedTypeArgs: [
            specifiedKeyType ?? CoreTypes.dynamic.ref(ctx),
            specifiedValueType ?? CoreTypes.dynamic.ref(ctx),
          ], boxed: false));
    }

    var key = compileExpression(e.key, ctx, specifiedKeyType);

    if (specifiedKeyType != null &&
        !key.type.isAssignableTo(ctx, specifiedKeyType)) {
      throw CompileError(
          'Cannot use key of type ${key.type} in map of type <$specifiedKeyType, $specifiedValueType>');
    }

    var value = compileExpression(e.value, ctx, specifiedValueType);

    if (specifiedValueType != null &&
        !value.type.isAssignableTo(ctx, specifiedValueType)) {
      throw CompileError(
          'Cannot use value of type ${value.type} in map of type <$specifiedKeyType, $specifiedValueType>');
    }

    if (box) {
      key = key.boxIfNeeded(ctx);
      value = value.boxIfNeeded(ctx);
    }

    ctx.pushOp(
        MapSet.make(setOrMap.scopeFrameOffset, key.scopeFrameOffset,
            value.scopeFrameOffset),
        MapSet.LEN);

    return Pair(setOrMap, [Pair(key.type, value.type)]);
  }

  throw CompileError('Unknown set or map collection element ${e.runtimeType}');
}
