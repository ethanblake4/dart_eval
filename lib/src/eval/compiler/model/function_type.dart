import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Builds a [FunctionSignature] from a bridge function definition. Bridge
/// generic names that are not in scope become [TypeParameterTypeRef]s
/// owned by the signature itself.
FunctionSignature functionSignatureFromBridgeFunctionDef(
  CompilerContext ctx,
  BridgeFunctionDef def, {
  Map<String, TypeRef> typeParameters = const {},
}) {
  final owner = TypeParameterOwner(
    TypeParameterOwnerKind.functionTypeAnnotation,
    -1,
    '',
    def.hashCode,
  );
  final genericEntries = def.generics.entries.toList();
  final ownDefs = <TypeParameterDef>[
    for (final (index, entry) in genericEntries.indexed)
      TypeParameterDef(owner, index, entry.key),
  ];
  for (final (index, entry) in genericEntries.indexed) {
    final bound = entry.value.$extends;
    ownDefs[index].bound = bound == null
        ? null
        : TypeRef.fromBridgeTypeRef(ctx, bound);
  }
  final scope = <String, TypeRef>{
    ...typeParameters,
    for (final def0 in ownDefs) def0.name: TypeParameterTypeRef(def0),
  };
  // Forward-referenced names outside the declared generics still need a
  // def — hand out fresh indices beyond the declared range, cached so the
  // same name maps to the same parameter within this signature.
  final extraDefs = <String, TypeParameterDef>{};
  TypeParameterDef extraDef(String name) =>
      extraDefs[name] ??= TypeParameterDef(
        owner,
        ownDefs.length + extraDefs.length,
        name,
      );

  TypeRef resolve(BridgeTypeAnnotation annotation) {
    final type = annotation.type;
    if (type.ref != null) {
      final resolved = scope[type.ref];
      if (resolved != null) {
        return resolved.copyWith(nullable: annotation.nullable);
      }
      return TypeParameterTypeRef(extraDef(type.ref!));
    }
    return TypeRef.fromBridgeAnnotation(
      ctx,
      annotation,
      typeParameters: scope,
    );
  }

  final positional = <TypeRef>[];
  var requiredPositional = 0;
  final named = <String, ({TypeRef type, bool required})>{};
  for (final param in def.params) {
    final type = resolve(param.type);
    if (param.optional) {
      positional.add(type);
    } else {
      positional.insert(requiredPositional, type);
      requiredPositional++;
    }
  }
  for (final param in def.namedParams) {
    named[param.name] = (
      type: resolve(param.type),
      required: !param.optional,
    );
  }
  return FunctionSignature(
    typeParameters: ownDefs,
    positional: positional,
    requiredPositional: requiredPositional,
    named: named,
    returnType: resolve(def.returns),
  );
}

/// Shared builder for a function type from its parts — a
/// [GenericFunctionType] annotation, or the legacy function-typed formal
/// parameter syntax `R f<P>(args)` whose parts live on a
/// [FunctionTypedFormalParameterSuffix]. [owner] keys the type's own
/// parameters so re-resolving the same source stays canonical.
FunctionSignature functionSignatureFromParts(
  CompilerContext ctx,
  int library, {
  required TypeAnnotation? returnType,
  required TypeParameterList? typeParameterList,
  required FormalParameterList? parameterList,
  required TypeParameterOwner owner,
  Map<String, TypeRef> typeParameters = const {},
}) {
  // The function type's own type parameters (`Function<A>(A x)`) are
  // resolvable inside its bounds, parameters, and return type, and shadow
  // outer type parameters. Bounds resolve in a second pass so F-bounds
  // (`T extends Foo<T>`) self-reference the already-seeded parameter.
  final ownParams =
      typeParameterList?.typeParameters ?? const <TypeParameter>[];
  final allTypeParams = <String, TypeRef>{...typeParameters};
  final ownDefs = declareTypeParameters(owner, ownParams, allTypeParams, (
    bound,
  ) {
    return TypeRef.fromAnnotation(
      ctx,
      library,
      bound,
      typeParameters: allTypeParams,
    );
  });

  TypeRef resolve(TypeAnnotation? type) => type == null
      ? CoreTypes.dynamic.ref(ctx)
      : TypeRef.fromAnnotation(
          ctx,
          library,
          type,
          typeParameters: allTypeParams,
        );

  final parameters =
      parameterList?.parameters ?? const <FormalParameter>[];
  final positional = <TypeRef>[
    for (final parameter in parameters)
      if (parameter.isPositional && parameter.isRequired)
        resolve(parameter.type),
    for (final parameter in parameters)
      if (parameter.isPositional && !parameter.isRequired)
        resolve(parameter.type),
  ];
  final requiredPositional = parameters
      .where((p) => p.isPositional && p.isRequired)
      .length;
  final named = <String, ({TypeRef type, bool required})>{
    for (final parameter in parameters)
      if (parameter.isNamed)
        parameter.name!.lexeme: (
          type: resolve(parameter.type),
          required: parameter.isRequired,
        ),
  };
  return FunctionSignature(
    typeParameters: ownDefs,
    positional: positional,
    requiredPositional: requiredPositional,
    named: named,
    returnType: resolve(returnType),
  );
}

/// Builds the function type declared by a [GenericFunctionType] annotation.
FunctionTypeRef functionTypeFromAnnotation(
  CompilerContext ctx,
  int library,
  GenericFunctionType annotation, {
  Map<String, TypeRef> typeParameters = const {},
}) {
  return FunctionTypeRef(
    functionSignatureFromParts(
      ctx,
      library,
      returnType: annotation.returnType,
      typeParameterList: annotation.typeParameters,
      parameterList: annotation.parameters,
      owner: TypeParameterOwner(
        TypeParameterOwnerKind.functionTypeAnnotation,
        library,
        '',
        annotation.offset,
      ),
      typeParameters: typeParameters,
    ),
    decl: ctx.types.bySpec(CoreTypes.function),
    nullable: annotation.question != null,
  );
}

/// Builds the structural callable type declared by a function or method.
/// Generic callables produce a [FunctionTypeRef] whose signature owns its own
/// type parameters; [ownTypeParameterOwner] keys those parameters so the same
/// declaration read from the same position keeps identical parameter identities
/// (a tear-off's owner differs from the body's — see [TypeParameterOwnerKind]).
TypeRef declaredFunctionType(
  CompilerContext ctx,
  int library,
  FormalParameterList? parameters,
  TypeAnnotation? returnType,
  TypeParameterList? typeParameters, {
  // The enclosing class's type parameters, name-keyed — a method's
  // signature resolves them (`MapBase<K, V>.remove` sees `K`).
  Map<String, TypeRef> memberTypeParameters = const {},
  TypeParameterOwner? ownTypeParameterOwner,
}) {
  if (typeParameters != null && typeParameters.typeParameters.isNotEmpty) {
    return FunctionTypeRef(
      functionSignatureFromParts(
        ctx,
        library,
        returnType: returnType,
        typeParameterList: typeParameters,
        parameterList: parameters,
        owner: ownTypeParameterOwner ??
            TypeParameterOwner(
              TypeParameterOwnerKind.function,
              library,
              '',
            ),
        typeParameters: memberTypeParameters,
      ),
      decl: ctx.types.bySpec(CoreTypes.function),
    );
  }

  TypeRef parameterType(FormalParameter parameter) {
    final annotation = parameter.type;
    return annotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : formalParameterAnnotationType(
            ctx,
            library,
            parameter,
            typeParameters: memberTypeParameters,
          );
  }

  final all = parameters?.parameters ?? const <FormalParameter>[];
  return FunctionTypeRef(
    FunctionSignature(
      positional: [
        for (final parameter in all)
          if (parameter.isPositional && parameter.isRequired)
            parameterType(parameter),
        for (final parameter in all)
          if (parameter.isPositional && !parameter.isRequired)
            parameterType(parameter),
      ],
      requiredPositional: all
          .where((p) => p.isPositional && p.isRequired)
          .length,
      named: {
        for (final parameter in all)
          if (parameter.isNamed)
            parameter.name!.lexeme: (
              type: parameterType(parameter),
              required: parameter.isRequired,
            ),
      },
      returnType: returnType == null
          ? CoreTypes.dynamic.ref(ctx)
          : TypeRef.fromAnnotation(
              ctx,
              library,
              returnType,
              typeParameters: memberTypeParameters,
            ),
    ),
    decl: ctx.types.bySpec(CoreTypes.function),
  );
}

/// The declared type of a formal parameter's type annotation. Legacy
/// function-typed parameters (`R f<P>(args)`) carry their parameter list and
/// type parameters on a [FunctionTypedFormalParameterSuffix] rather than a
/// [GenericFunctionType], so the function type is assembled from the parts.
TypeRef formalParameterAnnotationType(
  CompilerContext ctx,
  int library,
  FormalParameter param, {
  Map<String, TypeRef> typeParameters = const {},
}) {
  final annotation = param.type!;
  final suffix = param is RegularFormalParameter
      ? param.functionTypedSuffix
      : null;
  if (suffix == null) {
    return TypeRef.fromAnnotation(
      ctx,
      library,
      annotation,
      typeParameters: typeParameters,
    );
  }
  return FunctionTypeRef(
    functionSignatureFromParts(
      ctx,
      library,
      returnType: annotation,
      typeParameterList: suffix.typeParameters,
      parameterList: suffix.formalParameters,
      owner: TypeParameterOwner(
        TypeParameterOwnerKind.functionTypedParameter,
        library,
        '',
        suffix.offset,
      ),
      typeParameters: typeParameters,
    ),
    decl: ctx.types.bySpec(CoreTypes.function),
    nullable: suffix.question != null,
  );
}
