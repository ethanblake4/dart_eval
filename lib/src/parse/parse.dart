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

/// The parser class uses the Dart analyzer to parse Dart code and then transforms it into a Scope.
class Parse {
  final List<DartDeclaration> _additionalDefines = [];

  /// Add a new [DartDeclaration] to this Parse instance's [EvalScope]
  void define(DartDeclaration value) {
    _additionalDefines.add(value);
  }

  /// Parse a string containing Dart code and return a [ScopeWrapper] with that code and
  /// any
  ScopeWrapper parse(String content) {
    final d = parseString(content: content, throwIfDiagnostics: false);

    if (d.errors.isNotEmpty) {
      d.errors.forEach((element) {
        print(element);
      });
      throw ArgumentError();
    }

    final dd = <DartDeclaration>[];
    for (final declaration in d.unit.declarations) {
      dd.add(_parseDeclaration(ParseContext('main.dart'), declaration));
    }

    final tlUnit = EvalCompilationUnit([...dd, ...dartCore, ..._additionalDefines]);
    return ScopeWrapper(tlUnit.buildScope());
  }

  bool _isNotNull(dynamic it) => it == null ? false : true;

  DartDeclaration _parseDeclaration(ParseContext context, Declaration declaration) {
    if (declaration is ClassDeclaration) {
      return DartClassDeclaration(
          declaration.name.name,
          _parseTypeParameterList(context, declaration.typeParameters),
          declaration.members.map((m) => _parseDeclaration(context, m)).toList(),
          declaration.isAbstract,
          declaration.extendsClause?.superclass.name.name,
          parseContext: context);
    } else if (declaration is VariableDeclarationList) {
      return _parseVariableDecList(context, declaration as VariableDeclarationList, false, false);
    } else if (declaration is FieldDeclaration) {
      return _parseVariableDecList(
          context, declaration.fields, declaration.isStatic, _isNotNull(declaration.covariantKeyword));
    } else if (declaration is MethodDeclaration) {
      return _parseMethodDec(context, declaration);
    } else if (declaration is FunctionDeclaration) {
      return DartFunctionDeclaration(
          declaration.name.name, _parseFunctionExpression(context, declaration.functionExpression),
          isStatic: true, visibility: DeclarationVisibility.UNSPECIFIED);
    } else if(declaration is TopLevelVariableDeclaration) {
      return _parseVariableDecList(context, declaration.variables, true, false);
    } else if (declaration is ConstructorDeclaration) {
      return DartConstructorDeclaration(declaration.name?.name ?? '', _parseFPL(context, declaration.parameters));
    }
    throw ArgumentError('Unknown declaration type ${declaration.runtimeType}');
  }

  DartVariableDeclarationList _parseVariableDecList(
      ParseContext context, VariableDeclarationList list, bool isStatic, bool isCovariant) {
    final l = <DartVariableDeclaration>[];
    for (final v in list.variables) {
      l.add(_parseVariableDec(context, v));
    }
    return DartVariableDeclarationList(l,
        isLate: list.isLate,
        isFinal: list.isFinal,
        type: list.type,
        visibility: DeclarationVisibility.UNSPECIFIED,
        isStatic: isStatic);
  }

  // TODO getters
  DartMethodDeclaration _parseMethodDec(ParseContext context, MethodDeclaration declaration) {
    final mb = _parseFunctionBody(context, declaration.body);
    return DartMethodDeclaration(
        declaration.name.name, mb, _parseFPL(context, declaration.parameters!), declaration.isStatic);
  }

  List<ParameterDefinition> _parseFPL(ParseContext context, FormalParameterList list) {
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
              ? _parseExpression(context, param.defaultValue!)
              : null,
          isField: nfp is FieldFormalParameter));
    }
    return lis;
  }

  DartMethodBody _parseFunctionBody(ParseContext context, FunctionBody body) {
    DartBlockStatement? block;
    if (body is BlockFunctionBody) {
      block = _parseBlock(context, body.block);
    }
    return DartMethodBody(block: block);
  }

  DartStatement _parseStatement(ParseContext context, Statement statement) {
    if (statement is Block) {
      return _parseBlock(context, statement);
    } else if (statement is VariableDeclarationStatement) {
      return _parseVariableDecStatement(context, statement);
    } else if (statement is ExpressionStatement) {
      return _parseExpressionStatement(context, statement);
    } else if (statement is ReturnStatement) {
      return DartReturnStatement(statement.offset, statement.length,
          statement.expression == null ? EvalNullExpression(-1, -1) : _parseExpression(context, statement.expression!));
    }
    throw ArgumentError('Unknown statement type ${statement.runtimeType}');
  }

  DartBlockStatement _parseBlock(ParseContext context, Block block) =>
      DartBlockStatement(block.offset, block.length, block.statements.map((s) => _parseStatement(context, s)).toList());

  DartExpressionStatement _parseExpressionStatement(ParseContext context, ExpressionStatement statement) =>
      DartExpressionStatement(statement.offset, statement.length, _parseExpression(context, statement.expression));

  DartVariableDeclarationStatement _parseVariableDecStatement(
          ParseContext context, VariableDeclarationStatement statement) =>
      DartVariableDeclarationStatement(
          statement.offset, statement.length, _parseVariableDecList(context, statement.variables, false, false));

  DartVariableDeclaration _parseVariableDec(ParseContext context, VariableDeclaration declaration) {
    return DartVariableDeclaration(declaration.name.name,
        declaration.initializer == null ? null : _parseExpression(context, declaration.initializer!),
        isLate: declaration.isLate);
  }

  EvalExpression _parseExpression(ParseContext context, Expression expression) {
    if (expression is SimpleIdentifier) {
      return EvalIdentifierExpression(expression.offset, expression.length, expression.name);
    } else if (expression is PrefixedIdentifier) {
      return EvalPrefixedIdentifierExpression(
          expression.offset, expression.length, expression.prefix.name, expression.identifier.name);
    } else if (expression is MethodInvocation) {
      return EvalCallExpression(
          expression.offset,
          expression.length,
          expression.target != null ? _parseExpression(context, expression.target!) : null,
          expression.methodName.name,
          expression.argumentList.arguments.map((m) => _parseExpression(context, m)).toList());
    } else if (expression is Literal) {
      return _parseLiteral(context, expression);
    } else if (expression is FunctionExpression) {
      return _parseFunctionExpression(context, expression);
    } else if (expression is InstanceCreationExpression) {
      return EvalInstanceCreationExpresion(expression.offset, expression.length,
          _parseIdentifier(expression.constructorName.type.name), expression.constructorName.name?.name ?? '');
    } else if (expression is NamedExpression) {
      return EvalNamedExpression(expression.offset, expression.length, expression.name.label.name,
          _parseExpression(context, expression.expression));
    } else if (expression is BinaryExpression) {
      return EvalBinaryExpression(
          expression.offset,
          expression.length,
          _parseExpression(context, expression.leftOperand),
          expression.operator.type,
          _parseExpression(context, expression.rightOperand));
    } else if (expression is PropertyAccess) {
      // TODO support cascades
      return EvalPropertyAccessExpression(expression.offset, expression.length,
          _parseExpression(context, expression.realTarget), expression.propertyName.name);
    } else if (expression is AssignmentExpression) {
      return EvalAssignmentExpression(
          expression.offset,
          expression.length,
          _parseExpression(context, expression.leftHandSide) as EvalReferenceExpression,
          _parseExpression(context, expression.rightHandSide),
          expression.operator.type);
    } else if (expression is IndexExpression) {
      // TODO support cascades
      return EvalIndexExpression(expression.offset, expression.length, _parseExpression(context, expression.realTarget),
          _parseExpression(context, expression.index));
    }
    throw ArgumentError('Unknown expression found while parsing: ${expression.runtimeType}');
  }

  EvalFunctionExpression _parseFunctionExpression(ParseContext context, FunctionExpression expression) =>
      EvalFunctionExpression(expression.offset, expression.length, _parseFunctionBody(context, expression.body),
          _parseFPL(context, expression.parameters!));

  EvalIdentifierExpression _parseIdentifier(Identifier identifier) {
    if (identifier is SimpleIdentifier) {
      return EvalIdentifierExpression(identifier.offset, identifier.length, identifier.name);
    } else if (identifier is PrefixedIdentifier) {
      return EvalPrefixedIdentifierExpression(
          identifier.offset, identifier.length, identifier.prefix.name, identifier.name);
    }
    throw ArgumentError('Unknown identifier ${identifier.runtimeType}');
  }

  EvalExpression _parseLiteral(ParseContext context, Expression literal) {
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
          literal.offset, literal.length, literal.elements.map((e) => _parseCollectionElement(context, e)).toList());
    } else if (literal is SetOrMapLiteral) {
      return EvalMapLiteral(literal.offset, literal.length,
          literal.elements.map((e) => _parseCollectionElement(context, e)).toList());
    }
    throw ArgumentError('Unknown literal found while parsing: ${literal.runtimeType}');
  }

  EvalCollectionElement _parseCollectionElement(ParseContext context, CollectionElement element) {
    if (element is Expression) {
      return _parseExpression(context, element);
    } else if (element is MapLiteralEntry) {
      return EvalMapLiteralEntry(element.length, element.offset,
          _parseExpression(context, element.key), _parseExpression(context, element.value));
    }
    throw ArgumentError('Unknown collection element found while parsing: ${element.runtimeType}');
  }

  EvalGenericsList _parseTypeParameterList(ParseContext context, TypeParameterList? list) {
    if (list == null) {
      return EvalGenericsList([]);
    }
    return EvalGenericsList(list.typeParameters.map((e) => _parseTypeParameter(context, e)).toList());
  }

  EvalGenericParam _parseTypeParameter(ParseContext context, TypeParameter param) {
    return EvalGenericParam(param.name.name);
  }
}

/// The current parsing context
class ParseContext {
  String sourceFile;

  ParseContext(this.sourceFile);
}
