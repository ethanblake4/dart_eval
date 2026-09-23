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
        type = ctx.typeFactory.resolveTypeAlias( library, alias);
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
        mixin.typeArguments.isNotEmpty) {
      return mixin;
    }
    final mixinDeclRef = mixin.decl;
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
        final found = ctx.typeSystem.asInstanceOf(sup, pattern.decl);
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
              mixinParams2[i].bound?.substituteTypeParameters(
                substitution,
              ) ??
              CoreTypes.dynamic.ref(ctx),
      ],
    );
  }
}

/// A nominal type declared in compiled source: a class, mixin, enum, or
/// `class C = S with M` alias.
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
  TypeDeclKind get kind => switch (node) {
    ClassDeclaration() => TypeDeclKind.classDecl,
    MixinDeclaration() => TypeDeclKind.mixin,
    EnumDeclaration() => TypeDeclKind.enumDecl,
    ClassTypeAlias() => TypeDeclKind.classAlias,
    _ => throw StateError('Unsupported type declaration $node'),
  };

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
      for (final implementsName in implementsClause)
        resolveClauseType(implementsName),
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
      for (final g in classDef.type.generics.entries) () {
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

  void register(TypeDecl decl) =>
      _decls.putIfAbsent(decl.library, () => {})[decl.name] = decl;

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
      _ctx.visibleTypes[library]?[name]?.decl;
}
