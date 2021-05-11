import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/declarations.dart';
import 'package:dart_eval/src/eval/expressions.dart';
import 'package:dart_eval/src/parse/source.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;

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
  DartBlockStatement(int offset, int length, this.statements)
      : super(offset, length);

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
  DartExpressionStatement(int offset, int length, this.expression)
      : super(offset, length);

  final EvalExpression expression;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return DartStatementResult(DartStatementResultType.VALUE,
        value: expression.eval(lexicalScope, inheritedScope));
  }
}

class DartVariableDeclarationStatement extends DartStatement {
  DartVariableDeclarationStatement(int offset, int length, this.variables)
      : super(offset, length);

  final DartVariableDeclarationList variables;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final l = variables.declare(
        DeclarationContext.STATEMENT, lexicalScope, inheritedScope);
    l.forEach((key, value) {
      lexicalScope.define(key, value);
    });
    return DartStatementResult(DartStatementResultType.NONE);
  }
}

class DartReturnStatement extends DartStatement {
  DartReturnStatement(int offset, int length, this.expression)
      : super(offset, length);

  final EvalExpression expression;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    return DartStatementResult(DartStatementResultType.RETURN,
        value: expression.eval(lexicalScope, inheritedScope));
  }
}

class DartIfStatement extends DartStatement {
  DartIfStatement(int offset, int length, this.condition, this.thenStatement,
      this.elseStatement)
      : super(offset, length);

  EvalExpression condition;
  DartStatement thenStatement;
  DartStatement? elseStatement;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    if (condition.eval(lexicalScope, inheritedScope).realValue) {
      return thenStatement.eval(lexicalScope, inheritedScope);
    } else if (elseStatement != null) {
      return elseStatement!.eval(lexicalScope, inheritedScope);
    }
    return DartStatementResult(DartStatementResultType.NONE);
  }
}

/// A standard `for` loop
///
/// See [ast.ForStatement] and [ast.ForParts]
class DartForStatement extends DartStatement {
  DartForStatement(int offset, int length, this.declarationList,
      this.initialization, this.condition, this.updaters, this.body)
      : super(offset, length);

  EvalExpression? condition;
  DartVariableDeclarationList? declarationList;
  DartStatement body;
  EvalExpression? initialization;
  List<EvalExpression> updaters;

  @override
  DartStatementResult eval(EvalScope lexicalScope, EvalScope inheritedScope) {
    final loopScope = EvalScope(lexicalScope, {});

    if (declarationList != null) {
      final l = declarationList!
          .declare(DeclarationContext.STATEMENT, loopScope, inheritedScope);
      l.forEach((key, value) {
        loopScope.define(key, value);
      });
    } else {
      initialization?.eval(loopScope, inheritedScope);
    }

    if (condition == null) {
      loop:
      while (true) {
        final res = body.eval(loopScope, inheritedScope);

        switch (res.type) {
          case DartStatementResultType.RETURN:
            return res;
          case DartStatementResultType.CONTINUE:
            continue;
          case DartStatementResultType.BREAK:
            break loop;
          default:
            for (final u in updaters) {
              u.eval(loopScope, inheritedScope);
            }
        }
      }
    } else {
      loop:
      while (condition!.eval(loopScope, inheritedScope).realValue) {
        final res = body.eval(loopScope, inheritedScope);

        switch (res.type) {
          case DartStatementResultType.RETURN:
            return res;
          case DartStatementResultType.CONTINUE:
            continue;
          case DartStatementResultType.BREAK:
            break loop;
          default:
            for (final u in updaters) {
              u.eval(loopScope, inheritedScope);
            }
        }
      }
    }

    return DartStatementResult(DartStatementResultType.NONE);
  }
}
