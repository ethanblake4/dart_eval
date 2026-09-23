import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/member/resolved_member.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// The compiler's member-resolution service — the single owner of "who
/// declares member X on type Y". It answers two questions:
///
/// - [interfaceMember]: the member in the receiver type's public interface
///   (what a statically typed call resolves to — walks mixins, the
///   superclass, and implemented interfaces in interface order).
/// - [implementation]: the concrete member a call dispatches to (the first
///   non-abstract declaration along the superclass chain).
///
/// Plus the static side ([staticMember]), member-override checks
/// ([overriddenBelow]), and dispatch facts ([needsOwnerLink]).
final class MemberLookup {
  const MemberLookup(this.ctx);

  final CompilerContext ctx;

  /// The member named [name] in [type]'s public interface. Throws
  /// [CompileError] when no member exists — callers wanting a probe use
  /// [tryInterfaceMember].
  /// [superclassFirst] matches `resolveInstanceMethod`'s walk order
  /// (superclass, then mixins and interfaces); the default matches
  /// `resolveInstanceDeclaration` (mixins first — a mixin's declaration
  /// shadows the superclass's, mirroring real override semantics).
  ResolvedMember interfaceMember(
    TypeRef type,
    MemberName name, {
    AstNode? source,
    TypeRef? bottomType,
    bool superclassFirst = false,
  }) =>
      _interfaceMember(
        type,
        name,
        source: source,
        bottomType: bottomType,
        superclassFirst: superclassFirst,
        chain: const [],
      );

  ResolvedMember _interfaceMember(
    TypeRef type,
    MemberName name, {
    AstNode? source,
    TypeRef? bottomType,
    required bool superclassFirst,
    required List<String> chain,
  }) {
    final marker = '${type.file}:${type.name}';
    if (chain.contains(marker)) {
      // A hierarchy cycle (the bridge model's `Object extends dynamic`
      // edge) means the member isn't declared anywhere reachable.
      throw CompileError('Unknown method ${type.name}.${name.name}', source);
    }
    chain = [...chain, marker];
    if (type.isTypeParameter) {
      final bound = (type as TypeParameterTypeRef).parameter.bound ??
          CoreTypes.dynamic.ref(ctx);
      if (bound.isSpec(CoreTypes.dynamic)) {
        throw CompileError(
          'Cannot resolve ${name.name} on unbounded type parameter $type',
          source,
        );
      }
      return _interfaceMember(
        bound,
        name,
        source: source,
        bottomType: bottomType ?? type,
        superclassFirst: superclassFirst,
        chain: chain,
      );
    }
    final decl = type.decl ?? ctx.types.find(type.file, type.name);
    if (decl == null) {
      // Structural types (records, function types) have no declaration of
      // their own; their members come from the nominal supertype.
      final extendsType = ctx.typeSystem.superclassOf(type);
      if (extendsType != null) {
        return _interfaceMember(
          extendsType,
          name,
          source: source,
          bottomType: bottomType ?? type,
          superclassFirst: superclassFirst,
          chain: chain,
        );
      }
      throw CompileError(
        'Missing declaration for instance method ${name.name} on '
        '${type.name}',
        source,
      );
    }
    final bottomType0 = bottomType ?? type;

    final member = decl.declaredMember(name);
    if (member != null) {
      return ResolvedMember(member, _interfaceView(type, decl));
    }

    if (decl.kind == TypeDeclKind.enumDecl) {
      // Enum declarations resolve undeclared members through the Enum
      // bridge declaration (and transitively Object).
      return _interfaceMember(
        CoreTypes.enumType.ref(ctx),
        name,
        source: source,
        bottomType: bottomType0,
        superclassFirst: superclassFirst,
        chain: chain,
      );
    }

    // The interface walk: mixins (application order), then the superclass,
    // then implemented interfaces — members folded from mixins already
    // answered above through the declaration's own member table.
    if (superclassFirst) {
      final superclass = ctx.typeSystem.superclassOf(type);
      if (superclass != null) {
        final result = _tryInterfaceMember(
          superclass,
          name,
          source,
          bottomType0,
          chain,
          superclassFirst,
        );
        if (result != null) return result;
      }
    }
    for (final mixin in ctx.typeSystem.mixinsOf(type)) {
      final result = _tryInterfaceMember(
        mixin,
        name,
        source,
        bottomType0,
        chain,
        superclassFirst,
      );
      if (result != null) return result;
    }
    if (!superclassFirst) {
      final superclass = ctx.typeSystem.superclassOf(type);
      if (superclass != null) {
        final result = _tryInterfaceMember(
          superclass,
          name,
          source,
          bottomType0,
          chain,
          superclassFirst,
        );
        if (result != null) return result;
      }
    }
    for (final interface in ctx.typeSystem.interfacesOf(type)) {
      final result = _tryInterfaceMember(
        interface,
        name,
        source,
        bottomType0,
        chain,
        superclassFirst,
      );
      if (result != null) return result;
    }
    if (type.isSpec(CoreTypes.object)) {
      throw CompileError('Unknown method ${bottomType0.name}.${name.name}', source);
    }
    return _interfaceMember(
      CoreTypes.object.ref(ctx),
      name,
      source: source,
      bottomType: bottomType0,
      superclassFirst: superclassFirst,
      chain: chain,
    );
  }

  /// [interfaceMember], returning null instead of throwing when [type]
  /// lacks [name].
  ResolvedMember? tryInterfaceMember(
    TypeRef type,
    MemberName name, {
    AstNode? source,
    TypeRef? bottomType,
  }) {
    try {
      return interfaceMember(type, name, source: source, bottomType: bottomType);
    } on CompileError catch (e) {
      if (e.message.startsWith('Unknown method')) return null;
      rethrow;
    }
  }

  ResolvedMember? _tryInterfaceMember(
    TypeRef type,
    MemberName name,
    AstNode? source,
    TypeRef bottomType0,
    List<String> chain,
    bool superclassFirst,
  ) {
    try {
      return _interfaceMember(
        type,
        name,
        source: source,
        bottomType: bottomType0,
        superclassFirst: superclassFirst,
        chain: chain,
      );
    } on CompileError catch (e) {
      if (e.message.startsWith('Unknown method')) return null;
      rethrow;
    }
  }

  /// Whether [type] declares or inherits [name] in its interface —
  /// `hasInstanceMethod`'s probe: any resolution failure counts as absent.
  bool hasInstanceMember(TypeRef type, MemberName name) {
    try {
      interfaceMember(type, name);
      return true;
    } on CompileError {
      return false;
    }
  }

  /// The receiver's view of [decl]'s parameter space — `C<T>.member` seen
  /// through `C<int>` instantiates `T → int` in the member signature.
  TypeRef _interfaceView(TypeRef receiver, TypeDecl decl) {
    if (receiver is! InterfaceTypeRef) return decl.thisType;
    final found = ctx.typeSystem.asInstanceOf(receiver, decl);
    return found ?? decl.thisType;
  }

  /// A static member of [type] by name. Returns null when absent —
  /// `resolveStaticMethod`'s callers throw their own error messages.
  Member? staticMember(
    TypeRef type,
    String name,
    MemberKind kind,
  ) {
    final decl = type.decl ?? ctx.types.find(type.file, type.name);
    return decl?.staticMember(name, kind);
  }

  /// The class at-or-above [type] (in superclass order) that supplies the
  /// concrete implementation of [name] — null when the member is only
  /// reachable through a bridged ancestor or isn't on the chain.
  Member? implementation(
    TypeRef type,
    MemberName name,
  ) {
    return _implementationAt(type, name)?.$2;
  }

  /// The declaring [TypeDecl] whose [implementation] supplies [name] —
  /// what the legacy `memberOwner` returned as a [TypeRef].
  TypeRef? implementationOwner(TypeRef type, MemberName name) {
    return _implementationAt(type, name)?.$1;
  }

  /// The first link in [type]'s chain concretely implementing [name],
  /// with the member itself. `memberOwner` only counts members that are
  /// actually compiled — registration in `instanceDeclarationPositions`
  /// happens when the body is compiled.
  (TypeRef, Member)? _implementationAt(TypeRef type, MemberName name) {
    if (hasBridgeSuperclass(ctx, type)) {
      return null;
    }
    for (final link in [type, ...ctx.typeSystem.superclassChain(type)]) {
      final positions =
          ctx.instanceDeclarationPositions[link.file]?[link.name]
              ?[name.kind.positionIndex] as Map?;
      final positionsHit = positions != null &&
          (positions.containsKey(name.name) ||
              (name.name.startsWith('_') &&
                  positions.containsKey(
                    '${ctx.libraryUri(link.file)}::${name.name}',
                  )));
      if (!positionsHit) continue;
      final member = concreteMemberOn(link, name);
      if (member != null) return (link, member);
    }
    return null;
  }

  /// The member [link] concretely declares as [name] —
  /// `concreteMemberDecl`'s single-link probe: no chain walk, no
  /// interface fallback slots, abstract declarations excluded.
  Member? concreteMemberOn(TypeRef link, MemberName name) {
    final decl = ctx.types.find(link.file, link.name);
    if (decl is! SourceTypeDecl) return null;
    return decl.declaredMember(_linkName(name, link),
        forImplementation: true);
  }

  /// [name] qualified with [link]'s library: a private member folded in
  /// from another library is stored under `uri::_name`.
  MemberName _linkName(MemberName name, TypeRef link) => MemberName(
        name.name,
        name.kind,
        privateLibraryUri: name.name.startsWith('_')
            ? name.privateLibraryUri ?? ctx.libraryUri(link.file)
            : null,
      );

  /// Like [implementation], but for a receiver statically typed [type]
  /// that may hold a subclass instance: a fixed target exists only while
  /// no descendant of [type] redeclares [name].
  Member? directImplementation(TypeRef type, MemberName name) {
    if (overriddenBelow(type, name.name)) return null;
    return implementation(type, name);
  }

  TypeRef? directImplementationOwner(TypeRef type, MemberName name) {
    if (overriddenBelow(type, name.name)) return null;
    return implementationOwner(type, name);
  }

  /// Whether a subclass of [type] redeclares the member — the
  /// `memberOverriddenInSubclass` fact the owner table already tracks.
  bool overriddenBelow(TypeRef type, String name) =>
      ctx.memberOverriddenInSubclass(type.file, type.name, name);

  /// Whether calling [name] implemented on [owner] requires `this` bound
  /// to the declaring link — bodies that never touch `super` run on any
  /// link; synthesized field accessors always need theirs.
  bool needsOwnerLink(
    TypeRef owner,
    MemberName name,
  ) {
    final decl = ctx.types.find(owner.file, owner.name);
    final member = decl is SourceTypeDecl
        ? decl.declaredMember(name, forImplementation: true)
        : null;
    final node = member is SourceMember ? member.node : null;
    if (node is! MethodDeclaration) return true;
    var usesSuper = false;
    node.body.accept(_SuperSeeker(() => usesSuper = true));
    return usesSuper;
  }

  /// The declared type of field-accessor [name] on [type] — what
  /// `lookupFieldType` produced: the field/getter/setter annotation (or
  /// inferred type) instantiated through the receiver's arguments, or the
  /// setter's parameter type when [forSet].
  TypeRef? fieldType(
    TypeRef type,
    String name, {
    bool forFieldFormal = false,
    bool forSet = false,
    AstNode? source,
    Substitution substitutions = Substitution.empty,
  }) {
    if (type.isSpec(CoreTypes.dynamic)) return null;
    if (type.isTypeParameter) {
      final bound = (type as TypeParameterTypeRef).parameter.bound;
      if (bound == null) return null;
      return fieldType(
        bound,
        name,
        forFieldFormal: forFieldFormal,
        forSet: forSet,
        source: source,
        substitutions: substitutions,
      );
    }
    if (type is RecordTypeRef) {
      final named0 = type.named[name];
      if (named0 != null) return named0;
      if (name.startsWith('\$')) {
        final index = int.tryParse(name.substring(1));
        if (index != null && index >= 1 && index <= type.positional.length) {
          return type.positional[index - 1];
        }
      }
    }
    final decl = type.decl ?? ctx.types.find(type.file, type.name);
    if (decl == null) {
      final extendsType = ctx.typeSystem.superclassOf(type);
      if (extendsType == null) return null;
      return fieldType(
        extendsType,
        name,
        forFieldFormal: forFieldFormal,
        forSet: forSet,
        source: source,
        substitutions: substitutions,
      );
    }
    Member? member;
    var memberKind = MemberKind.getter;
    if (decl is SourceTypeDecl) {
      final map = ctx.instanceDeclarationsMap[decl.library]?[decl.name];
      if (map != null) {
        final private = name.startsWith('_') ? decl.libraryUri : null;
        Object? entry;
        if (forSet) {
          entry = map[MemberName(
            name,
            MemberKind.setter,
            privateLibraryUri: private,
          ).key];
          if (entry != null && entry is! MethodDeclaration) {
            throw CompileError(
              'Cannot query setter type of F${decl.library}:${decl.name}.$name, '
              'which is not a method',
              source,
            );
          }
          // A setter parameter with no type annotation has no queryable
          // field type (matching lookupFieldType's null).
          if (entry is MethodDeclaration &&
              entry.parameters?.parameters.firstOrNull?.type == null) {
            return null;
          }
          memberKind = MemberKind.setter;
        }
        entry ??= map[name];
        if (entry != null) {
          if (entry is MethodDeclaration &&
              !entry.isGetter &&
              !entry.isSetter) {
            return CoreTypes.function.ref(ctx);
          }
          // Getters and setters are members, not variables — the member
          // path below resolves their types; only a non-member entry must
          // be a declared field.
          if (entry is! VariableDeclaration && entry is! MethodDeclaration) {
            throw CompileError(
              'Cannot query field type of ${decl.name}.$name, '
              'which is not a field',
              source,
            );
          }
          memberKind = MemberKind.getter;
          if (entry is MethodDeclaration && entry.isSetter && forSet) {
            memberKind = MemberKind.setter;
          }
        }
        if (entry == null && !forFieldFormal) {
          entry = map[MemberName(
            name,
            MemberKind.getter,
            privateLibraryUri: private,
          ).key];
          if (entry != null && entry is! MethodDeclaration) {
            throw CompileError(
              'Cannot query getter type of F${decl.library}:${decl.name}.$name, '
              'which is not a method',
              source,
            );
          }
          memberKind = MemberKind.getter;
        }
        member = entry == null
            ? null
            : decl.sourceMemberOf(
                entry,
                MemberName(
                  name,
                  memberKind,
                  privateLibraryUri: private,
                ),
              );
      }
    } else {
      member = decl.declaredMember(
        MemberName(
          name,
          forSet ? MemberKind.setter : MemberKind.getter,
          privateLibraryUri: name.startsWith('_') ? decl.libraryUri : null,
        ),
      );
    }
    if (member == null) {
      final extendsType = ctx.typeSystem.superclassOf(type);
      if (extendsType == null) return null;
      return fieldType(
        extendsType,
        name,
        forFieldFormal: forFieldFormal,
        forSet: forSet,
        source: source,
        substitutions: substitutions,
      );
    }
    final resolved = ResolvedMember(member, _interfaceView(type, decl));
    final signature = resolved.signature;
    final result = forSet && signature.positional.isNotEmpty
        ? signature.positional.first.type
        : resolved.fieldType;
    if (result == null) return null;
    if (substitutions.isNotEmpty) {
      return result.substituteTypeParameters(substitutions);
    }
    return result;
  }
}

class _SuperSeeker extends RecursiveAstVisitor<void> {
  _SuperSeeker(this.onSuper);
  final void Function() onSuper;

  @override
  void visitSuperExpression(SuperExpression node) => onSuper();
}
