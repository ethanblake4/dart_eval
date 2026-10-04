import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern.dart';
import 'package:dart_eval/src/eval/compiler/helpers/pattern_condition.dart';
import 'package:dart_eval/src/eval/compiler/helpers/promotion.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

import 'statement.dart';

StatementInfo compilePatternVariableDeclarationStatement(
  PatternVariableDeclarationStatement s,
  CompilerContext ctx,
) {
  compilePatternVariableDeclaration(s.declaration, ctx);
  return StatementInfo();
}

void compilePatternVariableDeclaration(
  PatternVariableDeclaration dec,
  CompilerContext ctx,
) {
  final bound = patternTypeBound(ctx, dec.pattern, source: dec);
  final result = compileExpression(dec.expression, ctx, bound);
  Expression initializer = dec.expression;
  while (initializer is ParenthesizedExpression) {
    initializer = initializer.expression;
  }
  compileIrrefutablePattern(
    ctx,
    dec.pattern,
    result,
    // Ordinary declarations do not promote their initializer; receiver
    // declarations participate in the experimental `this` promotion flow.
    source: initializer is ThisExpression ? dec.expression : null,
    patternContext: dec.keyword.keyword == Keyword.FINAL
        ? PatternBindContext.declareFinal
        : PatternBindContext.declare,
  );

  // `var (b) = cond` records the condition's promotions on `b`, like
  // `bool b = cond` does.
  final (whenTrue, whenFalse) = conditionPromotions(ctx, dec.expression);
  if (whenTrue.isNotEmpty || whenFalse.isNotEmpty) {
    for (final name in patternBoundNames(dec.pattern, declared: true)) {
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
}
