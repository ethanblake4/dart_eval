import 'package:dart_eval/dart_eval_bridge.dart' show BridgeTypeSpec;

import '../type.dart';

/// A function type — `R Function<P...>(positional..., {name: T...})`.
/// Replaces the legacy `EvalFunctionType` attached to a `Function`
/// interface ref. The `Function` declaration stays attached so
/// supertypes (`Function <: Object`) resolve as before.
final class FunctionTypeRef extends TypeRef {
  FunctionTypeRef(
    this.signature, {
    required TypeDecl decl,
    super.nullable = false,
  }) : super(decl.library, decl.name, decl: decl);

  final FunctionSignature signature;

  /// Migration compatibility: function types were `Function` refs with an
  /// attached signature, so `isSpec(CoreTypes.function)` stays true until
  /// every `Function` check is classified as `isBareFunction` or
  /// `isFunctionLike` and this override is removed.
  @override
  bool isSpec(BridgeTypeSpec spec) =>
      spec.name == 'Function' && spec.library == 'dart:core';
}

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
