import 'package:collection/collection.dart';

import '../type.dart';

/// The structural shape of a function type: positional parameter types
/// (required first), named parameter types, return type, and the
/// signature's own type parameters. Positional parameter names are not
/// part of the type (`typedef void F(int x)` equals `void Function(int)`).
final class FunctionSignature {
  const FunctionSignature({
    this.typeParameters = const [],
    required this.positional,
    required this.requiredPositional,
    this.named = const {},
    required this.returnType,
  });

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionSignature &&
          requiredPositional == other.requiredPositional &&
          returnType == other.returnType &&
          const ListEquality<TypeParameterDef>().equals(
            typeParameters,
            other.typeParameters,
          ) &&
          const ListEquality<TypeRef>().equals(positional, other.positional) &&
          const MapEquality<String, ({TypeRef type, bool required})>().equals(
            named,
            other.named,
          );

  @override
  int get hashCode => Object.hash(
    requiredPositional,
    returnType,
    Object.hashAll(typeParameters),
    Object.hashAll(positional),
    Object.hashAllUnordered(
      named.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
