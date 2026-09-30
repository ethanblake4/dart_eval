import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/ir/flow.dart';
import '../backend/representation.dart';
import '../context.dart';
import '../expression/condition.dart';
import '../expression/expression.dart';
import '../variable.dart';
import '../type.dart';
import 'assigned_locals.dart';
import 'conversion.dart';
import 'pattern.dart';
import 'pattern_type.dart';
import 'promotion.dart';

/// Each failed test goes directly to the next case. Getters, indexes and
/// guards are emitted only along the edge where earlier tests succeeded.
(BasicBlockBuilder, bool, bool) compilePatternCondition(
  CompilerContext ctx,
  GuardedPattern pattern,
  Variable subject,
  BasicBlock<Operation> whenTrue,
  BasicBlock<Operation> whenFalse, {
  Expression? source,
}) {
  final parent = ctx.builder;
  final guard = pattern.whenClause;
  // Resolve the subject before a pattern variable can shadow its name.
  final slot = source == null
      ? null
      : promotableMemberSlot(
          ctx,
          source,
          excluded: guard == null
              ? const {}
              : assignedLocalNames([guard.expression]),
        );
  final initialState = ctx.saveState();
  final failedStates = <ContextSaveState>[];
  var canMatch = true;
  var canFail = false;
  void requireMatch(Variable condition) {
    if (condition.facts.constBool == true) return;
    final value = convertForAssignment(
      ctx,
      condition,
      CoreTypes.bool.ref(ctx),
      representation: MachineRepresentation.boolean,
    );
    ctx.resolveBranchStateDiscontinuity(initialState);
    failedStates.add(ctx.saveState());
    canFail |= canMatch;
    canMatch &= condition.facts.constBool != false;
    final next = BasicBlock<Operation>([], label: ctx.label('pattern_next'));
    ctx.pushOp(JumpIfFalse(value.ssa, whenFalse.label!));
    final tail = ctx.flushBlock();
    ctx.builder.link(tail, whenFalse);
    ctx.builder.link(tail, next);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [next], parent);
  }

  patternMatchAndBind(
    ctx,
    pattern.pattern,
    subject,
    patternContext: PatternBindContext.matching,
    requireMatch: requireMatch,
  );
  if (guard != null) {
    final value = compileExpression(
      guard.expression,
      ctx,
      CoreTypes.bool.ref(ctx),
    );
    enforceConditionType(ctx, value, guard.expression);
    requireMatch(value);
  }
  ctx.resolveBranchStateDiscontinuity(initialState);
  ctx.pushOp(Jump(whenTrue.label!));
  final tail = ctx.flushBlock();
  ctx.builder.link(tail, whenTrue);
  // Only enclosing locals join the failed tests. Pattern locals carry the
  // types and values of the successful path into the guard and case body.
  final bindings = ctx.locals.removeLast();
  ctx.mergeBranchState(failedStates);
  ctx.locals.add(bindings);
  if (slot != null) {
    final matchedType = matchedPatternType(ctx, pattern.pattern, subject.type);
    if (slot.member == null) {
      slot.local.binding?.typesOfInterest.add(matchedType);
      if (pattern.pattern case RecordPattern record) {
        slot.local.binding?.typesOfInterest.add(
          recordPatternShape(ctx, record),
        );
      }
    }
    slot.local.inferType(
      ctx,
      matchedType,
      slot.viaSuper ? 'super:${slot.member}' : slot.member,
    );
  }
  return (
    BasicBlockBuilder(ctx.activeGraph, [whenTrue, whenFalse], parent),
    canMatch,
    canFail,
  );
}
