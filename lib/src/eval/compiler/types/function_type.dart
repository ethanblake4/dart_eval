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

  /// Alpha-equivalent signatures share a key, but each nested binder gets
  /// its own parameter indices. Free parameters retain their declaration
  /// identity; bounds are part of the signature, not parameter identity.
  List<Object?> _key([Map<TypeParameterDef, int> outer = const {}]) {
    final bindings = typeParameters.isEmpty
        ? outer
        : {
            ...outer,
            for (var i = 0; i < typeParameters.length; i++)
              typeParameters[i]: outer.length + i,
          };
    return [
      requiredPositional,
      [for (final p in typeParameters) _typeKey(p.bound, bindings)],
      _typeKey(returnType, bindings),
      [for (final p in positional) _typeKey(p, bindings)],
      {
        for (final entry in named.entries)
          entry.key: [
            entry.value.required,
            _typeKey(entry.value.type, bindings),
          ],
      },
    ];
  }

  static Object? _typeKey(TypeRef? type, Map<TypeParameterDef, int> bindings) =>
      switch (type) {
        null => null,
        // Nominal leaves cannot refer to a binder. Reuse their existing
        // identity and cached hash instead of allocating a structural key.
        InterfaceTypeRef t when t.arguments.isEmpty => t,
        TypeParameterTypeRef t => [
          TypeParameterTypeRef,
          t.nullable,
          bindings[t.parameter] ?? t.parameter,
        ],
        InterfaceTypeRef t => [
          InterfaceTypeRef,
          t.file,
          t.name,
          t.nullable,
          [for (final argument in t.arguments) _typeKey(argument, bindings)],
        ],
        RecordTypeRef t => [
          RecordTypeRef,
          t.nullable,
          [for (final field in t.positional) _typeKey(field, bindings)],
          {
            for (final field in t.named.entries)
              field.key: _typeKey(field.value, bindings),
          },
        ],
        FunctionTypeRef t => [
          FunctionTypeRef,
          t.nullable,
          t.signature._key(bindings),
        ],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionSignature &&
          const DeepCollectionEquality().equals(_key(), other._key());

  @override
  int get hashCode => const DeepCollectionEquality().hash(_key());
}
