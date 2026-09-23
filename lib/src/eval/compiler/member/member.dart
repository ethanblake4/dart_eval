import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
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
      identical(this, other) || other is TypeDeclMemberOwner;

  @override
  int get hashCode => decl.hashCode;

  @override
  String toString() => 'memberOwner(${decl.libraryUri}:${decl.name})';
}

/// A member declared on an [EvalExtension] — the extension namespace
/// keeps its own lookup, but extension members still get signatures.
final class ExtensionDecl extends MemberOwner {
  const ExtensionDecl(this.extension);

  final EvalExtension extension;

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
}

/// The [MemberKind] a [MethodDeclaration] declares.
MemberKind memberKind(MethodDeclaration method) => switch ((
  method.isGetter,
  method.isSetter,
)) {
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
    required this.library,
    this.variable,
  });

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

  /// The declaring library — where annotations and defaults resolve.
  final int library;

  TypeDecl get _decl => (owner as TypeDeclMemberOwner).decl;

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
    final ctx = _decl.ctx;
    final ownerParams = _decl.ownTypeParams;
    switch (node) {
      case MethodDeclaration m:
        final methodName = '${_decl.name}.${m.name.lexeme}';
        return CallSignature.source(
          ctx,
          library,
          m.typeParameters,
          m.parameters,
          owner: TypeParameterOwner(
            TypeParameterOwnerKind.method,
            library,
            methodName,
            ctx.instanceMethodKey(m.name.lexeme, 0).hashCode & 0x7fffffff,
          ),
          returnAnnotation: m.returnType,
          returnFallback: switch (m.body) {
            ExpressionFunctionBody() => CoreTypes.dynamic.ref(ctx),
            _ => CoreTypes.dynamic.ref(ctx),
          },
          typeParameters: ownerParams,
          parameterHost: _decl is SourceTypeDecl
              ? (_decl as SourceTypeDecl).node
              : null,
        );
      case FieldDeclaration f:
        final fieldName = variable?.name.lexeme ?? name.name;
        final resolved = _fieldType(ctx, f);
        if (name.kind == MemberKind.setter) {
          return CallSignature(
            positional: [
              ParameterSpec(
                fieldName,
                resolved,
                isRequired: true,
                node: null,
              ),
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
        final cls = _decl is SourceTypeDecl
            ? (_decl as SourceTypeDecl).node
            : null;
        return CallSignature.source(
          ctx,
          library,
          null,
          c.parameters,
          owner: TypeParameterOwner(
            TypeParameterOwnerKind.method,
            library,
            '${_decl.name}.${c.name?.lexeme ?? ''}',
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

  TypeRef _fieldType(CompilerContext ctx, FieldDeclaration f) {
    final annotation = f.fields.type;
    if (annotation == null) return CoreTypes.dynamic.ref(ctx);
    return TypeRef.fromAnnotation(
      ctx,
      library,
      annotation,
      typeParameters: _decl.ownTypeParams,
    );
  }

  @override
  DeferredOrOffset? get body {
    final ctx = _decl.ctx;
    switch (node) {
      case ClassDeclaration _:
        return null;
      case ConstructorDeclaration c:
        final ctorName = c.name?.lexeme ?? '';
        return DeferredOrOffset.lookupStatic(
          ctx,
          library,
          _decl.name,
          ctorName,
        );
      case FieldDeclaration _:
        final key = ctx.memberNameKey(name.name);
        final table = ctx.instanceDeclarationPositions[library]?[_decl.name];
        final pos = table == null
            ? null
            : (table[name.kind.positionIndex] as Map?)?[key] as int?;
        return pos != null
            ? DeferredOrOffset(offset: pos, file: library)
            : DeferredOrOffset(
                file: library,
                name: '${_decl.name}.$key',
                className: _decl.name,
                methodType: name.kind.positionIndex,
                targetName: key,
              );
      case MethodDeclaration m:
        final memberName = ctx.memberNameOf(m.name.lexeme, memberKind(m));
        if (m.isStatic) {
          return DeferredOrOffset.lookupStatic(
            ctx,
            library,
            _decl.name,
            memberName.key,
          );
        }
        final table = ctx.instanceDeclarationPositions[library]?[_decl.name];
        final pos = table == null
            ? null
            : (table[memberName.kind.positionIndex] as Map?)?[memberName.nameKey]
                  as int?;
        return pos != null
            ? DeferredOrOffset(offset: pos, file: library)
            : DeferredOrOffset(
                file: library,
                name: '${_decl.name}.${memberName.key}',
                className: _decl.name,
                methodType: memberName.kind.positionIndex,
                targetName: memberName.nameKey,
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
        );
      case BridgeConstructorDef c:
        return CallSignature.bridge(
          ctx,
          c.functionDescriptor,
          returnFallback: _decl.thisType,
        );
      case BridgeFieldDef f:
        final resolved = TypeRef.fromBridgeAnnotation(ctx, f.type);
        if (name.kind == MemberKind.setter) {
          return CallSignature(
            positional: [
              ParameterSpec(name.name, resolved, isRequired: true),
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

  List<ClassMember> get _ownSourceMembers {
    final self = this;
    if (self is! SourceTypeDecl) return const [];
    return switch (self.node) {
      ClassDeclaration c => c.body.members,
      MixinDeclaration m => m.body.members,
      EnumDeclaration e => e.body.members,
      _ => const <ClassMember>[],
    };
  }

  MemberName _ownName(String lexeme, MemberKind kind) => MemberName(
    lexeme,
    kind,
    privateLibraryUri: lexeme.startsWith('_') ? libraryUri : null,
  );

  /// The member named [name] declared directly on this type — fields
  /// resolve to their accessor members (`getter`/`setter`), so asking for
  /// a field's setter returns the setter member.
  Member? declaredMember(MemberName name) {
    final self = this;
    if (self is SourceTypeDecl) {
      for (final member in _ownSourceMembers) {
        switch (member) {
          case MethodDeclaration m when !m.isStatic:
            if (_ownName(m.name.lexeme, memberKind(m)).nameKey ==
                name.nameKey) {
              return SourceMember(
                owner: memberOwner,
                name: name,
                node: m,
                library: library,
              );
            }
          case FieldDeclaration f when !f.isStatic:
            for (final variable in f.fields.variables) {
              final lexeme = variable.name.lexeme;
              if (_ownName(lexeme, MemberKind.getter).nameKey ==
                      name.nameKey &&
                  (name.kind != MemberKind.setter || !variable.isFinal)) {
                return SourceMember(
                  owner: memberOwner,
                  name: name,
                  node: f,
                  library: library,
                  variable: variable,
                );
              }
            }
          case _:
        }
      }
      return null;
    }
    final classDef = (self as BridgeTypeDecl).classDef;
    final enumDef = self.enumDef;
    final methods = classDef?.methods ?? enumDef?.methods ?? const {};
    final getters = classDef?.getters ?? enumDef?.getters ?? const {};
    final setters = classDef?.setters ?? enumDef?.setters ?? const {};
    final fields = classDef?.fields ?? enumDef?.fields ?? const {};
    switch (name.kind) {
      case MemberKind.method:
        final def = methods[name.name];
        if (def == null || def.isStatic) return null;
        return BridgeMember(owner: memberOwner, name: name, def: def);
      case MemberKind.getter:
        final def = getters[name.name];
        if (def != null && !def.isStatic) {
          return BridgeMember(owner: memberOwner, name: name, def: def);
        }
        final field = fields[name.name];
        if (field == null || field.isStatic) return null;
        return BridgeMember(owner: memberOwner, name: name, def: field);
      case MemberKind.setter:
        final def = setters[name.name];
        if (def != null && !def.isStatic) {
          return BridgeMember(owner: memberOwner, name: name, def: def);
        }
        final field = fields[name.name];
        if (field == null || field.isStatic) return null;
        return BridgeMember(owner: memberOwner, name: name, def: field);
      case MemberKind.constructor:
        return null;
    }
  }

  /// A static member by name — `method` covers static methods; `getter`
  /// and `setter` cover static getters, setters, and field accessors.
  Member? staticMember(String name, MemberKind kind) {
    final self = this;
    if (self is SourceTypeDecl) {
      for (final member in _ownSourceMembers) {
        switch (member) {
          case MethodDeclaration m when m.isStatic:
            final memberName = _ownName(m.name.lexeme, memberKind(m));
            if (memberName.name == name && memberName.kind == kind) {
              return SourceMember(
                owner: memberOwner,
                name: memberName,
                node: m,
                library: library,
              );
            }
          case FieldDeclaration f when f.isStatic:
            for (final variable in f.fields.variables) {
              if (variable.name.lexeme != name) continue;
              if (kind == MemberKind.setter && variable.isFinal) continue;
              return SourceMember(
                owner: memberOwner,
                name: _ownName(name, kind),
                node: f,
                library: library,
                variable: variable,
              );
            }
          case _:
        }
      }
      return null;
    }
    final classDef = (self as BridgeTypeDecl).classDef;
    final enumDef = self.enumDef;
    switch (kind) {
      case MemberKind.method:
        final def = classDef?.methods[name] ?? enumDef?.methods[name];
        if (def == null || !def.isStatic) return null;
        return BridgeMember(
          owner: memberOwner,
          name: MemberName(name, kind),
          def: def,
        );
      case MemberKind.getter || MemberKind.setter:
        final def =
            (kind == MemberKind.getter
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
      for (final member in _ownSourceMembers) {
        if (member is! ConstructorDeclaration) continue;
        final isFactory = member.factoryKeyword != null;
        if (isFactory != (kind == ConstructorKind.factory)) continue;
        if ((member.name?.lexeme ?? '') == name) {
          return SourceMember(
            owner: memberOwner,
            name: MemberName(
              '${this.name}.$name',
              MemberKind.constructor,
            ),
            node: member,
            library: library,
          );
        }
      }
      if (name == '' &&
          kind == ConstructorKind.generative &&
          self.node is ClassDeclaration &&
          !_ownSourceMembers.any((m) => m is ConstructorDeclaration)) {
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
