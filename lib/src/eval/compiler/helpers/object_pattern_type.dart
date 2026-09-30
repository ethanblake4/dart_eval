import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;

import '../context.dart';
import '../type.dart';

/// Context schemas use declared bounds before a subject type is available.
TypeRef objectPatternContextType(CompilerContext ctx, NamedType annotation) {
  final type = TypeRef.fromAnnotation(ctx, ctx.library, annotation);
  return annotation.typeArguments == null &&
          type is InterfaceTypeRef &&
          type.arguments.isEmpty
      ? type.copyWith(arguments: type.decl.defaultTypeArguments)
      : type;
}

/// Infers omitted arguments from the subject, independently of promotion.
/// Explicit arguments always determine the tested interface and getter types.
TypeRef objectPatternType(
  CompilerContext ctx,
  NamedType annotation,
  TypeRef subject,
) {
  if (annotation.typeArguments != null) {
    return TypeRef.fromAnnotation(ctx, ctx.library, annotation);
  }
  final prefix = annotation.importPrefix;
  final name = prefix == null
      ? annotation.name.lexeme
      : '${prefix.name.lexeme}.${annotation.name.lexeme}';
  final alias = ctx.typeAliases[ctx.library]?[name];
  final TypeRef template;
  final List<TypeParameterDef> parameters;
  if (alias != null) {
    template = ctx.typeFactory.resolveTypeAlias(
      ctx.library,
      alias,
      rawParams: true,
    );
    final nodes = switch (alias) {
      GenericTypeAlias(:final typeParameters) ||
      FunctionTypeAlias(
        :final typeParameters,
      ) => typeParameters?.typeParameters ?? const <TypeParameter>[],
      _ => const <TypeParameter>[],
    };
    final owner = TypeParameterOwner(
      TypeParameterOwnerKind.typeAlias,
      ctx.typeAliasFiles[alias] ?? ctx.library,
      alias.name.lexeme,
    );
    parameters = [
      for (var i = 0; i < nodes.length; i++)
        ctx.typeParameterDefs.key(owner, i, nodes[i].name.lexeme),
    ];
  } else {
    final type = TypeRef.fromAnnotation(ctx, ctx.library, annotation);
    if (type is! InterfaceTypeRef) return type;
    template = type.decl.thisType;
    parameters = type.decl.typeParameters;
  }
  if (parameters.isEmpty) return template;
  final inferred = <TypeParameterDef, TypeRef>{};
  ctx.typeSystem.unify(template, subject, inferred);
  inferred.removeWhere((parameter, _) => !parameters.contains(parameter));
  return template.substituteTypeParameters(
    Substitution.of(
      ctx.typeSystem.instantiateToBounds(
        parameters,
        knownTypes: inferred,
        recursiveDefault: CoreTypes.object.ref(ctx).withNullable(true),
      ),
    ),
  );
}
