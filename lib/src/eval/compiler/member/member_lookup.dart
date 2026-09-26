import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart'
    show clauseNamedType;
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/call_signature.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/mixin_application.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/member/resolved_member.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// The compiler's member-resolution service — the single owner of "who
/// declares member X on type Y". It answers two questions:
///
/// - [interfaceMember]: the member in the receiver type's public interface
///   (what a statically typed call resolves to — walks mixins, the
///   superclass, and implemented interfaces in interface order).
/// - [implementationOwner]: the type supplying the concrete member a call
///   dispatches to (the first non-abstract declaration along the superclass
///   chain).
///
/// Plus the static side ([staticMember]), member-override checks
/// ([overriddenBelow]), and dispatch facts ([needsOwnerLink]).
final class MemberLookup {
  const MemberLookup(this.ctx);

  final CompilerContext ctx;

  /// The exact earlier mixin body visible from the current member's lexical
  /// layer. Runtime member lookup on the host would see a later override.
  FoldedMemberBody? lexicalSuperBody(String name, MemberKind kind) {
    final hit = ctx.lexicalSuperMembers[MemberName(name, kind).key];
    return hit;
  }

  /// Resolve a folded body's source declaration without consulting the
  /// host's dispatch table, which may already contain a later override.
  Member? lexicalSuperMember(FoldedMemberBody body) {
    final owner = body.declaration.parent?.parent;
    if (owner is! Declaration) return null;
    final type = TypeRef.lookupDeclaration(ctx, body.library, owner);
    final kind = body.declaration.isGetter
        ? MemberKind.getter
        : body.declaration.isSetter
        ? MemberKind.setter
        : MemberKind.method;
    return concreteMemberOn(
      type,
      MemberName(body.declaration.name.lexeme, kind),
    );
  }

  TypeRef lexicalSuperResultType(FoldedMemberBody body) {
    final annotation = body.declaration.returnType;
    if (annotation == null) return CoreTypes.dynamic.ref(ctx);
    return TypeRef.fromAnnotation(
      ctx,
      body.library,
      annotation,
      typeParameters: lexicalSuperTypeParameters(body),
    );
  }

  TypeRef lexicalSuperSetterType(FoldedMemberBody body) {
    final parameters = body.declaration.parameters?.parameters;
    final parameter = parameters == null || parameters.isEmpty
        ? null
        : parameters.first;
    if (parameter?.type == null) return CoreTypes.dynamic.ref(ctx);
    return ctx.typeFactory.formalParameterAnnotationType(
      body.library,
      parameter!,
      typeParameters: lexicalSuperTypeParameters(body),
    );
  }

  Map<String, TypeRef> lexicalSuperTypeParameters(FoldedMemberBody body) =>
      foldedMemberTypeParams(
        ctx,
        ctx.currentClass!,
        body.declaration,
        body.library,
        ctx.enclosingLibrary ?? ctx.library,
      ) ??
      const {};

  /// The target of a lexical `super.name` access. [hops] are the superclass
  /// links between the initial super receiver and [owner]. A mixin member
  /// folded into the applying class has no hops and uses that class as owner.
  /// [abstractGetter] preserves the invocation shape when a call reaches
  /// noSuchMethod instead of a concrete member.
  ({TypeRef owner, List<TypeRef> hops, bool found, bool? abstractGetter})
  superMemberTarget(
    TypeRef start,
    String name, {
    required MemberKind kind,
    bool methodCall = false,
  }) {
    final mixinOwner = _superMixinOwner(name, methodCall: methodCall);
    if (mixinOwner != null) {
      return (
        owner: mixinOwner,
        hops: const [],
        found: true,
        abstractGetter: null,
      );
    }

    var owner = start;
    final hops = <TypeRef>[];
    bool? abstractGetter;
    while (true) {
      // Object.noSuchMethod is implicit in the declaration metadata.
      if (methodCall && name == 'noSuchMethod') {
        return (
          owner: owner,
          hops: hops,
          found: true,
          abstractGetter: abstractGetter,
        );
      }
      if (concreteMemberOn(owner, MemberName(name, MemberKind.method)) !=
              null ||
          concreteMemberOn(owner, MemberName(name, kind)) != null) {
        return (
          owner: owner,
          hops: hops,
          found: true,
          abstractGetter: abstractGetter,
        );
      }
      final bridge =
          ctx.topLevelDeclarationsMap[owner.file]?[owner.name]?.bridge;
      if (bridge is BridgeClassDef &&
          (bridge.fields.containsKey(name) ||
              switch (kind) {
                MemberKind.getter => bridge.getters.containsKey(name),
                MemberKind.setter => bridge.setters.containsKey(name),
                _ => false,
              })) {
        return (
          owner: owner,
          hops: hops,
          found: true,
          abstractGetter: abstractGetter,
        );
      }
      if (methodCall) {
        if (abstractGetter == null) {
          final decls = ctx.instanceDeclarationsMap[owner.file]?[owner.name];
          if (decls?.containsKey(MemberName.getter(name).key) ?? false) {
            abstractGetter = true;
          } else if (decls?.containsKey(name) ?? false) {
            abstractGetter = false;
          }
        }
        if (bridge is BridgeClassDef && bridge.methods.containsKey(name)) {
          return (
            owner: owner,
            hops: hops,
            found: true,
            abstractGetter: abstractGetter,
          );
        }
      }
      final parent = ctx.typeSystem.superclassOf(owner);
      if (parent == null) {
        return (
          owner: owner,
          hops: hops,
          found: false,
          abstractGetter: abstractGetter,
        );
      }
      owner = parent;
      hops.add(owner);
    }
  }

  TypeRef? _superMixinOwner(String name, {required bool methodCall}) {
    final host = ctx.currentClass;
    if (host == null || (!methodCall && ctx.memberDeclaringClass != null)) {
      return null;
    }
    final mixins = classLikeClauses(host).$2;
    var stop = mixins.length;
    final declaring = ctx.memberDeclaringClass;
    if (methodCall && declaring != null) {
      final declaringName = switch (declaring) {
        ClassDeclaration() ||
        MixinDeclaration() ||
        ClassTypeAlias() ||
        EnumDeclaration() => declarationName(declaring),
        _ => null,
      };
      for (var i = 0; i < mixins.length; i++) {
        if (mixins[i].name.lexeme == declaringName) {
          stop = i;
          break;
        }
      }
    }
    final library = methodCall
        ? ctx.enclosingLibrary ?? ctx.library
        : ctx.library;
    for (var i = stop - 1; i >= 0; i--) {
      final mixin = clauseNamedType(ctx, library, mixins[i]);
      if (mixin == null) continue;
      if (methodCall) {
        final declaration =
            ctx.instanceDeclarationsMap[mixin.file]?[mixin.name]?[name] ??
            ctx.instanceDeclarationsMap[mixin.file]?[mixin
                .name]?[MemberName.getter(name).key];
        if (declaration == null ||
            (declaration is MethodDeclaration && !declaration.isComplete)) {
          continue;
        }
      } else {
        final decl = ctx.types.find(mixin.file, mixin.name);
        if (decl == null || declaredAccessor(decl, name) == null) continue;
      }
      return TypeRef.lookupDeclaration(ctx, library, host);
    }
    return null;
  }

  /// The member named [name] in [type]'s public interface. Throws
  /// [UnknownMemberError] when no member exists — callers wanting a
  /// probe use [tryInterfaceMember]. Mixins walk before the superclass,
  /// mirroring mixin-application override semantics.
  ResolvedMember interfaceMember(
    TypeRef type,
    MemberName name, {
    AstNode? source,
    TypeRef? bottomType,
  }) => _interfaceMember(
    type,
    name,
    source: source,
    bottomType: bottomType,
    chain: const [],
  );

  ResolvedMember _interfaceMember(
    TypeRef type,
    MemberName name, {
    AstNode? source,
    TypeRef? bottomType,
    required List<String> chain,
  }) {
    final marker = '${type.file}:${type.name}';
    if (chain.contains(marker)) {
      // A hierarchy cycle (the bridge model's `Object extends dynamic`
      // edge) means the member isn't declared anywhere reachable.
      throw UnknownMemberError(
        'Unknown method ${type.name}.${name.name}',
        source,
      );
    }
    chain = [...chain, marker];
    if (type.isTypeParameter) {
      final bound =
          (type as TypeParameterTypeRef).parameter.bound ??
          CoreTypes.dynamic.ref(ctx);
      return _interfaceMember(
        bound,
        name,
        source: source,
        bottomType: bottomType ?? type,
        chain: chain,
      );
    }
    final decl = nominalDeclOf(type) ?? ctx.types.find(type.file, type.name);
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
      return ResolvedMember(
        member,
        _interfaceView(type, member.declaringDecl ?? decl),
      );
    }

    if (decl.kind == TypeDeclKind.enumDecl) {
      // Enum declarations resolve undeclared members through the Enum
      // bridge declaration (and transitively Object).
      return _interfaceMember(
        CoreTypes.enumType.ref(ctx),
        name,
        source: source,
        bottomType: bottomType0,
        chain: chain,
      );
    }

    // The interface walk: mixins (application order), then implemented
    // interfaces, then the superclass. An `implements` member defines the
    // signature every concrete implementation must satisfy — it binds
    // argument lists even when the inherited implementation is narrower
    // (`B extends A implements I` binds `I.foo` for `b.foo`). The call
    // still dispatches virtually by name.
    for (final mixin in ctx.typeSystem.mixinsOf(type)) {
      final result = _tryInterfaceMember(
        mixin,
        name,
        source,
        bottomType0,
        chain,
      );
      if (result != null) return result;
    }
    // Multiple interfaces may declare [name]: `C implements I1, I2` merges
    // `I1.f` and `I2.f` into a combined signature (Dart's combined member
    // signature) — parameters widen to their least upper bound, the return
    // narrows to the most specific candidate.
    final interfaces = [
      for (final interface in ctx.typeSystem.interfacesOf(type))
        ?_tryInterfaceMember(interface, name, source, bottomType0, chain),
    ];
    if (interfaces.isNotEmpty) {
      return interfaces.length == 1
          ? interfaces.first
          : mergeInterfaceMembers(interfaces);
    }
    final superclass = ctx.typeSystem.superclassOf(type);
    if (superclass != null) {
      final result = _tryInterfaceMember(
        superclass,
        name,
        source,
        bottomType0,
        chain,
      );
      if (result != null) return result;
    }
    if (type.isSpec(CoreTypes.object)) {
      throw UnknownMemberError(
        'Unknown method ${bottomType0.name}.${name.name}',
        source,
      );
    }
    return _interfaceMember(
      CoreTypes.object.ref(ctx),
      name,
      source: source,
      bottomType: bottomType0,
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
      return interfaceMember(
        type,
        name,
        source: source,
        bottomType: bottomType,
      );
    } on UnknownMemberError {
      return null;
    }
  }

  ResolvedMember? _tryInterfaceMember(
    TypeRef type,
    MemberName name,
    AstNode? source,
    TypeRef bottomType0,
    List<String> chain,
  ) {
    try {
      return _interfaceMember(
        type,
        name,
        source: source,
        bottomType: bottomType0,
        chain: chain,
      );
    } on UnknownMemberError {
      return null;
    }
  }

  /// The combined signature across several implemented interfaces:
  /// parameters widen to the candidates' least upper bound, arity to the
  /// most permissive candidate, and the return narrows to the most
  /// specific candidate.
  ResolvedMember mergeInterfaceMembers(List<ResolvedMember> candidates) {
    final first = candidates.first;
    final signatures = [
      for (final candidate in candidates) candidate.signature,
    ];
    ParameterSpec? at(int i, CallSignature s) =>
        i < s.positional.length ? s.positional[i] : null;
    final positionalCount = signatures.fold(
      0,
      (n, s) => s.positional.length > n ? s.positional.length : n,
    );
    final positional = [
      for (var i = 0; i < positionalCount; i++)
        _mergeParameter([for (final s in signatures) ?at(i, s)]),
    ];
    final names = <String>{
      for (final s in signatures)
        for (final p in s.named) p.name,
    };
    final named = [
      for (final name in names)
        _mergeParameter([
          for (final s in signatures) ...s.named.where((p) => p.name == name),
        ]),
    ];
    final returnType = signatures.fold<TypeRef>(
      CoreTypes.dynamic.ref(ctx),
      (most, s) => s.returnType.isAssignableTo(ctx, most) ? s.returnType : most,
    );
    return ResolvedMember(
      first.member,
      first.viewedAs,
      signature: CallSignature(
        typeParameters: first.signature.typeParameters,
        typeParameterRefs: first.signature.typeParameterRefs,
        positional: positional,
        requiredPositional: signatures.fold(
          positionalCount,
          (n, s) => s.requiredPositional < n ? s.requiredPositional : n,
        ),
        named: named,
        returnType: returnType,
      ),
    );
  }

  /// One merged parameter: the first candidate supplies name, default, and
  /// node; the type widens to the candidates' least upper bound and
  /// requiredness relaxes to the most permissive.
  ParameterSpec _mergeParameter(List<ParameterSpec> candidates) {
    final first = candidates.first;
    final type = TypeRef.commonBaseType(ctx, {
      for (final c in candidates) c.type,
    });
    final isRequired = candidates.every((c) => c.isRequired);
    return ParameterSpec(
      first.name,
      type,
      isRequired: isRequired,
      defaultValue: first.defaultValue,
      erased: first.erased,
      node: first.node,
    );
  }

  /// The member [decl] itself declares for [name]'s accessor slot —
  /// field, getter, setter, or method — or null. `resolveInstanceDeclaration`
  /// restricted to one link: getter first (its `x*g`/`x` probes cover fields,
  /// getters, and plain-keyed methods), then setter, then arity-keyed methods.
  Member? declaredAccessor(TypeDecl decl, String name) =>
      decl.declaredMember(MemberName(name, MemberKind.getter)) ??
      decl.declaredMember(MemberName(name, MemberKind.setter)) ??
      decl.declaredMember(MemberName(name, MemberKind.method));

  /// Whether [type] declares or inherits [name] in its interface —
  /// `hasInstanceMethod`'s probe: any resolution failure counts as absent.
  bool hasInstanceMember(TypeRef type, MemberName name) {
    try {
      interfaceMember(type, name);
      return true;
    } on UnknownMemberError {
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
  Member? staticMember(TypeRef type, String name, MemberKind kind) {
    final decl = nominalDeclOf(type) ?? ctx.types.find(type.file, type.name);
    if (decl != null) return decl.staticMember(name, kind);
    // Extensions have no TypeDecl; `E.name` keys live in the static
    // namespace — resolve against the extension's own member list.
    final ext = extensionForType(ctx, type);
    if (ext == null) return null;
    return extensionMember(ext, name, kind);
  }

  /// A static member visible by its bare name inside the enclosing class or
  /// any mixin folded into it. The returned owner is the namespace used for
  /// the member's global/static key.
  (Member, int, String)? scopedStaticMember(
    String name, {
    bool forSet = false,
  }) {
    final current = ctx.memberDeclaringClass ?? ctx.currentClass;
    if (current == null) return null;
    final kind = forSet ? MemberKind.setter : MemberKind.getter;
    (Member, int, String)? on(int library, String owner) {
      final member = ctx.types.find(library, owner)?.staticMember(name, kind);
      return member == null ? null : (member, library, owner);
    }

    final ownName = declarationName(current);
    final own = on(ctx.library, ownName);
    if (own != null) return own;
    final seen = <Declaration>{current};
    final queue = <Declaration>[current];
    while (queue.isNotEmpty) {
      final declaration = queue.removeAt(0);
      for (final mixinType in classLikeClauses(declaration).$2) {
        final prefix = mixinType.importPrefix;
        final mixinName = prefix == null
            ? mixinType.name.lexeme
            : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
        final type = ctx.visibleTypes[ctx.library]?[mixinName];
        if (type == null) continue;
        final found = on(type.file, type.name);
        if (found != null) return found;
        final mixinDeclaration =
            ctx.topLevelDeclarationsMap[type.file]?[type.name]?.declaration;
        if (mixinDeclaration != null && seen.add(mixinDeclaration)) {
          queue.add(mixinDeclaration);
        }
      }
    }
    return null;
  }

  /// A member of extension [ext] by name — `E.name` namespace resolution.
  /// `method` covers static methods and instance members applied
  /// explicitly (`E.m(recv)`); `getter`/`setter` cover accessors and field
  /// accessors.
  Member? extensionMember(EvalExtension ext, String name, MemberKind kind) {
    for (final member in ext.members) {
      if (member is MethodDeclaration &&
          member.name.lexeme == name &&
          switch (kind) {
            // `E.m` and `E.g` both register under `E.name` for calls —
            // a getter is a valid call target (`E.g(args)` reads, then
            // invokes the result), mirroring resolveStaticMethod's
            // `'$name*g'` fallback.
            MemberKind.method => !member.isSetter,
            MemberKind.getter => member.isGetter,
            MemberKind.setter => member.isSetter,
            _ => false,
          }) {
        return SourceMember(
          owner: ExtensionDecl(ctx, ext),
          name: MemberName(name, kind),
          node: member,
          library: ext.library,
        );
      }
      if (member is FieldDeclaration && kind != MemberKind.constructor) {
        for (final v in member.fields.variables) {
          if (v.name.lexeme == name) {
            return SourceMember(
              owner: ExtensionDecl(ctx, ext),
              name: MemberName(name, kind),
              node: member,
              library: ext.library,
              variable: v,
            );
          }
        }
      }
    }
    return null;
  }

  /// The declaring [TypeDecl] whose concrete implementation supplies [name] —
  /// what the legacy `memberOwner` returned as a [TypeRef].
  TypeRef? implementationOwner(TypeRef type, MemberName name) {
    return _implementationAt(type, name)?.$1;
  }

  /// The first link in [type]'s chain concretely implementing [name],
  /// with the member itself. Resolve declarations rather than compiled body
  /// positions: an override may be recursive or declared later in the file.
  /// Its call offset is resolved after all bodies have been compiled.
  (TypeRef, Member)? _implementationAt(TypeRef type, MemberName name) {
    if (hasBridgeSuperclass(ctx, type)) {
      return null;
    }
    for (final link in [type, ...ctx.typeSystem.superclassChain(type)]) {
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
    return decl.declaredMember(linkName(name, link), forImplementation: true);
  }

  /// [name] qualified with [link]'s library: a private member folded in
  /// from another library is stored under `uri::_name`.
  MemberName linkName(MemberName name, TypeRef link) => MemberName(
    name.name,
    name.kind,
    privateLibraryUri: name.name.startsWith('_')
        ? name.privateLibraryUri ?? ctx.libraryUri(link.file)
        : null,
  );

  /// The declaring [TypeDecl] whose direct implementation supplies [name],
  /// provided no descendant of [type] redeclares it.
  TypeRef? directImplementationOwner(TypeRef type, MemberName name) =>
      _directImplementationAt(type, name)?.$1;

  (TypeRef, Member)? _directImplementationAt(TypeRef type, MemberName name) {
    if (overriddenBelow(type, name.name)) return null;
    return _implementationAt(type, name);
  }

  /// Whether a subclass of [type] redeclares the member — the
  /// `memberOverriddenInSubclass` fact the owner table already tracks.
  bool overriddenBelow(TypeRef type, String name) =>
      ctx.memberOverriddenInSubclass(type.file, type.name, name);

  /// Whether calling [name] implemented on [owner] requires `this` bound
  /// to the declaring link — bodies that never touch `super` run on any
  /// link; synthesized field accessors always need theirs.
  bool needsOwnerLink(TypeRef owner, MemberName name) {
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
  /// setter's parameter type when [forSet]. Field formals require a field
  /// declared on this class ([forFieldFormal]).
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
    if (forFieldFormal) {
      final decl = nominalDeclOf(type);
      // A field formal binds a real field, which lives at the bare name —
      // an inherited abstract accessor can occupy the getter slot instead.
      final member = decl?.declaredMember(MemberName(name, MemberKind.method));
      if (member == null || !member.isField) {
        throw CompileError(
          'Field formals did not find field $name in class $type',
          source,
        );
      }
      final result = ResolvedMember(member, type).fieldType;
      return substitutions.isEmpty
          ? result
          : result?.substituteTypeParameters(substitutions);
    }
    final resolved = tryInterfaceMember(
      type,
      MemberName(name, forSet ? MemberKind.setter : MemberKind.getter),
      source: source,
    );
    if (resolved == null) return null;
    final signature = resolved.signature;
    if (forSet) {
      final spec = signature.positional.firstOrNull;
      final node = spec?.node;
      // A setter parameter with no type annotation has no queryable
      // field type (matching lookupFieldType's null).
      if (spec == null || (node != null && node.type == null)) {
        return null;
      }
    }
    final result = forSet
        ? signature.positional.firstOrNull?.type
        : resolved.fieldType;
    if (result == null) return null;
    if (substitutions.isNotEmpty) {
      return result.substituteTypeParameters(substitutions);
    }
    return result;
  }

  /// The link and storage slot a `name`-accessor on an exact [type]
  /// resolves to — `(owning link, field-storage index, LoadSuper hops)`.
  /// Reads ([MemberKind.getter]) take a storage slot as soon as it
  /// exists; writes ([MemberKind.setter]) count storage only where a
  /// compiled setter slot also lives — a final field has no write.
  (TypeRef, int?, List<TypeRef>)? accessorSlot(
    TypeRef type,
    String name,
    MemberKind kind,
  ) {
    final memberName = MemberName(name, kind);
    final links = [type, ...ctx.typeSystem.superclassChain(type)];
    for (var i = 0; i < links.length; i++) {
      final link = links[i];
      final index = ctx.instanceGetterIndices[link.file]?[link.name]?[name];
      final hasAccessor =
          (ctx.instanceDeclarationPositions[link.file]?[link.name]?[kind]
                  as Map?)
              ?.containsKey(linkName(memberName, link).nameKey) ==
          true;
      if (index != null && (kind == MemberKind.getter || hasAccessor)) {
        return (link, index, links.sublist(1, i + 1));
      }
      if (hasAccessor && concreteMemberOn(link, memberName) != null) {
        return (link, null, links.sublist(1, i + 1));
      }
    }
    return null;
  }
}

class _SuperSeeker extends RecursiveAstVisitor<void> {
  _SuperSeeker(this.onSuper);
  final void Function() onSuper;

  @override
  void visitSuperExpression(SuperExpression node) => onSuper();
}

/// Whether any class in [type]'s superclass chain is bridged. Bridged
/// ancestors provide members natively, so resolving a call to an evaluated
/// class on the chain would skip the real (native) implementation.
bool hasBridgeSuperclass(CompilerContext ctx, TypeRef type) {
  for (final parent in ctx.typeSystem.superclassChain(type)) {
    final bridge =
        ctx.topLevelDeclarationsMap[parent.file]?[parent.name]?.bridge;
    if (bridge is BridgeClassDef && bridge.bridge) return true;
  }
  return false;
}
