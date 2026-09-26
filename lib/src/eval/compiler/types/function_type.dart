import 'package:collection/collection.dart';

import '../type.dart';

/// The structural shape of a function type: positional parameter types
/// (required first), named parameter types, return type, and the
/// signature's own type parameters. Positional parameter names are not
/// part of the type (`typedef void F(int x)` equals `void Function(int)`).
final class FunctionSignature {
  FunctionSignature({
    List<TypeParameterDef> typeParameters = const [],
    required List<TypeRef> positional,
    required this.requiredPositional,
    Map<String, ({TypeRef type, bool required})> named = const {},
    required this.returnType,
  }) : typeParameters = List.unmodifiable(typeParameters),
       positional = List.unmodifiable(positional),
       named = Map.unmodifiable(named);

  /// The signature's own type parameters (`R Function<T>(T x)`). Refs to
  /// them are owned by this signature — see [TypeParameterOwnerKind].
  final List<TypeParameterDef> typeParameters;

  /// Positional parameter types: the first [requiredPositional] are
  /// required, the rest optional.
  final List<TypeRef> positional;

  final int requiredPositional;

  /// Named parameter types and whether each is required.
  final Map<String, ({TypeRef type, bool required})> named;

  final TypeRef returnType;

  /// Type equality is alpha-insensitive — `X Function<X>` and
  /// `Y Function<Y>` are the same type — so equality and hashing normalize
  /// signature-bound parameters to owner-independent defs. The owner uses
  /// a negative position, which no real source offset can collide with.
  static TypeParameterDef _eqDef(int index) => TypeParameterDef(
    TypeParameterOwner(
      TypeParameterOwnerKind.scope,
      -1,
      '<signature>',
      -1 - index,
    ),
    index,
    '<sig#$index>',
  );

  Substitution get _eqSubstitution => Substitution.of({
    for (var i = 0; i < typeParameters.length; i++)
      typeParameters[i]: TypeParameterTypeRef(_eqDef(i)),
  });

  TypeRef _normalize(TypeRef type, Substitution substitution) =>
      typeParameters.isEmpty ? type : type.substituteTypeParameters(substitution);

  Iterable<TypeRef> _normalized(
    List<TypeRef> types,
    Substitution substitution,
  ) => typeParameters.isEmpty
      ? types
      : types.map((type) => type.substituteTypeParameters(substitution));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FunctionSignature ||
        requiredPositional != other.requiredPositional ||
        typeParameters.length != other.typeParameters.length) {
      return false;
    }
    final subst = _eqSubstitution;
    final otherSubst = other._eqSubstitution;
    if (_normalize(returnType, subst) !=
        _normalize(other.returnType, otherSubst)) {
      return false;
    }
    if (!const ListEquality<TypeRef>().equals(
      _normalized(positional, subst).toList(growable: false),
      _normalized(other.positional, otherSubst).toList(growable: false),
    )) {
      return false;
    }
    if (named.length != other.named.length) return false;
    for (final entry in named.entries) {
      final o = other.named[entry.key];
      if (o == null ||
          o.required != entry.value.required ||
          _normalize(entry.value.type, subst) !=
              _normalize(o.type, otherSubst)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    final subst = _eqSubstitution;
    return Object.hash(
      requiredPositional,
      typeParameters.length,
      _normalize(returnType, subst),
      Object.hashAll(_normalized(positional, subst)),
      Object.hashAllUnordered(
        named.entries.map(
          (e) => Object.hash(
            e.key,
            _normalize(e.value.type, subst),
            e.value.required,
          ),
        ),
      ),
    );
  }
}
