import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/source_node_wrapper.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

import '../errors.dart';
import 'expression.dart';

/// Compile a [PrefixExpression] to EVC bytecode
Variable compilePrefixExpression(CompilerContext ctx, PrefixExpression e) {
  var V = compileExpression(e.operand, ctx);

  final opMap = {
    TokenType.MINUS: '-',
    TokenType.BANG: '!',
  };

  var method = opMap[e.operator.type] ??
      (throw CompileError('Unknown unary operator ${e.operator.type}'));

  if (method == '-' &&
      V.type != CoreTypes.int.ref(ctx) &&
      V.type != CoreTypes.double.ref(ctx)) {
    throw CompileError(
        'Unary operator "-" is currently only supported for ints and doubles');
  } else if (method == '!' && V.type != CoreTypes.bool.ref(ctx)) {
    throw CompileError(
        'Unary operator "!" is currently only supported for bools');
  }

  if (method == "!") {
    return V.invoke(ctx, method, []).result;
  }
  final zero = V.type == CoreTypes.int.ref(ctx)
      ? BuiltinValue(intval: 0)
      : BuiltinValue(doubleval: 0.0);
  return zero.push(ctx).invoke(ctx, method, [V]).result;
}
