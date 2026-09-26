import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/compiler/variable/binding.dart';
import 'assigned_locals.dart';

/// The action one branch edge takes with a proved promotion: [member] is
/// null for a local's own type, or the member name for a `x._f` member
/// promotion recorded on `x`'s binding facts.
typedef PromotionApply = void Function(
  Variable local,
  TypeRef type,
  String? member,
);

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
  _visitPromotions(ctx, expression, value, _apply, excluded: excluded);
}

/// The promotion action for live branches: rebind the local / attach the
/// member fact onto the receiver's binding.
void _apply(Variable local, TypeRef type, String? member) {
  if (member == null) {
    local.binding?.typesOfInterest.add(type);
    final promoted = local.withType(type);
    promoted.binding?.rebind(promoted);
  } else {
    promoteMember(local, member, type);
  }
}

/// Promotes a local or promotable member (`c._f!`, `this._f!`) to its
/// non-null type — `e!` is a checked assertion, not a branch condition.
void promoteNonNull(CompilerContext ctx, Expression expression) =>
    _promoteSlot(ctx, expression, null, _apply, const {});

/// Attaches member [member]'s promotion on [local]'s binding — the fact
/// rides on the receiver's value so it clears when `c` is reassigned and
/// joins at flow merges through [ValueFacts.join].
void promoteMember(Variable local, String member, TypeRef type) {
  final binding = local.binding;
  if (binding == null) return;
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
        if (name.startsWith('#')) return;
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
  if (expression is SimpleIdentifier &&
      !excluded.contains(expression.name)) {
    final binding = ctx.lookupBinding(expression.name);
    if (binding != null && !binding.writeCaptured) {
      final recorded = value
          ? binding.current.facts.truePromotions
          : binding.current.facts.falsePromotions;
      if (recorded != null) {
        for (final entry in recorded.entries) {
          _applyRecorded(ctx, entry.key, entry.value, promote, excluded);
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
    final slot = switch ((
      expression.leftOperand,
      expression.rightOperand,
    )) {
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
  if (expression is IsExpression) {
    final tested = TypeRef.fromAnnotation(ctx, ctx.library, expression.type);
    final matches = expression.notOperator == null ? value : !value;
    if (!matches) {
      // A failed `is` check still registers the tested type as a type of
      // interest — `if (x is! S) { x = sValue }` promotes `x` to `S`.
      _promoteSlot(ctx, expression.expression, tested, (_, _, _) {}, excluded);
      return;
    }
    _promoteSlot(ctx, expression.expression, tested, promote, excluded);
    return;
  }
}

/// Applies a recorded condition entry — `x` promotes a local directly,
/// `x._f` promotes a member of `x`'s binding.
void _applyRecorded(
  CompilerContext ctx,
  String key,
  (TypeRef, int) recorded,
  PromotionApply promote,
  Set<String> excluded,
) {
  final dot = key.lastIndexOf('.');
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
  promote(binding.current, recorded.$1, dot < 0 ? null : key.substring(dot + 1));
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
  Expression? receiver;
  String? member;
  var viaSuper = false;
  if (target is PropertyAccess && target.operator.type == TokenType.PERIOD) {
    receiver = target.realTarget;
    member = target.propertyName.name;
  } else if (target is PrefixedIdentifier) {
    receiver = target.prefix;
    member = target.identifier.name;
  }

  // Promotion applies through the binding — a cell/slot-backed local's
  // reads are materialized unbound copies, so `lookupLocal` would lose the
  // name and write epoch the record/apply logic relies on.
  LocalBinding? binding;
  String? memberKey;
  if (member == null) {
    if (target is! SimpleIdentifier || excluded.contains(target.name)) {
      return;
    }
    final name = target.name;
    binding = ctx.lookupBinding(name);
    // A write-captured local can be reassigned by any closure invocation,
    // so conditions never promote it.
    if (binding != null && binding.writeCaptured) {
      return;
    }
    if (binding == null) {
      // A bare identifier that isn't a local can be an implicit-this
      // member (`_f` inside a class body) — it promotes like `this._f`.
      binding = ctx.lookupBinding('#this');
      if (binding == null ||
          binding.writeCaptured ||
          !isPromotableMember(ctx, binding.current.type, name)) {
        return;
      }
      member = name;
      memberKey = name;
    }
  } else {
    if (!member.startsWith('_')) return;
    // `(c)._f` — parens don't change the receiver.
    while (receiver is ParenthesizedExpression) {
      receiver = receiver.expression;
    }
    switch (receiver) {
      case SimpleIdentifier(:final name):
        binding = ctx.lookupBinding(name);
        memberKey = member;
      case ThisExpression():
        binding = ctx.lookupBinding('#this');
        memberKey = member;
      case SuperExpression():
        binding = ctx.lookupBinding('#this');
        memberKey = 'super:$member';
        viaSuper = true;
      default:
        return;
    }
    if (binding == null ||
        binding.writeCaptured ||
        excluded.contains(binding.name)) {
      return;
    }
    if (!isPromotableMember(ctx, binding.current.type, member)) return;
  }
  final local = binding.current;

  if (memberKey == null) {
    // Local promotion.
    if (tested == null) {
      if (local.type.nullable) {
        promote(local, local.type.withNullable(false), null);
      }
      return;
    }
    // `x is S` narrows only when `S` is a subtype of the declared type —
    // an `is` check never widens a local to a type it can't represent.
    if (isPromotionSubtype(ctx, tested, local.type)) {
      // The tested type joins the types of interest in *both* branches —
      // `if (x is! S) { x = valueOfS }` still promotes `x` to `S`.
      local.binding?.typesOfInterest.add(tested);
      promote(local, tested, null);
    }
    return;
  }

  // Member promotion — the fact key distinguishes `super._f`.
  final memberType = promotedMemberReadType(ctx, local, member!, viaSuper);
  if (tested == null) {
    if (!memberType.nullable) return;
    promote(local, memberType.withNullable(false), memberKey);
    return;
  }
  if (isPromotionSubtype(ctx, tested, memberType)) {
    promote(local, tested, memberKey);
  }
}

/// Whether [type] declares member [name] as a promotable slot: a private,
/// non-static, `final` non-`late` non-external field, or an abstract
/// getter (no implementation — it can't run user code that invalidates).
bool isPromotableMember(CompilerContext ctx, TypeRef type, String name) {
  if (!name.startsWith('_')) return false;
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
  final recorded = local.binding?.current.facts.promotedMembers?[key];
  if (recorded != null) return recorded;
  final resolved = ctx.memberLookup.tryInterfaceMember(
    local.type,
    MemberName(member, MemberKind.getter),
  );
  return resolved?.fieldType ?? CoreTypes.dynamic.ref(ctx);
}

/// Whether [tested] narrows [current] for `is`-promotion — a subtype
/// check strict about function variance (the looser assignability used
/// for argument coercion treats all function types as compatible).
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
