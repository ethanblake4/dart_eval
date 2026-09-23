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

/// The declaration-level identity of a nominal type — where it was declared
/// and what it is called. Nominal questions ("is this `dart:core`'s `List`?")
/// are answered by the declaration, not by reconstructing a [TypeRef] and
/// comparing.
///
/// [library] is the compiler's library index (a value of
/// [CompilerContext.libraryMap]); [libraryUri] is its source URI
/// (`'dart:core'`, `'package:...'`).
sealed class TypeDecl {
  TypeDecl(this.library, this.libraryUri, this.name);

  final int library;
  final String libraryUri;
  final String name;

  TypeDeclKind get kind;

  BridgeTypeSpec get spec => BridgeTypeSpec(libraryUri, name);

  bool isSpec(BridgeTypeSpec s) => name == s.name && libraryUri == s.library;

  /// Declared in `dart:core` — the library URI, not a file index, so no
  /// context lookup is needed.
  bool get isDartCore => libraryUri == 'dart:core';

  /// The raw `C` reference for this declaration — no arguments, no
  /// nullability — what `spec.ref(ctx)` returns.
  late final TypeRef rawType = TypeRef(library, name, decl: this);

  /// `C<args...>` — the raw declaration instantiated with [arguments].
  TypeRef instantiate(List<TypeRef> arguments, {bool nullable = false}) =>
      rawType.copyWith(specifiedTypeArgs: arguments, nullable: nullable);

  /// A bridged class whose instances are host objects; always false for
  /// source declarations. Used by `hasBridgeSuperclass`.
  bool get isHostBridged => false;
}

/// A nominal type declared in compiled source: a class, mixin, enum, or
/// `class C = S with M` alias.
final class SourceTypeDecl extends TypeDecl {
  SourceTypeDecl(super.library, super.libraryUri, super.name, this.node);

  final Declaration node;

  @override
  TypeDeclKind get kind => switch (node) {
    ClassDeclaration() => TypeDeclKind.classDecl,
    MixinDeclaration() => TypeDeclKind.mixin,
    EnumDeclaration() => TypeDeclKind.enumDecl,
    ClassTypeAlias() => TypeDeclKind.classAlias,
    _ => throw StateError('Unsupported type declaration $node'),
  };
}

/// A nominal type declared by a host bridge definition.
///
/// [isHostBridged] marks a bridged class whose instances are host objects
/// (`BridgeClassDef.bridge`).
final class BridgeTypeDecl extends TypeDecl {
  BridgeTypeDecl(
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
}

/// The context's [TypeDecl] table. Declarations are registered in
/// `Compiler._cacheTypeRef` — the same pass that assigns runtime type ids —
/// so lookup order is identical to the old `_TypeRefCache` population order.
final class TypeDeclRegistry {
  TypeDeclRegistry(this._ctx);

  final CompilerContext _ctx;
  final _decls = <int, Map<String, TypeDecl>>{};

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
