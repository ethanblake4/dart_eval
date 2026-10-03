import 'package:dart_eval/src/eval/compiler/collection/for.dart';
import 'package:dart_eval/src/eval/compiler/collection/if.dart';
import 'package:dart_eval/src/eval/compiler/collection/spread.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/helpers/context_type.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/helpers/global.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import '../values/value_rep.dart';
import '../variable/value_facts.dart';
import 'element_result.dart';
import 'null_aware.dart';

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
  if (literal.isConst && bound != null) {
    bound = ctx.typeSystem.constantContextType(bound);
  }
  final resolvedBound = bound == null
      ? null
      : inferContextType(ctx, CoreTypes.map.ref(ctx), bound);
  final hasMapContext =
      resolvedBound != null &&
      sameDeclaration(resolvedBound, CoreTypes.map.ref(ctx));
  final iterableBound = resolvedBound == null
      ? null
      : ctx.typeSystem.asInstanceOf(
          resolvedBound,
          ctx.types.bySpec(CoreTypes.iterable),
        );
  TypeRef? boundKey, boundValue;
  if (resolvedBound != null) {
    final boundArgs = interfaceArgumentsOf(resolvedBound);
    // Schema holes and inference variables don't constrain the literal's own
    // shape — unification binds them afterwards. A bare type parameter is
    // likewise an inference target: `const {1: 10}` under `Map<K, V>`
    // produces `Map<int, int>` and binds `K`, `V`.
    // Empty literals retain declared parameters because they have no upward
    // evidence; call-site inference variables still provide no constraint.
    TypeRef? constrains(TypeRef type) =>
        type is UnknownTypeRef ||
            type.hasInferenceVariables ||
            (type.isTypeParameter && literal.elements.isNotEmpty)
        ? null
        : type;
    if (hasMapContext && boundArgs.length == 2) {
      boundKey = constrains(boundArgs[0]);
      boundValue = constrains(boundArgs[1]);
    } else if (hasMapContext && boundArgs.isEmpty) {
      // A raw Map context supplies dynamic for both type arguments.
      boundKey = boundValue = CoreTypes.dynamic.ref(ctx);
    } else if (iterableBound != null &&
        interfaceArgumentsOf(iterableBound).length == 1) {
      boundKey = constrains(interfaceArgumentsOf(iterableBound).first);
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
  // literal of only spreads uses static Map evidence when available.
  final leaves = [
    for (final element in literal.elements) ..._leavesOf(element),
  ];
  final hasEntryLeaf = leaves.any((element) => element is MapLiteralEntry);
  final hasExprLeaf = leaves.any(
    (element) => element is Expression || element is NullAwareElement,
  );
  final firstSpreadElement = leaves.whereType<SpreadElement>().firstOrNull;
  final needsSpreadInference =
      annotations == null &&
      !hasEntryLeaf &&
      !hasExprLeaf &&
      !hasMapContext &&
      iterableBound == null &&
      firstSpreadElement != null;
  final hasMapSpread =
      needsSpreadInference &&
      leaves.whereType<SpreadElement>().any(
        (spread) => _hasMapSpreadType(ctx, literal, spread),
      );
  final inferFromSpread = needsSpreadInference && !hasMapSpread;
  var isMap =
      explicitValue != null ||
      (annotations == null &&
          (literal.elements.isEmpty
              // An Iterable context selects a Set for a bare `{}`.
              ? iterableBound == null
              : hasEntryLeaf ||
                    hasMapSpread ||
                    (!hasExprLeaf && hasMapContext)));
  final keyTypes = <TypeRef>{};
  final valueTypes = <TypeRef>{};
  final target = ctx.svar(isMap ? 'map' : 'set');
  final collectionType = (isMap ? CoreTypes.map : CoreTypes.set).ref(ctx);
  final exactCollectionType = collectionType.copyWith(
    arguments: [
      explicitKey ?? UnknownTypeRef.instance,
      if (isMap) explicitValue ?? UnknownTypeRef.instance,
    ],
  );
  // Keep the allocation before any guards. Its kind is finalized when the
  // first spread compiles in its own branch, without evaluating it early.
  final allocationCode = ctx.blockCode;
  final allocationIndex = allocationCode.length;
  var collection = Variable.ssa(
    ctx,
    isMap
        ? NewMap(target, constBacking: literal.isConst)
        : NewSet(target, constBacking: literal.isConst),
    exactCollectionType,
    rep: isMap ? ValueRep.nativeMap : ValueRep.nativeSet,
    facts: ValueFacts(exact: exactCollectionType),
  );
  CollectionElementResult compileElement(CollectionElement element) {
    if (element is IfElement) {
      return compileIfElement(element, ctx, compileElement);
    }
    if (element is ForElement) {
      return compileForElement(element, ctx, compileElement);
    }
    Variable? source;
    if (inferFromSpread && identical(element, firstSpreadElement)) {
      source = compileExpression(firstSpreadElement.expression, ctx);
      isMap = source.type
          .withNullable(false)
          .isAssignableTo(
            ctx,
            CoreTypes.map.ref(ctx),
            forceAllowDynamic: false,
          );
      if (isMap) {
        final type = CoreTypes.map
            .ref(ctx)
            .copyWith(
              arguments: [UnknownTypeRef.instance, UnknownTypeRef.instance],
            );
        collection = collection.copyWith(
          type: type,
          rep: ValueRep.nativeMap,
          facts: ValueFacts(exact: type),
        );
        allocationCode[allocationIndex] = NewMap(
          target,
          constBacking: literal.isConst,
        );
      }
    }
    return _compileElement(
      element,
      collection,
      ctx,
      isMap: isMap,
      explicitKey: explicitKey,
      explicitValue: explicitValue,
      spreadSource: source,
    );
  }

  for (final element in literal.elements) {
    final elementResult = compileElement(element);
    // Abrupt evaluation is separate from bottom-type contributions.
    if (!elementResult.completesNormally) {
      return Variable.never(ctx);
    }
    if (isMap) {
      for (var i = 0; i + 1 < elementResult.types.length; i += 2) {
        keyTypes.add(elementResult.types[i]);
        valueTypes.add(elementResult.types[i + 1]);
      }
    } else {
      keyTypes.addAll(elementResult.types);
    }
  }
  // Only null spreads contribute no evidence in a nonempty literal.
  TypeRef infer(TypeRef? explicit, Set<TypeRef> values) =>
      explicit != null && !explicit.hasSchemaHoles
      ? explicit
      : values.isEmpty
      ? ctx.typeSystem.closeSchemaHoles(
          explicit ??
              (literal.elements.isEmpty ? CoreTypes.dynamic : CoreTypes.never)
                  .ref(ctx),
        )
      : TypeRef.commonBaseType(ctx, values);
  final resultType = (collection.type as InterfaceTypeRef).copyWith(
    arguments: [
      infer(explicitKey, keyTypes),
      if (isMap) infer(explicitValue, valueTypes),
    ],
  );
  final result = collection.copyWith(
    type: resultType,
    facts: ValueFacts(exact: resultType),
  );
  if (isMap &&
      !literal.isConst &&
      resultType.arguments.first.isSpec(CoreTypes.string) &&
      !resultType.arguments.first.nullable) {
    allocationCode[allocationIndex] = NewMap(target, stringKeys: true);
  }
  return literal.isConst ? internConst(ctx, result, result.type) : result;
}

Iterable<CollectionElement> _leavesOf(CollectionElement element) sync* {
  if (element is IfElement) {
    yield* _leavesOf(element.thenElement);
    if (element.elseElement case final alternate?) {
      yield* _leavesOf(alternate);
    }
  } else if (element is ForElement) {
    yield* _leavesOf(element.body);
  } else {
    yield element;
  }
}

/// Recognizes Map evidence without emitting expression evaluation. Loop and
/// pattern bindings aren't in scope yet, so leave their spreads to compilation.
bool _hasMapSpreadType(
  CompilerContext ctx,
  SetOrMapLiteral literal,
  SpreadElement spread,
) {
  for (var parent = spread.parent; parent != literal; parent = parent.parent) {
    if (parent == null ||
        parent is ForElement ||
        parent is IfElement && parent.caseClause != null) {
      return false;
    }
  }
  TypeRef? typeOf(Expression expression) => switch (expression) {
    SimpleIdentifier(:final name) =>
      ctx.lookupBinding(name)?.declaredType ??
          inferStaticExpressionType(ctx, ctx.library, expression),
    ParenthesizedExpression(:final expression) => typeOf(expression),
    AsExpression(:final type) => TypeRef.fromAnnotation(ctx, ctx.library, type),
    MethodInvocation(target: null, :final methodName)
        when ctx.lookupBinding(methodName.name) == null =>
      inferStaticExpressionType(ctx, ctx.library, expression),
    SetOrMapLiteral(:final typeArguments, :final elements)
        when typeArguments?.arguments.length == 2 ||
            elements.any((element) => element is MapLiteralEntry) =>
      CoreTypes.map.ref(ctx),
    _ => null,
  };
  return typeOf(spread.expression)
          ?.withNullable(false)
          .isAssignableTo(
            ctx,
            CoreTypes.map.ref(ctx),
            forceAllowDynamic: false,
          ) ??
      false;
}

CollectionElementResult _compileElement(
  CollectionElement element,
  Variable collection,
  CompilerContext ctx, {
  required bool isMap,
  required TypeRef? explicitKey,
  required TypeRef? explicitValue,
  Variable? spreadSource,
}) {
  final target = collection.ssa;
  if (element is SpreadElement) {
    return CollectionElementResult(
      compileCollectionSpread(
        element,
        collection,
        ctx,
        isMap: isMap,
        isSet: !isMap,
        source: spreadSource,
      ),
    );
  }
  if (isMap && element is MapLiteralEntry) {
    CollectionElementResult append(Variable key, Variable value) {
      final storedKey = explicitKey == null
          ? key.boxIfNeeded(ctx)
          : convertForAssignment(
              ctx,
              key,
              explicitKey,
              representation: MachineRepresentation.object,
              source: element.key,
            );
      final storedValue = explicitValue == null
          ? value.boxIfNeeded(ctx)
          : convertForAssignment(
              ctx,
              value,
              explicitValue,
              representation: MachineRepresentation.object,
              source: element.value,
            );
      final completes = ![
        storedKey.type,
        storedValue.type,
      ].any((type) => type.isSpec(CoreTypes.never) && !type.nullable);
      if (completes) ctx.pushOp(MapSet(target, storedKey.ssa, storedValue.ssa));
      return CollectionElementResult([
        storedKey.type,
        storedValue.type,
      ], completesNormally: completes);
    }

    CollectionElementResult compileValue(Variable key) {
      // Value evaluation may reassign the local that supplied the key.
      if (key.binding != null) {
        key = key.copyIntoFreshSlot(ctx, 'map_key');
      }
      if (element.valueQuestion != null) {
        return compileNullAwareCollectionValue(
          element.value,
          ctx,
          explicitValue,
          (value) => append(key, value),
          nullContribution: CollectionElementResult([
            key.type,
            CoreTypes.never.ref(ctx),
          ]),
        );
      }
      return append(key, compileExpression(element.value, ctx, explicitValue));
    }

    if (element.keyQuestion != null) {
      return compileNullAwareCollectionValue(
        element.key,
        ctx,
        explicitKey,
        compileValue,
      );
    }
    final key = compileExpression(element.key, ctx, explicitKey);
    if (key.type.isSpec(CoreTypes.never) && !key.type.nullable) {
      return CollectionElementResult([
        key.type,
        key.type,
      ], completesNormally: false);
    }
    return compileValue(key);
  }
  if (!isMap) {
    CollectionElementResult append(Variable value) {
      final stored = explicitKey == null
          ? value.boxIfNeeded(ctx)
          : convertForAssignment(
              ctx,
              value,
              explicitKey,
              representation: MachineRepresentation.object,
              source: element,
            );
      final completes =
          !stored.type.isSpec(CoreTypes.never) || stored.type.nullable;
      if (completes) ctx.pushOp(SetAdd(target, stored.ssa));
      return CollectionElementResult([
        stored.type,
      ], completesNormally: completes);
    }

    if (element is NullAwareElement) {
      return compileNullAwareCollectionValue(
        element.value,
        ctx,
        explicitKey,
        append,
        nullContribution: CollectionElementResult([CoreTypes.never.ref(ctx)]),
      );
    }
    if (element is Expression) {
      return append(compileExpression(element, ctx, explicitKey));
    }
  }
  throw CompileError(
    'Unsupported set or map element ${element.runtimeType}',
    element,
  );
}
