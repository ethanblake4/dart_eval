import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern_condition.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

Variable compilePatternAssignment(CompilerContext ctx, PatternAssignment e) {
  final bound = patternTypeBound(ctx, e.pattern);
  final result = compileExpression(e.expression, ctx, bound);

  compileIrrefutablePattern(
    ctx,
    e.pattern,
    result,
    patternContext: PatternBindContext.none,
  );

  // `(b) = cond` records the condition's promotions on `b`, like `b = cond`.
  final (whenTrue, whenFalse) = conditionPromotions(ctx, e.expression);
  if (whenTrue.isNotEmpty || whenFalse.isNotEmpty) {
    for (final name in patternBoundNames(e.pattern, declared: false)) {
      final binding = ctx.lookupBinding(name);
      if (binding != null &&
          !binding.writeCaptured &&
          binding.current.type.isSpec(CoreTypes.bool)) {
        binding.rebind(
          binding.current.withFacts(
            binding.current.facts.copyWith(
              truePromotions: whenTrue,
              falsePromotions: whenFalse,
            ),
          ),
        );
      }
    }
  }

  return result;
}
