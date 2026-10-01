import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import '../errors.dart';
import '../expression/expression.dart';
import '../type.dart';
import '../variable.dart';
import 'conversion.dart';

/// An extension type's representation field is an identity projection.
TypeRef? extensionRepresentationField(
  CompilerContext ctx,
  TypeRef type,
  String name,
) {
  final decl = nominalDeclOf(type);
  if (decl is! SourceTypeDecl ||
      decl.extensionRepresentationParameter?.name?.lexeme != name ||
      name.startsWith('_') && decl.library != ctx.library) {
    return null;
  }
  return decl.extensionRepresentation;
}

/// Constructs the source type while preserving its representation value.
Variable constructExtensionType(
  CompilerContext ctx,
  SourceTypeDecl declaration,
  TypeRef instantiatedType,
  String name,
  ArgumentList arguments, {
  required bool isConst,
  required AstNode source,
}) {
  if (name.isNotEmpty ||
      arguments.arguments.length != 1 ||
      arguments.arguments.single is NamedArgument) {
    throw CompileError(
      'Expected one positional representation argument',
      source,
    );
  }
  final primary =
      (declaration.node as ExtensionTypeDeclaration).namePart
          as PrimaryConstructorDeclaration;
  if (isConst && primary.constKeyword == null) {
    throw CompileError('Extension type constructor is not const', source);
  }
  final representation = declaration.extensionRepresentation!;
  final value = compileExpression(
    arguments.arguments.single.argumentExpression,
    ctx,
    representation,
  );
  if (isConst && !value.isConst) {
    throw CompileError('Representation argument is not constant', source);
  }
  return convertForAssignment(
    ctx,
    value,
    representation,
    source: source,
  ).copyWith(type: instantiatedType, isConst: isConst);
}
