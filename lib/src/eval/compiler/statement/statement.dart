import '../helpers/captures.dart';
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
    } else if (s is VariableDeclarationStatement) {
      return compileVariableDeclarationStatement(s, ctx);
    } else if (s is ExpressionStatement) {
      final V = compileExpressionAndDiscardResult(s.expression, ctx);
      if (V != null && V.type == CoreTypes.never.ref(ctx)) {
        return StatementInfo(willAlwaysThrow: true);
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
    } else if (s is PatternVariableDeclarationStatement) {
      return compilePatternVariableDeclarationStatement(s, ctx);
    } else if (s is FunctionDeclarationStatement) {
      final decl = s.functionDeclaration;
      final captured = capturesFor(decl).captured.contains(decl);
      if (captured) {
        final placeholder = BuiltinValue()
            .push(ctx)
            .copyWith(type: CoreTypes.function.ref(ctx));
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

class StatementInfo {
  StatementInfo({
    this.willAlwaysReturn = false,
    this.willAlwaysThrow = false,
    this.willAlwaysBreak = false,
  });

  final bool willAlwaysReturn;
  final bool willAlwaysThrow;
  final bool willAlwaysBreak;

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
