import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
      return PrefixedIdentifierReference(id.prefix.name, id.identifier.name);
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
    return (type as InterfaceTypeRef).copyWith(
      arguments: [
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
    return ctx.typeFactory.resolveTypeAlias(
      library,
      alias,
      typeArgs: clause.typeArguments?.arguments,
      callerTypeParameters: typeParameters,
    );
  }
  return null;
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
  final decl = ctx.types.find(library, $class);
  final member = decl?.staticMember(
    name,
    forSet ? MemberKind.setter : MemberKind.getter,
  );
  if (member is SourceMember) {
    return DeclarationOrBridge(library, declaration: member.sourceDeclaration);
  }
  if (member is BridgeMember) {
    return DeclarationOrBridge(
      library,
      bridge: member.def as BridgeDeclaration,
    );
  }
  return null;
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
