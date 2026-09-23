import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/declaration/constructor.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/declaration/method.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/identifier.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import '../member/member.dart';
import '../member/member_name.dart';

void compileClassDeclaration(CompilerContext ctx, ClassDeclaration d) {
  return ctx.withTypeParameters(
    ctx.library,
    TypeParameterOwner(
      TypeParameterOwnerKind.classLike,
      ctx.library,
      d.namePart.typeName.lexeme,
    ),
    d.namePart.typeParameters?.typeParameters,
    () {
      final $runtimeType = ctx
          .runtimeTypes
          .indexMap[TypeRef.lookupDeclaration(ctx, ctx.library, d).decl!];
      final clsName = d.namePart.typeName.lexeme;
      ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
        {},
        {},
        {},
        $runtimeType,
      ];
      ctx.instanceGetterIndices[ctx.library]![clsName] = {};
      final (constructors, fields, methods) = partitionClassMembers(
        d.body.members,
      );
      final (mixinFields, mixinMethods, memberLibraries) = _mixinMembers(
        ctx,
        d.withClause?.mixinTypes,
      );
      _checkAbstractMixinMemberConformance(
        ctx,
        d,
        fields,
        methods,
        mixinFields,
        mixinMethods,
        memberLibraries,
        classLikeClauses(d).$1,
      );
      ctx.enclosingLibrary = ctx.library;
      if (constructors.isEmpty) {
        ctx.currentClass = d;
        final $extends = classLikeClauses(d).$1;
        final superRef = $extends == null
            ? null
            : _resolveSuperclass(ctx, $extends);
        if ($extends == null ||
            _superclassHasUnnamedConstructor(ctx, superRef)) {
          compileDefaultConstructor(ctx, d, [
            ...mixinFields,
            ...fields,
          ], memberLibraries: memberLibraries);
        } else if (ctx
                .topLevelDeclarationsMap[superRef!.file]?[superRef.name]
                ?.declaration !=
            null) {
          throw CompileError(
            'The superclass ${superRef.name} has no unnamed constructor that '
            'takes no arguments',
            $extends,
            ctx.library,
            ctx,
          );
        }
      }
      compileClassMembers(
        ctx,
        d,
        constructors: constructors,
        fields: [...mixinFields, ...fields],
        methods: [...mixinMethods, ...methods],
        memberLibraries: memberLibraries,
      );
      ctx.enclosingLibrary = null;
      ctx.currentClass = null;
    },
  );
}

/// Compiles a class type alias (`class C = S with M implements I`): the alias
/// IS the mixin-application class, so its members fold in the `with` mixins'
/// members and it gains forwarding constructors to each superclass
/// constructor.
void compileClassTypeAlias(CompilerContext ctx, ClassTypeAlias d) {
  return ctx.withTypeParameters(
    ctx.library,
    TypeParameterOwner(
      TypeParameterOwnerKind.classLike,
      ctx.library,
      d.name.lexeme,
    ),
    d.typeParameters?.typeParameters,
    () {
      final $runtimeType = ctx
          .runtimeTypes
          .indexMap[TypeRef.lookupDeclaration(ctx, ctx.library, d).decl!];
      final clsName = d.name.lexeme;
      ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
        {},
        {},
        {},
        $runtimeType,
      ];
      ctx.instanceGetterIndices[ctx.library]![clsName] = {};
      final (mixinFields, mixinMethods, memberLibraries) = _mixinMembers(
        ctx,
        d.withClause.mixinTypes,
      );
      _checkAbstractMixinMemberConformance(
        ctx,
        d,
        const [],
        const [],
        mixinFields,
        mixinMethods,
        memberLibraries,
        d.superclass,
      );
      ctx.enclosingLibrary = ctx.library;
      ctx.currentClass = d;
      final superRef = _resolveSuperclass(ctx, d.superclass);
      final superCtors = ctx.topLevelDeclarationsMap[superRef.file]!;
      final superCtorEntries = [
        for (final entry in superCtors.entries)
          if (entry.key.startsWith('${superRef.name}.') &&
              entry.value.declaration is ConstructorDeclaration &&
              (entry.value.declaration! as ConstructorDeclaration)
                      .factoryKeyword ==
                  null)
            entry,
      ];
      if (!superCtorEntries.any((e) => e.key == '${superRef.name}.') &&
          _superclassHasUnnamedConstructor(ctx, superRef)) {
        // The superclass has an implicit unnamed constructor, so `C.` is the
        // synthesized default body forwarding to it.
        compileDefaultConstructor(
          ctx,
          d,
          mixinFields,
          memberLibraries: memberLibraries,
        );
      }
      compileClassMembers(
        ctx,
        d,
        constructors: const [],
        fields: mixinFields,
        methods: mixinMethods,
        memberLibraries: memberLibraries,
      );
      // Forwarding constructors: `C.n(...)` for each `S.n(...)` on the superclass.
      for (final entry in superCtorEntries) {
        final ctorName = entry.key.substring(superRef.name.length + 1);
        if (ctx.topLevelDeclarationPositions[ctx.library]!.containsKey(
          '$clsName.$ctorName',
        )) {
          continue;
        }
        compileAliasForwardingConstructor(
          ctx,
          d,
          ctorName,
          entry.value,
          mixinFields,
          memberLibraries,
        );
      }
      ctx.enclosingLibrary = null;
      ctx.currentClass = null;
    },
  );
}

/// Resolves a superclass `NamedType` to its [TypeRef] — visible types first,
/// then type aliases — throwing when the name cannot be resolved.
TypeRef _resolveSuperclass(CompilerContext ctx, NamedType superclass) {
  final prefix = superclass.importPrefix;
  final name = prefix == null
      ? superclass.name.lexeme
      : '${prefix.name.lexeme}.${superclass.name.lexeme}';
  final resolved =
      ctx.visibleTypes[ctx.library]![name] ??
      (ctx.typeAliases[ctx.library]?[name] is TypeAlias
          ? ctx.typeFactory.resolveTypeAlias(
              ctx.library,
              ctx.typeAliases[ctx.library]![name]!,
              typeArgs: superclass.typeArguments?.arguments,
            )
          : null);
  if (resolved == null) {
    throw CompileError("Type '$name' not found", superclass, ctx.library, ctx);
  }
  return resolved;
}

/// Compiles a mixin's declaration. A mixin is a type but is never
/// instantiated — its members are compiled per application site (see
/// [compileClassDeclaration]), so this only registers its name.
void compileMixinDeclaration(CompilerContext ctx, MixinDeclaration d) {
  final $runtimeType =
      ctx.runtimeTypes.indexMap[TypeRef.lookupDeclaration(ctx, ctx.library, d).decl!];
  final clsName = d.name.lexeme;
  ctx.instanceDeclarationPositions[ctx.library]![clsName] = [
    {},
    {},
    {},
    $runtimeType,
  ];
  ctx.instanceGetterIndices[ctx.library]![clsName] = {};
  // Instance members fold into applying classes and never compile here;
  // statics keep the mixin's name (`M.x`) and compile in place.
  ctx.currentClass = d;
  for (final m in d.body.members.whereType<MethodDeclaration>().where(
    (e) => e.isStatic,
  )) {
    compileMethodDeclaration(m, ctx, d);
  }
  ctx.currentClass = null;
}

/// Resolves the `with`-clause mixin names and collects their fields and
/// methods (in application order, so a later mixin shadows an earlier one),
/// plus a map recording each folded member's declaring library — folded
/// member bodies resolve identifiers and types in the mixin's own library.
/// Type parameters on the mixin are seeded from the clause's type arguments.
(List<FieldDeclaration>, List<MethodDeclaration>, Map<ClassMember, int>)
_mixinMembers(
  CompilerContext ctx,
  List<NamedType>? mixinTypes, [
  // The declaration whose `with` clause is being folded — the applying class
  // normally, but the applied alias/mixin decl itself when recursing into a
  // mixin that is a mixin application (`with A` where `A = S with M`).
  Declaration? ownerDecl,
  // Mixin-application declarations already folded along this path — reentry
  // means a cyclic `with` chain (`class C = S with C`), a compile error.
  Set<String>? visited,
]) {
  visited ??= {};
  final fields = <FieldDeclaration>[];
  final methods = <MethodDeclaration>[];
  final memberLibraries = <ClassMember, int>{};
  if (mixinTypes == null) return (fields, methods, memberLibraries);
  for (final mixinType in mixinTypes) {
    final ref = TypeRef.fromAnnotation(ctx, ctx.library, mixinType);
    final decl = ctx.topLevelDeclarationsMap[ref.file]![ref.name]?.declaration;
    final declKey = '${ref.file}:${ref.name}';
    if (!visited.add(declKey)) {
      throw CompileError(
        'Cyclic mixin application involving ${ref.name}',
        mixinType,
        ctx.library,
        ctx,
      );
    }
    // Seed the mixin's type parameters with the clause's arguments so folded
    // member signatures resolve (`with M<int>`). A name already bound on the
    // applying class is left alone — `class B<T> with M<T>` binds M's T to
    // B's T.
    final mixinParams = switch (decl) {
      MixinDeclaration(:final typeParameters) => typeParameters?.typeParameters,
      ClassDeclaration(:final namePart) =>
        namePart.typeParameters?.typeParameters,
      _ => null,
    };
    if (mixinParams != null && mixinParams.isNotEmpty) {
      final temps = ctx.typeParameterScope(ctx.library);
      final args = mixinType.typeArguments?.arguments;
      final owner = ownerDecl ?? ctx.currentClass;
      final ownerParams = switch (owner) {
        ClassDeclaration c => c.namePart.typeParameters?.typeParameters,
        MixinDeclaration m => m.typeParameters?.typeParameters,
        ClassTypeAlias a => a.typeParameters?.typeParameters,
        _ => null,
      };
      final ownerName = switch (owner) {
        ClassDeclaration c => c.namePart.typeName.lexeme,
        MixinDeclaration m => m.name.lexeme,
        ClassTypeAlias a => a.name.lexeme,
        _ => '',
      };
      for (var i = 0; i < mixinParams.length; i++) {
        final param = mixinParams[i];
        if (temps.containsKey(param.name.lexeme)) continue;
        final bound = param.bound;
        temps[param.name.lexeme] =
            (args != null && i < args.length
                ? ctx.typeFactory.resolveAppliedTypeArgument(
                    ctx.library,
                    ownerName,
                    ownerParams,
                    args[i],
                  )
                : null) ??
            (bound != null
                ? TypeRef.fromAnnotation(ctx, ctx.library, bound)
                : CoreTypes.dynamic.ref(ctx));
      }
    }
    // A `class` used in `with` is a mixin class — its members fold in like a
    // mixin's (its constructors are ignored in the application).
    final (
      List<ConstructorDeclaration> mixinCtors,
      List<FieldDeclaration> mixinFields,
      List<MethodDeclaration> mixinMethods,
    ) = switch (decl) {
      MixinDeclaration m => partitionClassMembers(m.body.members),
      // A `class` or class type alias used in `with` may itself apply mixins
      // (`mixin class D<U> = X with M<U>`): fold those recursively after
      // loading the decl's own type parameters for argument resolution.
      ClassDeclaration c when c.withClause != null => () {
        // The applied class's own parameters scope over its `with` clause:
        // `class D<U> = X with M<U>` resolves `M`'s arguments against U.
        // A pushed frame keeps the seed scoped to this fold.
        final (f0, m0, l0) = ctx.withTypeParameters(
          ctx.library,
          TypeParameterOwner(
            TypeParameterOwnerKind.classLike,
            ctx.library,
            c.namePart.typeName.lexeme,
          ),
          c.namePart.typeParameters?.typeParameters,
          () => _mixinMembers(
            ctx,
            c.withClause!.mixinTypes,
            c,
            visited,
          ),
        );
        memberLibraries.addAll(l0);
        final (_, cf, cm) = partitionClassMembers(c.body.members);
        return (<ConstructorDeclaration>[], [...f0, ...cf], [...m0, ...cm]);
      }(),
      ClassDeclaration c => partitionClassMembers(c.body.members),
      // A class type alias used as a mixin (`with C` where `C = S with M`)
      // contributes the alias's own folded mixin members.
      ClassTypeAlias a => () {
        final (f, m, l) = ctx.withTypeParameters(
          ctx.library,
          TypeParameterOwner(
            TypeParameterOwnerKind.classLike,
            ctx.library,
            a.name.lexeme,
          ),
          a.typeParameters?.typeParameters,
          () => _mixinMembers(
            ctx,
            a.withClause.mixinTypes,
            a,
            visited,
          ),
        );
        memberLibraries.addAll(l);
        return (<ConstructorDeclaration>[], f, m);
      }(),
      _ => throw CompileError(
        '${ref.name} is not a mixin (used in a with clause)',
        mixinType,
        ctx.library,
        ctx,
      ),
    };
    if (decl is MixinDeclaration && mixinCtors.isNotEmpty) {
      throw CompileError(
        'Mixins cannot declare constructors',
        mixinType,
        ctx.library,
        ctx,
      );
    }
    for (final member in [...mixinFields, ...mixinMethods]) {
      memberLibraries.putIfAbsent(member, () => ref.file);
    }
    fields.addAll(mixinFields);
    methods.addAll(mixinMethods);
    visited.remove(declKey);
  }
  return (fields, methods, memberLibraries);
}

/// Whether a synthesized default constructor can forward to [superRef]'s
/// unnamed constructor — it must exist (a registered `'S.'` entry, a source
/// class with no constructors at all, or an alias that transitively has one)
/// and take no required positional arguments.
bool _superclassHasUnnamedConstructor(CompilerContext ctx, TypeRef? superRef) {
  if (superRef == null) return false;
  final entries = ctx.topLevelDeclarationsMap[superRef.file]!;
  final unnamedEntry = entries['${superRef.name}.'];
  final unnamed = unnamedEntry?.declaration;
  if (unnamed is ConstructorDeclaration) {
    return unnamed.parameters.parameters.every(
      (p) => p.isOptionalPositional || p.isNamed,
    );
  }
  if (unnamedEntry != null) return true;
  final decl = entries[superRef.name]?.declaration;
  if (decl is ClassDeclaration) {
    return !decl.body.members.any((m) => m is ConstructorDeclaration);
  }
  if (decl is ClassTypeAlias) {
    final namedType = classLikeClauses(decl).$1;
    if (namedType == null) return false;
    final prefix = namedType.importPrefix;
    final name = prefix == null
        ? namedType.name.lexeme
        : '${prefix.name.lexeme}.${namedType.name.lexeme}';
    return _superclassHasUnnamedConstructor(
      ctx,
      ctx.visibleTypes[superRef.file]?[name],
    );
  }
  return false;
}

/// A concrete class applying mixins must satisfy each folded abstract member
/// with a conforming concrete implementation (from its own members, another
/// mixin layer, or the superclass chain): the implementation's return type is
/// covariant and its parameters accept everything the interface promises.
void _checkAbstractMixinMemberConformance(
  CompilerContext ctx,
  Declaration host,
  List<FieldDeclaration> ownFields,
  List<MethodDeclaration> ownMethods,
  List<FieldDeclaration> mixinFields,
  List<MethodDeclaration> mixinMethods,
  Map<ClassMember, int> memberLibraries,
  NamedType? superclassClause,
) {
  final hostIsAbstract = switch (host) {
    ClassDeclaration d => d.abstractKeyword != null,
    ClassTypeAlias d => d.abstractKeyword != null,
    _ => false,
  };
  if (hostIsAbstract || mixinMethods.isEmpty) return;
  final hostName = declarationName(host);
  // A noSuchMethod declared on the host class itself satisfies any abstract
  // interface member (a folded one still has to override Object's).
  if (ownMethods.any((m) => m.name.lexeme == 'noSuchMethod')) return;
  TypeRef? superRef;
  if (superclassClause != null) {
    try {
      superRef = clauseNamedType(ctx, ctx.library, superclassClause);
    } on CompileError {
      superRef = null;
    }
  }
  // A class without an `extends` clause implicitly extends Object.
  superRef ??= ctx.visibleTypes[ctx.library]?['Object'];
  for (final decl in mixinMethods) {
    final declLib = memberLibraries[decl] ?? ctx.library;
    if (decl.body is EmptyFunctionBody) {
      final impl = _effectiveConcreteMember(
        ctx,
        decl,
        ownFields,
        ownMethods,
        mixinFields,
        mixinMethods,
        memberLibraries,
        superRef,
      );
      if (impl == null) {
        // A superclass chain that resolved is uninspectable once it reaches
        // a bridged or external type — only report when there is no
        // superclass that could provide the member.
        if (superRef == null) {
          throw CompileError(
            'Missing concrete implementation of ${decl.name.lexeme}',
            decl,
            declLib,
            ctx,
          );
        }
        continue;
      }
      if (!_memberConformsTo(
        ctx,
        impl,
        DeclarationOrBridge(declLib, declaration: decl),
        setter: decl.isSetter,
        getter: decl.isGetter,
      )) {
        throw CompileError(
          "The implementation of '${decl.name.lexeme}' in the non-abstract "
          "class '$hostName' does not conform to its interface",
          decl,
          declLib,
          ctx,
        );
      }
    } else if (superRef != null) {
      // A folded concrete member overrides any same-signature member on the
      // superclass chain and must conform to it (INVALID_OVERRIDE).
      final interface = _superMemberOf(ctx, decl, superRef);
      final badOverride =
          interface != null &&
          !_memberConformsTo(
            ctx,
            DeclarationOrBridge(declLib, declaration: decl),
            interface,
            setter: decl.isSetter,
            getter: decl.isGetter,
          );
      // Object.noSuchMethod(Invocation) is implicit — it is not present in
      // the bridge declaration, so check its arity directly.
      final badNoSuchMethod =
          interface == null &&
          decl.name.lexeme == 'noSuchMethod' &&
          (decl.parameters?.parameters
                  .where((p) => p.isRequiredPositional)
                  .isEmpty ??
              false);
      if (badOverride || badNoSuchMethod) {
        throw CompileError(
          "Applying the mixin to '${superRef.name}' introduces an erroneous "
          "override of '${decl.name.lexeme}'",
          decl,
          declLib,
          ctx,
        );
      }
    }
  }
}

/// The superclass-chain member matching [decl]'s name and kind, or null when
/// the chain is uninspectable (bridged/external) or declares no such member.
DeclarationOrBridge? _superMemberOf(
  CompilerContext ctx,
  MethodDeclaration decl,
  TypeRef superRef,
) {
  final kind = decl.isGetter
      ? MemberKind.getter
      : decl.isSetter
      ? MemberKind.setter
      : MemberKind.method;
  final resolved = ctx.memberLookup.tryInterfaceMember(
    superRef,
    MemberName(decl.name.lexeme, kind),
  );
  if (resolved == null) return null;
  final member = resolved.member;
  // The declaring class's instantiated type — its file is the member's
  // true declaring library.
  final memberFile = resolved.viewedAs.file;
  if (member is SourceMember) {
    return DeclarationOrBridge(
      memberFile,
      declaration: member.sourceDeclaration,
    );
  }
  return DeclarationOrBridge(
    memberFile,
    bridge: (member as BridgeMember).def as BridgeDeclaration,
  );
}

/// The most-derived concrete member matching [decl]'s name and kind: own
/// members first, then the last concrete same-key mixin member, then the
/// superclass chain.
DeclarationOrBridge? _effectiveConcreteMember(
  CompilerContext ctx,
  MethodDeclaration decl,
  List<FieldDeclaration> ownFields,
  List<MethodDeclaration> ownMethods,
  List<FieldDeclaration> mixinFields,
  List<MethodDeclaration> mixinMethods,
  Map<ClassMember, int> memberLibraries,
  TypeRef? superRef,
) {
  bool sameMember(ClassMember m) {
    final name = m is MethodDeclaration
        ? m.name.lexeme
        : m is FieldDeclaration && m.fields.variables.isNotEmpty
        ? m.fields.variables.first.name.lexeme
        : null;
    if (name != decl.name.lexeme) return false;
    if (m is FieldDeclaration) return decl.isGetter || decl.isSetter;
    return m is MethodDeclaration &&
        m.isGetter == decl.isGetter &&
        m.isSetter == decl.isSetter;
  }

  DeclarationOrBridge source(ClassMember m) =>
      DeclarationOrBridge(memberLibraries[m] ?? ctx.library, declaration: m);

  for (final m in [...ownMethods, ...ownFields]) {
    if (!sameMember(m)) continue;
    if (m is MethodDeclaration && m.body is EmptyFunctionBody) continue;
    return source(m);
  }
  for (var i = mixinMethods.length - 1; i >= 0; i--) {
    final m = mixinMethods[i];
    if (m.body is EmptyFunctionBody || !sameMember(m)) continue;
    return source(m);
  }
  for (var i = mixinFields.length - 1; i >= 0; i--) {
    final m = mixinFields[i];
    if (sameMember(m)) return source(m);
  }
  if (superRef != null) {
    return _superMemberOf(ctx, decl, superRef);
  }
  return null;
}

/// A normalized member signature for conformance checks: resolved positional
/// parameter types, named parameter types, and the return type.
typedef _MemberSig = ({
  List<(TypeRef?, bool)> positional,
  Map<String, (TypeRef?, bool)> named,
  TypeRef? returnType,
});

/// Resolves a member's signature in its declaring library — `setter`/`getter`
/// select which accessor view a field or accessor-pair member takes. Returns
/// null when the member can't be inspected (e.g. a non-method bridge).
_MemberSig? _memberSig(
  CompilerContext ctx,
  DeclarationOrBridge member,
  int declLib, {
  required bool setter,
}) {
  final decl = member.declaration;
  if (decl is MethodDeclaration) {
    final pos = <(TypeRef?, bool)>[];
    final named = <String, (TypeRef?, bool)>{};
    for (final p in decl.parameters?.parameters ?? const <FormalParameter>[]) {
      if (p.isNamed) {
        named[p.name!.lexeme] = (_paramType(ctx, declLib, p), p.isRequired);
      } else {
        pos.add((_paramType(ctx, declLib, p), p.isRequiredPositional));
      }
    }
    return (
      positional: pos,
      named: named,
      returnType: setter
          ? null
          : _annotationType(ctx, declLib, decl.returnType),
    );
  }
  if (decl is FieldDeclaration) {
    final t = _annotationType(ctx, declLib, decl.fields.type);
    // A field viewed as a setter takes one value parameter; viewed as a
    // getter it returns the field type. A final field is getter-only.
    if (setter && decl.fields.isFinal) return null;
    return (
      positional: setter ? [(t, true)] : const [],
      named: const {},
      returnType: setter ? null : t,
    );
  }
  final bridge = member.bridge;
  if (bridge is BridgeMethodDef) {
    final fn = bridge.functionDescriptor;
    TypeRef? bt(BridgeTypeAnnotation a) {
      try {
        return TypeRef.fromBridgeAnnotation(ctx, a);
      } on CompileError {
        return null;
      }
    }

    final pos = <(TypeRef?, bool)>[];
    for (final p in fn.params) {
      pos.add((bt(p.type), !p.optional));
    }
    final named = <String, (TypeRef?, bool)>{
      for (final p in fn.namedParams) p.name: (bt(p.type), !p.optional),
    };
    return (
      positional: pos,
      named: named,
      returnType: setter ? null : bt(fn.returns),
    );
  }
  return null;
}

/// Whether [impl]'s signature conforms to [interface]'s — covariant return
/// type and, for methods, a parameter list accepting everything the interface
/// promises (no more required positionals, at least as many positionals, a
/// superset of named parameters, contravariant parameter types).
bool _memberConformsTo(
  CompilerContext ctx,
  DeclarationOrBridge impl,
  DeclarationOrBridge interface, {
  required bool setter,
  required bool getter,
}) {
  // A method interface needs a method; a field holding a callable is not an
  // override per spec but is conservatively accepted here.
  if (!getter && !setter && interface.declaration is MethodDeclaration) {
    if (impl.declaration is! MethodDeclaration) return true;
  }
  // A final field has no setter and can't satisfy a setter interface.
  if (setter &&
      impl.declaration is FieldDeclaration &&
      (impl.declaration as FieldDeclaration).fields.isFinal) {
    return false;
  }
  final implSig = _memberSig(ctx, impl, impl.sourceLib, setter: setter);
  final ifaceSig = _memberSig(
    ctx,
    interface,
    interface.sourceLib,
    setter: setter,
  );
  if (implSig == null || ifaceSig == null) return true;

  final declReturn = ifaceSig.returnType;
  final implReturn = implSig.returnType;
  if (declReturn != null &&
      implReturn != null &&
      !implReturn.isTypeParameter &&
      !declReturn.isTypeParameter &&
      !implReturn.isAssignableTo(ctx, declReturn, forceAllowDynamic: true)) {
    return false;
  }

  final ifaceRequired = ifaceSig.positional.where((p) => p.$2).length;
  final implRequired = implSig.positional.where((p) => p.$2).length;
  if (implRequired > ifaceRequired ||
      implSig.positional.length < ifaceSig.positional.length) {
    return false;
  }
  for (final p in ifaceSig.named.entries) {
    if (!implSig.named.containsKey(p.key)) return false;
  }

  // Contravariant parameter types: the impl's parameter accepts at least the
  // values the interface promises.
  bool accepts((TypeRef?, bool) ifaceParam, (TypeRef?, bool)? implParam) {
    if (implParam == null) return false;
    final declType = ifaceParam.$1;
    final implType = implParam.$1;
    if (declType == null || implType == null) return true;
    if (declType.isTypeParameter || implType.isTypeParameter) return true;
    return declType.isAssignableTo(ctx, implType, forceAllowDynamic: true);
  }

  for (var i = 0; i < ifaceSig.positional.length; i++) {
    if (!accepts(
      ifaceSig.positional[i],
      i < implSig.positional.length ? implSig.positional[i] : null,
    )) {
      return false;
    }
  }
  for (final p in ifaceSig.named.entries) {
    if (!accepts(p.value, implSig.named[p.key])) return false;
  }
  return true;
}

TypeRef? _paramType(CompilerContext ctx, int library, FormalParameter param) =>
    _annotationType(ctx, library, param.type);

TypeRef? _annotationType(
  CompilerContext ctx,
  int library,
  TypeAnnotation? annotation,
) {
  if (annotation == null) return null;
  try {
    return TypeRef.fromAnnotation(ctx, library, annotation);
  } on CompileError {
    return null;
  }
}
