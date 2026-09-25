import 'package:dart_eval/src/eval/compiler/collection/for.dart';
import 'package:dart_eval/src/eval/compiler/collection/if.dart';
import 'package:dart_eval/src/eval/compiler/collection/spread.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import '../values/value_rep.dart';
import '../variable/value_facts.dart';

/// Compiles `{...}` into a Set or Map literal. [bound] is the context type
/// (e.g. a declared field or parameter type): in Dart it drives literal
/// inference, so `_m = {}` in a `Map<String, int>` slot infers
/// `Map<String, int>` rather than `Map<dynamic, dynamic>`.
Variable compileSetOrMapLiteral(
  SetOrMapLiteral literal,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  final annotations = literal.typeArguments?.arguments;
  final resolvedBound = bound;
  TypeRef? boundKey, boundValue;
  if (resolvedBound != null) {
    final boundArgs = interfaceArgumentsOf(resolvedBound);
    // `dynamic` and inference variables don't constrain the literal's own
    // shape — unification binds them afterwards. A bare type parameter is
    // likewise an inference target: `const {1: 10}` under `Map<K, V>`
    // produces `Map<int, int>` and binds `K`, `V`.
    TypeRef? constrains(TypeRef type) =>
        type.isSpec(CoreTypes.dynamic) ||
                type.hasInferenceVariables ||
                type.isTypeParameter
        ? null
        : type;
    if (sameDeclaration(resolvedBound, CoreTypes.map.ref(ctx)) &&
        boundArgs.length == 2) {
      boundKey = constrains(boundArgs[0]);
      boundValue = constrains(boundArgs[1]);
    } else if (sameDeclaration(resolvedBound, CoreTypes.set.ref(ctx)) &&
        boundArgs.length == 1) {
      boundKey = constrains(boundArgs[0]);
    }
  }
  final explicitKey = annotations == null
      ? boundKey
      : TypeRef.fromAnnotation(ctx, ctx.library, annotations.first);
  final explicitValue = annotations != null && annotations.length >= 2
      ? TypeRef.fromAnnotation(ctx, ctx.library, annotations[1])
      : annotations == null
      ? boundValue
      : null;
  // The literal's kind comes from its leaf elements in document order:
  // a `key: value` leaf makes it a Map, an expression leaf a Set, and a
  // literal of only spreads infers from the first spread's type.
  final leaves = [for (final element in literal.elements) _leafOf(element)];
  final hasEntryLeaf = leaves.any((element) => element is MapLiteralEntry);
  final hasExprLeaf = leaves.any((element) => element is Expression);
  final firstSpreadElement = leaves.whereType<SpreadElement>().firstOrNull;
  Variable? firstSpread;
  if (annotations == null &&
      !hasEntryLeaf &&
      !hasExprLeaf &&
      firstSpreadElement != null) {
    firstSpread = compileExpression(firstSpreadElement.expression, ctx);
  }
  final isMap =
      explicitValue != null ||
      (annotations == null &&
          (literal.elements.isEmpty
              // A bare `{}` is a Set only when the context says Set;
              // otherwise it is a Map.
              ? resolvedBound == null ||
                    !sameDeclaration(resolvedBound, CoreTypes.set.ref(ctx))
              : hasEntryLeaf ||
                    (!hasExprLeaf &&
                        (firstSpread?.type
                                .withNullable(false)
                                .isAssignableTo(
                                  ctx,
                                  CoreTypes.map.ref(ctx),
                                  forceAllowDynamic: false,
                                ) ??
                            false))));
  final keyTypes = <TypeRef>{};
  final valueTypes = <TypeRef>{};
  final target = ctx.svar(isMap ? 'map' : 'set');
  final collectionType = (isMap ? CoreTypes.map : CoreTypes.set).ref(ctx);
  final exactCollectionType = collectionType.copyWith(
    arguments: [
      explicitKey ?? CoreTypes.dynamic.ref(ctx),
      if (isMap) explicitValue ?? CoreTypes.dynamic.ref(ctx),
    ],
  );
  final collection = Variable.ssa(
    ctx,
    isMap
        ? NewMap(target, constBacking: literal.isConst)
        : NewSet(target, constBacking: literal.isConst),
    exactCollectionType,
    rep: isMap ? ValueRep.nativeMap : ValueRep.nativeSet,
    facts: ValueFacts(exact: exactCollectionType),
  );
  for (final element in literal.elements) {
    final (keys, values) = _compileElement(
      element,
      collection,
      ctx,
      isMap: isMap,
      explicitKey: explicitKey,
      explicitValue: explicitValue,
      peekedSpread: firstSpreadElement != null && firstSpread != null
          ? (firstSpreadElement, firstSpread)
          : null,
    );
    keyTypes.addAll(keys);
    valueTypes.addAll(values);
  }
  TypeRef infer(TypeRef? explicit, Set<TypeRef> values) =>
      explicit ??
      (values.isEmpty
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.commonBaseType(ctx, values));
  final result = collection.copyWith(
    type: (collection.type as InterfaceTypeRef).copyWith(
      arguments: [
        infer(explicitKey, keyTypes),
        if (isMap) infer(explicitValue, valueTypes),
      ],
    ),
  );
  return literal.isConst ? internConst(ctx, result, result.type) : result;
}

/// The first leaf of [element] — itself, unless it is an `if`/`for`
/// element wrapping a nested body.
CollectionElement _leafOf(CollectionElement element) => switch (element) {
  IfElement(:final thenElement) => _leafOf(thenElement),
  ForElement(:final body) => _leafOf(body),
  _ => element,
};

(List<TypeRef>, List<TypeRef>) _compileElement(
  CollectionElement element,
  Variable collection,
  CompilerContext ctx, {
  required bool isMap,
  required TypeRef? explicitKey,
  required TypeRef? explicitValue,
  (SpreadElement, Variable)? peekedSpread,
}) {
  final target = collection.ssa;
  final keys = <TypeRef>[];
  final values = <TypeRef>[];
  if (element is SpreadElement) {
    final types = compileCollectionSpread(
      element,
      collection,
      ctx,
      isMap: isMap,
      isSet: !isMap,
      source: peekedSpread != null && identical(peekedSpread.$1, element)
          ? peekedSpread.$2
          : null,
    );
    keys.add(types.first);
    if (isMap) values.add(types[1]);
  } else if (element is IfElement) {
    final types = compileIfElement(element, ctx, (e) {
      final (k, v) = _compileElement(
        e,
        collection,
        ctx,
        isMap: isMap,
        explicitKey: explicitKey,
        explicitValue: explicitValue,
        peekedSpread: peekedSpread,
      );
      return isMap ? [...k, ...v] : k;
    });
    if (isMap) {
      for (var i = 0; i + 1 < types.length; i += 2) {
        keys.add(types[i]);
        values.add(types[i + 1]);
      }
    } else {
      keys.addAll(types);
    }
  } else if (element is ForElement) {
    final types = compileForElement(element, ctx, (e) {
      final (k, v) = _compileElement(
        e,
        collection,
        ctx,
        isMap: isMap,
        explicitKey: explicitKey,
        explicitValue: explicitValue,
        peekedSpread: peekedSpread,
      );
      return isMap ? [...k, ...v] : k;
    });
    if (isMap) {
      for (var i = 0; i + 1 < types.length; i += 2) {
        keys.add(types[i]);
        values.add(types[i + 1]);
      }
    } else {
      keys.addAll(types);
    }
  } else if (isMap && element is MapLiteralEntry) {
    var key = compileExpression(element.key, ctx, explicitKey);
    var value = compileExpression(element.value, ctx, explicitValue);
    if (explicitKey != null) {
      key = convertForAssignment(
        ctx,
        key,
        explicitKey,
        representation: MachineRepresentation.object,
        source: element.key,
      );
    } else {
      key = key.boxIfNeeded(ctx);
    }
    if (explicitValue != null) {
      value = convertForAssignment(
        ctx,
        value,
        explicitValue,
        representation: MachineRepresentation.object,
        source: element.value,
      );
    } else {
      value = value.boxIfNeeded(ctx);
    }
    keys.add(key.type);
    values.add(value.type);
    ctx.pushOp(MapSet(target, key.ssa, value.ssa));
  } else if (!isMap && element is Expression) {
    var value = compileExpression(element, ctx, explicitKey);
    value = explicitKey == null
        ? value.boxIfNeeded(ctx)
        : convertForAssignment(
            ctx,
            value,
            explicitKey,
            representation: MachineRepresentation.object,
            source: element,
          );
    keys.add(value.type);
    ctx.pushOp(SetAdd(target, value.ssa));
  } else {
    throw CompileError(
      'Unsupported set or map element ${element.runtimeType}',
      element,
    );
  }
  return (keys, values);
}
