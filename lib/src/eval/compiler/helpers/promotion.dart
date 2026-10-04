// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/denotation.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'assigned_locals.dart';
import 'captures.dart';
import 'extension_type.dart';

final _flowExperiments = Expando<Set<String>>();

bool _flowExperimentEnabled(AstNode source, String experiment) {
  final unit = source.thisOrAncestorOfType<CompilationUnit>();
  if (unit == null) return false;
  var enabled = _flowExperiments[unit];
  if (enabled == null) {
    enabled = <String>{};
    for (
      Token? comment = unit.beginToken.precedingComments;
      comment != null;
      comment = comment.next
    ) {
      if (!RegExp(r'^//\s*SharedOptions=').hasMatch(comment.lexeme)) continue;
      for (final match in RegExp(
        r'--enable-experiment=([^\s]+)',
      ).allMatches(comment.lexeme)) {
        enabled.addAll(match.group(1)!.split(','));
      }
    }
    _flowExperiments[unit] = enabled;
  }
  return enabled.contains(experiment);
}

bool inferenceUpdate4Enabled(AstNode source) =>
    _flowExperimentEnabled(source, 'inference-update-4');

bool promotionChainIntersectionJoinEnabled(AstNode source) =>
    _flowExperimentEnabled(source, 'promotion-chain-intersection-join');

bool thisPromotionEnabled(CompilerContext ctx, AstNode source) =>
    ctx.anonymousThisReceiver != null ||
    _flowExperimentEnabled(source, 'this-promotion');

/// Suspension lets enclosing invocations write captured variables. Local
/// variables and unwritten captures retain their promotions.
void demoteAfterSuspension(CompilerContext ctx, AstNode source) {
  final function =
      source.thisOrAncestorOfType<FunctionExpression>() ??
      source.thisOrAncestorOfType<MethodDeclaration>() ??
      source.thisOrAncestorOfType<ConstructorDeclaration>();
  if (function == null) return;
  final analysis = capturesFor(source);
  final unit = source.thisOrAncestorOfType<CompilationUnit>();
  var inferenceUpdate4 = false;
  for (
    Token? comment = unit?.beginToken.precedingComments;
    comment != null;
    comment = comment.next
  ) {
    if (RegExp(
      r'^//\s*SharedOptions=.*--enable-experiment=inference-update-4(?:\s|,|$)',
    ).hasMatch(comment.lexeme)) {
      inferenceUpdate4 = true;
    }
  }
  for (final scope in ctx.locals) {
    for (final binding in scope.values) {
      final declaration = binding.captureDeclaration;
      if (declaration == null ||
          analysis.declaringFunctions[declaration] == function ||
          !analysis.assignedDeclarations.contains(declaration) ||
          binding.isFinal && inferenceUpdate4) {
        continue;
      }
      final current = binding.current;
      binding.rebind(
        current
            .withType(binding.declaredType)
            .withFacts(current.facts.cleared()),
      );
      binding.current.writeEpoch = current.writeEpoch + 1;
    }
  }
}

/// The action one branch edge takes with a proved promotion: [member] is
/// null for a local's own type, or the member name for a `x._f` member
/// promotion recorded on `x`'s binding facts.
typedef PromotionApply =
    void Function(Variable local, TypeRef type, String? member);

/// Records the local promotions that hold when [expression] has [value].
///
/// This intentionally covers only the promotion forms the compiler can prove
/// from one branch edge. Other expressions leave the local type unchanged.
void recordConditionPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value,
) {
  _visitPromotions(ctx, expression, value, (local, type, member) {
    local.inferType(ctx, type, member);
  });
}

/// Applies branch-local promotions while compiling a short-circuit operand.
void applyConditionPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value, {
  Set<String> excluded = const {},
}) {
  _visitPromotions(
    ctx,
    expression,
    value,
    (local, type, member) => _apply(ctx, local, type, member),
    excluded: excluded,
  );
}

/// The promotion action for live branches: rebind the local / attach the
/// member fact onto the receiver's binding.
void _apply(CompilerContext ctx, Variable local, TypeRef type, String? member) {
  if (member == null) {
    local.binding?.typesOfInterest.add(type);
    local.binding?.promote(type);
  } else {
    promoteMember(ctx, local, member, type);
  }
}

/// Promotes a local or promotable member (`c._f!`, `this._f!`) to its
/// non-null type — `e!` is a checked assertion, not a branch condition.
void promoteNonNull(
  CompilerContext ctx,
  Expression expression, {
  Set<String> excluded = const {},
}) => _promoteSlot(ctx, expression, null, (local, type, member) {
  _apply(ctx, local, type, member);
}, excluded);

/// Attaches member [member]'s promotion on [local]'s binding — the fact
/// rides on the receiver's value so it clears when `c` is reassigned and
/// joins at flow merges through [ValueFacts.join]. An unbound [local] is
/// an ephemeral cascade target (`getC().._f`): the fact is written onto
/// the ambient cascade variable itself.
void promoteMember(
  CompilerContext ctx,
  Variable local,
  String member,
  TypeRef type,
) {
  final binding = local.binding;
  if (binding == null) {
    if (identical(local, ctx.cascadeTarget)) {
      ctx.cascadeTarget = local.withFacts(
        local.facts.withPromotedMember(member, type),
      );
    }
    return;
  }
  binding.rebind(
    binding.current.withFacts(
      binding.current.facts.withPromotedMember(member, type),
    ),
  );
}

/// The promotions [expression] proves when it evaluates to true/false,
/// keyed by the promoted slot's name — `x` for a local, `x._f` for a
/// promotable member of a local. Used to implement promotion through
/// boolean variables (`bool b = x != null; if (b) ...`).
(Map<String, (TypeRef, int)> whenTrue, Map<String, (TypeRef, int)> whenFalse)
conditionPromotions(CompilerContext ctx, Expression expression) {
  final whenTrue = <String, (TypeRef, int)>{};
  final whenFalse = <String, (TypeRef, int)>{};
  PromotionApply collect(Map<String, (TypeRef, int)> map) =>
      (local, type, member) {
        // Keys must be binding (source) names — `local.name` is the SSA
        // register (`arg_0`), which `_applyRecorded` cannot resolve. The
        // epoch lets a later `x = ...` invalidate `b`'s record of `x`.
        final name = local.binding?.name ?? local.name;
        if (name.startsWith('#') &&
            (name != '#this' || !thisPromotionEnabled(ctx, expression))) {
          return;
        }
        map[member == null ? name : '$name.$member'] = (
          type,
          local.binding == null ? -1 : local.writeEpoch,
        );
      };
  _visitPromotions(ctx, expression, true, collect(whenTrue));
  _visitPromotions(ctx, expression, false, collect(whenFalse));
  return (whenTrue, whenFalse);
}

void _visitPromotions(
  CompilerContext ctx,
  Expression expression,
  bool value,
  PromotionApply promote, {
  Set<String> excluded = const {},
}) {
  _visitCompletedAssertionPromotions(ctx, expression, value, promote, excluded);
  if (expression is ParenthesizedExpression) {
    _visitPromotions(
      ctx,
      expression.expression,
      value,
      promote,
      excluded: excluded,
    );
    return;
  }
  if (expression is ConditionalExpression) {
    final paths = <Map<(String, String?), (Variable, TypeRef)>>[];
    for (final (outcome, arm) in [
      (true, expression.thenExpression),
      (false, expression.elseExpression),
    ]) {
      if (arm is BooleanLiteral && arm.value != value) continue;
      final proofs = <(String, String?), (Variable, TypeRef)>{};
      void collect(Variable local, TypeRef type, String? member) {
        final key = (local.binding?.name ?? local.name, member);
        final old = proofs[key];
        if (old == null || canPromoteTo(ctx, type, old.$2, expression)) {
          proofs[key] = (local, type);
        }
      }

      _visitPromotions(
        ctx,
        expression.condition,
        outcome,
        collect,
        excluded: {
          ...excluded,
          ...assignedLocalNames([arm]),
        },
      );
      _visitPromotions(ctx, arm, value, collect, excluded: excluded);
      paths.add(proofs);
    }
    if (paths.isNotEmpty) {
      for (final entry in paths.first.entries) {
        if (paths
            .skip(1)
            .every((path) => path[entry.key]?.$2 == entry.value.$2)) {
          promote(entry.value.$1, entry.value.$2, entry.key.$2);
        }
      }
    }
    return;
  }
  if (expression is AnonymousMethodInvocation &&
      expression.parameters == null &&
      expression.body is AnonymousExpressionBody) {
    final body = (expression.body as AnonymousExpressionBody).expression;
    final receiver = promotableMemberSlot(
      ctx,
      expression.realTarget,
      excluded: excluded,
    );
    final binding = receiver?.member == null ? receiver?.local.binding : null;
    if (binding != null && !assignedLocalNames([body]).contains(binding.name)) {
      ctx.beginScope();
      ctx.locals.last['#this'] = binding;
      try {
        _visitPromotions(ctx, body, value, promote, excluded: excluded);
      } finally {
        ctx.endScope();
      }
    }
    return;
  }
  if (expression is PrefixExpression && expression.operator.lexeme == '!') {
    _visitPromotions(
      ctx,
      expression.operand,
      !value,
      promote,
      excluded: excluded,
    );
    return;
  }
  // A bool local carries the condition it was assigned: `if (b)` applies
  // the recorded true-promotions, `if (!b)` the false ones.
  if (expression is SimpleIdentifier && !excluded.contains(expression.name)) {
    // A deferred initializer may run after any writes in the containing
    // function. Conditions whose local dependencies are never assigned
    // remain valid there; other dependencies must not promote.
    final body = ctx.lateInitializerDepth == 0
        ? null
        : expression.thisOrAncestorOfType<FunctionBody>();
    final deferredWrites = body == null
        ? const <String>{}
        : assignedLocalNames([body]);
    if (deferredWrites.contains(expression.name)) return;
    final binding = ctx.lookupBinding(expression.name);
    if (binding != null && !binding.writeCaptured) {
      final recorded = value
          ? binding.current.facts.truePromotions
          : binding.current.facts.falsePromotions;
      if (recorded != null) {
        for (final entry in recorded.entries) {
          _applyRecorded(
            ctx,
            expression,
            entry.key,
            entry.value,
            promote,
            deferredWrites.isEmpty
                ? excluded
                : {...excluded, ...deferredWrites},
          );
        }
      }
    }
    return;
  }
  if (expression is BinaryExpression) {
    final operator = expression.operator.lexeme;
    if ((operator == '&&' && value) || (operator == '||' && !value)) {
      _visitPromotions(
        ctx,
        expression.leftOperand,
        value,
        promote,
        excluded: {
          ...excluded,
          ...assignedLocalNames([expression.rightOperand]),
        },
      );
      _visitPromotions(
        ctx,
        expression.rightOperand,
        value,
        promote,
        excluded: excluded,
      );
      return;
    }
    final slot = switch ((expression.leftOperand, expression.rightOperand)) {
      (final Expression slot, NullLiteral()) => slot,
      (NullLiteral(), final Expression slot) => slot,
      _ => null,
    };
    if (slot != null &&
        ((operator == '!=' && value) || (operator == '==' && !value))) {
      _promoteSlot(ctx, slot, null, promote, excluded);
    }
    return;
  }
  if (!value &&
      expression is MethodInvocation &&
      _isCoreIdentical(ctx, expression)) {
    final arguments = expression.argumentList.arguments;
    if (arguments.length == 2) {
      final slot = switch ((arguments[0], arguments[1])) {
        (final Expression slot, NullLiteral()) => slot,
        (NullLiteral(), final Expression slot) => slot,
        _ => null,
      };
      if (slot != null) _promoteSlot(ctx, slot, null, promote, excluded);
    }
    return;
  }
  if (expression is IsExpression) {
    final tested = TypeRef.fromAnnotation(ctx, ctx.library, expression.type);
    final matches = expression.notOperator == null ? value : !value;
    if (!matches) {
      // A failed `is` check still registers the tested type as a type of
      // interest — `if (x is! S) { x = sValue }` promotes `x` to `S`.
      _promoteSlot(ctx, expression.expression, tested, (_, _, _) {}, excluded);
      final slot = promotableMemberSlot(
        ctx,
        expression.expression,
        excluded: excluded,
      );
      if (slot?.member == null &&
          slot?.local.binding?.name == '#this' &&
          slot!.local.type.nullable &&
          tested == slot.local.type.withNullable(false)) {
        promote(slot.local, CoreTypes.never.ref(ctx).withNullable(true), null);
      }
      return;
    }
    _promoteSlot(ctx, expression.expression, tested, promote, excluded);
    return;
  }
}

/// A checked assertion proves its type on normal completion, regardless of the
/// condition's result. Visit eager operands in order and intersect alternatives
/// so a skipped assertion or a later write never establishes a proof.
void _visitCompletedAssertionPromotions(
  CompilerContext ctx,
  Expression expression,
  bool? outcome,
  PromotionApply promote,
  Set<String> excluded,
) {
  void sequence(List<(Expression, bool?)> parts) {
    for (var i = 0; i < parts.length; i++) {
      _visitCompletedAssertionPromotions(
        ctx,
        parts[i].$1,
        parts[i].$2,
        promote,
        {
          ...excluded,
          ...assignedLocalNames(parts.skip(i + 1).map((part) => part.$1)),
        },
      );
    }
  }

  void alternatives(List<List<(Expression, bool?)>> paths) {
    final proofs = <Map<(String, String?), (Variable, TypeRef)>>[];
    for (final path in paths) {
      if (path.any(
        (part) =>
            part.$1 is ThrowExpression ||
            part.$1 is BooleanLiteral &&
                part.$2 != null &&
                (part.$1 as BooleanLiteral).value != part.$2,
      )) {
        continue;
      }
      final collected = <(String, String?), (Variable, TypeRef)>{};
      for (var i = 0; i < path.length; i++) {
        _visitCompletedAssertionPromotions(
          ctx,
          path[i].$1,
          path[i].$2,
          (local, type, member) {
            final key = (local.binding?.name ?? local.name, member);
            final previous = collected[key];
            if (previous == null ||
                canPromoteTo(ctx, type, previous.$2, expression)) {
              collected[key] = (local, type);
            }
          },
          {
            ...excluded,
            ...assignedLocalNames(path.skip(i + 1).map((part) => part.$1)),
          },
        );
      }
      proofs.add(collected);
    }
    if (proofs.isEmpty) return;
    for (final entry in proofs.first.entries) {
      if (proofs
          .skip(1)
          .every((path) => path[entry.key]?.$2 == entry.value.$2)) {
        promote(entry.value.$1, entry.value.$2, entry.key.$2);
      }
    }
  }

  if (expression is ParenthesizedExpression) {
    sequence([(expression.expression, outcome)]);
  } else if (expression is AsExpression) {
    sequence([(expression.expression, null)]);
    _promoteSlot(
      ctx,
      expression.expression,
      TypeRef.fromAnnotation(ctx, ctx.library, expression.type),
      promote,
      excluded,
    );
  } else if (expression is ConditionalExpression) {
    alternatives([
      [(expression.condition, true), (expression.thenExpression, outcome)],
      [(expression.condition, false), (expression.elseExpression, outcome)],
    ]);
  } else if (expression is BinaryExpression) {
    final left = expression.leftOperand;
    final right = expression.rightOperand;
    final operator = expression.operator.lexeme;
    if (operator == '&&' || operator == '||') {
      final continuing = operator == '&&';
      alternatives([
        if (outcome == null || outcome == !continuing) [(left, !continuing)],
        if (outcome == null || outcome == continuing)
          [(left, continuing), (right, continuing)],
        if (outcome == null || outcome == !continuing)
          [(left, continuing), (right, !continuing)],
      ]);
    } else if (operator == '??') {
      alternatives([
        [(left, null)],
        [(left, null), (right, outcome)],
      ]);
    } else {
      sequence([(left, null), (right, null)]);
    }
  } else if (expression is PropertyAccess && expression.target != null) {
    sequence([(expression.target!, null)]);
  } else if (expression is MethodInvocation) {
    sequence([
      if (expression.target != null) (expression.target!, null),
      if (!_hasNullShortingReceiver(expression))
        for (final argument in expression.argumentList.arguments)
          (argument.argumentExpression, null),
    ]);
  } else if (expression is PrefixExpression) {
    sequence([
      (
        expression.operand,
        expression.operator.lexeme == '!' && outcome != null ? !outcome : null,
      ),
    ]);
  } else if (expression is PostfixExpression) {
    sequence([(expression.operand, null)]);
    if (expression.operator.lexeme == '!') {
      _promoteSlot(ctx, expression.operand, null, promote, excluded);
    }
  } else if (expression is AssignmentExpression) {
    if (expression.operator.lexeme == '??=') return;
    _visitCompletedAssertionPromotions(
      ctx,
      expression.rightHandSide,
      null,
      promote,
      {
        ...excluded,
        ...assignedLocalNames([expression]),
      },
    );
  }
}

bool _hasNullShortingReceiver(Expression expression) => switch (expression) {
  MethodInvocation(:final isNullAware, :final target) ||
  PropertyAccess(
    :final isNullAware,
    :final target,
  ) => isNullAware || target != null && _hasNullShortingReceiver(target),
  IndexExpression(:final isNullAware, :final target) =>
    isNullAware || target != null && _hasNullShortingReceiver(target),
  _ => false,
};

bool _isCoreIdentical(CompilerContext ctx, MethodInvocation expression) {
  if (expression.methodName.name != 'identical' || expression.isCascaded) {
    return false;
  }
  try {
    final Denotation denotation;
    final target = expression.target;
    if (target == null) {
      denotation = resolveIdentifier(
        ctx,
        'identical',
        forSet: false,
        source: expression,
      );
    } else if (target is SimpleIdentifier) {
      final prefix = resolveIdentifier(
        ctx,
        target.name,
        forSet: false,
        source: target,
      );
      if (prefix is! PrefixDenotation) return false;
      denotation = prefix.memberAccess(
        ctx,
        'identical',
        forSet: false,
        source: expression,
      );
    } else {
      return false;
    }
    final library = switch (denotation) {
      FunctionDenotation(:final target) ||
      BridgeDenotation(:final target) => target.sourceLib,
      _ => null,
    };
    return library != null && library == ctx.libraryMap['dart:core'];
  } on CompileError {
    return false;
  }
}

/// Replays local and member proofs whose binding write epochs still match.
void replayRecordedPromotions(
  CompilerContext ctx,
  AstNode source,
  Map<String, (TypeRef, int)>? recorded,
) {
  for (final entry
      in recorded?.entries ?? const <MapEntry<String, (TypeRef, int)>>[]) {
    _applyRecorded(
      ctx,
      source,
      entry.key,
      entry.value,
      (local, type, member) => _apply(ctx, local, type, member),
      const {},
    );
  }
}

/// Applies a recorded condition entry — `x` promotes a local directly,
/// `x._f` promotes a member of `x`'s binding.
void _applyRecorded(
  CompilerContext ctx,
  AstNode source,
  String key,
  (TypeRef, int) recorded,
  PromotionApply promote,
  Set<String> excluded,
) {
  final dot = key.indexOf('.');
  final localName = dot < 0 ? key : key.substring(0, dot);
  if (excluded.contains(localName)) return;
  final binding = ctx.lookupBinding(localName);
  // A write to the receiver since `b` was recorded drops the promotion —
  // `bool b = c._o != null; c = c2; if (b)` leaves `c._o` unpromoted —
  // and a write-captured local is never promoted at all.
  if (binding == null ||
      binding.writeCaptured ||
      binding.current.writeEpoch != recorded.$2) {
    return;
  }
  final member = dot < 0 ? null : key.substring(dot + 1);
  final viaSuper = member?.startsWith('super:') ?? false;
  final current = member == null
      ? binding.current.type
      : promotedMemberReadType(
          ctx,
          binding.current,
          viaSuper ? member.substring(6) : member,
          viaSuper,
        );
  // A cached boolean can replay an older promotion over a newer one.
  // Sound flow analysis preserves the newer type for mutual subtypes.
  if (!canPromoteTo(ctx, recorded.$1, current, source)) {
    return;
  }
  promote(binding.current, recorded.$1, member);
}

/// The promotion slot [target] addresses — the local itself when
/// [member] is null, else a promotable member of a local/`this`/`super`
/// receiver. [member] is the plain member name; [viaSuper] distinguishes
/// `super._f` (its facts key is `super:`-prefixed at use sites).
typedef PromotionSlot = ({Variable local, String? member, bool viaSuper});

/// Resolves [target] to its promotion slot: a local variable, or a
/// promotable member of a local/`this`/`super` receiver (`c._f`,
/// `this._f`, bare `_f` in a class body, `super._f`). Returns null when
/// the target isn't a promotable slot.
///
/// Promotion applies through the binding — a cell/slot-backed local's
/// reads are materialized unbound copies, so `lookupLocal` would lose the
/// name and write epoch the record/apply logic relies on.
PromotionSlot? promotableMemberSlot(
  CompilerContext ctx,
  Expression target, {
  Set<String> excluded = const {},
}) {
  while (target is ParenthesizedExpression) {
    target = target.expression;
  }
  if (target is ThisExpression) {
    if (!thisPromotionEnabled(ctx, target)) return null;
    final binding = ctx.lookupBinding('#this');
    return binding == null ||
            binding.writeCaptured ||
            excluded.contains('#this')
        ? null
        : (local: binding.current, member: null, viaSuper: false);
  }
  if ((target is AssignmentExpression || target is PrefixExpression) &&
      inferenceUpdate4Enabled(target)) {
    final operand = switch (target) {
      AssignmentExpression(:final leftHandSide) => leftHandSide,
      PrefixExpression(:final operand, :final operator)
          when operator.lexeme == '++' || operator.lexeme == '--' =>
        operand,
      _ => null,
    };
    if (operand is SimpleIdentifier &&
        ctx.lookupBinding(operand.name) != null) {
      return promotableMemberSlot(ctx, operand, excluded: excluded);
    }
  }
  if (target is AnonymousMethodInvocation &&
      target.parameters == null &&
      target.body is AnonymousExpressionBody) {
    final expression = (target.body as AnonymousExpressionBody).expression;
    final receiver = target.realTarget;
    final source = promotableMemberSlot(ctx, receiver, excluded: excluded);
    final binding = source?.member == null ? source?.local.binding : null;
    if (binding == null ||
        assignedLocalNames([expression]).contains(binding.name)) {
      return null;
    }
    ctx.beginScope();
    ctx.locals.last['#this'] = binding;
    try {
      return promotableMemberSlot(ctx, expression, excluded: excluded);
    } finally {
      ctx.endScope();
    }
  }
  Expression? receiver;
  String? member;
  if (target is PropertyAccess &&
      (target.operator.type == TokenType.PERIOD ||
          target.isCascaded ||
          (target.operator.type == TokenType.QUESTION_PERIOD &&
              ctx.soundFlowAnalysis(target)))) {
    // A cascaded `.._f` has a null target — the receiver is the ambient
    // cascade variable.
    receiver = target.realTarget;
    member = target.propertyName.name;
  } else if (target is PrefixedIdentifier) {
    receiver = target.prefix;
    member = target.identifier.name;
  }

  LocalBinding? binding;
  if (member == null) {
    if (target is! SimpleIdentifier || excluded.contains(target.name)) {
      return null;
    }
    final name = target.name;
    binding = ctx.lookupBinding(name);
    // A write-captured local can be reassigned by any closure invocation,
    // so conditions never promote it.
    if (binding != null && binding.writeCaptured) {
      return null;
    }
    if (binding == null) {
      // A bare identifier that isn't a local can be an implicit-this
      // member (`_f` inside a class body) — it promotes like `this._f`.
      binding = ctx.lookupBinding('#this');
      if (binding == null ||
          binding.writeCaptured ||
          !isPromotableMember(ctx, binding.current.type, name, target)) {
        return null;
      }
      member = name;
    } else {
      return (local: binding.current, member: null, viaSuper: false);
    }
  } else {
    if (!member.startsWith('_')) return null;
    // `(c)._f` — parens don't change the receiver.
    while (receiver is ParenthesizedExpression) {
      receiver = receiver.expression;
    }
    if (receiver == null || (target is PropertyAccess && target.isCascaded)) {
      // Cascaded `.._f` — promote the ambient cascade target. A bound
      // target stores facts on its binding; an ephemeral target
      // (`getC().._f`) carries them on the variable itself.
      final cascade = ctx.cascadeTarget;
      if (cascade == null) return null;
      final bindingName = cascade.binding?.name;
      if (bindingName != null && excluded.contains(bindingName)) {
        return null;
      }
      if (!isPromotableMember(ctx, cascade.type, member, target)) {
        return null;
      }
      return (local: cascade, member: member, viaSuper: false);
    }
    final PromotionSlot? parent;
    if (receiver is ThisExpression || receiver is SuperExpression) {
      final self = ctx.lookupBinding('#this');
      parent =
          self == null || self.writeCaptured || excluded.contains(self.name)
          ? null
          : (
              local: self.current,
              member: null,
              viaSuper: receiver is SuperExpression,
            );
    } else {
      parent = promotableMemberSlot(ctx, receiver, excluded: excluded);
    }
    if (parent == null) return null;
    final owner = parent.member == null
        ? parent.local.type
        : promotedMemberReadType(
            ctx,
            parent.local,
            parent.member!,
            parent.viaSuper,
          );
    if (!isPromotableMember(ctx, owner, member, target)) {
      return null;
    }
    return (
      local: parent.local,
      member: parent.member == null ? member : '${parent.member}.$member',
      viaSuper: parent.viaSuper,
    );
  }
  return (local: binding.current, member: member, viaSuper: false);
}

/// A slot a condition can promote: a local variable, or a promotable
/// member of a local/`this`/`super` receiver (`c._f`, `this._f`, bare
/// `_f` in a class body, `super._f`).
void _promoteSlot(
  CompilerContext ctx,
  Expression target,
  TypeRef? tested,
  PromotionApply promote,
  Set<String> excluded,
) {
  final slot = promotableMemberSlot(ctx, target, excluded: excluded);
  if (slot == null) return;
  final local = slot.local;
  final member = slot.member;

  if (member == null) {
    // Local promotion.
    if (tested == null) {
      if (local.type.nullable) {
        promote(local, local.type.withNullable(false), null);
      }
      return;
    }
    // `x is S` narrows only when `S` is a subtype of the declared type —
    // an `is` check never widens a local to a type it can't represent.
    // The tested type joins the types of interest in *both* branches —
    // `if (x is! S) { x = valueOfS }` still promotes `x` to `S`.
    // A nullable tested type cannot promote a non-nullable local when
    // it is not a subtype of the local's current type.
    local.binding?.typesOfInterest.add(tested.withNullable(false));
    final promotedTo = canPromoteTo(ctx, tested, local.type, target)
        ? tested
        : null;
    if (promotedTo != null) {
      local.binding?.typesOfInterest.add(promotedTo);
      promote(local, promotionView(local.type, promotedTo), null);
    }
    return;
  }

  // Member promotion — the fact key distinguishes `super._f`.
  final memberKey = slot.viaSuper ? 'super:$member' : member;
  final memberType = promotedMemberReadType(ctx, local, member, slot.viaSuper);
  if (tested == null) {
    if (!memberType.nullable) return;
    promote(local, memberType.withNullable(false), memberKey);
    return;
  }
  if (canPromoteTo(ctx, tested, memberType, target)) {
    promote(local, promotionView(memberType, tested), memberKey);
  }
}

/// The `X & S` promotion view for a type-parameter slot: `x is S` narrows a
/// `X`-typed local to the intersection, which keeps `X`'s identity for
/// binding and equality while bound-aware consumers (flatten, member
/// lookup, subtype checks) see [promoted]. Non-parameter slots promote to
/// [promoted] directly.
TypeRef promotionView(TypeRef declared, TypeRef promoted) {
  if (declared is TypeParameterTypeRef &&
      !(promoted is TypeParameterTypeRef &&
          promoted.parameter == declared.parameter)) {
    return TypeParameterTypeRef(
      declared.parameter,
      nullable: declared.nullable && promoted.nullable,
      promotedBound: promoted,
    );
  }
  return promoted;
}

/// Whether [type] declares member [name] as a promotable slot: a private,
/// non-static, `final` non-`late` non-external field, or an abstract
/// getter (no implementation — it can't run user code that invalidates).
/// Field promotion ships with `inference-update-2` (Dart 3.2) — files
/// pinned below via `// @dart=` never promote members.
bool isPromotableMember(
  CompilerContext ctx,
  TypeRef type,
  String name,
  AstNode source,
) {
  if (!name.startsWith('_')) return false;
  if (!ctx.languageVersionAtLeast(source, 3, 2)) return false;
  if (extensionRepresentationField(ctx, type, name) != null) return true;
  // Field promotion is library-wide: any non-final field, concrete getter,
  // or method named `name` in the library disables it everywhere.
  if (ctx.promotionBlockers(ctx.library).contains(name)) return false;
  final resolved = ctx.memberLookup.tryInterfaceMember(
    type,
    MemberName(name, MemberKind.getter),
  );
  final member = resolved?.member;
  if (member is! SourceMember) return false;
  return switch (member.node) {
    // `late final` promotes too — its single-assignment slot can't change.
    FieldDeclaration node =>
      node.staticKeyword == null &&
          node.externalKeyword == null &&
          node.fields.isFinal,
    // A getter with no body is abstract — promotable.
    MethodDeclaration node =>
      node.isGetter && !node.isStatic && node.body is EmptyFunctionBody,
    _ => false,
  };
}

/// The type a member read reports: the recorded promotion on [local]'s
/// facts when one exists, else the member's declared type. [viaSuper]
/// selects the `super:`-namespaced slot for `super._f`.
TypeRef promotedMemberReadType(
  CompilerContext ctx,
  Variable local,
  String member, [
  bool viaSuper = false,
]) {
  final key = viaSuper ? 'super:$member' : member;
  // The binding's current value is authoritative when bound; an unbound
  // ephemeral (cascade target) carries facts on itself.
  final recorded =
      (local.binding?.current ?? local).facts.promotedMembers?[key];
  if (recorded != null) return recorded;
  final dot = member.lastIndexOf('.');
  final owner = dot < 0
      ? local.type
      : promotedMemberReadType(ctx, local, member.substring(0, dot), viaSuper);
  final name = dot < 0 ? member : member.substring(dot + 1);
  final representation = extensionRepresentationField(ctx, owner, name);
  if (representation != null) return representation;
  final resolved = ctx.memberLookup.tryInterfaceMember(
    owner,
    MemberName(name, MemberKind.getter),
  );
  return resolved?.fieldType ?? CoreTypes.dynamic.ref(ctx);
}

/// Whether [tested] narrows [current] for `is`-promotion — a subtype
/// check strict about function variance (the looser assignability used
/// for argument coercion treats all function types as compatible).
/// Dart 3.9 also requires a proper subtype, excluding mutual subtypes.
/// A type parameter remains distinct from its bound even when assignability
/// permits the reverse conversion through that bound.
bool canPromoteTo(
  CompilerContext ctx,
  TypeRef tested,
  TypeRef current,
  AstNode? source,
) =>
    isPromotionSubtype(ctx, tested, current) &&
    (!ctx.soundFlowAnalysis(source) ||
        tested.isTypeParameter && tested != current ||
        !isPromotionSubtype(ctx, current, tested));

bool isPromotionSubtype(CompilerContext ctx, TypeRef tested, TypeRef current) {
  // `x is C` where x is a type parameter produces the intersection `T&C`:
  // model it as the tested type — the value genuinely is a C afterwards.
  // `dynamic` narrows to whatever the test proves.
  if (current.isTypeParameter || current.isSpec(CoreTypes.dynamic)) {
    return true;
  }
  if (tested is! FunctionTypeRef || current is! FunctionTypeRef) {
    return tested.isAssignableTo(ctx, current, forceAllowDynamic: false);
  }
  final ts = tested.signature;
  final cs = current.signature;
  if (ts.typeParameters.isNotEmpty || cs.typeParameters.isNotEmpty) {
    return true;
  }
  // The tested signature must accept at least the calls [current]
  // accepts: no more required positionals, no fewer positionals, every
  // named parameter [current] declares, and contravariant parameter
  // types (covariant return).
  if (ts.requiredPositional > cs.requiredPositional ||
      ts.positional.length < cs.positional.length) {
    return false;
  }
  for (var i = 0; i < cs.positional.length; i++) {
    if (!cs.positional[i].isAssignableTo(
      ctx,
      ts.positional[i],
      forceAllowDynamic: false,
    )) {
      return false;
    }
  }
  for (final entry in cs.named.entries) {
    final param = ts.named[entry.key];
    if (param == null ||
        !entry.value.type.isAssignableTo(
          ctx,
          param.type,
          forceAllowDynamic: false,
        )) {
      return false;
    }
  }
  for (final entry in ts.named.entries) {
    if (entry.value.required && !cs.named.containsKey(entry.key)) {
      return false;
    }
  }
  return ts.returnType.isAssignableTo(ctx, cs.returnType);
}
