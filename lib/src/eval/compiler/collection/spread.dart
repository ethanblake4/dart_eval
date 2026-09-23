import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/macros/loop.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
import '../values/value_rep.dart';

/// Iterates a spread source once, placing iterator creation inside the null guard.
List<TypeRef> compileCollectionSpread(
  SpreadElement element,
  Variable target,
  CompilerContext ctx, {
  required bool isMap,
  required bool isSet,
  bool box = true,
  Variable? source,
}) {
  final collection = source ?? compileExpression(element.expression, ctx);
  if (element.isNullAware && collection.type == CoreTypes.nullType.ref(ctx)) {
    return target.type.specifiedTypeArgs;
  }
  final sourceType = collection.type
      .copyWith(nullable: false)
      .resolveTypeChain(ctx);
  final requiredType = (isMap ? CoreTypes.map : CoreTypes.iterable).ref(ctx);
  if (!sourceType.isAssignableTo(ctx, requiredType)) {
    throw CompileError(
      'Cannot spread ${collection.type} into ${target.type}',
      element,
    );
  }
  final sourceArgs = sourceType.specifiedTypeArgs;
  final types = [
    for (var i = 0; i < (isMap ? 2 : 1); i++)
      sourceArgs.length > i ? sourceArgs[i] : CoreTypes.dynamic.ref(ctx),
  ];
  for (var i = 0; i < types.length; i++) {
    if (!types[i].isAssignableTo(ctx, target.type.specifiedTypeArgs[i])) {
      throw CompileError(
        'Spread element type ${types[i]} is not assignable to ${target.type.specifiedTypeArgs[i]}',
        element,
      );
    }
  }
  StatementInfo append(CompilerContext ctx, AlwaysReturnType? _) {
    final nonNull = collection
        .copyWith(type: collection.type.copyWith(nullable: false))
        .boxIfNeeded(ctx);
    final iterable = isMap ? nonNull.getProperty(ctx, 'entries') : nonNull;
    final iterator = iterable.getProperty(ctx, 'iterator');
    return macroLoop(
      ctx,
      null,
      condition: (ctx) => iterator.invoke(ctx, 'moveNext', []).result,
      body: (ctx, _) {
        final current = iterator.getProperty(ctx, 'current');
        if (isMap) {
          final key = convertForAssignment(
            ctx,
            current.getProperty(ctx, 'key'),
            target.type.specifiedTypeArgs[0],
            representation: box ? MachineRepresentation.object : null,
            source: element,
          );
          final value = convertForAssignment(
            ctx,
            current.getProperty(ctx, 'value'),
            target.type.specifiedTypeArgs[1],
            representation: box ? MachineRepresentation.object : null,
            source: element,
          );
          ctx.pushOp(MapSet(target.ssa, key.ssa, value.ssa));
        } else {
          final value = convertForAssignment(
            ctx,
            current,
            target.type.specifiedTypeArgs[0],
            representation: box ? MachineRepresentation.object : null,
            source: element,
          );
          ctx.pushOp(
            isSet
                ? SetAdd(target.ssa, value.ssa)
                : ListAppend(target.ssa, value.ssa),
          );
        }
        return StatementInfo();
      },
    );
  }

  if (element.isNullAware) {
    macroBranch(
      ctx,
      null,
      condition: (ctx) {
        final nullTest = Variable.ssa(
          ctx,
          IsNull(ctx.svar('spread_is_null'), collection.ssa),
          CoreTypes.bool.ref(ctx),
          rep: ValueRep.bool,
        );
        return Variable.ssa(
          ctx,
          LogicalNot(ctx.svar('spread_not_null'), nullTest.ssa),
          nullTest.type,
        );
      },
      thenBranch: append,
    );
  } else {
    if (collection.type.nullable) {
      throw CompileError(
        'A nullable collection requires a null-aware spread',
        element,
      );
    }
    append(ctx, null);
  }
  return types;
}

List<TypeRef> compileSpreadElementForList(
  SpreadElement element,
  Variable list,
  CompilerContext ctx,
  bool box,
) => compileCollectionSpread(
  element,
  list,
  ctx,
  isMap: false,
  isSet: false,
  box: box,
);
