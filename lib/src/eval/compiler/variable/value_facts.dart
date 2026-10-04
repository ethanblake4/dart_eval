import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';

/// Compile-time facts known about the value a [Variable] holds: what its
/// runtime type provably is, what it denotes, and whether it is constant.
///
/// Allocation proofs ([exact], [possibleClasses]) justify devirtualization;
/// they are dropped by [cleared] when the value can be replaced (e.g. an
/// SSA merge or a captured-cell round trip).
final class ValueFacts {
  const ValueFacts({
    this.exact,
    this.possibleClasses = const [],
    this.denotedType,
    this.callableSignature,
    this.nullShortedType,
    this.nullShortedPromotions,
    this.isConst = false,
    this.isConstInt = false,
    this.constBool,
    this.promotedMembers,
    this.promotionHistory,
    this.memberPromotionHistory,
    this.truePromotions,
    this.falsePromotions,
    this.conditionPromotionOrigin,
  });

  static const none = ValueFacts();

  /// The exact runtime type of the value, when it is provably exactly this
  /// type (set at allocation sites: literals, constructor calls). Unlike
  /// [possibleClasses], an exact type can never be a subclass instance, so
  /// it justifies devirtualization even for classes that are subclassed.
  final TypeRef? exact;

  /// The possible runtime classes of the value; empty means unknown.
  final List<TypeRef> possibleClasses;

  /// For a `Type`-typed value, the type it denotes (type literals, type
  /// parameter values).
  final TypeRef? denotedType;

  /// A runtime callable's known signature, including bridge return rules.
  /// Retained when its static type is widened to `Function` or `dynamic`.
  final CallSignature? callableSignature;

  /// The selector's type on the executed path of a null-shorted chain,
  /// before the skipped path adds null. Only chain continuations use it;
  /// binding the expression or joining unrelated values discards it.
  final TypeRef? nullShortedType;

  /// Local and member proofs on the executed path of a null-shorted chain.
  /// Epochs prevent a later receiver write from reviving an earlier proof.
  final Map<String, (TypeRef, int)>? nullShortedPromotions;

  /// Whether this value is the result of a compile-time-constant
  /// expression — a literal or a `const`-declared binding.
  final bool isConst;

  /// Whether this value is an integer literal or compile-time constant int
  /// expression — enables the `int → double` literal coercion.
  final bool isConstInt;

  /// The compile-time-known value of a constant `bool` — set on `true`/`false`
  /// literals and on expressions the compiler statically folds to a bool
  /// (`x is T` on provably disjoint types). Lets condition emission mark the
  /// never-taken edge unreachable so its writes don't join the flow state.
  final bool? constBool;

  /// Promoted types of promotable members *of this object* — `c._f` where
  /// `_f` is a private final field. Keys include nested member paths; each value
  /// is the promoted type the member read currently reports. Absent = none.
  final Map<String, TypeRef>? promotedMembers;

  /// Ordered narrowing proofs. Null avoids allocating for unpromoted locals;
  /// an empty history records that a join discarded all explicit proofs.
  final List<TypeRef>? promotionHistory;
  final Map<String, List<TypeRef>>? memberPromotionHistory;

  /// For a bool-typed value that recorded a condition expression
  /// (`bool b = x != null`): the local promotions that hold when the value
  /// is true / false — the "promotion through boolean variables" rule.
  /// Keys are local binding names (`x`, `x._f`); each entry pairs the
  /// promoted type with the receiver binding's write epoch, so writing
  /// `x` invalidates the record (`b` no longer promotes `x`).
  final Map<String, (TypeRef, int)>? truePromotions;

  /// See [truePromotions].
  final Map<String, (TypeRef, int)>? falsePromotions;

  /// Distinguishes separately evaluated conditions with equivalent proofs.
  /// Copies retain this identity; control-flow joins cannot invent one.
  final Object? conditionPromotionOrigin;

  /// Copies scalar markers and possible classes. Nullable denotation facts
  /// stay unchanged; replace the whole object when a value is overwritten.
  ValueFacts copyWith({
    List<TypeRef>? possibleClasses,
    bool? isConst,
    bool? isConstInt,
    bool? constBool,
    bool clearConstBool = false,
    Map<String, TypeRef>? promotedMembers,
    List<TypeRef>? promotionHistory,
    Map<String, List<TypeRef>>? memberPromotionHistory,
    bool replacePromotionHistory = false,
    Map<String, (TypeRef, int)>? truePromotions,
    Map<String, (TypeRef, int)>? falsePromotions,
    TypeRef? nullShortedType,
    Map<String, (TypeRef, int)>? nullShortedPromotions,
  }) => ValueFacts(
    exact: exact,
    possibleClasses: possibleClasses ?? this.possibleClasses,
    denotedType: denotedType,
    callableSignature: callableSignature,
    nullShortedType: nullShortedType ?? this.nullShortedType,
    nullShortedPromotions: nullShortedPromotions ?? this.nullShortedPromotions,
    isConst: isConst ?? this.isConst,
    isConstInt: isConstInt ?? this.isConstInt,
    constBool: clearConstBool ? null : constBool ?? this.constBool,
    promotedMembers: promotedMembers ?? this.promotedMembers,
    promotionHistory: replacePromotionHistory
        ? promotionHistory
        : promotionHistory ?? this.promotionHistory,
    memberPromotionHistory: replacePromotionHistory
        ? memberPromotionHistory
        : memberPromotionHistory ?? this.memberPromotionHistory,
    truePromotions: truePromotions ?? this.truePromotions,
    falsePromotions: falsePromotions ?? this.falsePromotions,
    conditionPromotionOrigin: truePromotions != null || falsePromotions != null
        ? Object()
        : conditionPromotionOrigin,
  );

  /// Facts for a merged value: [exact] survives only when both inputs
  /// agree, [possibleClasses] unions only when both are known, and the
  /// const markers require both. Member promotions and recorded conditions
  /// retain shared proofs from their promotion histories; recorded conditions
  /// survive only when both edges agree on the same entry.
  ValueFacts join(ValueFacts other) {
    final sameCondition = identical(
      conditionPromotionOrigin,
      other.conditionPromotionOrigin,
    );
    final memberHistories = joinMemberHistories(other);
    var members = _joinMaps(promotedMembers, other.promotedMembers);
    for (final entry
        in memberHistories?.entries ??
            const <MapEntry<String, List<TypeRef>>>[]) {
      if (entry.value.isEmpty) {
        members?.remove(entry.key);
      } else {
        (members ??= {})[entry.key] = entry.value.last;
      }
    }
    return ValueFacts(
      exact: other.exact == exact ? exact : null,
      possibleClasses: possibleClasses.isEmpty || other.possibleClasses.isEmpty
          ? const []
          : {...possibleClasses, ...other.possibleClasses}.toList(),
      denotedType: other.denotedType == denotedType ? denotedType : null,
      callableSignature: other.callableSignature == callableSignature
          ? callableSignature
          : null,
      isConst: isConst && other.isConst,
      isConstInt: isConstInt && other.isConstInt,
      constBool: constBool == other.constBool ? constBool : null,
      promotedMembers: members,
      promotionHistory:
          promotionHistory == null && other.promotionHistory == null
          ? null
          : intersectHistories(promotionHistory, other.promotionHistory),
      memberPromotionHistory: memberHistories,
      truePromotions: sameCondition
          ? _joinMaps(truePromotions, other.truePromotions)
          : null,
      falsePromotions: sameCondition
          ? _joinMaps(falsePromotions, other.falsePromotions)
          : null,
      conditionPromotionOrigin: sameCondition ? conditionPromotionOrigin : null,
    );
  }

  static List<TypeRef> intersectHistories(List<TypeRef>? a, List<TypeRef>? b) =>
      List.unmodifiable([
        for (final type in a ?? const <TypeRef>[])
          if (b?.contains(type) ?? false) type,
      ]);

  Map<String, List<TypeRef>>? joinMemberHistories(ValueFacts other) {
    if (memberPromotionHistory == null &&
        other.memberPromotionHistory == null) {
      return null;
    }
    return Map.unmodifiable({
      for (final key in {
        ...?memberPromotionHistory?.keys,
        ...?other.memberPromotionHistory?.keys,
      })
        key: intersectHistories(
          memberPromotionHistory?[key],
          other.memberPromotionHistory?[key],
        ),
    });
  }

  ValueFacts withPromotion(TypeRef type) =>
      copyWith(promotionHistory: appendPromotion(promotionHistory, type));

  static List<TypeRef> appendPromotion(List<TypeRef>? history, TypeRef type) =>
      history != null && history.isNotEmpty && history.last == type
      ? history
      : List.unmodifiable([...?history, type]);

  static Map<String, V>? _joinMaps<V>(Map<String, V>? a, Map<String, V>? b) {
    if (a == null || b == null) return null;
    final result = <String, V>{};
    for (final entry in a.entries) {
      if (b[entry.key] == entry.value) result[entry.key] = entry.value;
    }
    return result.isEmpty ? null : result;
  }

  /// This value's facts with member [name] promoted to [type].
  ValueFacts withPromotedMember(String name, TypeRef type) => copyWith(
    promotedMembers: {...?promotedMembers, name: type},
    memberPromotionHistory: Map.unmodifiable({
      ...?memberPromotionHistory,
      name: appendPromotion(memberPromotionHistory?[name], type),
    }),
  );

  /// No facts survive an unknown value change, including callable signatures.
  ValueFacts cleared() => const ValueFacts();

  /// Facts for the form a value takes once bound to a local: the const
  /// literal markers (`isConstInt`, `constBool`) never survive binding (only
  /// literal expressions coerce `int → double` or carry a known bool value),
  /// member promotions do not transfer across objects (`c2 = c` must not
  /// carry `c`'s field facts onto `c2`), and recorded conditions attach to
  /// the local they were assigned into — `b2 = b` does not make `b2` a
  /// condition carrier.
  ValueFacts forBinding() => ValueFacts(
    exact: exact,
    possibleClasses: possibleClasses,
    denotedType: denotedType,
    callableSignature: callableSignature,
    isConst: isConst,
  );
}
