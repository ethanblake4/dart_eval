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
  late final List<GenericParam> typeParameters = computeTypeParameters();

  /// The declared supertypes, computed once and shared by every
  /// instantiation — cyclic hierarchies throw the same [CompileError] the
  /// old recursion depth guard produced.
  late final DeclaredSupertypes supertypes = _guardedSupertypes();

  /// `C<T0, ..., Tn>` — this declaration instantiated over its own
  /// parameters.
  late final TypeRef thisType = instantiate([
    for (var i = 0; i < typeParameters.length; i++)
      ownParameterRef(i),
  ]);

  /// The raw `C` reference for this declaration — no arguments, no
  /// nullability — what `spec.ref(ctx)` returns.
  late final TypeRef rawType = TypeRef(library, name, decl: this);

  /// A [TypeRef] for this declaration's [index]th type parameter — the
  /// shared key (`class:library:name`, index) clause types and member
  /// annotations resolve against.
  TypeRef ownParameterRef(int index) => TypeRef(
    library,
    typeParameters[index].name,
    typeParameterOwner: 'class:$library:$name',
    typeParameterIndex: index,
    typeParameterBound:
        typeParameters[index].extendsType ?? CoreTypes.dynamic.ref(ctx),
  );

  /// `C<args...>` — the raw declaration instantiated with [arguments].
  TypeRef instantiate(List<TypeRef> arguments, {bool nullable = false}) =>
      rawType.copyWith(specifiedTypeArgs: arguments, nullable: nullable);

  /// A bridged class whose instances are host objects; always false for
  /// source declarations. Used by `hasBridgeSuperclass`.
  bool get isHostBridged => false;

  /// Each parameter name mapped to its own-parameter [TypeRef] — the scope
  /// `extends`/`implements`/`with` clause types and bounds resolve in.
  Map<String, TypeRef> get ownTypeParams => {
    for (var i = 0; i < typeParameters.length; i++)
      typeParameters[i].name: ownParameterRef(i),
  };

  List<GenericParam> computeTypeParameters();

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
        type = resolveTypeAlias(ctx, library, alias);
      }
    }
    if (type == null) {
      throw CompileError('Type $name not found');
    }
    final ownTypeParams = this.ownTypeParams;
    return type.copyWith(
      specifiedTypeArgs: [
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
    if (clauseName.typeArguments != null || mixin.specifiedTypeArgs.isNotEmpty) {
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
      mixinDeclRef.library,
      mixinDeclRef.name,
      mixinDecl.typeParameters,
    );
    final substitutions = <(String, int), TypeRef>{};
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
          ctx.typeSystem.unify(pattern, found, substitutions);
        }
      }
    }
    if (substitutions.isEmpty) return mixin;
    final mixinParams2 = mixinDeclRef.typeParameters;
    return mixin.copyWith(
      specifiedTypeArgs: [
        for (var i = 0; i < mixinParams2.length; i++)
          substitutions[('class:${mixinDeclRef.library}:${mixinDeclRef.name}', i)] ??
              mixinParams2[i].extendsType?.substituteTypeParameters(
                substitutions,
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
  List<GenericParam> computeTypeParameters() {
    final typeParameters = classLikeClauses(node).$4;
    if (typeParameters == null) return const [];
    // Bounds can reference earlier parameters (`S extends T`), so resolve
    // them with the class's own parameters already seeded.
    final paramRefs = classTypeParameterRefs(library, name, typeParameters);
    return [
      for (final t in typeParameters.typeParameters)
        GenericParam(
          t.name.lexeme,
          t.bound == null
              ? null
              : TypeRef.fromAnnotation(
                  ctx,
                  library,
                  t.bound!,
                  typeParameters: paramRefs,
                ),
        ),
    ];
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
      mixins.add(
        inferMixinArguments(withName, mixin, [superclass, ...mixins]),
      );
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
  List<GenericParam> computeTypeParameters() {
    final classDef = this.classDef;
    if (classDef == null) return const [];
    return [
      for (final g in classDef.type.generics.entries)
        GenericParam(
          g.key,
          g.value.$extends == null
              ? null
              : TypeRef.fromBridgeTypeRef(ctx, g.value.$extends!),
        ),
    ];
  }

  @override
  DeclaredSupertypes computeSupertypes() {
    if (enumDef != null) {
      return DeclaredSupertypes(CoreTypes.enumType.ref(ctx), const [], const []);
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
        superclass = superclass.copyWith(nullable: true);
      }
    }
    return DeclaredSupertypes(superclass, [
      for (final i in type.$implements)
        TypeRef.fromBridgeTypeRef(
          ctx,
          i,
          specifiedType: thisType,
          typeParameters: ownTypeParams,
        ),
    ], [
      for (final i in type.$with)
        TypeRef.fromBridgeTypeRef(
          ctx,
          i,
          specifiedType: thisType,
          typeParameters: ownTypeParams,
        ),
    ]);
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
  /// library only, no visibility.
  TypeDecl? find(int library, String name) => _decls[library]?[name];

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
