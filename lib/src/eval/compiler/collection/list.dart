import 'package:dart_eval/src/eval/compiler/collection/spread.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/collection/for.dart';
import 'package:dart_eval/src/eval/compiler/collection/if.dart';

import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/const.dart';
import 'package:dart_eval/src/eval/compiler/helpers/context_type.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/ir/collection.dart';
import '../values/value_rep.dart';
import '../variable/value_facts.dart';
import 'element_result.dart';
import 'null_aware.dart';

const _boxListElements = true;

Variable compileListLiteral(
  ListLiteral l,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  final elements = l.elements;
  if (bound != null) {
    if (l.isConst && l.typeArguments == null) {
      bound = ctx.typeSystem.constantContextType(bound);
    }
    bound = inferContextType(ctx, CoreTypes.list.ref(ctx), bound);
  }

  TypeRef? boundType;
  if (bound != null && interfaceArgumentsOf(bound).isNotEmpty) {
    if (interfaceArgumentsOf(bound).length > 1) {
      throw CompileError('Lists can only have one type argument');
    }
    boundType = interfaceArgumentsOf(bound).first;
    if (boundType is UnknownTypeRef) boundType = null;
    // An inference variable is not a constraint: `<num>[...]` under
    // `List<T>` binds `T` to `num` — let the elements decide. A bare type
    // parameter is the same target: `[0]` under `Iterable<E>` produces
    // `List<int>` and binds `E`.
    if (boundType != null &&
        (boundType.hasInferenceVariables || boundType.isTypeParameter) &&
        elements.isNotEmpty) {
      boundType = boundType.isTypeParameter
          ? null
          : boundType.lowerTypeParameters(ctx);
    }
  }
  if (bound != null &&
      (sameDeclaration(bound, CoreTypes.list.ref(ctx)) ||
          sameDeclaration(bound, CoreTypes.iterable.ref(ctx))) &&
      interfaceArgumentsOf(bound).isEmpty) {
    // A raw collection context supplies dynamic instead of leaving the
    // literal unconstrained to infer its element type from the entries.
    boundType = CoreTypes.dynamic.ref(ctx);
  }
  TypeRef? listSpecifiedType;
  final typeArgs = l.typeArguments;
  if (typeArgs != null) {
    listSpecifiedType = TypeRef.fromAnnotation(
      ctx,
      ctx.library,
      typeArgs.arguments[0],
    );
    // An inference-variable bound isn't a constraint — `<int>[]` under
    // `Iterable<T>` binds `T` to `int` rather than failing the check.
    if (boundType != null &&
        !boundType.hasInferenceVariables &&
        !boundType.isTypeParameter &&
        !listSpecifiedType.isAssignableTo(ctx, boundType)) {
      throw CompileError(
        'List of type $listSpecifiedType is not assignable to List of type $boundType',
      );
    }
  } else {
    listSpecifiedType = boundType;
  }

  // Uninferred elements are schema holes, so nested spreads can infer upward.
  final listType = CoreTypes.list
      .ref(ctx)
      .copyWith(arguments: [listSpecifiedType ?? UnknownTypeRef.instance]);
  var list = Variable.ssa(
    ctx,
    NewList(ctx.svar('list')),
    listType,
    rep: ValueRep.nativeList,
    facts: ValueFacts(exact: listType),
  );

  ctx.beginScope();
  final resultTypes = <TypeRef>[];
  for (final e in elements) {
    final element = compileListElement(e, list, ctx, _boxListElements);
    // An element that cannot complete ends the literal's evaluation.
    // A bottom-type contribution alone (such as ?null) does not.
    if (!element.completesNormally) {
      ctx.endScope();
      return Variable.never(ctx);
    }
    resultTypes.addAll(element.types);
  }
  ctx.endScope();

  if (listSpecifiedType == null || listSpecifiedType.hasSchemaHoles) {
    // A literal containing only null spreads infers Never, unlike an empty [].
    list = list.copyWith(
      type: CoreTypes.list
          .ref(ctx)
          .copyWith(
            arguments: [
              resultTypes.isEmpty
                  ? ctx.typeSystem.closeSchemaHoles(
                      listSpecifiedType ??
                          (elements.isEmpty
                                  ? CoreTypes.dynamic
                                  : CoreTypes.never)
                              .ref(ctx),
                    )
                  : TypeRef.commonBaseType(ctx, resultTypes.toSet()),
            ],
          ),
    );
    list = list.withFacts(ValueFacts(exact: list.type));
  }

  return l.isConst ? internConst(ctx, list, list.type) : list;
}

Variable boxListContents(CompilerContext ctx, Variable list) {
  final elementType = interfaceArgumentsOf(list.type).first;
  final newList = Variable.ssa(
    ctx,
    NewList(ctx.svar('boxed_elements')),
    (list.type as InterfaceTypeRef).copyWith(arguments: [elementType]),
    rep: ValueRep.nativeList,
  );
  final index = BuiltinValue(intval: 0).push(ctx);
  final one = BuiltinValue(intval: 1).push(ctx);
  final length = Variable.ssa(
    ctx,
    IterableLength(ctx.svar('length'), list.ssa),
    CoreTypes.int.ref(ctx),
    rep: ValueRep.int,
  );
  macroLoop(
    ctx,
    null,
    condition: (ctx) => Variable.ssa(
      ctx,
      IntLessThan(ctx.svar('in_bounds'), index.ssa, length.ssa),
      CoreTypes.bool.ref(ctx),
      rep: ValueRep.bool,
    ),
    body: (ctx, _) {
      final element = Variable.ssa(
        ctx,
        IndexList(ctx.svar('element'), list.ssa, index.ssa),
        elementType,
      );
      ctx.pushOp(ListAppend(newList.ssa, element.boxIfNeeded(ctx).ssa));
      return StatementInfo();
    },
    update: (ctx) {
      final incremented = ctx.svar('next_index');
      ctx.pushOp(IntAdd(incremented, index.ssa, one.ssa));
      ctx.pushOp(Assign(index.ssa, incremented));
    },
  );
  return newList;
}

CollectionElementResult compileListElement(
  CollectionElement e,
  Variable list,
  CompilerContext ctx,
  bool box,
) {
  final listType = interfaceArgumentsOf(list.type)[0];
  if (e is NullAwareElement) {
    return compileNullAwareCollectionValue(e.value, ctx, listType, (value) {
      final stored = convertForAssignment(
        ctx,
        value,
        listType,
        representation: box ? MachineRepresentation.object : null,
        source: e,
      );
      ctx.pushOp(ListAppend(list.ssa, stored.ssa));
      return CollectionElementResult([stored.type]);
    }, nullContribution: CollectionElementResult([CoreTypes.never.ref(ctx)]));
  }
  if (e is Expression) {
    var result = compileExpression(e, ctx, listType);
    result = convertForAssignment(
      ctx,
      result,
      listType,
      representation: box ? MachineRepresentation.object : null,
      source: e,
      description:
          'Cannot use expression of type ${result.type} in list of type $listType',
    );
    if (result.type.isSpec(CoreTypes.never) && !result.type.nullable) {
      return CollectionElementResult([result.type], completesNormally: false);
    }
    ctx.pushOp(ListAppend(list.ssa, result.ssa));
    return CollectionElementResult([result.type]);
  } else if (e is IfElement) {
    return compileIfElementForList(e, list, ctx, box);
  } else if (e is ForElement) {
    return compileForElementForList(e, list, ctx, box);
  } else if (e is SpreadElement) {
    return CollectionElementResult(
      compileSpreadElementForList(e, list, ctx, box),
    );
  }
  throw CompileError('Unknown list collection element ${e.runtimeType}');
}
