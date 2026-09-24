import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compileIdentifier(
  Identifier id,
  CompilerContext ctx, [
  TypeRef? bound,
]) {
  return compileIdentifierAsReference(id, ctx).getValue(ctx, id, bound);
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
    return IdentifierReference.receiver(
      compileReceiver(ctx, id.prefix),
      id.identifier.name,
    );
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
