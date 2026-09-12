import 'package:dart_eval/src/eval/compiler/collection/spread.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';

Variable compileSetOrMapLiteral(SetOrMapLiteral literal, CompilerContext ctx) {
  final annotations = literal.typeArguments?.arguments;
  final explicitKey = annotations == null
      ? null
      : TypeRef.fromAnnotation(ctx, ctx.library, annotations.first);
  final explicitValue = annotations == null || annotations.length < 2
      ? null
      : TypeRef.fromAnnotation(ctx, ctx.library, annotations[1]);
  Variable? firstSpread;
  final first = literal.elements.firstOrNull;
  if (annotations == null && first is SpreadElement) {
    firstSpread = compileExpression(first.expression, ctx);
  }
  final isMap =
      explicitValue != null ||
      (annotations == null &&
          (literal.elements.isEmpty ||
              literal.elements.first is MapLiteralEntry ||
              (firstSpread?.type
                      .copyWith(nullable: false)
                      .isAssignableTo(
                        ctx,
                        CoreTypes.map.ref(ctx),
                        forceAllowDynamic: false,
                      ) ??
                  false)));
  final keyTypes = <TypeRef>{};
  final valueTypes = <TypeRef>{};
  final target = ctx.svar(isMap ? 'map' : 'set');
  final collectionType = (isMap ? CoreTypes.map : CoreTypes.set).ref(ctx);
  final collection = Variable.ssa(
    ctx,
    isMap ? NewMap(target) : NewSet(target),
    collectionType.copyWith(
      boxed: false,
      specifiedTypeArgs: [
        explicitKey ?? CoreTypes.dynamic.ref(ctx),
        if (isMap) explicitValue ?? CoreTypes.dynamic.ref(ctx),
      ],
    ),
  );
  for (final element in literal.elements) {
    if (element is SpreadElement) {
      final types = compileCollectionSpread(
        element,
        collection,
        ctx,
        isMap: isMap,
        isSet: !isMap,
        source: identical(element, first) ? firstSpread : null,
      );
      keyTypes.add(types.first);
      if (isMap) valueTypes.add(types[1]);
    } else if (isMap && element is MapLiteralEntry) {
      var key = compileExpression(element.key, ctx, explicitKey);
      var value = compileExpression(element.value, ctx, explicitValue);
      if (explicitKey != null && !key.type.isAssignableTo(ctx, explicitKey)) {
        throw CompileError(
          'Cannot use key of type ${key.type} in map of type $explicitKey',
          element,
        );
      }
      if (explicitValue != null &&
          !value.type.isAssignableTo(ctx, explicitValue)) {
        throw CompileError(
          'Cannot use value of type ${value.type} in map of type $explicitValue',
          element,
        );
      }
      key = key.boxIfNeeded(ctx);
      value = value.boxIfNeeded(ctx);
      keyTypes.add(key.type);
      valueTypes.add(value.type);
      ctx.pushOp(MapSet(target, key.ssa, value.ssa));
    } else if (!isMap && element is Expression) {
      var value = compileExpression(element, ctx, explicitKey);
      if (explicitKey != null && !value.type.isAssignableTo(ctx, explicitKey)) {
        throw CompileError(
          'Cannot use value of type ${value.type} in set of type $explicitKey',
          element,
        );
      }
      value = value.boxIfNeeded(ctx);
      keyTypes.add(value.type);
      ctx.pushOp(SetAdd(target, value.ssa));
    } else {
      throw CompileError(
        'Unsupported set or map element ${element.runtimeType}',
        element,
      );
    }
  }
  TypeRef infer(TypeRef? explicit, Set<TypeRef> values) =>
      (explicit ??
              (values.isEmpty
                  ? CoreTypes.dynamic.ref(ctx)
                  : TypeRef.commonBaseType(ctx, values)))
          .copyWith(boxed: true);
  return collection.copyWith(
    type: collection.type.copyWith(
      specifiedTypeArgs: [
        infer(explicitKey, keyTypes),
        if (isMap) infer(explicitValue, valueTypes),
      ],
    ),
  );
}
