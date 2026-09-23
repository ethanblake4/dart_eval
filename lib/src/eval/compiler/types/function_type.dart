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

  /// Temporary structural key — equality on the signature's shape as the
  /// legacy `EvalFunctionType.semanticKey` produced it. Deleted when
  /// [TypeRef] equality flips structural in step 5.
  String semanticKey() {
    String parameter(int index) =>
        '${index < requiredPositional ? 1 : 0}:${positional[index].semanticKey}';
    final sortedNamed = named.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '(${[for (var i = 0; i < requiredPositional; i++) parameter(i)].join(',')})'
        '[${[for (var i = requiredPositional; i < positional.length; i++) parameter(i)].join(',')}]'
        '{${sortedNamed.map((entry) => '${entry.key}=${entry.value.required ? 1 : 0}:${entry.value.type.semanticKey}').join(',')}}'
        '->${returnType.semanticKey}'
        '<${typeParameters.map((value) => value.name).join(',')}>';
  }
}
