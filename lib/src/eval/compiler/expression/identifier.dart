import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../member/member_name.dart';

Variable compileIdentifier(Identifier id, CompilerContext ctx) {
  return compileIdentifierAsReference(id, ctx).getValue(ctx, id);
}

Reference compileIdentifierAsReference(Identifier id, CompilerContext ctx) {
  if (id is SimpleIdentifier) {
    return IdentifierReference(null, id.name);
  } else if (id is PrefixedIdentifier) {
    // A prefix denotation composes `p.C` into the prefix's child rather
    // than compiling `p` as a receiver — no exceptions for control flow.
    final prefixRef = IdentifierReference(null, id.prefix.name);
    if (prefixRef.denotation(ctx, source: id) case PrefixDenotation()) {
      return IdentifierReference(null, '${id.prefix}.${id.identifier.name}');
    }
    final L = prefixRef.getValue(ctx, id);
    return IdentifierReference(L, id.identifier.name);
  }
  throw CompileError('Unknown identifier ${id.runtimeType}');
}

Variable compilePrefixedIdentifier(
  String prefix,
  String name,
  CompilerContext ctx,
) {
  return compilePrefixedIdentifierAsReference(prefix, name).getValue(ctx);
}

Reference compilePrefixedIdentifierAsReference(
  String prefix,
  String identifier,
) {
  return PrefixedIdentifierReference(prefix, identifier);
}

(TypeRef, DeclarationOrBridge)? resolveInstanceDeclaration(
  CompilerContext ctx,
  int library,
  String $class,
  String name, {
  TypeRef? instantiated,
}) {
  final result = _resolveInstanceDeclarationImpl(
    ctx,
    library,
    $class,
    name,
    instantiated: instantiated,
  );
  assert(() {
    final owner = result?.$1;
    final decl = result?.$2;
    if (owner == null || decl == null) return true;
    final inner = decl.declaration;
    final probeKind = decl is GetSet || inner is! MethodDeclaration
        ? MemberKind.getter
        : inner.isSetter
        ? MemberKind.setter
        : inner.isGetter
        ? MemberKind.getter
        : MemberKind.method;
    final resolved = ctx.memberLookup.tryInterfaceMember(
      owner,
      ctx.memberNameOf(name, probeKind),
    );
    if (resolved == null) return true;
    final member = resolved.member;
    final newNode = member is SourceMember
        ? (member.isField ? (member.variable ?? member.node) : member.node)
        : member is BridgeMember
        ? member.def
        : null;
    final oldNode = decl is GetSet
        ? (decl.declaration ?? decl.bridge)
        : decl.declaration ?? decl.bridge;
    assert(
      newNode == null || identical(newNode, oldNode),
      'MemberLookup.interfaceMember disagreed with '
      'resolveInstanceDeclaration on $owner.$name: new=$newNode old=$oldNode',
    );
    return true;
  }());
  return result;
}

(TypeRef, DeclarationOrBridge)? _resolveInstanceDeclarationImpl(
  CompilerContext ctx,
  int library,
  String $class,
  String name, {
  TypeRef? instantiated,
}) {
  final dec = ctx.instanceDeclarationsMap[library]![$class]?[name];

  if (dec != null) {
    final $type = instantiated ?? ctx.visibleTypes[library]![$class]!;
    return ($type, DeclarationOrBridge(-1, declaration: dec));
  }

  // Structural types (records, function types) have no declaration.
  final $classDec = ctx.topLevelDeclarationsMap[library]![$class];
  if ($classDec == null) return null;

  if ($classDec.isBridge) {
    final bridge = $classDec.bridge as BridgeClassDef;
    final method = bridge.methods[name];
    if (method != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      return ($type, DeclarationOrBridge(-1, bridge: method));
    }
    final getter = bridge.getters[name];
    final setter = bridge.setters[name];

    if (getter != null || setter != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      final setter0 = setter == null
          ? null
          : DeclarationOrBridge<MethodDeclaration, BridgeMethodDef>(
              -1,
              bridge: setter,
            );
      return ($type, GetSet(-1, bridge: getter, setter: setter0));
    }

    final field = bridge.fields[name];
    if (field != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      return ($type, DeclarationOrBridge(-1, bridge: field));
    }

    final $extends = bridge.type.$extends;
    if ($extends != null) {
      final type = TypeRef.fromBridgeTypeRef(ctx, $extends);
      if (type.file < 0) {
        return null;
      }
      return _resolveInstanceDeclarationImpl(
        ctx,
        type.file,
        type.name,
        name,
        instantiated: type,
      );
    }

    return null;
  } else {
    final getter = ctx.instanceDeclarationsMap[library]![$class]?[MemberName.getter(name).key];
    final setter = ctx.instanceDeclarationsMap[library]![$class]?[MemberName.setter(name).key];
    if (getter != null || setter != null) {
      final $type = ctx.visibleTypes[library]![$class]!;
      if (getter == null) {
        // Setter-only member: no [GetSet] since its declaration slot is the
        // getter's — surface the setter directly instead.
        return (
          $type,
          DeclarationOrBridge(-1, declaration: setter as MethodDeclaration),
        );
      }
      final getset = GetSet(
        -1,
        declaration: getter as MethodDeclaration,
        setter: setter == null
            ? null
            : DeclarationOrBridge(-1, declaration: setter as MethodDeclaration),
      );
      return ($type, getset);
    }
  }
  final $dec = $classDec.declaration!;
  // Clause type arguments (`extends A<T>`, `with M<T>`) name the declaring
  // class's own type parameters — resolve them against the instantiated
  // receiver's arguments (`B<int>` sees `A<int>`, not an unbound `T`).
  final hostBindings = _hostParamBindings($dec, instantiated);
  final $withClause = $dec is ClassDeclaration
      ? $dec.withClause
      : ($dec is EnumDeclaration ? $dec.withClause : null);
  if ($withClause != null) {
    for (final $mixin in $withClause.mixinTypes) {
      final mixinType = clauseNamedType(
        ctx,
        library,
        $mixin,
        typeParameters: hostBindings,
      );
      if (mixinType == null) continue;
      final result = _resolveInstanceDeclarationImpl(
        ctx,
        mixinType.file,
        mixinType.name,
        name,
        instantiated: mixinType,
      );
      if (result != null) {
        return result;
      }
    }
  }
  final $superclass = classLikeClauses($dec).$1;
  if ($superclass != null) {
    final extendsType = clauseNamedType(
      ctx,
      library,
      $superclass,
      typeParameters: hostBindings,
    );
    if (extendsType != null) {
      final result = _resolveInstanceDeclarationImpl(
        ctx,
        extendsType.file,
        extendsType.name,
        name,
        instantiated: extendsType,
      );
      if (result != null) return result;
    }
  }

  // Members declared on implemented interfaces are part of this type's
  // interface: resolve them for signatures even though the concrete
  // implementation dispatches on the instance's own class.
  for (final $interface in classLikeClauses($dec).$3) {
    final ifaceType = clauseNamedType(
      ctx,
      library,
      $interface,
      typeParameters: hostBindings,
    );
    if (ifaceType == null) continue;
    final result = _resolveInstanceDeclarationImpl(
      ctx,
      ifaceType.file,
      ifaceType.name,
      name,
      instantiated: ifaceType,
    );
    if (result != null) return result;
  }

  final $type = ctx.visibleTypes[library]![$class]!;
  final objectType = CoreTypes.object.ref(ctx);
  if ($type != objectType) {
    return _resolveInstanceDeclarationImpl(
      ctx,
      objectType.file,
      'Object',
      name,
      instantiated: objectType,
    );
  }
  return null;
}

/// Binds a class declaration's type parameters to the [instantiated]
/// receiver's type arguments, for resolving its supertype clauses.
Map<String, TypeRef> _hostParamBindings(
  Declaration dec,
  TypeRef? instantiated,
) {
  final params = classLikeClauses(dec).$4?.typeParameters;
  final args = instantiated?.typeArguments;
  if (params == null || args == null || args.isEmpty) return const {};
  return {
    for (var i = 0; i < params.length && i < args.length; i++)
      params[i].name.lexeme: args[i],
  };
}

/// Resolves a `NamedType` appearing in an extends/with/implements/on clause to
/// the instantiated [TypeRef] — type arguments applied, typedefs expanded.
/// [typeParameters] supplies the declaring class's parameter bindings when the
/// clause is resolved outside its lexical scope (e.g. during member lookup).
TypeRef? clauseNamedType(
  CompilerContext ctx,
  int library,
  NamedType clause, {
  Map<String, TypeRef> typeParameters = const {},
}) {
  final prefix = clause.importPrefix;
  final name = prefix == null
      ? clause.name.lexeme
      : '${prefix.name.lexeme}.${clause.name.lexeme}';
  final type = ctx.visibleTypes[library]?[name];
  if (type != null) {
    final args = clause.typeArguments?.arguments;
    if (args == null) return type;
    return type.copyWith(
      typeArguments: [
        for (final arg in args)
          TypeRef.fromAnnotation(
            ctx,
            library,
            arg,
            typeParameters: typeParameters,
          ),
      ],
    );
  }
  final alias = ctx.typeAliases[library]?[name];
  if (alias is TypeAlias) {
    return resolveTypeAlias(
      ctx,
      library,
      alias,
      typeArgs: clause.typeArguments?.arguments,
      callerTypeParameters: typeParameters,
    );
  }
  return null;
}

class GetSet extends DeclarationOrBridge<MethodDeclaration, BridgeMethodDef> {
  GetSet(super.sourceLib, {this.setter, super.declaration, super.bridge});

  DeclarationOrBridge<MethodDeclaration, BridgeMethodDef>? setter;
}

/// Resolves [name] as a static member of [$class] in [library]. Static
/// accessors register under `*g`/`*s` keys: [forSet] checks the setter key
/// first (writes), otherwise the getter key (reads), then the plain name
/// (methods and static fields).
DeclarationOrBridge<Declaration, BridgeDeclaration>? resolveStaticDeclaration(
  CompilerContext ctx,
  int library,
  String $class,
  String name, {
  bool forSet = false,
}) {
  final map = ctx.topLevelDeclarationsMap[library]!;
  final found = (forSet ? map['${$class}.${MemberName.setter(name).key}'] : map['${$class}.${MemberName.getter(name).key}']) ??
      map['${$class}.$name'];
  assert(() {
    final decl = ctx.types.find(library, $class);
    if (decl == null) return true;
    final member = decl.staticMember(
      name,
      forSet ? MemberKind.setter : MemberKind.getter,
    );
    final newNode = member is SourceMember
        ? (member.isField ? (member.variable ?? member.node) : member.node)
        : member is BridgeMember
        ? member.def
        : null;
    final oldNode = found?.declaration ?? found?.bridge;
    assert(
      found == null || identical(newNode, oldNode),
      'TypeDecl.staticMember disagreed with resolveStaticDeclaration on '
      '${$class}.$name: new=$newNode old=$oldNode',
    );
    return true;
  }());
  return found;
}

/// Looks up [name] as a static member of the enclosing class, then of each
/// mixin applied to it transitively — bodies of members folded in from a
/// mixin reference the mixin's statics bare (`with M` where M declares
/// `static x` lets the applying class's methods say just `x`). Returns the
/// declaration plus the library and owner name under which its global/static
/// key was registered, or null.
(DeclarationOrBridge<Declaration, BridgeDeclaration>, int, String)?
resolveScopedStaticDeclaration(
  CompilerContext ctx,
  String name, {
  bool forSet = false,
}) {
  final current = ctx.memberDeclaringClass ?? ctx.currentClass;
  if (current == null) return null;
  final className = declarationName(current);
  final own = resolveStaticDeclaration(
    ctx,
    ctx.library,
    className,
    name,
    forSet: forSet,
  );
  if (own != null) return (own, ctx.library, className);
  final seen = <Declaration>{current};
  final queue = <Declaration>[current];
  while (queue.isNotEmpty) {
    final decl = queue.removeAt(0);
    for (final mixinType in classLikeClauses(decl).$2) {
      final prefix = mixinType.importPrefix;
      final mixinName = prefix == null
          ? mixinType.name.lexeme
          : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
      final ref = ctx.visibleTypes[ctx.library]?[mixinName];
      if (ref == null) continue;
      final found = resolveStaticDeclaration(
        ctx,
        ref.file,
        ref.name,
        name,
        forSet: forSet,
      );
      if (found != null) return (found, ref.file, ref.name);
      final mixinDecl =
          ctx.topLevelDeclarationsMap[ref.file]?[ref.name]?.declaration;
      if (mixinDecl != null && seen.add(mixinDecl)) queue.add(mixinDecl);
    }
  }
  return null;
}
