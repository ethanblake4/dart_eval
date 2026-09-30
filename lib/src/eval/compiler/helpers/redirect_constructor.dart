import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';

import '../context.dart';
import '../type.dart';

typedef RedirectParameter = ({
  TypeRef type,
  ConstructorDeclaration constructor,
  FormalParameter parameter,
});

/// Maps a factory parameter to its immediate source redirect target.
/// Positional names may differ; named parameters retain their names.
RedirectParameter? redirectParameterTarget(
  CompilerContext ctx,
  int library,
  FormalParameter parameter,
  ConstructorDeclaration constructor,
) {
  final redirect = constructor.redirectedConstructor;
  if (redirect == null) return null;
  final (typeName, constructorName) = splitConstructorTypeName(
    ctx,
    library,
    redirect.type,
    redirect.name?.name,
  );
  final type = ctx.visibleTypes[library]?[typeName];
  final target = type == null
      ? null
      : ctx
            .topLevelDeclarationsMap[type
                .file]?['${type.name}.$constructorName']
            ?.declaration;
  if (target is! ConstructorDeclaration) return null;
  final position = constructor.parameters.parameters
      .where((p) => p.isPositional)
      .toList()
      .indexOf(parameter);
  final targetParameter = parameter.isNamed
      ? target.parameters.parameters.firstWhereOrNull(
          (p) => p.isNamed && p.name?.lexeme == parameter.name?.lexeme,
        )
      : target.parameters.parameters
            .where((p) => p.isPositional)
            .elementAtOrNull(position);
  return targetParameter == null
      ? null
      : (type: type!, constructor: target, parameter: targetParameter);
}
