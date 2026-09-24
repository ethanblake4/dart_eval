import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Constructs [TypeRef]s — the single home for every annotation→type
/// resolution path (source annotations, bridge type refs, type aliases,
/// applied generic arguments, function-type parts). Replaces the
/// `TypeRef.fromX` factories and the free resolution helpers; the
/// factories remain as thin forwarders onto [ctx].
final class TypeFactory {
  TypeFactory(this._ctx);

  final CompilerContext _ctx;

  /// Stable per-[BridgeFunctionDef] identity for type-parameter owner keys.
  /// `def.hashCode` is an identity hash that can collide across different
  /// defs; a sequence number cannot.
  final _bridgeFunctionDefIds = Expando<int>();
  var _bridgeFunctionDefSeq = 0;

  /// Resolves a source [TypeAnnotation] to its [TypeRef]: named types look
  /// up in-scope parameters then library-visible types, `?`-suffixed names
  /// set nullability, applied type arguments resolve recursively, and
  /// bare references defer to [typeParameters].
  TypeRef fromAnnotation(
    int library,
    TypeAnnotation typeAnnotation, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    if (typeAnnotation is GenericFunctionType) {
      return functionTypeFromAnnotation(
        library,
        typeAnnotation,
        typeParameters: typeParameters,
      );
    }
    if (typeAnnotation is RecordTypeAnnotation) {
      final positional = <TypeRef>[
        for (final field in typeAnnotation.positionalFields)
          fromAnnotation(library, field.type, typeParameters: typeParameters),
      ];
      final named = <String, TypeRef>{
        for (final field
            in typeAnnotation.namedFields?.fields ??
                <RecordTypeAnnotationNamedField>[])
          field.name.lexeme: fromAnnotation(
            library,
            field.type,
            typeParameters: typeParameters,
          ),
      };
      return RecordTypeRef(
        positional,
        named,
        nullable: typeAnnotation.question != null,
      );
    }
    typeAnnotation as NamedType;
    final prefix = typeAnnotation.importPrefix;
    final n = prefix == null
        ? typeAnnotation.name.stringValue ?? typeAnnotation.name.value()
        : '${prefix.name.lexeme}.${typeAnnotation.name.lexeme}';
    final unspecifiedType =
        typeParameters[n] ??
        _ctx.typeScopes[library]?[n] ??
        _ctx.visibleTypes[library]?[n];
    if (unspecifiedType == null) {
      final alias = _ctx.typeAliases[library]?[n];
      if (alias != null) {
        return resolveTypeAlias(
          library,
          alias,
          nullable: typeAnnotation.question != null,
          typeArgs: typeAnnotation.typeArguments?.arguments,
          callerTypeParameters: typeParameters,
        );
      }
      // `FutureOr<T>` is a union type (`Future<T> | T`), which this compiler
      // cannot represent; it degrades to `dynamic` so `is`/`as` and
      // assignability checks remain permissive in both directions.
      if (n == 'FutureOr') {
        return CoreTypes.dynamic.ref(_ctx);
      }
      throw CompileError(
        'Unknown type $n',
        typeAnnotation.parent,
        library,
        _ctx,
      );
    }
    final typeArgs = typeAnnotation.typeArguments;
    if (typeArgs != null) {
      final resolved = <TypeRef>[];
      for (final arg in typeArgs.arguments) {
        resolved.add(
          fromAnnotation(library, arg, typeParameters: typeParameters),
        );
      }
      final nullability =
          typeAnnotation.question != null || unspecifiedType.nullable;
      return switch (unspecifiedType) {
        InterfaceTypeRef() => unspecifiedType.copyWith(
          arguments: resolved,
          nullable: nullability,
        ),
        _ => unspecifiedType.withNullable(nullability),
      };
    }
    // A bare type-parameter reference keeps the nullability of its bound
    // value — `T` is nullable when T resolves to `String?`.
    return unspecifiedType.withNullable(
      typeAnnotation.question != null || unspecifiedType.nullable,
    );
  }

  /// A [BridgeTypeAnnotation] — a bridge type reference plus a nullability
  /// flag.
  TypeRef fromBridgeAnnotation(
    BridgeTypeAnnotation typeAnnotation, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return fromBridgeTypeRef(
      typeAnnotation.type,
      specifyingType: specifyingType,
      specifiedType: specifiedType,
      typeParameters: typeParameters,
    ).withNullable(typeAnnotation.nullable);
  }

  /// A serialized [BridgeTypeRef]: cached ids resolve through the runtime
  /// type list, specs resolve through their library's visible types, refs
  /// resolve against the bridged class's generics, and generic function
  /// types resolve through [signatureFromBridgeFunctionDef].
  TypeRef fromBridgeTypeRef(
    BridgeTypeRef typeReference, {
    TypeRef? specifyingType,
    TypeRef? specifiedType,
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final cacheId = typeReference.cacheId;
    if (cacheId != null) {
      final t = _ctx.runtimeTypes.list[cacheId];
      return _ctx.bridgeTypeRefCache.putIfAbsent(cacheId, () => t);
    }
    final spec = typeReference.spec;
    if (spec != null) {
      final arguments = <TypeRef>[];
      for (final arg in typeReference.typeArgs) {
        arguments.add(
          fromBridgeAnnotation(
            arg,
            specifiedType: specifiedType,
            typeParameters: typeParameters,
          ),
        );
      }
      final lib =
          _ctx.libraryMap[spec.library] ??
          (throw CompileError('Bridge: cannot find library ${spec.library}'));
      final typeSpec =
          _ctx.visibleTypes[lib]![spec.name] ??
          (throw CompileError(
            'Bridge: cannot find type ${spec.name} in library ${spec.library}',
          ));
      return (typeSpec as InterfaceTypeRef).copyWith(arguments: arguments);
    }
    final ref = typeReference.ref;
    if (ref != null) {
      final typeParameter = typeParameters[ref];
      if (typeParameter != null) return typeParameter;
      specifiedType ??= _ctx.visibleTypes[_ctx.library]![_ctx.currentClassName];

      if (specifiedType == null) {
        return CoreTypes.dynamic.ref(_ctx);
      }

      final declaration = _ctx
          .topLevelDeclarationsMap[specifiedType.file]![specifiedType.name]!;
      if (!declaration.isBridge) {
        // `ref` is declared on a bridge type, but [specifiedType] is a plain
        // class — resolve through a bridged ancestor in its chain (e.g. a
        // Dart class extending `List<T>`), else degrade to dynamic.
        return _ctx.typeSystem.bridgedTypeArgument(specifiedType, ref) ??
            CoreTypes.dynamic.ref(_ctx);
      }
      final dec = declaration.bridge!;
      if (dec is! BridgeClassDef) {
        throw CompileError(
          'Trying to resolve bridged generic type $ref on $specifiedType, which is not a bridge class',
        );
      }

      final genericIndex = dec.type.generics.keys.toList().indexWhere(
        (key) => key == ref,
      );
      if (genericIndex >= 0 &&
          genericIndex < interfaceArgumentsOf(specifiedType).length) {
        return interfaceArgumentsOf(specifiedType)[genericIndex];
      }
      final generic = dec.type.generics[ref];
      if (generic == null) return CoreTypes.dynamic.ref(_ctx);
      final $extends = generic.$extends;
      final boundType = $extends == null
          ? CoreTypes.dynamic.ref(_ctx)
          : fromBridgeTypeRef($extends);

      if (specifyingType != null && genericIndex >= 0) {
        final instantiatedType =
            [
              specifyingType,
              ..._ctx.typeSystem.superclassChain(specifyingType),
            ].firstWhereOrNull(
              (candidate) =>
                  sameDeclaration(candidate, specifiedType!) &&
                  genericIndex < interfaceArgumentsOf(candidate).length,
            );
        if (instantiatedType != null) {
          final resolvedDeclaredType =
              interfaceArgumentsOf(instantiatedType)[genericIndex];
          if (!resolvedDeclaredType.isAssignableTo(_ctx, boundType)) {
            throw CompileError(
              "Type argument $resolvedDeclaredType does not conform to type parameter $ref's"
              "bound ($boundType)",
            );
          }
          return resolvedDeclaredType;
        }
      }

      return boundType;
    }
    final gft = typeReference.gft;
    if (gft != null) {
      return FunctionTypeRef(
        signatureFromBridgeFunctionDef(gft, typeParameters: typeParameters),
        decl: _ctx.types.bySpec(CoreTypes.function),
      );
    }
    throw CompileError(
      'No support for looking up types by other bridge annotation types',
    );
  }

  /// Resolves a [TypeAlias] to the type it expands to, substituting applied
  /// type arguments for its parameters. Recursive aliases throw.
  TypeRef resolveTypeAlias(
    int library,
    TypeAlias alias, {
    bool nullable = false,
    List<TypeAnnotation>? typeArgs,
    Map<String, TypeRef> callerTypeParameters = const {},
    bool rawParams = false,
  }) {
    // Resolve supplied type arguments first — they are finite annotations that
    // may legally mention this same alias (`Fcov<Fcov<Never>>`). Only the
    // alias's own body resolution is guarded against recursion.
    final argRefs = typeArgs == null
        ? null
        : [
            for (final arg in typeArgs)
              fromAnnotation(
                library,
                arg,
                typeParameters: callerTypeParameters,
              ),
          ];
    if (!_ctx.resolvingTypeAliases.add(alias)) {
      throw CompileError(
        'Type alias ${alias.name.lexeme} references itself recursively',
        alias,
        library,
        _ctx,
      );
    }
    try {
      return _resolveTypeAlias(
        library,
        alias,
        nullable: nullable,
        argRefs: argRefs,
        callerTypeParameters: callerTypeParameters,
        rawParams: rawParams,
      );
    } finally {
      _ctx.resolvingTypeAliases.remove(alias);
    }
  }

  TypeRef _resolveTypeAlias(
    int library,
    TypeAlias alias, {
    bool nullable = false,
    List<TypeRef>? argRefs,
    Map<String, TypeRef> callerTypeParameters = const {},
    bool rawParams = false,
  }) {
    final typeParameters =
        switch (alias) {
          GenericTypeAlias(:final typeParameters) => typeParameters,
          FunctionTypeAlias(:final typeParameters) => typeParameters,
          ClassTypeAlias(:final typeParameters) => typeParameters,
          _ => null,
        }?.typeParameters ??
        const <TypeParameter>[];
    // Bind the alias's own type parameters inside its body. With concrete
    // arguments, substitute them. Without arguments the alias instantiates to
    // bounds (`typedef TB<T extends C> = T` referenced bare is `TB<C>`); with
    // [rawParams] the parameters stay abstract type-parameter references so a
    // caller performing downward inference can substitute them itself. The body
    // resolves against the alias's own file — it may name types private to that
    // library.
    final declLibrary = _ctx.typeAliasFiles[alias] ?? library;
    final aliasOwner = TypeParameterOwner(
      TypeParameterOwnerKind.typeAlias,
      declLibrary,
      alias.name.lexeme,
    );
    final bindings = <String, TypeRef>{};
    for (var i = 0; i < typeParameters.length; i++) {
      final param = typeParameters[i];
      final arg = argRefs == null || i >= argRefs.length ? null : argRefs[i];
      final bound = param.bound;
      if (arg != null) {
        bindings[param.name.lexeme] = arg;
      } else if (rawParams) {
        bindings[param.name.lexeme] = TypeParameterTypeRef(
          _ctx.typeParameterDefs.key(aliasOwner, i, param.name.lexeme),
          file: declLibrary,
        );
      } else if (bound == null) {
        bindings[param.name.lexeme] = CoreTypes.dynamic.ref(_ctx);
      } else {
        // A recursive bound (`X extends A<X>`) sees the parameter itself.
        bindings[param.name.lexeme] = TypeParameterTypeRef(
          _ctx.typeParameterDefs.key(aliasOwner, i, param.name.lexeme),
          file: declLibrary,
        );
        bindings[param.name.lexeme] = fromAnnotation(
          declLibrary,
          bound,
          typeParameters: bindings,
        );
      }
    }

    final TypeRef target;
    if (alias is GenericTypeAlias) {
      final functionType = alias.functionType;
      target = functionType == null
          ? fromAnnotation(declLibrary, alias.type, typeParameters: bindings)
          : functionTypeFromAnnotation(
              declLibrary,
              functionType,
              typeParameters: bindings,
            );
    } else if (alias is FunctionTypeAlias) {
      // Legacy `typedef R f(P...)` syntax declares the signature inline. The
      // alias's parameters become the signature's own generics only under
      // [rawParams] (downward inference); otherwise [bindings] instantiate
      // them so the result is a plain function type.
      target = FunctionTypeRef(
        signatureFromParts(
          declLibrary,
          returnType: alias.returnType,
          typeParameterList: rawParams ? alias.typeParameters : null,
          parameterList: alias.parameters,
          owner: TypeParameterOwner(
            TypeParameterOwnerKind.typeAlias,
            declLibrary,
            alias.name.lexeme,
          ),
          typeParameters: bindings,
        ),
        decl: _ctx.types.bySpec(CoreTypes.function),
      );
    } else {
      target = CoreTypes.function.ref(_ctx);
    }
    return target.withNullable(nullable || target.nullable);
  }

  /// Resolves a type argument in a `with`/`extends` application: a bare name
  /// matching one of [classParams] resolves to that parameter's [TypeRef];
  /// other named types resolve their arguments recursively (so `List<U>`
  /// resolves when `U` is a parameter of the applying class). Concrete
  /// arguments resolve normally. Returns null when the argument resolves to
  /// none of these.
  TypeRef? resolveAppliedTypeArgument(
    int libraryIndex,
    String ownerClassName,
    List<TypeParameter>? classParams,
    TypeAnnotation arg,
  ) {
    if (arg is NamedType) {
      if (arg.importPrefix == null) {
        final index = (classParams ?? const <TypeParameter>[]).indexWhere(
          (p) => p.name.lexeme == arg.name.lexeme,
        );
        if (index >= 0) {
          final bound = classParams![index].bound;
          final parameter = _ctx.typeParameterDefs.key(
            TypeParameterOwner(
              TypeParameterOwnerKind.classLike,
              libraryIndex,
              ownerClassName,
            ),
            index,
            arg.name.lexeme,
          );
          if (bound != null && !parameter.boundSet) {
            parameter.bound = fromAnnotation(libraryIndex, bound);
          }
          return TypeParameterTypeRef(parameter);
        }
      }
      final prefix = arg.importPrefix;
      final name = prefix == null
          ? arg.name.lexeme
          : '${prefix.name.lexeme}.${arg.name.lexeme}';
      final base = _ctx.visibleTypes[libraryIndex]?[name];
      if (base != null) {
        final nestedArgs = arg.typeArguments?.arguments;
        if (nestedArgs == null) return base;
        return (base as InterfaceTypeRef).copyWith(
          arguments: [
            for (final nested in nestedArgs)
              resolveAppliedTypeArgument(
                    libraryIndex,
                    ownerClassName,
                    classParams,
                    nested,
                  ) ??
                  CoreTypes.dynamic.ref(_ctx),
          ],
        );
      }
    }
    try {
      return fromAnnotation(libraryIndex, arg);
    } on CompileError {
      return null;
    }
  }

  /// Dart's "no declared type" inference widens a `Null`-typed initializer to
  /// `dynamic` (`var x = null`, `var f = null`): an uninhabited declared type
  /// would reject every later assignment.
  TypeRef widenedInferredType(TypeRef type) =>
      type.isSpec(CoreTypes.nullType) ? CoreTypes.dynamic.ref(_ctx) : type;

  /// Builds a [FunctionSignature] from a bridge function definition. Bridge
  /// generic names that are not in scope become [TypeParameterTypeRef]s
  /// owned by the signature itself.
  FunctionSignature signatureFromBridgeFunctionDef(
    BridgeFunctionDef def, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final owner = TypeParameterOwner(
      TypeParameterOwnerKind.functionTypeAnnotation,
      -1,
      '',
      _bridgeFunctionDefIds[def] ??= ++_bridgeFunctionDefSeq,
    );
    final genericEntries = def.generics.entries.toList();
    final ownDefs = _ctx.typeParameterDefs.intern(owner, [
      for (final (index, entry) in genericEntries.indexed)
        TypeParameterDef(owner, index, entry.key),
    ]);
    for (final (index, entry) in genericEntries.indexed) {
      final bound = entry.value.$extends;
      if (bound != null && !ownDefs[index].boundSet) {
        ownDefs[index].bound = fromBridgeTypeRef(bound);
      }
    }
    final scope = <String, TypeRef>{
      ...typeParameters,
      for (final def0 in ownDefs) def0.name: TypeParameterTypeRef(def0),
    };
    // Forward-referenced names outside the declared generics still need a
    // def — hand out fresh indices beyond the declared range, cached so the
    // same name maps to the same parameter within this signature.
    final extraDefs = <String, TypeParameterDef>{};
    TypeParameterDef extraDef(String name) => extraDefs[name] ??=
        TypeParameterDef(owner, ownDefs.length + extraDefs.length, name);

    TypeRef resolve(BridgeTypeAnnotation annotation) {
      final type = annotation.type;
      if (type.ref != null) {
        final resolved = scope[type.ref];
        if (resolved != null) {
          return resolved.withNullable(annotation.nullable);
        }
        return TypeParameterTypeRef(extraDef(type.ref!));
      }
      return fromBridgeAnnotation(annotation, typeParameters: scope);
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
  FunctionSignature signatureFromParts(
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
    final ownDefs = declareTypeParameters(
      _ctx,
      owner,
      ownParams,
      allTypeParams,
      (bound) {
        return fromAnnotation(library, bound, typeParameters: allTypeParams);
      },
    );

    TypeRef resolve(TypeAnnotation? type) => type == null
        ? CoreTypes.dynamic.ref(_ctx)
        : fromAnnotation(library, type, typeParameters: allTypeParams);

    final parameters = parameterList?.parameters ?? const <FormalParameter>[];
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
    int library,
    GenericFunctionType annotation, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    return FunctionTypeRef(
      signatureFromParts(
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
      decl: _ctx.types.bySpec(CoreTypes.function),
      nullable: annotation.question != null,
    );
  }

  /// Builds the structural callable type declared by a function or method.
  /// Generic callables produce a [FunctionTypeRef] whose signature owns its own
  /// type parameters; [ownTypeParameterOwner] keys those parameters so the same
  /// declaration read from the same position keeps identical parameter identities
  /// (a tear-off's owner differs from the body's — see [TypeParameterOwnerKind]).
  TypeRef declaredFunctionType(
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
        signatureFromParts(
          library,
          returnType: returnType,
          typeParameterList: typeParameters,
          parameterList: parameters,
          owner:
              ownTypeParameterOwner ??
              TypeParameterOwner(TypeParameterOwnerKind.function, library, ''),
          typeParameters: memberTypeParameters,
        ),
        decl: _ctx.types.bySpec(CoreTypes.function),
      );
    }

    TypeRef parameterType(FormalParameter parameter) {
      final annotation = parameter.type;
      return annotation == null
          ? CoreTypes.dynamic.ref(_ctx)
          : formalParameterAnnotationType(
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
            ? CoreTypes.dynamic.ref(_ctx)
            : fromAnnotation(
                library,
                returnType,
                typeParameters: memberTypeParameters,
              ),
      ),
      decl: _ctx.types.bySpec(CoreTypes.function),
    );
  }

  /// The declared type of a formal parameter's type annotation. Legacy
  /// function-typed parameters (`R f<P>(args)`) carry their parameter list and
  /// type parameters on a [FunctionTypedFormalParameterSuffix] rather than a
  /// [GenericFunctionType], so the function type is assembled from the parts.
  TypeRef formalParameterAnnotationType(
    int library,
    FormalParameter param, {
    Map<String, TypeRef> typeParameters = const {},
  }) {
    final annotation = param.type!;
    final suffix = param is RegularFormalParameter
        ? param.functionTypedSuffix
        : null;
    if (suffix == null) {
      return fromAnnotation(
        library,
        annotation,
        typeParameters: typeParameters,
      );
    }
    return FunctionTypeRef(
      signatureFromParts(
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
      decl: _ctx.types.bySpec(CoreTypes.function),
      nullable: suffix.question != null,
    );
  }
}
