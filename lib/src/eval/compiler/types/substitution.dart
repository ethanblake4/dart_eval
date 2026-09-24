import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;

import '../type.dart';

/// A substitution of type parameters by types, keyed by [TypeParameterDef].
/// Replaces the legacy `Map<(String, int), TypeRef>` keyed by
/// `(ownerString, index)` — defs are shared objects with the same key space.
final class Substitution {
  const Substitution._(this.bindings);

  static const empty = Substitution._({});

  /// An immutable substitution over a copy of [bindings] — accumulation
  /// into a shared map happens on a plain `Map<TypeParameterDef, TypeRef>`
  /// (e.g. `TypeSystem.unify`), then crosses the boundary here.
  factory Substitution.of(Map<TypeParameterDef, TypeRef> bindings) =>
      Substitution._(Map.unmodifiable(bindings));

  /// The declaration's parameters mapped to [type]'s arguments. Missing
  /// arguments use the bound, or `dynamic` when unbounded — the rule
  /// `appliedArguments` applies today.
  factory Substitution.forInterface(TypeRef type) {
    final decl = type.decl;
    final params = decl?.typeParameters ?? const <TypeParameterDef>[];
    if (params.isEmpty) {
      if (type.typeArguments.isEmpty) return empty;
      return Substitution._({
        for (var i = 0; i < type.typeArguments.length; i++)
          TypeParameterDef(
            TypeParameterOwner(
              TypeParameterOwnerKind.classLike,
              type.file,
              type.name,
            ),
            i,
            '',
          ): type.typeArguments[i],
      });
    }
    return Substitution._({
      for (var i = 0; i < params.length; i++)
        params[i]: i < type.typeArguments.length
            ? type.typeArguments[i]
            : (params[i].bound ?? CoreTypes.dynamic.ref(decl!.ctx)),
    });
  }

  final Map<TypeParameterDef, TypeRef> bindings;

  TypeRef? operator [](TypeParameterDef parameter) => bindings[parameter];

  bool get isEmpty => bindings.isEmpty;
  bool get isNotEmpty => bindings.isNotEmpty;

  /// Bindings of [other] win.
  Substitution extend(Substitution other) {
    if (bindings.isEmpty) return other;
    return Substitution._({...bindings, ...other.bindings});
  }

  /// Applies [outer] to every binding: composition along a supertype path.
  Substitution then(Substitution outer) => Substitution._({
    for (final entry in bindings.entries)
      entry.key: entry.value.substituteTypeParameters(outer),
  });
}
