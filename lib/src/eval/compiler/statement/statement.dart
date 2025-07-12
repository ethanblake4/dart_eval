import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/statement/assert.dart';
import 'package:dart_eval/src/eval/compiler/statement/break.dart';
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
    Statement s, AlwaysReturnType? expectedReturnType, CompilerContext ctx) {
  if (s is Block) {
    return compileBlock(s, expectedReturnType, ctx);
  } else if (s is VariableDeclarationStatement) {
    return compileVariableDeclarationStatement(s, ctx);
  } else if (s is ExpressionStatement) {
    final V = compileExpressionAndDiscardResult(s.expression, ctx);
    if (V != null && V.type == CoreTypes.never.ref(ctx)) {
      return StatementInfo(-1, willAlwaysThrow: true);
    }
    return StatementInfo(-1);
  } else if (s is ReturnStatement) {
    return compileReturn(ctx, s, expectedReturnType);
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
  } else if (s is PatternVariableDeclarationStatement) {
    return compilePatternVariableDeclarationStatement(s, ctx);
  } else {
    throw CompileError('Unknown statement type ${s.runtimeType}');
  }
}

class StatementInfo {
  StatementInfo(this.position,
      {this.willAlwaysReturn = false, this.willAlwaysThrow = false});

  final int position;
  final bool willAlwaysReturn;
  final bool willAlwaysThrow;

  StatementInfo operator |(StatementInfo other) {
    return StatementInfo(position,
        willAlwaysReturn: willAlwaysReturn && other.willAlwaysReturn,
        willAlwaysThrow: willAlwaysThrow && other.willAlwaysThrow);
  }

  StatementInfo copyWith(
      {int? position, bool? willAlwaysReturn, bool? willAlwaysThrow}) {
    return StatementInfo(position ?? this.position,
        willAlwaysReturn: willAlwaysReturn ?? this.willAlwaysReturn,
        willAlwaysThrow: willAlwaysThrow ?? this.willAlwaysThrow);
  }
}
