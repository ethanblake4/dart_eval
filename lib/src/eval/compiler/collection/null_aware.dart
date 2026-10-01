import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:control_flow_graph/control_flow_graph.dart';

import '../context.dart';
import '../expression/expression.dart';
import '../helpers/promotion.dart';
import '../macros/branch.dart';
import '../statement/statement.dart';
import '../type.dart';
import '../variable.dart';
import '../../ir/flow.dart';
import 'element_result.dart';

/// Evaluate once under a nullable context, then emit the present element.
CollectionElementResult compileNullAwareCollectionValue(
  Expression expression,
  CompilerContext ctx,
  TypeRef? bound,
  CollectionElementResult Function(Variable) present, {
  CollectionElementResult? nullContribution,
}) {
  final value = compileExpression(expression, ctx, bound?.withNullable(true));
  if (value.type.isSpec(CoreTypes.never) && !value.type.nullable) {
    return CollectionElementResult([value.type], completesNormally: false);
  }
  if (value.type.isSpec(CoreTypes.nullType) && nullContribution != null) {
    return nullContribution;
  }
  final canBeAbsent = !value.type.isAssignableTo(
    ctx,
    CoreTypes.object.ref(ctx),
    forceAllowDynamic: false,
  );
  if (!canBeAbsent) return present(value);
  if (value.type.isSpec(CoreTypes.nullType)) {
    // A null key still contributes its value's inferred type, but its value
    // expression must have no executable edge. Compile the inference arm on
    // a disconnected branch; graph cleanup removes its code.
    late CollectionElementResult contribution;
    macroBranch(
      ctx,
      null,
      conditionGraph: (ctx, whenTrue, whenFalse) {
        final parent = ctx.builder;
        ctx.pushOp(Jump(whenFalse.label!));
        final tail = ctx.flushBlock();
        ctx.builder.link(tail, whenFalse);
        return (
          BasicBlockBuilder(ctx.activeGraph, [whenTrue, whenFalse], parent),
          !ctx.soundFlowAnalysis(expression),
          true,
        );
      },
      thenBranch: (ctx, _) {
        contribution = present(value.copyWith(type: CoreTypes.never.ref(ctx)));
        return StatementInfo();
      },
    );
    return CollectionElementResult(contribution.types);
  }
  final nonNullType = _nonNullType(ctx, value.type, {});
  late CollectionElementResult contribution;
  macroBranch(
    ctx,
    null,
    condition: (ctx) => compileNonNullCondition(ctx, value),
    thenBranch: (ctx, _) {
      contribution = present(value.copyWith(type: nonNullType));
      return StatementInfo();
    },
  );
  return CollectionElementResult(contribution.types, completesNormally: true);
}

TypeRef _nonNullType(
  CompilerContext ctx,
  TypeRef type,
  Set<TypeParameterDef> visiting,
) {
  if (type.isSpec(CoreTypes.nullType)) return CoreTypes.never.ref(ctx);
  if (type is! TypeParameterTypeRef) return type.withNullable(false);
  if (!visiting.add(type.parameter)) return CoreTypes.object.ref(ctx);
  final bound = type.effectiveBound;
  return promotionView(
    type,
    _nonNullType(
      ctx,
      bound == null || bound.isSpec(CoreTypes.dynamic)
          ? CoreTypes.object.ref(ctx)
          : bound,
      visiting,
    ),
  );
}
