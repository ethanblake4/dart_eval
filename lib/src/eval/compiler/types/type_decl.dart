import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../errors.dart';
import '../type.dart';

/// What a [TypeDecl] declares. Mirrors the class-like declaration forms the
/// compiler can see, including bridge defs.
enum TypeDeclKind {
  classDecl,
  mixin,
  enumDecl,
  classAlias,
  extensionType,
  bridgeClass,
  bridgeEnum,
}

/// A declaration's supertypes in its own type-parameter space — a
/// `class C~T~ extends B~T~` records `B~T~` with T bound to `class:C`
/// parameter 0.
/// Instantiated views substitute the applied arguments at each use site.
final class DeclaredSupertypes {
  const DeclaredSupertypes(this.superclass, this.interfaces, this.mixins);

  /// The `extends` type, or null for enums-unnamed, `Object`, and
  /// non-class-like declarations.
  final TypeRef? superclass;

  /// The `implements` types.
  final List<TypeRef> interfaces;

  /// The `with` types, with arguments already inferred where the clause is
  /// raw (`with M` where `M<T> on I<T>` binds `T` from the superclass chain).
  final List<TypeRef> mixins;

  /// The historical `allSupertypes` order: extends, implements, with.
  Iterable<TypeRef> get all => [?superclass, ...interfaces, ...mixins];
}

/// The declaration-level identity of a nominal type — where it was declared
/// and what it is called. Nominal questions ("is this `dart:core`'s `List`?")
/// are answered by the declaration, not by reconstructing a [TypeRef] and
/// comparing.
///
/// [library] is the compiler's library index (a value of
/// [CompilerContext.libraryMap]); [libraryUri] is its source URI
/// (`'dart:core'`, `'package:...'`).
sealed class TypeDecl {
  TypeDecl(this.ctx, this.library, this.libraryUri, this.name);

  final CompilerContext ctx;
  final int library;
  final String libraryUri;
  final String name;

  TypeDeclKind get kind;

  BridgeTypeSpec get spec => BridgeTypeSpec(libraryUri, name);

  bool isSpec(BridgeTypeSpec s) => name == s.name && libraryUri == s.library;

  /// Declared in `dart:core` — the library URI, not a file index, so no
  /// context lookup is needed.
  bool get isDartCore => libraryUri == 'dart:core';

  /// The declared type parameters (`<T extends num, S>`), with bounds
  /// resolved in the declaring library's scope.
  late final List<TypeParameterDef> typeParameters = computeTypeParameters();

  /// The declared supertypes, computed once and shared by every
  /// instantiation — cyclic hierarchies throw the same [CompileError] the
  /// old recursion depth guard produced.
  late final DeclaredSupertypes supertypes = _guardedSupertypes();

  /// `C<T0, ..., Tn>` — this declaration instantiated over its own
  /// parameters.
  late final TypeRef thisType = instantiate([
    for (var i = 0; i < typeParameters.length; i++) ownParameterRef(i),
  ]);

  /// The raw `C` reference for this declaration — no arguments, no
  /// nullability — what `spec.ref(ctx)` returns.
  late final InterfaceTypeRef rawType = InterfaceTypeRef(this);

  /// Arguments used when an annotation or construction omits this class's
  /// type arguments, including dependent and recursive bounds.
  late final List<TypeRef> defaultTypeArguments = _defaultTypeArguments();

  List<TypeRef> _defaultTypeArguments() {
    final defaults = ctx.typeSystem.instantiateToBounds(typeParameters);
    return [for (final parameter in typeParameters) defaults[parameter]!];
  }

  /// A [TypeRef] for this declaration's [index]th type parameter — the
  /// shared key (`class:library:name`, index) clause types and member
  /// annotations resolve against.
  TypeRef ownParameterRef(int index) =>
      TypeParameterTypeRef(typeParameters[index], file: library);

  /// `C<args...>` — the raw declaration instantiated with [arguments].
  InterfaceTypeRef instantiate(
    List<TypeRef> arguments, {
    bool nullable = false,
  }) => InterfaceTypeRef(this, arguments: arguments, nullable: nullable);

  /// A bridged class whose instances are host objects; always false for
  /// source declarations. Used by `hasBridgeSuperclass`.
  bool get isHostBridged => false;

  /// Each parameter name mapped to its own-parameter [TypeRef] — the scope
  /// `extends`/`implements`/`with` clause types and bounds resolve in.
  Map<String, TypeRef> get ownTypeParams => {
    for (var i = 0; i < typeParameters.length; i++)
      typeParameters[i].name: ownParameterRef(i),
  };

  List<TypeParameterDef> computeTypeParameters();

  DeclaredSupertypes computeSupertypes();

  DeclaredSupertypes _guardedSupertypes() {
    final inProgress = ctx.types._inProgress;
    if (!inProgress.add(this)) {
      throw CompileError(
        'Reached max limit on recursion while resolving types. '
        'Your type hierarchy is probably recursive '
        '(caught while resolving $this)',
      );
    }
    try {
      return computeSupertypes();
    } finally {
      inProgress.remove(this);
    }
  }

  /// Resolves one clause type (`extends C<T>`, `implements p.I`, `with M`)
  /// to a [TypeRef] in this declaration's parameter space. Clause targets
  /// may be prefixed (`p.C`); `visibleTypes` keys prefixed types as
  /// 'prefix.Name'. Falls back to a `typedef` alias expansion.
  TypeRef resolveClauseType(NamedType clauseName) {
    final prefix = clauseName.importPrefix;
    final name = prefix == null
        ? clauseName.name.lexeme
        : '${prefix.name.lexeme}.${clauseName.name.lexeme}';
    var type = ctx.visibleTypes[library]![name];
    if (type == null) {
      final alias = ctx.typeAliases[library]?[name];
      if (alias != null) {
        type = ctx.typeFactory.resolveTypeAlias(library, alias);
      }
    }
    if (type == null) {
      throw CompileError('Type $name not found');
    }
    final ownTypeParams = this.ownTypeParams;
    return (type as InterfaceTypeRef).copyWith(
      arguments: [
        for (final arg in clauseName.typeArguments?.arguments ?? const [])
          TypeRef.fromAnnotation(
            ctx,
            library,
            arg,
            typeParameters: ownTypeParams,
          ),
      ],
    );
  }

  /// Shared mixin-application inference for `with M` where `M<T> on I<T>`
  /// and the superclass/mixin chain supplies `I<int>` — binds `T → int` from
  /// the `on` constraints.
  TypeRef inferMixinArguments(
    NamedType clauseName,
    TypeRef mixin,
    List<TypeRef> chainSoFar,
  ) {
    if (clauseName.typeArguments != null ||
        interfaceArgumentsOf(mixin).isNotEmpty) {
      return mixin;
    }
    final mixinDeclRef = nominalDeclOf(mixin);
    if (mixinDeclRef == null) return mixin;
    final mixinDecl = ctx
        .topLevelDeclarationsMap[mixinDeclRef.library]?[mixinDeclRef.name]
        ?.declaration;
    if (mixinDecl is! MixinDeclaration || mixinDecl.onClause == null) {
      return mixin;
    }
    final mixinParams = classTypeParameterRefs(
      ctx,
      mixinDeclRef.library,
      mixinDeclRef.name,
      mixinDecl.typeParameters,
    );
    final bindings = <TypeParameterDef, TypeRef>{};
    for (final constraint in mixinDecl.onClause!.superclassConstraints) {
      final pattern = TypeRef.fromAnnotation(
        ctx,
        mixinDeclRef.library,
        constraint,
        typeParameters: mixinParams,
      );
      for (final sup in chainSoFar) {
        final found = ctx.typeSystem.asInstanceOf(sup, nominalDeclOf(pattern));
        if (found != null) {
          ctx.typeSystem.unify(pattern, found, bindings);
        }
      }
    }
    if (bindings.isEmpty) return mixin;
    final substitution = Substitution.of(bindings);
    final mixinParams2 = mixinDeclRef.typeParameters;
    return (mixin as InterfaceTypeRef).copyWith(
      arguments: [
        for (var i = 0; i < mixinParams2.length; i++)
          bindings[mixinParams2[i]] ??
              mixinParams2[i].bound?.substituteTypeParameters(substitution) ??
              CoreTypes.dynamic.ref(ctx),
      ],
    );
  }
}

/// A nominal type declared in compiled source: a class, mixin, enum,
/// extension type, or `class C = S with M` alias.
final class SourceTypeDecl extends TypeDecl {
  SourceTypeDecl(
    super.ctx,
    super.library,
    super.libraryUri,
    super.name,
    this.node,
  );

  final Declaration node;

  @override
  Map<String, TypeRef> get ownTypeParams {
    final parameters =
        classLikeClauses(node).$4?.typeParameters ?? const <TypeParameter>[];
    return {
      for (var i = 0; i < parameters.length && i < typeParameters.length; i++)
        if (!isWildcardTypeParameter(ctx, parameters[i]))
          parameters[i].name.lexeme: ownParameterRef(i),
    };
  }

  @override
  TypeDeclKind get kind => switch (node) {
    ClassDeclaration() => TypeDeclKind.classDecl,
    MixinDeclaration() => TypeDeclKind.mixin,
    EnumDeclaration() => TypeDeclKind.enumDecl,
    ClassTypeAlias() => TypeDeclKind.classAlias,
    ExtensionTypeDeclaration() => TypeDeclKind.extensionType,
    _ => throw StateError('Unsupported type declaration $node'),
  };

  /// The representation parameter of an extension type's primary constructor.
  FormalParameter? get extensionRepresentationParameter {
    final declaration = node;
    if (declaration is! ExtensionTypeDeclaration) return null;
    final primary = declaration.namePart;
    if (primary is! PrimaryConstructorDeclaration ||
        primary.formalParameters.parameters.length != 1) {
      throw CompileError(
        'Extension types require one representation parameter',
      );
    }
    return primary.formalParameters.parameters.single;
  }

  /// Extension types retain their source identity but erase to this type.
  late final TypeRef? extensionRepresentation =
      _resolveExtensionRepresentation();

  TypeRef? _resolveExtensionRepresentation() {
    final parameter = extensionRepresentationParameter;
    if (parameter == null) return null;
    final annotation = parameter.type;
    if (annotation == null || parameter.functionTypedSuffix != null) {
      throw CompileError('Unsupported extension type representation');
    }
    final previousScope = ctx.typeScopes.remove(library);
    try {
      return TypeRef.fromAnnotation(
        ctx,
        library,
        annotation,
        typeParameters: ownTypeParams,
      );
    } finally {
      if (previousScope == null) {
        ctx.typeScopes.remove(library);
      } else {
        ctx.typeScopes[library] = previousScope;
      }
    }
  }

  /// The representation template applied to this extension's use-site type.
  TypeRef? extensionRepresentationFor(TypeRef type) => extensionRepresentation
      ?.substituteTypeParameters(Substitution.forInterface(type));

  /// Checks interfaces independently of resolving the hierarchy, since the
  /// representation may itself be an extension type with declared interfaces.
  void validateExtensionInterfaces() {
    final declaration = node;
    if (declaration is! ExtensionTypeDeclaration) return;
    final active = <TypeDecl>{};
    final checked = <TypeDecl>{};
    void checkCycles(TypeDecl declaration) {
      if (declaration.kind != TypeDeclKind.extensionType ||
          checked.contains(declaration)) {
        return;
      }
      if (!active.add(declaration)) {
        throw CompileError('Cyclic extension type interfaces', node);
      }
      for (final interface in declaration.supertypes.interfaces) {
        final target = nominalDeclOf(interface);
        if (target != null) checkCycles(target);
      }
      active.remove(declaration);
      checked.add(declaration);
    }

    checkCycles(this);
    final representation = extensionRepresentation!;
    for (final clause
        in declaration.implementsClause?.interfaces ?? const <NamedType>[]) {
      if (clause.question != null) {
        throw CompileError(
          'Extension type interface cannot be nullable',
          clause,
        );
      }
      final interface = resolveClauseType(clause) as InterfaceTypeRef;
      final target = interface.decl;
      final parameters = target.typeParameters;
      final arguments = interface.arguments.isEmpty
          ? target.defaultTypeArguments
          : interface.arguments;
      if (clause.typeArguments != null &&
          clause.typeArguments!.arguments.length != parameters.length) {
        throw CompileError('Wrong number of interface type arguments', clause);
      }
      final applied = target.instantiate(arguments);
      final substitution = Substitution.forInterface(applied);
      for (var i = 0; i < parameters.length; i++) {
        final bound = parameters[i].bound?.substituteTypeParameters(
          substitution,
        );
        if (bound != null &&
            !arguments[i].isAssignableTo(
              ctx,
              bound,
              forceAllowDynamic: false,
            )) {
          throw CompileError(
            'Interface type argument does not satisfy its bound',
            clause,
          );
        }
      }
      final requiredRepresentation = target.kind == TypeDeclKind.extensionType
          ? applied.erasedExtensionType
          : applied;
      final actualRepresentation = target.kind == TypeDeclKind.extensionType
          ? representation.erasedExtensionType
          : representation;
      if (!actualRepresentation.isAssignableTo(
        ctx,
        requiredRepresentation,
        forceAllowDynamic: false,
      )) {
        throw CompileError(
          'Extension type representation is not a subtype of its interface',
          clause,
        );
      }
    }
  }

  @override
  List<TypeParameterDef> computeTypeParameters() {
    final nodes = classLikeClauses(node).$4;
    if (nodes == null) return const [];
    // Bounds can reference earlier parameters (`S extends T`), so resolve
    // them with the class's own parameters already seeded.
    final paramRefs = <String, TypeRef>{};
    final defs = declareTypeParameters(
      ctx,
      TypeParameterOwner(TypeParameterOwnerKind.classLike, library, name),
      nodes.typeParameters,
      paramRefs,
      (bound) => TypeRef.fromAnnotation(
        ctx,
        library,
        bound,
        typeParameters: paramRefs,
      ),
    );
    return defs;
  }

  @override
  DeclaredSupertypes computeSupertypes() {
    if (node case ExtensionTypeDeclaration(:final implementsClause)) {
      // Nullable representations do not make the nominal type an Object.
      return DeclaredSupertypes(CoreTypes.object.ref(ctx).withNullable(true), [
        for (final interface
            in implementsClause?.interfaces ?? const <NamedType>[])
          resolveClauseType(interface),
      ], const []);
    }
    final (extendsClause, withClause, implementsClause, _) = classLikeClauses(
      node,
    );

    TypeRef? superclass;
    if (extendsClause != null) {
      superclass = resolveClauseType(extendsClause);
    } else if (node is EnumDeclaration) {
      superclass = CoreTypes.enumType.ref(ctx);
    } else {
      superclass = CoreTypes.object.ref(ctx);
    }

    final mixins = <TypeRef>[];
    for (final withName in withClause) {
      final mixin = resolveClauseType(withName);
      mixins.add(inferMixinArguments(withName, mixin, [superclass, ...mixins]));
    }

    return DeclaredSupertypes(superclass, [
      if (node case MixinDeclaration(:final onClause))
        for (final constraint
            in onClause?.superclassConstraints ?? const <NamedType>[])
          resolveClauseType(constraint),
      for (final implementsName in implementsClause)
        // `implements Function` has no effect on the subtype relation —
        // a callable class is not a subtype of `Function`.
        if (resolveClauseType(implementsName) case final type
            when !type.isBareFunction)
          type,
    ], mixins);
  }
}

/// A nominal type declared by a host bridge definition.
///
/// [isHostBridged] marks a bridged class whose instances are host objects
/// (`BridgeClassDef.bridge`).
final class BridgeTypeDecl extends TypeDecl {
  BridgeTypeDecl(
    super.ctx,
    super.library,
    super.libraryUri,
    super.name, {
    this.classDef,
    this.enumDef,
  });

  final BridgeClassDef? classDef;
  final BridgeEnumDef? enumDef;

  @override
  TypeDeclKind get kind =>
      classDef != null ? TypeDeclKind.bridgeClass : TypeDeclKind.bridgeEnum;

  @override
  bool get isHostBridged => classDef?.bridge ?? false;

  @override
  List<TypeParameterDef> computeTypeParameters() {
    final classDef = this.classDef;
    if (classDef == null) return const [];
    final owner = TypeParameterOwner(
      TypeParameterOwnerKind.classLike,
      library,
      name,
    );
    var index = 0;
    final defs = ctx.typeParameterDefs.intern(owner, [
      for (final g in classDef.type.generics.entries)
        () {
          final def = TypeParameterDef(owner, index++, g.key);
          final extends_ = g.value.$extends;
          if (extends_ != null) {
            def.bound = TypeRef.fromBridgeTypeRef(ctx, extends_);
          }
          return def;
        }(),
    ]);
    return defs;
  }

  @override
  DeclaredSupertypes computeSupertypes() {
    if (enumDef != null) {
      return DeclaredSupertypes(
        CoreTypes.enumType.ref(ctx),
        const [],
        const [],
      );
    }
    final type = classDef!.type;
    final ownTypeParams = this.ownTypeParams;
    TypeRef? superclass;
    if (type.$extends != null) {
      superclass = TypeRef.fromBridgeTypeRef(
        ctx,
        type.$extends!,
        specifiedType: thisType,
        typeParameters: ownTypeParams,
      );
      // Null's nominal superclass is Object, but `Null <: T` holds only
      // when T is nullable or a top type — model that as extends Object?.
      if (isSpec(CoreTypes.nullType)) {
        superclass = superclass.withNullable(true);
      }
    }
    return DeclaredSupertypes(
      superclass,
      [
        for (final i in type.$implements)
          TypeRef.fromBridgeTypeRef(
            ctx,
            i,
            specifiedType: thisType,
            typeParameters: ownTypeParams,
          ),
      ],
      [
        for (final i in type.$with)
          TypeRef.fromBridgeTypeRef(
            ctx,
            i,
            specifiedType: thisType,
            typeParameters: ownTypeParams,
          ),
      ],
    );
  }
}

/// The context's [TypeDecl] table. Declarations are registered in
/// `Compiler._cacheTypeRef` — the same pass that assigns runtime type ids —
/// so lookup order is identical to the old `_TypeRefCache` population order.
final class TypeDeclRegistry {
  TypeDeclRegistry(this._ctx);

  final CompilerContext _ctx;
  final _decls = <int, Map<String, TypeDecl>>{};
  final _inProgress = <TypeDecl>{};
  BridgeTypeDecl? _futureOrDecl;

  void register(TypeDecl decl) =>
      _decls.putIfAbsent(decl.library, () => {})[decl.name] = decl;

  /// The synthetic declaration behind `FutureOr<T>` annotations — a union
  /// `Future<T> | T` that has no real class. Type semantics special-case it;
  /// the nominal keeps arguments (`FutureOr<S>`) flowing through `TypeRef`
  /// machinery instead of degrading to `dynamic`.
  BridgeTypeDecl get futureOr => _futureOrDecl ??= () {
    final decl = BridgeTypeDecl(
      _ctx,
      _ctx.libraryMap['dart:async'] ?? _ctx.library,
      'dart:async',
      'FutureOr',
      classDef: const BridgeClassDef(
        BridgeClassType(
          BridgeTypeRef(AsyncTypes.futureOr),
          generics: {'T': BridgeGenericParam()},
        ),
        constructors: {},
        methods: {},
        getters: {},
        setters: {},
        fields: {},
        wrap: true,
      ),
    );
    register(decl);
    return decl;
  }();

  /// The declaration declared in [library] under [name] — the declaring
  /// library only, no visibility. On first use the decl is materialized
  /// from `topLevelDeclarationsMap` and registered so it stays canonical —
  /// member lookup needs decls for types that were never registered as
  /// use-site [TypeRef]s.
  TypeDecl? find(int library, String name) {
    final registered = _decls[library]?[name];
    if (registered != null) return registered;
    final entry = _ctx.topLevelDeclarationsMap[library]?[name];
    if (entry == null) return null;
    final TypeDecl decl;
    if (entry.isBridge) {
      final bridge = entry.bridge;
      decl = BridgeTypeDecl(
        _ctx,
        library,
        _ctx.libraryUri(library),
        name,
        classDef: bridge is BridgeClassDef ? bridge : null,
        enumDef: bridge is BridgeEnumDef ? bridge : null,
      );
    } else {
      final node = entry.declaration;
      if (node == null) return null;
      decl = SourceTypeDecl(
        _ctx,
        library,
        _ctx.libraryUri(library),
        name,
        node,
      );
    }
    register(decl);
    return decl;
  }

  /// The declaration [spec] names (spec's library URI must be part of the
  /// compilation). Resolves through the spec library's visible types so a
  /// re-exported name still finds the real declaration.
  TypeDecl bySpec(BridgeTypeSpec spec) {
    final lib =
        _ctx.libraryMap[spec.library] ??
        (throw CompileError('Bridge: cannot find library ${spec.library}'));
    return visible(lib, spec.name) ??
        (throw CompileError(
          'Bridge: cannot find type ${spec.name} in library ${spec.library}',
        ));
  }

  /// The declaration for a type visible in [library] under [name] —
  /// [name] may be prefixed (`prefix.Name`).
  TypeDecl? visible(int library, String name) =>
      nominalDeclOf(_ctx.visibleTypes[library]?[name]);
}
