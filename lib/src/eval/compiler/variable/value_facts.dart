import 'package:dart_eval/src/eval/compiler/type.dart';

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
    this.isConst = false,
    this.isConstInt = false,
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

  /// Whether this value is the result of a compile-time-constant
  /// expression — a literal or a `const`-declared binding.
  final bool isConst;

  /// Whether this value is an integer literal or compile-time constant int
  /// expression — enables the `int → double` literal coercion.
  final bool isConstInt;

  /// Copies scalar markers and possible classes. Nullable denotation facts
  /// stay unchanged; replace the whole object when a value is overwritten.
  ValueFacts copyWith({
    List<TypeRef>? possibleClasses,
    bool? isConst,
    bool? isConstInt,
  }) => ValueFacts(
    exact: exact,
    possibleClasses: possibleClasses ?? this.possibleClasses,
    denotedType: denotedType,
    isConst: isConst ?? this.isConst,
    isConstInt: isConstInt ?? this.isConstInt,
  );

  /// Facts for a merged value: [exact] survives only when both inputs
  /// agree, [possibleClasses] unions only when both are known, and the
  /// const markers require both.
  ValueFacts join(ValueFacts other) => ValueFacts(
    exact: other.exact == exact ? exact : null,
    possibleClasses: possibleClasses.isEmpty || other.possibleClasses.isEmpty
        ? const []
        : {...possibleClasses, ...other.possibleClasses}.toList(),
    denotedType: other.denotedType == denotedType ? denotedType : null,
    isConst: isConst && other.isConst,
    isConstInt: isConstInt && other.isConstInt,
  );

  /// Facts that survive a value change — nothing. Mirrors `widened`.
  ValueFacts cleared() => const ValueFacts();

  /// Facts for the form a value takes once bound to a local: the const-int
  /// literal marker never survives binding (only literal expressions
  /// coerce `int → double`), everything else does.
  ValueFacts forBinding() => isConstInt ? copyWith(isConstInt: false) : this;
}
