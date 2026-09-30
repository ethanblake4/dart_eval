import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
// The public AST has no construction or replacement API. Keep the pinned
// analyzer implementation dependency confined to this syntax-lowering step.
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart' as ast;

import '../errors.dart';

/// Lowering preserves the class header's name token as the constructor name.
/// Ordinary constructor declarations have their own name token.
bool isLoweredPrimaryConstructor(ConstructorDeclaration constructor) {
  final owner = constructor.parent?.parent;
  return owner is ClassDeclaration &&
      identical(constructor.typeName?.token, owner.namePart.typeName);
}

/// Reuses ordinary constructor registration, signatures and field lowering.
/// Original tokens and expression nodes retain their source locations.
void lowerPrimaryConstructor(ClassDeclaration declaration) {
  final header = declaration.namePart;
  if (header is! PrimaryConstructorDeclaration) return;
  final body = header.body;
  final members = declaration.body.members;
  // Late initializers run on first access in instance scope. Ordinary field
  // lowering currently evaluates them during construction instead.
  if (members.whereType<FieldDeclaration>().any(
    (field) =>
        !field.isStatic &&
        field.fields.isLate &&
        field.fields.variables.any((variable) => variable.initializer != null),
  )) {
    throw CompileError(
      'Primary constructors with late field initializers are not supported',
      header,
    );
  }
  final fields = <ast.FieldDeclarationImpl>[];
  final parameters = <ast.FormalParameterImpl>[];
  for (final parameter in header.formalParameters.parameters) {
    if (parameter is! RegularFormalParameter ||
        parameter.constFinalOrVarKeyword == null) {
      parameters.add(parameter as ast.FormalParameterImpl);
      continue;
    }
    final suffix = parameter.functionTypedSuffix;
    final fieldType = suffix == null
        ? parameter.type as ast.TypeAnnotationImpl?
        : ast.GenericFunctionTypeImpl(
            returnType: parameter.type as ast.TypeAnnotationImpl?,
            functionKeyword: Token(Keyword.FUNCTION, parameter.name!.offset),
            typeParameters: suffix.typeParameters as ast.TypeParameterListImpl?,
            parameters: suffix.formalParameters as ast.FormalParameterListImpl,
            question: suffix.question,
          );
    final field = ast.VariableDeclarationImpl(
      comment: null,
      metadata: [],
      name: parameter.name!,
      equals: null,
      initializer: null,
    );
    fields.add(
      ast.FieldDeclarationImpl(
        comment: null,
        metadata: [],
        augmentKeyword: null,
        externalKeyword: null,
        staticKeyword: null,
        abstractKeyword: null,
        covariantKeyword: parameter.covariantKeyword,
        fields: ast.VariableDeclarationListImpl(
          comment: null,
          metadata: [],
          lateKeyword: null,
          keyword: fieldType == null || parameter.isFinal
              ? parameter.constFinalOrVarKeyword
              : null,
          type: fieldType,
          variables: [field],
        ),
        semicolon: Token(TokenType.SEMICOLON, parameter.end),
      ),
    );
    final original = parameter as ast.FormalParameterImpl;
    parameters.add(
      ast.FieldFormalParameterImpl(
        comment: original.documentationComment,
        metadata: original.metadata.toList(),
        kind: original.kind,
        requiredKeyword: original.requiredKeyword,
        covariantKeyword: original.covariantKeyword,
        constFinalOrVarKeyword: null,
        type: null,
        thisKeyword: Token(Keyword.THIS, parameter.offset),
        period: Token(TokenType.PERIOD, parameter.name!.offset),
        name: parameter.name!,
        functionTypedSuffix: null,
        defaultClause: original.defaultClause,
      ),
    );
  }
  final originalParameters = header.formalParameters;
  final constructor = ast.ConstructorDeclarationImpl(
    comment: body?.documentationComment as ast.CommentImpl?,
    metadata: body?.metadata.cast<ast.AnnotationImpl>().toList() ?? [],
    augmentKeyword: null,
    externalKeyword: null,
    constKeyword: header.constKeyword,
    factoryKeyword: null,
    newKeyword: null,
    typeName: ast.SimpleIdentifierImpl(token: header.typeName),
    period: header.constructorName?.period,
    name: header.constructorName?.name,
    parameters: ast.FormalParameterListImpl(
      leftParenthesis: originalParameters.leftParenthesis,
      parameters: parameters,
      leftDelimiter: originalParameters.leftDelimiter,
      rightDelimiter: originalParameters.rightDelimiter,
      rightParenthesis: originalParameters.rightParenthesis,
    ),
    separator: body?.colon,
    initializers:
        body?.initializers.cast<ast.ConstructorInitializerImpl>().toList() ??
        [],
    redirectedConstructor: null,
    body:
        body?.body as ast.FunctionBodyImpl? ??
        ast.EmptyFunctionBodyImpl(
          semicolon: Token(TokenType.SEMICOLON, originalParameters.end),
        ),
  );
  final originalBody = declaration.body;
  final lowered = declaration as ast.ClassDeclarationImpl;
  lowered.namePart = ast.NameWithTypeParametersImpl(
    typeName: header.typeName,
    typeParameters: header.typeParameters as ast.TypeParameterListImpl?,
  );
  lowered.body = ast.BlockClassBodyImpl(
    leftBracket: originalBody is BlockClassBody
        ? originalBody.leftBracket
        : Token(TokenType.OPEN_CURLY_BRACKET, originalBody.offset),
    members: [
      ...fields,
      constructor,
      for (final member in members)
        if (member is! PrimaryConstructorBody) member as ast.ClassMemberImpl,
    ],
    rightBracket: originalBody is BlockClassBody
        ? originalBody.rightBracket
        : Token(TokenType.CLOSE_CURLY_BRACKET, originalBody.end),
  );
}
