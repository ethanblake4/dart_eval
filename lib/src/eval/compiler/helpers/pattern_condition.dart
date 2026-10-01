import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import '../backend/representation.dart';
import '../builtins.dart';
import '../context.dart';
import '../expression/condition.dart';
import '../expression/expression.dart';
import '../reference.dart';
import '../variable.dart';
import '../type.dart';
import '../values/abi.dart';
import 'assigned_locals.dart';
import 'conversion.dart';
import 'pattern.dart';
import 'pattern_bindings.dart';
import 'pattern_type.dart';
import 'promotion.dart';

/// Destructuring uses the same short-circuit graph as a case, but a failed
/// shape or missing key throws instead of selecting another alternative.
void compileIrrefutablePattern(
  CompilerContext ctx,
  DartPattern pattern,
  Variable subject, {
  required PatternBindContext patternContext,
}) {
  final parent = ctx.builder;
  final state = ctx.saveState();
  final failure = BasicBlock<Operation>([], label: ctx.label('pattern_failed'));
  final matching = _PatternCondition(ctx, state, failure);
  var value = subject.copyIntoFreshSlot(ctx, 'pattern_value');
  if (patternContext.usesAssignmentContext &&
      value.type.isSpec(CoreTypes.dynamic)) {
    value = convertForAssignment(
      ctx,
      value,
      ctx.typeSystem.closeSchemaHoles(patternTypeBound(ctx, pattern)),
      representation: value.representation,
      source: pattern,
    );
  }
  patternMatchAndBind(
    ctx,
    pattern,
    value,
    patternContext: patternContext,
    continuation: matching,
  );
  for (final (pattern, value) in matching.assignments) {
    IdentifierReference(
      null,
      pattern.name.lexeme,
    ).setValue(ctx, value, pattern);
  }
  if (!matching.canFail) return;
  final success = ctx.saveState();
  final tail = ctx.flushBlock();
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [failure], parent);
  final message = BuiltinValue(
    stringval: 'Pattern did not match',
  ).push(ctx).boxIfNeeded(ctx);
  final error = Variable.ssa(
    ctx,
    InvokeExternal(
      ctx.svar('pattern_error'),
      ctx.bridgeStaticFunctionIndices[ctx
          .libraryMap['dart:core']]!['StateError.']!,
      [message.ssa],
    ),
    CoreTypes.stateError.ref(ctx),
  );
  ctx.pushOp(Throw(error.ssa));
  ctx.flushBlock();
  ctx.restoreState(success);
  ctx.builder = BasicBlockBuilder(ctx.activeGraph, [tail], parent);
}

/// Each failed test goes directly to the next case. Getters, indexes and
/// guards are emitted only along the edge where earlier tests succeeded.
(BasicBlockBuilder, bool, bool) compilePatternCondition(
  CompilerContext ctx,
  GuardedPattern pattern,
  Variable subject,
  BasicBlock<Operation> whenTrue,
  BasicBlock<Operation> whenFalse, {
  Expression? source,
  int? sourceEpoch,
}) {
  final parent = ctx.builder;
  final guard = pattern.whenClause;
  // Resolve the subject before a pattern variable can shadow its name.
  var slot = source == null
      ? null
      : promotableMemberSlot(
          ctx,
          source,
          excluded: guard == null
              ? const {}
              : assignedLocalNames([guard.expression]),
        );
  if (sourceEpoch != null && slot?.local.writeEpoch != sourceEpoch) {
    slot = null;
  }
  final initialState = ctx.saveState();
  final matching = _PatternCondition(ctx, initialState, whenFalse);

  patternMatchAndBind(
    ctx,
    pattern.pattern,
    subject,
    patternContext: PatternBindContext.matching,
    continuation: matching,
  );
  if (guard != null) {
    final value = compileExpression(
      guard.expression,
      ctx,
      CoreTypes.bool.ref(ctx),
    );
    enforceConditionType(ctx, value, guard.expression);
    matching.requireMatch(value);
  }
  ctx.resolveBranchStateDiscontinuity(initialState);
  ctx.pushOp(Jump(whenTrue.label!));
  final tail = ctx.flushBlock();
  ctx.builder.link(tail, whenTrue);
  // Only enclosing locals join the failed tests. Pattern locals carry the
  // types and values of the successful path into the guard and case body.
  final bindings = ctx.locals.removeLast();
  ctx.mergeBranchState(matching.failedStates);
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
    matching.canMatch,
    matching.canFail,
  );
}

final class _PatternCondition implements PatternMatchContinuation {
  _PatternCondition(
    this.ctx,
    this.initialState,
    this.whenFalse, {
    this.deferCaptures = false,
  }) : parent = ctx.builder;

  final CompilerContext ctx;
  final ContextSaveState initialState;
  final BasicBlock<Operation> whenFalse;
  final BasicBlockBuilder parent;
  final failedStates = <ContextSaveState>[];
  final assignments = <(AssignedVariablePattern, Variable)>[];
  var canMatch = true;
  var canFail = false;
  @override
  final bool deferCaptures;

  @override
  void assignVariable(AssignedVariablePattern pattern, Variable value) {
    final reference = IdentifierReference(null, pattern.name.lexeme);
    final snapshot = value.copyIntoFreshSlot(ctx, 'pattern_assignment');
    assignments.add((
      pattern,
      convertForAssignment(
        ctx,
        snapshot,
        reference.resolveType(ctx, forSet: true, source: pattern),
        representation: snapshot.representation,
        source: pattern,
      ),
    ));
  }

  @override
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

  @override
  Variable matchOr(
    LogicalOrPattern pattern,
    Variable subject,
    PatternBindContext patternContext,
  ) {
    final before = ctx.saveState();
    final rightBlock = BasicBlock<Operation>(
      [],
      label: ctx.label('pattern_or'),
    );
    final join = BasicBlock<Operation>([], label: ctx.label('pattern_join'));
    final left = _PatternCondition(
      ctx,
      initialState,
      rightBlock,
      deferCaptures: true,
    );
    patternMatchAndBind(
      ctx,
      pattern.leftOperand,
      subject,
      patternContext: patternContext,
      continuation: left,
    );
    final leftState = ctx.saveState();
    final leftTail = ctx.flushBlock();

    ctx.restoreState(before);
    ctx.mergeBranchState(left.failedStates);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [rightBlock], parent);
    final right = _PatternCondition(
      ctx,
      initialState,
      whenFalse,
      deferCaptures: true,
    );
    patternMatchAndBind(
      ctx,
      pattern.rightOperand,
      subject,
      patternContext: patternContext,
      continuation: right,
    );
    final rightState = ctx.saveState();
    final rightTail = ctx.flushBlock();
    final declarations = {
      for (final declaration in patternDeclarations(pattern.leftOperand))
        declaration.name.lexeme: declaration,
    };
    final outputs = <String, Variable>{};
    for (final name in declarations.keys) {
      final lhs = leftState.locals.last[name]!.current;
      final rhs = rightState.locals.last[name]!.current;
      final type = TypeRef.commonBaseType(ctx, {lhs.type, rhs.type});
      // Keep a shared register bank. Conversion is necessary only when the
      // alternatives actually produce different physical representations.
      final rep = lhs.rep == rhs.rep ? lhs.rep : Abi.storageSlot(type);
      outputs[name] = Variable.of(
        ctx,
        ctx.svar(name),
        type,
        rep: rep,
        facts: lhs.facts.join(rhs.facts),
      );
    }

    void finishArm(BasicBlock<Operation> tail, ContextSaveState state) {
      ctx.restoreState(state);
      ctx.builder = BasicBlockBuilder(ctx.activeGraph, [tail], parent);
      for (final entry in outputs.entries) {
        ctx.locals.last[entry.key]!.current.toRep(
          ctx,
          entry.value.rep,
          into: entry.value.ssa,
        );
      }
      ctx.resolveBranchStateDiscontinuity(before);
      ctx.pushOp(Jump(join.label!));
      final end = ctx.flushBlock();
      ctx.builder.link(end, join);
    }

    finishArm(leftTail, leftState);
    finishArm(rightTail, rightState);
    ctx.restoreState(before);
    ctx.mergeBranchState([
      if (left.canMatch) leftState,
      if (left.canFail && right.canMatch) rightState,
    ]);
    ctx.builder = BasicBlockBuilder(ctx.activeGraph, [join], parent);
    for (final entry in outputs.entries) {
      final original = leftState.locals.last[entry.key]!.binding;
      final binding = ctx.setLocal(
        entry.key,
        entry.value,
        declaredType: original.declaredType,
        isFinal: original.isFinal,
      );
      // The guard is the first possible closure creation. Allocate its cell
      // after joining, so both alternatives share exactly one binding.
      if (!deferCaptures) {
        binding.captureBinding(ctx, declarations[entry.key]!);
      }
    }
    if (left.canFail) failedStates.addAll(right.failedStates);
    canFail |= canMatch && left.canFail && right.canFail;
    canMatch &= left.canMatch || (left.canFail && right.canMatch);
    return BuiltinValue(boolval: true).push(ctx);
  }
}
