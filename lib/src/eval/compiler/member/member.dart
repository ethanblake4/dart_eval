import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import '../invocation/deferred.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Whether a constructor member is generative or a factory.
enum ConstructorKind { generative, factory }

/// What declared a member: a nominal type or an extension.
sealed class MemberOwner {
  const MemberOwner();
}

/// A member declared on a [TypeDecl] — a class, mixin, enum, alias, or
/// bridged type.
final class TypeDeclMemberOwner extends MemberOwner {
  const TypeDeclMemberOwner(this.decl);

  final TypeDecl decl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeDeclMemberOwner &&
          decl.libraryUri == other.decl.libraryUri &&
          decl.name == other.decl.name;

  @override
  int get hashCode => Object.hash(decl.libraryUri, decl.name);

  @override
  String toString() => 'memberOwner(${decl.libraryUri}:${decl.name})';
}

/// A member declared on an [EvalExtension] — the extension namespace
/// keeps its own lookup, but extension members still get signatures.
final class ExtensionDecl extends MemberOwner {
  ExtensionDecl(this.ctx, this.extension);

  final CompilerContext ctx;
  final EvalExtension extension;

  /// The extension's type parameters keyed by name — instance members
  /// resolve `T` against these; static members can't see them.
  late final Map<String, TypeRef> ownTypeParams = () {
    final nodes =
        extension.declaration.typeParameters?.typeParameters ??
        const <TypeParameter>[];
    final scope = <String, TypeRef>{};
    declareTypeParameters(
      ctx,
      TypeParameterOwner(
        TypeParameterOwnerKind.extension,
        extension.library,
        extension.name,
      ),
      nodes,
      scope,
      (bound) => TypeRef.fromAnnotation(
        ctx,
        extension.library,
        bound,
        typeParameters: scope,
      ),
    );
    return scope;
  }();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtensionDecl &&
          extension.library == other.extension.library &&
          extension.name == other.extension.name;

  @override
  int get hashCode => Object.hash(extension.library, extension.name);

  @override
  String toString() => 'memberOwner(extension ${extension.name})';
}

/// A callable or accessible member of a type — instance and static methods,
/// getters, setters, fields, and constructors. Bodies are
/// [DeferredOrOffset]s resolved when the backend links calls; signatures
/// are in the owner's type-parameter space.
sealed class Member {
  const Member();

  MemberOwner get owner;

  /// Convenience for the overwhelmingly common [TypeDeclMemberOwner].
  TypeDecl? get ownerDecl => switch (owner) {
    TypeDeclMemberOwner d => d.decl,
    _ => null,
  };

  MemberName get name;
  bool get isStatic;
  bool get isAbstract;
  bool get isField;
  CallSignature get signature;
  DeferredOrOffset? get body;

  /// The decl that declared this member — for mixin-folded members the
  /// applying class's decl is [ownerDecl] but the member's annotations,
  /// type parameters, and library belong to the mixin. Null where the
  /// owner isn't a type declaration.
  TypeDecl? get declaringDecl => null;
}

/// The [MemberKind] a [MethodDeclaration] declares.
MemberKind memberKind(MethodDeclaration method) =>
    switch ((method.isGetter, method.isSetter)) {
      (true, _) => MemberKind.getter,
      (_, true) => MemberKind.setter,
      _ => MemberKind.method,
    };

/// A member declared in compiled source — its declaration is an AST node
/// and its position lives in the context's member tables.
final class SourceMember extends Member {
  SourceMember({
    required this.owner,
    required this.name,
    required this.node,
    required int library,
    this.variable,
  }) : _declaredLibrary = library;

  @override
  final MemberOwner owner;
  @override
  final MemberName name;

  /// The declaring member — a [MethodDeclaration], [FieldDeclaration], or
  /// [ConstructorDeclaration]. For a synthesized default constructor this is
  /// the enclosing [ClassDeclaration].
  final AstNode node;

  /// For field accessors, the particular variable this member is for.
  final VariableDeclaration? variable;

  /// The raw declaration-map entry — the [VariableDeclaration] for fields,
  /// the AST node otherwise. This is what legacy `concreteMemberDecl`
  /// returned.
  Declaration get sourceDeclaration => variable ?? node as Declaration;

  /// The declaring library — where annotations and defaults resolve. For
  /// mixin-folded members this is the mixin's library.
  late final int library = declaringDecl?.library ?? _declaredLibrary;

  final int _declaredLibrary;

  @override
  late final TypeDecl? declaringDecl = _declaringDecl();

  /// The declaring decl is [node]'s enclosing class-like; when it isn't
  /// the owner decl itself (a mixin-folded member) the mixin's decl is
  /// found by walking the owner's supertype graph.
  TypeDecl? _declaringDecl() {
    final o = owner;
    if (o is! TypeDeclMemberOwner) return null;
    final decl = o.decl;
    final ast = node.parent?.parent;
    if (ast is! Declaration) return decl;
    if (decl is SourceTypeDecl && identical(decl.node, ast)) return decl;
    return _findDeclaringDecl(decl, ast, <TypeDecl>{}) ?? decl;
  }

  TypeDecl? _findDeclaringDecl(
    TypeDecl decl,
    AstNode target,
    Set<TypeDecl> seen,
  ) {
    if (!seen.add(decl)) return null;
    for (final sup in decl.supertypes.all) {
      final d = nominalDeclOf(sup) ?? _ctx.types.find(sup.file, sup.name);
      if (d is! SourceTypeDecl) continue;
      if (identical(d.node, target)) return d;
      final found = _findDeclaringDecl(d, target, seen);
      if (found != null) return found;
    }
    return null;
  }

  TypeDecl get _decl => (owner as TypeDeclMemberOwner).decl;

  CompilerContext get _ctx => switch (owner) {
    TypeDeclMemberOwner o => o.decl.ctx,
    ExtensionDecl o => o.ctx,
  };

  String get _ownerName => switch (owner) {
    TypeDeclMemberOwner o => o.decl.name,
    ExtensionDecl o => o.extension.name,
  };

  Map<String, TypeRef> get _ownTypeParams => switch (owner) {
    TypeDeclMemberOwner _ => declaringDecl!.ownTypeParams,
    ExtensionDecl o => o.ownTypeParams,
  };

  Declaration? get _parameterHost => switch (owner) {
    TypeDeclMemberOwner _ =>
      declaringDecl is SourceTypeDecl
          ? (declaringDecl! as SourceTypeDecl).node
          : null,
    ExtensionDecl o => o.extension.declaration,
  };

  @override
  bool get isStatic => switch (node) {
    MethodDeclaration m => m.isStatic,
    FieldDeclaration f => f.isStatic,
    ConstructorDeclaration c => c.factoryKeyword != null,
    _ => false,
  };

  @override
  bool get isAbstract => switch (node) {
    MethodDeclaration m => !m.isComplete,
    _ => false,
  };

  @override
  bool get isField => node is FieldDeclaration;

  @override
  late final CallSignature signature = _buildSignature();

  CallSignature _buildSignature() {
    final ctx = _ctx;
    final ownerParams = _ownTypeParams;
    switch (node) {
      case MethodDeclaration m:
        final methodName = '$_ownerName.${m.name.lexeme}';
        return CallSignature.source(
          ctx,
          library,
          m.typeParameters,
          m.parameters,
          owner: TypeParameterOwner(
            TypeParameterOwnerKind.method,
            library,
            methodName,
            m.offset,
          ),
          returnAnnotation: m.returnType,
          returnFallback: CoreTypes.dynamic.ref(ctx),
          typeParameters: ownerParams,
          parameterHost: _parameterHost,
        );
      case FieldDeclaration f:
        final fieldName = variable?.name.lexeme ?? name.name;
        final resolved = _fieldType(ctx, f) ?? CoreTypes.dynamic.ref(ctx);
        if (name.kind == MemberKind.setter) {
          return CallSignature(
            positional: [
              ParameterSpec(fieldName, resolved, isRequired: true, node: null),
            ],
            requiredPositional: 1,
            returnType: CoreTypes.voidType.ref(ctx),
          );
        }
        return CallSignature(
          positional: const [],
          requiredPositional: 0,
          returnType: resolved,
        );
      case ClassDeclaration _:
        return CallSignature(
          positional: const [],
          requiredPositional: 0,
          returnType: _decl.thisType,
        );
      case ConstructorDeclaration c:
        final cls = _parameterHost;
        return CallSignature.source(
          ctx,
          library,
          null,
          c.parameters,
          owner: TypeParameterOwner(
            TypeParameterOwnerKind.method,
            library,
            '$_ownerName.${c.name?.lexeme ?? ''}',
            c.offset,
          ),
          returnAnnotation: null,
          returnFallback: _decl.thisType,
          typeParameters: ownerParams,
          parameterHost: cls,
        );
      default:
        return CallSignature(
          positional: const [],
          requiredPositional: 0,
          returnType: CoreTypes.dynamic.ref(ctx),
        );
    }
  }

  /// The field's declared or inferred type, or null when it has neither —
  /// mirrors `lookupFieldType`'s null for unannotated fields.
  TypeRef? get fieldType {
    final f = node;
    if (f is! FieldDeclaration || variable == null) return null;
    return _fieldType(_ctx, f);
  }

  TypeRef? _fieldType(CompilerContext ctx, FieldDeclaration f) {
    final annotation = f.fields.type;
    if (annotation == null) {
      // `lookupFieldType` returned null here rather than dynamic — a field
      // with neither an annotation nor an inferred entry is left
      // unresolved (callers degrade to dynamic themselves).
      final inferred = ctx.inferredFieldTypes[library]?[_ownerName]?[name.name];
      if (inferred == null) return null;
      return inferred;
    }
    return TypeRef.fromAnnotation(
      ctx,
      library,
      annotation,
      typeParameters: _ownTypeParams,
    );
  }

  @override
  DeferredOrOffset? get body {
    final ctx = _ctx;
    switch (node) {
      case ClassDeclaration _:
        return null;
      case ConstructorDeclaration c:
        final ctorName = c.name?.lexeme ?? '';
        return DeferredOrOffset.lookupStatic(
          ctx,
          library,
          _ownerName,
          ctorName,
        );
      case FieldDeclaration _:
        final key = ctx.memberNameKey(name.name);
        final table = ctx.instanceDeclarationPositions[library]?[_ownerName];
        final pos = table == null ? null : table[name.kind]?[key];
        return pos != null
            ? DeferredOrOffset(offset: pos, file: library)
            : DeferredOrOffset(
                file: library,
                name: '$_ownerName.$key',
                className: _ownerName,
                methodType: name.kind,
              );
      case MethodDeclaration m:
        final memberName = ctx.memberNameOf(m.name.lexeme, memberKind(m));
        if (m.isStatic) {
          return DeferredOrOffset.lookupStatic(
            ctx,
            library,
            _ownerName,
            memberName.key,
          );
        }
        final table = ctx.instanceDeclarationPositions[library]?[_ownerName];
        final pos = table == null
            ? null
            : table[memberName.kind]?[memberName.nameKey];
        return pos != null
            ? DeferredOrOffset(offset: pos, file: library)
            : DeferredOrOffset(
                file: library,
                name: '$_ownerName.${memberName.key}',
                className: _ownerName,
                methodType: memberName.kind,
              );
      default:
        return null;
    }
  }
}

/// A member declared by a bridge definition — the runtime object supplies
/// the body; [signature] comes from the bridge function descriptor or the
/// field's bridge type annotation.
final class BridgeMember extends Member {
  BridgeMember({
    required this.owner,
    required this.name,
    required this.def,
    this.constructorKind,
  });

  @override
  final MemberOwner owner;
  @override
  final MemberName name;

  /// A [BridgeMethodDef], [BridgeConstructorDef], or [BridgeFieldDef].
  final Object def;

  final ConstructorKind? constructorKind;

  TypeDecl get _decl => (owner as TypeDeclMemberOwner).decl;

  @override
  bool get isStatic => switch (def) {
    BridgeMethodDef m => m.isStatic,
    BridgeFieldDef f => f.isStatic,
    _ => false,
  };

  @override
  bool get isAbstract => false;

  @override
  bool get isField => def is BridgeFieldDef;

  @override
  late final CallSignature signature = _buildSignature();

  CallSignature _buildSignature() {
    final ctx = _decl.ctx;
    switch (def) {
      case BridgeMethodDef m:
        return CallSignature.bridge(
          ctx,
          m.functionDescriptor,
          returnFallback: CoreTypes.dynamic.ref(ctx),
          owner: _decl.thisType,
        );
      case BridgeConstructorDef c:
        return CallSignature.bridge(
          ctx,
          c.functionDescriptor,
          returnFallback: _decl.thisType,
          owner: _decl.thisType,
        );
      case BridgeFieldDef f:
        final resolved = TypeRef.fromBridgeAnnotation(
          ctx,
          f.type,
          specifiedType: _decl.thisType,
        );
        if (name.kind == MemberKind.setter) {
          return CallSignature(
            positional: [ParameterSpec(name.name, resolved, isRequired: true)],
            requiredPositional: 1,
            returnType: CoreTypes.voidType.ref(ctx),
          );
        }
        return CallSignature(
          positional: const [],
          requiredPositional: 0,
          returnType: resolved,
        );
      default:
        return CallSignature(
          positional: const [],
          requiredPositional: 0,
          returnType: CoreTypes.dynamic.ref(ctx),
        );
    }
  }

  @override
  DeferredOrOffset? get body => null;
}

/// Member lookup on a declaration — instance members, static members, and
/// constructors declared ON this declaration (no inheritance).
extension TypeDeclMembers on TypeDecl {
  /// The [MemberOwner] for members this declaration declares.
  TypeDeclMemberOwner get memberOwner => TypeDeclMemberOwner(this);

  /// The member named [name] declared directly on this type — fields
  /// resolve to their accessor members (`getter`/`setter`), so asking for
  /// a field's setter returns the setter member. Instance-map keys:
  /// methods at `name@arity`, fields at the bare `name`, getters `name*g`,
  /// setters `name*s` (private members use raw names — the map is already
  /// class-scoped). Interface lookups fall back to the field/getter slots
  /// (`x.m()` on a function-typed field or getter result resolves that
  /// member — it dispatches `.call`); [forImplementation] mirrors
  /// `concreteMemberDecl` — a single key, no fallback.
  Member? declaredMember(MemberName name, {bool forImplementation = false}) {
    final self = this;
    if (self is SourceTypeDecl) {
      final map = ctx.instanceDeclarationsMap[library]?[this.name];
      // Position tables qualify private names as `uri::_x`; the instance
      // map stores the raw `_x` — probe both spellings.
      Object? probe(String key) {
        final found = map?[key];
        if (found != null) return found;
        final sep = key.lastIndexOf('::');
        return sep < 0 ? null : map?[key.substring(sep + 2)];
      }

      Object? found;
      switch (name.kind) {
        case MemberKind.method:
          found = probe(name.nameKey);
          if (found == null && !forImplementation) {
            final prefix = '${name.name}@';
            for (final entry
                in map?.entries ??
                    const Iterable<MapEntry<String, Declaration>>.empty()) {
              if (entry.key.startsWith(prefix)) {
                found = entry.value;
                break;
              }
            }
          }
          if (found == null && !forImplementation) {
            found = probe(MemberName.getter(name.name).key);
          }
        case MemberKind.getter:
          found = probe(
            MemberName(
              name.name,
              MemberKind.getter,
              privateLibraryUri: name.privateLibraryUri,
            ).key,
          );
          if (found == null && !forImplementation) {
            found = probe(name.nameKey);
          }
        case MemberKind.setter:
          // `x*s` only — a field's setter slot is resolved through the
          // GetSet machinery, not the member map.
          found = probe(
            MemberName(
              name.name,
              MemberKind.setter,
              privateLibraryUri: name.privateLibraryUri,
            ).key,
          );
        case MemberKind.constructor:
          found = null;
      }
      final member = self.sourceMemberOf(found, name);
      // `concreteMemberDecl` filters abstract declarations — a
      // body-less re-declaration never supplies the implementation.
      if (forImplementation && (member?.isAbstract ?? false)) {
        return null;
      }
      return member;
    }
    final classDef = (self as BridgeTypeDecl).classDef;
    final enumDef = self.enumDef;
    switch (name.kind) {
      case MemberKind.method:
        final def = classDef?.methods[name.name] ?? enumDef?.methods[name.name];
        if (def == null || def.isStatic) {
          if (forImplementation) return null;
          final getter =
              classDef?.getters[name.name] ?? enumDef?.getters[name.name];
          if (getter == null || getter.isStatic) return null;
          return BridgeMember(
            owner: memberOwner,
            name: MemberName.getter(name.name),
            def: getter,
          );
        }
        return BridgeMember(
          owner: memberOwner,
          name: MemberName(name.name, name.kind),
          def: def,
        );
      case MemberKind.getter || MemberKind.setter:
        var def =
            (name.kind == MemberKind.getter
                ? classDef?.getters[name.name] ?? enumDef?.getters[name.name]
                : classDef?.setters[name.name] ??
                      enumDef?.setters[name.name]) ??
            classDef?.fields[name.name] ??
            enumDef?.fields[name.name];
        if (def == null && name.kind == MemberKind.getter) {
          // A getter probe covers method reads too — `x.m` on a bridged
          // method is a bound tear-off, matching the source map where a
          // method entry sits at the bare `name` key.
          def = classDef?.methods[name.name] ?? enumDef?.methods[name.name];
        }
        if (def == null) return null;
        if ((def is BridgeMethodDef && def.isStatic) ||
            (def is BridgeFieldDef && def.isStatic)) {
          return null;
        }
        return BridgeMember(owner: memberOwner, name: name, def: def);
      case MemberKind.constructor:
        return null;
    }
  }

  /// Wraps a declaration-map child ([MethodDeclaration],
  /// [VariableDeclaration], [ConstructorDeclaration], or null) as a
  /// [SourceMember] of this type — fields carry their
  /// [VariableDeclaration] in `member.variable` and their wrapper
  /// ([FieldDeclaration]/[TopLevelVariableDeclaration]) in `member.node`.
  Member? sourceMemberOf(Object? declaration, MemberName name) {
    if (this is! SourceTypeDecl) return null;
    switch (declaration) {
      case MethodDeclaration m:
        return SourceMember(
          owner: memberOwner,
          name: name,
          node: m,
          library: library,
        );
      case VariableDeclaration v:
        return SourceMember(
          owner: memberOwner,
          name: name,
          node: v.parent!.parent!,
          library: library,
          variable: v,
        );
      case ConstructorDeclaration c:
        // `Class.ctor` entries share the static-member namespace.
        return SourceMember(
          owner: memberOwner,
          name: name,
          node: c,
          library: library,
        );
      case _:
        return null;
    }
  }

  /// A static member by name — `method` covers static methods; `getter`
  /// and `setter` cover static getters, setters, and field accessors.
  /// A `method` lookup also probes the getter key, matching
  /// `resolveStaticMethod`'s `'$name*g'` fallback.
  Member? staticMember(String name, MemberKind kind) {
    final self = this;
    if (self is SourceTypeDecl) {
      final map = ctx.topLevelDeclarationsMap[library];
      final prefix = '${this.name}.';
      final memberName = MemberName(name, kind);
      final entry =
          switch (kind) {
            MemberKind.method => map?['$prefix$name'] ?? map?['$prefix$name*g'],
            MemberKind.getter ||
            MemberKind.setter => map?['$prefix${memberName.key}'],
            MemberKind.constructor => null,
          } ??
          map?['$prefix$name'];
      if (entry == null) return null;
      final declaration = entry.declaration;
      if (declaration != null) {
        return sourceMemberOf(
          declaration,
          declaration is VariableDeclaration ? memberName : memberName,
        );
      }
      final bridge = entry.bridge;
      return bridge == null
          ? null
          : BridgeMember(owner: memberOwner, name: memberName, def: bridge);
    }
    final classDef = (self as BridgeTypeDecl).classDef;
    final enumDef = self.enumDef;
    switch (kind) {
      case MemberKind.method:
        final def = classDef?.methods[name] ?? enumDef?.methods[name];
        if (def != null && def.isStatic) {
          return BridgeMember(
            owner: memberOwner,
            name: MemberName(name, kind),
            def: def,
          );
        }
        // Named constructors share the `Class.name` static namespace.
        final ctor = classDef?.constructors[name];
        if (ctor == null) return null;
        return BridgeMember(
          owner: memberOwner,
          name: MemberName(name, kind),
          def: ctor,
        );
      case MemberKind.getter || MemberKind.setter:
        final def = (kind == MemberKind.getter
            ? classDef?.getters[name] ?? enumDef?.getters[name]
            : classDef?.setters[name] ?? enumDef?.setters[name]);
        if (def != null && def.isStatic) {
          return BridgeMember(
            owner: memberOwner,
            name: MemberName(name, kind),
            def: def,
          );
        }
        final field = classDef?.fields[name] ?? enumDef?.fields[name];
        if (field == null || !field.isStatic) return null;
        return BridgeMember(
          owner: memberOwner,
          name: MemberName(name, kind),
          def: field,
        );
      case MemberKind.constructor:
        return null;
    }
  }

  /// A constructor by name (empty for the default) and kind. Source
  /// classes without a declared default constructor get a synthesized
  /// generative one.
  Member? constructor(String name, ConstructorKind kind) {
    final self = this;
    if (self is SourceTypeDecl) {
      final members = switch (self.node) {
        ClassDeclaration c => c.body.members,
        MixinDeclaration m => m.body.members,
        EnumDeclaration e => e.body.members,
        _ => const <ClassMember>[],
      };
      var hasCtor = false;
      for (final member in members) {
        if (member is! ConstructorDeclaration) continue;
        hasCtor = true;
        final isFactory = member.factoryKeyword != null;
        if (isFactory != (kind == ConstructorKind.factory)) continue;
        if ((member.name?.lexeme ?? '') == name) {
          return SourceMember(
            owner: memberOwner,
            name: MemberName('${this.name}.$name', MemberKind.constructor),
            node: member,
            library: library,
          );
        }
      }
      if (name == '' &&
          kind == ConstructorKind.generative &&
          self.node is ClassDeclaration &&
          !hasCtor) {
        return SourceMember(
          owner: memberOwner,
          name: MemberName('${this.name}.', MemberKind.constructor),
          node: self.node,
          library: library,
        );
      }
      return null;
    }
    final def = (self as BridgeTypeDecl).classDef?.constructors[name];
    if (def == null) return null;
    return BridgeMember(
      owner: memberOwner,
      name: MemberName('${this.name}.$name', MemberKind.constructor),
      def: def,
      constructorKind: def.isFactory
          ? ConstructorKind.factory
          : ConstructorKind.generative,
    );
  }
}
