import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/declarations.dart';
import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/parse/source.dart';

abstract class DartStatement extends DartSourceNode {
  DartStatement(int offset, int length) : super(offset, length);

  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope);
}

class DartStatementResult {
  DartStatementResult(this.type, {this.value});

  DartStatementResultType type;
  EvalValue? value;
}

enum DartStatementResultType { RETURN, BREAK, CONTINUE, VALUE, NONE }

class DartBlockStatement extends DartStatement {
  DartBlockStatement(int offset, int length, this.statements) : super(offset, length);

  final List<DartStatement> statements;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final blockScope = EvalScope(lexicalScope, {});
    for (final statement in statements) {
      final r = statement.eval(blockScope, inheritedScope);
      if (r.type == DartStatementResultType.RETURN) {
        return r;
      }
    }
    return DartStatementResult(DartStatementResultType.NONE);
  }
}

class DartExpressionStatement extends DartStatement {
  DartExpressionStatement(int offset, int length, this.expression) : super(offset, length);

  final EvalExpression expression;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return DartStatementResult(DartStatementResultType.VALUE, value: expression.eval(lexicalScope, inheritedScope));
  }
}

class DartVariableDeclarationStatement extends DartStatement {
  DartVariableDeclarationStatement(int offset, int length, this.variables) : super(offset, length);

  final DartVariableDeclarationList variables;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final l = variables.declare(DeclarationContext.STATEMENT, lexicalScope, inheritedScope);
    l.forEach((key, value) {
      lexicalScope.define(key, value);
    });
    return DartStatementResult(DartStatementResultType.NONE);
  }
}

class DartReturnStatement extends DartStatement {
  DartReturnStatement(int offset, int length, this.expression) : super(offset, length);

  final EvalExpression expression;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return DartStatementResult(DartStatementResultType.RETURN, value: expression.eval(lexicalScope, inheritedScope));
  }
}
