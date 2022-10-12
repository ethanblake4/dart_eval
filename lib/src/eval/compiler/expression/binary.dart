import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../errors.dart';
import 'expression.dart';

/// Compile a [BinaryExpression] to DBC bytecode
Variable compileBinaryExpression(CompilerContext ctx, BinaryExpression e, [TypeRef? boundType]) {
  var L = compileExpression(e.leftOperand, ctx, boundType);
  var R = compileExpression(e.rightOperand, ctx, boundType);

  final opMap = {
    TokenType.PLUS: '+',
    TokenType.MINUS: '-',
    TokenType.SLASH: '/',
    TokenType.STAR: '*',
    TokenType.LT: '<',
    TokenType.GT: '>',
    TokenType.LT_EQ: '<=',
    TokenType.GT_EQ: '>=',
    TokenType.PERCENT: '%',
    TokenType.EQ_EQ: '==',
    TokenType.AMPERSAND_AMPERSAND: '&&',
    TokenType.BAR_BAR: '||'
  };

  var method = opMap[e.operator.type] ?? (throw CompileError('Unknown binary operator ${e.operator.type}'));

  return L.invoke(ctx, method, [R]).result;
}
