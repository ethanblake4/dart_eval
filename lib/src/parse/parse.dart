import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/collections.dart';
import 'package:dart_eval/src/eval/declarations.dart';
import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/eval/functions.dart';
import 'package:dart_eval/src/eval/generics.dart';
import 'package:dart_eval/src/eval/literals.dart';
import 'package:dart_eval/src/eval/statements.dart';
import 'package:dart_eval/src/eval/unit.dart';
import 'package:dart_eval/src/libs/dart_core.dart';

import '../../dart_eval.dart';

class Parse {
  List<Map<String, EvalField>> additionalDefines = [];

  void define(String name, EvalValue value) {
    additionalDefines.add({
      name: EvalField(name, value, null, Getter(null)),
    });
  }

  ScopeWrapper parse(String content) {
    final d = parseString(content: content, throwIfDiagnostics: false);

    if (d.errors != null && d.errors.isNotEmpty) {
      d.errors.forEach((element) {
        print(element);
      });
      throw ArgumentError();
    }

    final dd = <DartDeclaration>[];
    for (final declaration in d.unit.declarations) {
      dd.add(parseDeclaration(ParseContext('main.dart'), declaration));
    }

    final tlUnit = EvalCompilationUnit(dd);
    final tlScope = tlUnit.buildScope([dartCore, ...additionalDefines]);
    return ScopeWrapper(tlScope);
  }

  bool isNotNull(dynamic it) => it == null ? false : true;

  DartDeclaration parseDeclaration(ParseContext context, Declaration declaration) {
    if (declaration is ClassDeclaration) {
      return DartClassDeclaration(
          declaration.name.name,
          parseTypeParameterList(context, declaration.typeParameters),
          declaration.members.map((m) => parseDeclaration(context, m)).toList(),
          declaration.isAbstract,
          declaration.extendsClause?.superclass.name.name,
          parseContext: context);
    } else if (declaration is VariableDeclarationList) {
      return parseVariableDecList(context, declaration as VariableDeclarationList, false, false);
    } else if (declaration is FieldDeclaration) {
      return parseVariableDecList(
          context, declaration.fields, declaration.isStatic, isNotNull(declaration.covariantKeyword));
    } else if (declaration is MethodDeclaration) {
      return parseMethodDec(context, declaration);
    } else if (declaration is FunctionDeclaration) {
      return DartFunctionDeclaration(
          declaration.name.name, parseFunctionExpression(context, declaration.functionExpression),
          isStatic: true, visibility: DeclarationVisibility.UNSPECIFIED);
    } else if (declaration is ConstructorDeclaration) {
      return DartConstructorDeclaration(declaration.name?.name ?? '', parseFPL(context, declaration.parameters));
    }
    throw ArgumentError('Unknown declaration type ${declaration.runtimeType}');
  }

  DartVariableDeclarationList parseVariableDecList(
      ParseContext context, VariableDeclarationList list, bool isStatic, bool isCovariant) {
    final l = <DartVariableDeclaration>[];
    for (final v in list.variables) {
      l.add(parseVariableDec(context, v));
    }
    return DartVariableDeclarationList(l,
        isLate: list.isLate,
        isFinal: list.isFinal,
        type: list.type,
        visibility: DeclarationVisibility.UNSPECIFIED,
        isStatic: isStatic);
  }

  // TODO getters
  DartMethodDeclaration parseMethodDec(ParseContext context, MethodDeclaration declaration) {
    final mb = parseFunctionBody(context, declaration.body);
    return DartMethodDeclaration(
        declaration.name.name, mb, parseFPL(context, declaration.parameters!), declaration.isStatic);
  }

  List<ParameterDefinition> parseFPL(ParseContext context, FormalParameterList list) {
    final lis = <ParameterDefinition>[];
    for (final param in list.parameters) {
      final nfp = (param is DefaultFormalParameter) ? param.parameter : param as NormalFormalParameter;

      TypeAnnotation? ta;
      if (nfp is SimpleFormalParameter) {
        ta = nfp.type;
      } else if (nfp is FunctionTypedFormalParameter) {
        throw UnimplementedError('Function typed formal parameters not yet supported');
      }
      lis.add(ParameterDefinition(
          nfp.identifier!.name,
          ta != null ? EvalType.fromAnnotation(ta, context.sourceFile) : null,
          ta?.question != null,
          nfp.isOptional,
          nfp.isNamed,
          nfp.isRequired,
          param is DefaultFormalParameter && param.defaultValue != null
              ? parseExpression(context, param.defaultValue!)
              : null,
          isField: nfp is FieldFormalParameter));
    }
    return lis;
  }

  DartMethodBody parseFunctionBody(ParseContext context, FunctionBody body) {
    DartBlockStatement? block;
    if (body is BlockFunctionBody) {
      block = parseBlock(context, body.block);
    }
    return DartMethodBody(block: block);
  }

  DartStatement parseStatement(ParseContext context, Statement statement) {
    if (statement is Block) {
      return parseBlock(context, statement);
    } else if (statement is VariableDeclarationStatement) {
      return parseVariableDecStatement(context, statement);
    } else if (statement is ExpressionStatement) {
      return parseExpressionStatement(context, statement);
    } else if (statement is ReturnStatement) {
      return DartReturnStatement(statement.offset, statement.length,
          statement.expression == null ? EvalNullExpression(-1, -1) : parseExpression(context, statement.expression!));
    }
    throw ArgumentError('Unknown statement type ${statement.runtimeType}');
  }

  DartBlockStatement parseBlock(ParseContext context, Block block) =>
      DartBlockStatement(block.offset, block.length, block.statements.map((s) => parseStatement(context, s)).toList());

  DartExpressionStatement parseExpressionStatement(ParseContext context, ExpressionStatement statement) =>
      DartExpressionStatement(statement.offset, statement.length, parseExpression(context, statement.expression));

  DartVariableDeclarationStatement parseVariableDecStatement(
          ParseContext context, VariableDeclarationStatement statement) =>
      DartVariableDeclarationStatement(
          statement.offset, statement.length, parseVariableDecList(context, statement.variables, false, false));

  DartVariableDeclaration parseVariableDec(ParseContext context, VariableDeclaration declaration) {
    return DartVariableDeclaration(declaration.name.name,
        declaration.initializer == null ? null : parseExpression(context, declaration.initializer!),
        isLate: declaration.isLate);
  }

  EvalExpression parseExpression(ParseContext context, Expression expression) {
    if (expression is SimpleIdentifier) {
      return EvalIdentifierExpression(expression.offset, expression.length, expression.name);
    } else if (expression is PrefixedIdentifier) {
      return EvalPrefixedIdentifierExpression(
          expression.offset, expression.length, expression.prefix.name, expression.identifier.name);
    } else if (expression is MethodInvocation) {
      return EvalCallExpression(
          expression.offset,
          expression.length,
          expression.target != null ? parseExpression(context, expression.target!) : null,
          expression.methodName.name,
          expression.argumentList.arguments.map((m) => parseExpression(context, m)).toList());
    } else if (expression is Literal) {
      return parseLiteral(context, expression);
    } else if (expression is FunctionExpression) {
      return parseFunctionExpression(context, expression);
    } else if (expression is InstanceCreationExpression) {
      return EvalInstanceCreationExpresion(expression.offset, expression.length,
          parseIdentifier(expression.constructorName.type.name), expression.constructorName.name?.name ?? '');
    } else if (expression is NamedExpression) {
      return EvalNamedExpression(expression.offset, expression.length, expression.name.label.name,
          parseExpression(context, expression.expression));
    } else if (expression is BinaryExpression) {
      return EvalBinaryExpression(
          expression.offset,
          expression.length,
          parseExpression(context, expression.leftOperand),
          expression.operator.type,
          parseExpression(context, expression.rightOperand));
    } else if (expression is PropertyAccess) {
      // TODO support cascades
      return EvalPropertyAccessExpression(expression.offset, expression.length,
          parseExpression(context, expression.realTarget), expression.propertyName.name);
    } else if (expression is AssignmentExpression) {
      return EvalAssignmentExpression(
          expression.offset,
          expression.length,
          parseExpression(context, expression.leftHandSide) as EvalReferenceExpression,
          parseExpression(context, expression.rightHandSide),
          expression.operator.type);
    }
    throw ArgumentError('Unknown expression found while parsing: ${expression.runtimeType}');
  }

  EvalFunctionExpression parseFunctionExpression(ParseContext context, FunctionExpression expression) =>
      EvalFunctionExpression(expression.offset, expression.length, parseFunctionBody(context, expression.body),
          parseFPL(context, expression.parameters!));

  EvalIdentifierExpression parseIdentifier(Identifier identifier) {
    if (identifier is SimpleIdentifier) {
      return EvalIdentifierExpression(identifier.offset, identifier.length, identifier.name);
    } else if (identifier is PrefixedIdentifier) {
      return EvalPrefixedIdentifierExpression(
          identifier.offset, identifier.length, identifier.prefix.name, identifier.name);
    }
    throw ArgumentError('Unknown identifier ${identifier.runtimeType}');
  }

  EvalExpression parseLiteral(ParseContext context, Expression literal) {
    if (literal is StringLiteral) {
      if (literal is SimpleStringLiteral) {
        return EvalStringLiteral(literal.offset, literal.length, literal.value);
      }
      throw ArgumentError('Unknown literal found while parsing: ${literal.runtimeType}');
    } else if (literal is BooleanLiteral) {
      return EvalBoolLiteral(literal.offset, literal.length, literal.value);
    } else if (literal is IntegerLiteral) {
      return EvalIntLiteral(literal.offset, literal.length, literal.value!);
    } else if (literal is ListLiteral) {
      return EvalListLiteral(
          literal.offset, literal.length, literal.elements.map((e) => parseCollectionElement(context, e)).toList());
    }
    throw ArgumentError('Unknown literal found while parsing: ${literal.runtimeType}');
  }

  EvalCollectionElement parseCollectionElement(ParseContext context, CollectionElement element) {
    if (element is Expression) {
      return parseExpression(context, element);
    }
    throw ArgumentError('Unknown collection element found while parsing: ${element.runtimeType}');
  }

  EvalGenericsList parseTypeParameterList(ParseContext context, TypeParameterList? list) {
    if (list == null) {
      return EvalGenericsList([]);
    }
    return EvalGenericsList(list.typeParameters.map((e) => parseTypeParameter(context, e)).toList());
  }

  EvalGenericParam parseTypeParameter(ParseContext context, TypeParameter param) {
    return EvalGenericParam(param.name.name);
  }
}

class ParseContext {
  String sourceFile;

  ParseContext(this.sourceFile);
}
