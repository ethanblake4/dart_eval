import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// Compile a [SwitchExpression] to EVC bytecode
Variable compileSwitchExpression(SwitchExpression e, CompilerContext ctx,
    [TypeRef? boundType]) {
  final switchExpr = compileExpression(e.expression, ctx).boxIfNeeded(ctx);

  // Create a temporary variable to hold the result
  ctx.setLocal('#switch_result', BuiltinValue().push(ctx));
  final resultRef = IdentifierReference(null, '#switch_result');
  final types = <TypeRef>{if (boundType != null) boundType};

  // Compile switch cases recursively
  _compileSwitchExpressionCases(
      ctx, switchExpr, e.cases, 0, resultRef, types, boundType);

  final result = resultRef.getValue(ctx).updated(ctx);
  return result.copyWith(
      type: TypeRef.commonBaseType(ctx, types).copyWith(boxed: result.boxed));
}

void _compileSwitchExpressionCases(
  CompilerContext ctx,
  Variable switchExpr,
  List<SwitchExpressionCase> cases,
  int index,
  IdentifierReference resultRef,
  Set<TypeRef> types,
  TypeRef? boundType,
) {
  if (index >= cases.length) {
    // No more cases - check if we have exhaustive coverage
    // if (_isExhaustive(ctx, switchExpr, cases)) {
    // This case should not be reached if switch is truly exhaustive
    // return;
    // }
    return;
    // throw CompileError('Switch expression must be exhaustive');
  }

  final currentCase = cases[index];
  final pattern = currentCase.guardedPattern.pattern;

  // Handle default case (WildcardPattern with _)
  if (pattern is WildcardPattern) {
    final value = compileExpression(currentCase.expression, ctx, boundType);
    types.add(value.type);
    resultRef.setValue(ctx, value);
    return;
  }

  // Handle constant pattern cases
  Expression? caseExpression;
  if (pattern.runtimeType.toString().contains('ConstantPattern')) {
    try {
      final dynamic constantPattern = pattern;
      caseExpression = constantPattern.expression;
    } catch (e) {
      throw CompileError(
          'Unsupported pattern type in switch expression: ${pattern.runtimeType}',
          currentCase);
    }
  } else {
    throw CompileError(
        'Only constant patterns and wildcard patterns are currently supported in switch expressions',
        currentCase);
  }

  if (caseExpression == null) {
    throw CompileError(
        'Could not extract expression from switch case pattern', currentCase);
  }

  // Use macroBranch to handle the case matching
  macroBranch(
    ctx,
    boundType == null ? null : AlwaysReturnType(boundType, false),
    condition: (_ctx) {
      final caseExpr =
          compileExpression(caseExpression!, _ctx).boxIfNeeded(_ctx);
      return switchExpr.invoke(_ctx, '==', [caseExpr]).result;
    },
    thenBranch: (_ctx, _) {
      // This case matches - compile the expression and store result
      final value = compileExpression(currentCase.expression, ctx, boundType);
      types.add(value.type);
      resultRef.setValue(ctx, value);
      return StatementInfo(-1);
    },
    elseBranch: (_ctx, _) {
      // Try next case
      _compileSwitchExpressionCases(
          ctx, switchExpr, cases, index + 1, resultRef, types, boundType);
      return StatementInfo(-1);
    },
    resolveStateToThen: true,
    source: currentCase,
  );
}

/// Check if a switch expression is exhaustive
// bool _isExhaustive(CompilerContext ctx, Variable switchExpr,
//     List<SwitchExpressionCase> cases) {
//   // Check if there's a wildcard pattern (default case)
//   for (final case_ in cases) {
//     if (case_.guardedPattern.pattern is WildcardPattern) {
//       return true;
//     }
//   }

//   // For boolean types, check if both true and false are covered
//   if (switchExpr.type == CoreTypes.bool.ref(ctx)) {
//     bool hasTrue = false;
//     bool hasFalse = false;

//     for (final case_ in cases) {
//       final pattern = case_.guardedPattern.pattern;
//       if (pattern.runtimeType.toString().contains('ConstantPattern')) {
//         try {
//           final dynamic constantPattern = pattern;
//           final expr = constantPattern.expression;
//           if (expr is BooleanLiteral) {
//             if (expr.value == true) hasTrue = true;
//             if (expr.value == false) hasFalse = true;
//           }
//         } catch (e) {
//           // Ignore and continue
//         }
//       }
//     }

//     return hasTrue && hasFalse;
//   }

//   // For other types, we'll be conservative and require a wildcard
//   return false;
// }
