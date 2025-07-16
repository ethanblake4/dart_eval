import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

Variable compilePatternAssignment(CompilerContext ctx, PatternAssignment e) {
  final bound = patternTypeBound(ctx, e.pattern);
  final result = compileExpression(e.expression, ctx, bound);
  if (!result.type.isAssignableTo(ctx, bound)) {
    throw CompileError(
      'Type ${result.type} is not assignable to pattern type $bound',
      e,
    );
  }

  patternMatchAndBind(ctx, e.pattern, result,
      patternContext: PatternBindContext.none);

  return result;
}
