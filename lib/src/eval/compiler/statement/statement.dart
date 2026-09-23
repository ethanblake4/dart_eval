import '../helpers/captures.dart';
import '../helpers/return.dart';
import '../builtins.dart';
import '../reference.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/statement/assert.dart';
import 'package:dart_eval/src/eval/compiler/statement/break.dart';
import 'package:dart_eval/src/eval/compiler/statement/continue.dart';
import 'package:dart_eval/src/eval/compiler/statement/do.dart';
import 'package:dart_eval/src/eval/compiler/statement/for.dart';
import 'package:dart_eval/src/eval/compiler/statement/if.dart';
import 'package:dart_eval/src/eval/compiler/statement/labeled.dart';
import 'package:dart_eval/src/eval/compiler/statement/pattern_variable_declaration.dart';
import 'package:dart_eval/src/eval/compiler/statement/return.dart';
import 'package:dart_eval/src/eval/compiler/statement/switch.dart';
import 'package:dart_eval/src/eval/compiler/statement/try.dart';
import 'package:dart_eval/src/eval/compiler/statement/variable_declaration.dart';
import 'package:dart_eval/src/eval/compiler/statement/while.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

import 'block.dart';

StatementInfo compileStatement(
  Statement s,
  AlwaysReturnType? expectedReturnType,
  CompilerContext ctx, {
  bool skipClassBoxing = false,
}) {
  try {
    if (s is Block) {
      return compileBlock(
        s,
        expectedReturnType,
        ctx,
        skipClassBoxing: skipClassBoxing,
      );
    } else if (s is EmptyStatement) {
      return StatementInfo();
    } else if (s is VariableDeclarationStatement) {
      return compileVariableDeclarationStatement(s, ctx);
    } else if (s is ExpressionStatement) {
      final V = compileExpressionAndDiscardResult(s.expression, ctx);
      if (V != null && V.type.isSpec(CoreTypes.never)) {
        return markNeverTerminates(ctx);
      }
      return StatementInfo();
    } else if (s is ReturnStatement) {
      return compileReturn(
        ctx,
        s,
        expectedReturnType,
        skipClassBoxing: skipClassBoxing,
      );
    } else if (s is ForStatement) {
      return compileForStatement(s, ctx, expectedReturnType);
    } else if (s is WhileStatement) {
      return compileWhileStatement(s, ctx, expectedReturnType);
    } else if (s is DoStatement) {
      return compileDoStatement(s, ctx, expectedReturnType);
    } else if (s is IfStatement) {
      return compileIfStatement(s, ctx, expectedReturnType);
    } else if (s is SwitchStatement) {
      return compileSwitchStatement(s, ctx, expectedReturnType);
    } else if (s is TryStatement) {
      return compileTryStatement(s, ctx, expectedReturnType);
    } else if (s is AssertStatement) {
      return compileAssertStatement(s, ctx, expectedReturnType);
    } else if (s is BreakStatement) {
      return compileBreakStatement(s, ctx);
    } else if (s is ContinueStatement) {
      return compileContinueStatement(s, ctx);
    } else if (s is LabeledStatement) {
      return compileLabeledStatement(s, ctx, expectedReturnType);
    } else if (s is PatternVariableDeclarationStatement) {
      return compilePatternVariableDeclarationStatement(s, ctx);
    } else if (s is FunctionDeclarationStatement) {
      final decl = s.functionDeclaration;
      if (decl.name.lexeme == '_') {
        // A local `_` function is a wildcard: compile it, bind nothing.
        compileFunctionExpression(decl.functionExpression, ctx);
        return StatementInfo();
      }
      final captured = capturesFor(decl).captured.contains(decl);
      if (captured) {
        final placeholder = BuiltinValue()
            .push(ctx)
            .copyWith(
              type: CoreTypes.function.ref(ctx),
              declaredType: CoreTypes.function.ref(ctx),
            );
        ctx.setLocal(decl.name.lexeme, placeholder.captureBinding(ctx, decl));
      }
      final variable = compileFunctionExpression(decl.functionExpression, ctx);
      if (captured) {
        IdentifierReference(null, decl.name.lexeme).setValue(ctx, variable);
      } else {
        ctx.setLocal(decl.name.lexeme, variable);
      }
      return StatementInfo();
    }
  } on Error {
    print('Failed to compile a statement "$s"');
    rethrow;
  }
  throw CompileError('Unknown statement type ${s.runtimeType}');
}

/// Control-flow facts about a compiled statement.
///
/// The `willAlwaysX` flags are only set when the statement is guaranteed to
/// diverge that way on *every* path — used e.g. to decide whether a function
/// body needs an implicit return appended.
class StatementInfo {
  StatementInfo({
    this.willAlwaysReturn = false,
    this.willAlwaysThrow = false,
    this.willAlwaysBreak = false,
  });

  final bool willAlwaysReturn;
  final bool willAlwaysThrow;
  final bool willAlwaysBreak;

  /// Joins the infos of two alternative control-flow paths (e.g. try body vs.
  /// catch block): a `willAlwaysX` flag survives only if it holds on *both*
  /// sides, hence `&&` despite the `|` name.
  StatementInfo operator |(StatementInfo other) {
    return StatementInfo(
      willAlwaysReturn: willAlwaysReturn && other.willAlwaysReturn,
      willAlwaysThrow: willAlwaysThrow && other.willAlwaysThrow,
      willAlwaysBreak: willAlwaysBreak && other.willAlwaysBreak,
    );
  }

  StatementInfo copyWith({
    bool? willAlwaysReturn,
    bool? willAlwaysThrow,
    bool? willAlwaysBreak,
  }) {
    return StatementInfo(
      willAlwaysReturn: willAlwaysReturn ?? this.willAlwaysReturn,
      willAlwaysThrow: willAlwaysThrow ?? this.willAlwaysThrow,
      willAlwaysBreak: willAlwaysBreak ?? this.willAlwaysBreak,
    );
  }
}
