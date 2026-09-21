import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';

import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../variable.dart';

/// Defaults are bound before entering a typed function, including host exports.
/// Keep their native values separate from language wrappers and register banks.
Object? evaluateDefaultValue(
  CompilerContext ctx,
  int library,
  Expression? expression, [
  Set<AstNode>? evaluating,
]) {
  if (expression == null || expression is NullLiteral) return null;
  final active = evaluating ?? <AstNode>{};
  if (!active.add(expression)) {
    throw CompileError('Cyclic default value', expression);
  }
  Object? evaluate(Expression value) =>
      evaluateDefaultValue(ctx, library, value, active);
  try {
    switch (expression) {
      case IntegerLiteral(:final value):
        return value;
      case DoubleLiteral(:final value):
        return value;
      case BooleanLiteral(:final value):
        return value;
      case StringLiteral(:final stringValue) when stringValue != null:
        return stringValue;
      case ParenthesizedExpression(:final expression):
        return evaluate(expression);
      case PrefixExpression(:final operand, :final operator):
        final value = evaluate(operand);
        return switch ((operator.lexeme, value)) {
          ('-', int value) => -value,
          ('-', double value) => -value,
          ('~', int value) => ~value,
          ('!', bool value) => !value,
          _ => throw CompileError('Unsupported default expression', expression),
        };
      case BinaryExpression(
        :final leftOperand,
        :final rightOperand,
        :final operator,
      ):
        final left = evaluate(leftOperand);
        if (operator.lexeme == '??' && left != null) return left;
        if (operator.lexeme == '&&' && left == false) return false;
        if (operator.lexeme == '||' && left == true) return true;
        final right = evaluate(rightOperand);
        return switch ((operator.lexeme, left, right)) {
          ('+', num a, num b) => a + b,
          ('-', num a, num b) => a - b,
          ('*', num a, num b) => a * b,
          ('/', num a, num b) => a / b,
          ('~/', num a, num b) => a ~/ b,
          ('%', num a, num b) => a % b,
          ('+', String a, String b) => a + b,
          ('==', _, _) => left == right,
          ('!=', _, _) => left != right,
          ('&&', bool a, bool b) => a && b,
          ('||', bool a, bool b) => a || b,
          ('??', _, _) => right,
          _ => throw CompileError('Unsupported default expression', expression),
        };
      case ConditionalExpression(
        :final condition,
        :final thenExpression,
        :final elseExpression,
      ):
        return evaluate(
          evaluate(condition) as bool ? thenExpression : elseExpression,
        );
      case SimpleIdentifier(:final name):
        final declaration =
            ctx.visibleDeclarations[library]?[name]?.declaration;
        final variable = declaration?.declaration;
        if (variable is VariableDeclaration &&
            variable.isConst &&
            variable.initializer != null) {
          return evaluateDefaultValue(
            ctx,
            declaration!.sourceLib,
            variable.initializer,
            active,
          );
        }
    }
    throw CompileError(
      'Typed parameter defaults require supported scalar constant expressions',
      expression,
    );
  } finally {
    active.remove(expression);
  }
}

Variable pushDefaultValue(CompilerContext ctx, Object? value) =>
    switch (value) {
      null => BuiltinValue(),
      int value => BuiltinValue(intval: value),
      double value => BuiltinValue(doubleval: value),
      bool value => BuiltinValue(boolval: value),
      String value => BuiltinValue(stringval: value),
      _ => throw StateError('Invalid typed default value: $value'),
    }.push(ctx);

/// The constant value an optional parameter takes when the caller omits it.
///
/// Scalar constants encode directly in bytecode; everything else (tear-offs,
/// const objects, const collections) compiles to a hidden zero-argument
/// *thunk* whose index the closure descriptor stores for lazy evaluation.
(Object? value, int thunkIndex) compileParameterDefault(
  CompilerContext ctx,
  int library,
  FormalParameter parameter,
) {
  final expression = parameter.defaultClause?.value;
  if (expression == null) return (null, -1);
  try {
    return (evaluateDefaultValue(ctx, library, expression), -1);
  } on CompileError {
    return (null, _compileDefaultThunk(ctx, expression));
  }
}

/// Emits [expression] as a hidden 0-arg function returning its value, and
/// returns the new function's index. Identical expressions share one thunk
/// per compilation. Defaults are compile-time constants, so the thunk never
/// references enclosing locals.
int _compileDefaultThunk(CompilerContext ctx, Expression expression) {
  final cached = ctx.defaultThunkCache[expression];
  if (cached != null) return cached;

  final outerGraph = ctx.activeGraph;
  final outerBuilder = ctx.builder;
  final outerBlockCode = ctx.blockCode;
  final outerFunctionId = ctx.currentFunctionId;
  final outerFunctionLabel = ctx.funcLabel;
  final outerHasBegun = ctx.hasBegunMethod;
  final outerLabels = [...ctx.labels];
  final outerExceptions = [...ctx.caughtExceptionTargets];
  final outerExceptionDepth = ctx.exceptionDepth;
  final saveState = ctx.saveState();
  final previousTypes = {...?ctx.temporaryTypes[ctx.library]};
  ctx.blockCode = [];
  ctx.labels.clear();
  ctx.caughtExceptionTargets.clear();
  ctx.finishMethod();
  try {
    final thunkId = ctx.beginFunction('<default>');
    ctx.locals = [];
    ctx.exceptionDepth = 0;
    ctx.beginScope();
    ctx.functionSignatures[thunkId] = const MachineFunctionSignature(
      [],
      MachineRepresentation.object,
    );
    final value = compileExpression(expression, ctx).boxIfNeeded(ctx);
    ctx.pushOp(Return(value.ssa));
    ctx.endScope();
    ctx.finishMethod();
    return ctx.defaultThunkCache[expression] = thunkId;
  } finally {
    ctx.activeGraph = outerGraph;
    ctx.builder = outerBuilder;
    ctx.blockCode = outerBlockCode;
    ctx.currentFunctionId = outerFunctionId;
    ctx.funcLabel = outerFunctionLabel;
    ctx.hasBegunMethod = outerHasBegun;
    ctx.exceptionDepth = outerExceptionDepth;
    ctx.labels
      ..clear()
      ..addAll(outerLabels);
    ctx.caughtExceptionTargets
      ..clear()
      ..addAll(outerExceptions);
    ctx.restoreState(saveState);
    ctx.temporaryTypes[ctx.library] = previousTypes;
  }
}
