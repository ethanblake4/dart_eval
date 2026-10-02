import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart'
    show DeclarationOrBridge;
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/expression/literal.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';

import '../builtins.dart';
import '../context.dart';
import '../errors.dart';
import '../member/member.dart' show SourceMember;
import '../variable.dart';
import 'redirect_constructor.dart';

/// Compiles a constant default in its lexical scope, including class statics.
T withDefaultExpressionScope<T>(
  CompilerContext ctx,
  int library,
  AstNode expression,
  T Function() body,
) {
  Declaration? owner;
  for (AstNode? node = expression.parent; node != null; node = node.parent) {
    if (node is ClassDeclaration ||
        node is MixinDeclaration ||
        node is EnumDeclaration ||
        node is ExtensionDeclaration ||
        node is ExtensionTypeDeclaration) {
      owner = node as Declaration;
      break;
    }
  }
  final previousLibrary = ctx.library;
  final previousClass = ctx.currentClass;
  final previousEnclosingLibrary = ctx.enclosingLibrary;
  final previousExtension = ctx.currentExtension;
  final previousAnonymousReceiver = ctx.anonymousThisReceiver;
  final previousDeclaringClass = ctx.memberDeclaringClass;
  final previousLocals = ctx.locals;
  final previousTypeScope = ctx.typeScopes.remove(library);
  ctx
    ..library = library
    ..currentClass = owner
    ..enclosingLibrary = library
    ..currentExtension = owner is ExtensionDeclaration ? owner : null
    ..anonymousThisReceiver = null
    ..memberDeclaringClass = null
    ..locals = [{}];
  try {
    return body();
  } finally {
    if (previousTypeScope == null) {
      ctx.typeScopes.remove(library);
    } else {
      ctx.typeScopes[library] = previousTypeScope;
    }
    ctx
      ..library = previousLibrary
      ..currentClass = previousClass
      ..enclosingLibrary = previousEnclosingLibrary
      ..currentExtension = previousExtension
      ..anonymousThisReceiver = previousAnonymousReceiver
      ..memberDeclaringClass = previousDeclaringClass
      ..locals = previousLocals;
  }
}

/// Defaults are bound before entering a typed function, including host exports.
/// Keep their native values separate from language wrappers and register banks.
Object? evaluateDefaultValue(
  CompilerContext ctx,
  int library,
  Expression? expression, {
  Set<AstNode>? evaluating,
  TypeRef? bound,
}) {
  if (expression == null || expression is NullLiteral) return null;
  final active = evaluating ?? <AstNode>{};
  if (!active.add(expression)) {
    throw CompileError('Cyclic default value', expression);
  }
  Object? evaluate(Expression value, {TypeRef? context}) =>
      evaluateDefaultValue(
        ctx,
        library,
        value,
        evaluating: active,
        bound: context,
      );
  try {
    switch (expression) {
      case IntegerLiteral():
        final value = parseConstLiteral(expression, ctx, bound);
        return value.doubleval ?? value.intval;
      case DoubleLiteral(:final value):
        return value;
      case BooleanLiteral(:final value):
        return value;
      case StringLiteral(:final stringValue) when stringValue != null:
        return stringValue;
      case ParenthesizedExpression(:final expression):
        return evaluate(expression, context: bound);
      case PrefixExpression(:final operand, :final operator):
        final value = evaluate(operand, context: bound);
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
        final left = evaluate(leftOperand, context: bound);
        if (operator.lexeme == '??' && left != null) return left;
        if (operator.lexeme == '&&' && left == false) return false;
        if (operator.lexeme == '||' && left == true) return true;
        final right = evaluate(rightOperand, context: bound);
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
          context: bound,
        );
      case SimpleIdentifier(:final name):
        final staticMember = withDefaultExpressionScope(
          ctx,
          library,
          expression,
          () => ctx.memberLookup.scopedStaticMember(name, forSet: false),
        );
        if (staticMember?.$1 case SourceMember member) {
          final variable = member.sourceDeclaration;
          if (variable is VariableDeclaration &&
              variable.isConst &&
              variable.initializer != null) {
            return evaluateDefaultValue(
              ctx,
              staticMember!.$2,
              variable.initializer,
              evaluating: active,
            );
          }
        }
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
            evaluating: active,
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

/// The super-constructor parameter that super formal [param] binds to —
/// the nth positional parameter for positional super formals (their local
/// names need not match the callee's), the same-named one for named formals —
/// along with the super-constructor declaration owning it. The target is a
/// [FormalParameter] for eval constructors and a [BridgeParameter] for bridge
/// constructors; null when the super constructor has no such parameter.
(DeclarationOrBridge<Declaration, BridgeDeclaration>, Object?)
superFormalTarget(
  CompilerContext ctx,
  int decLibrary,
  SuperFormalParameter param,
  ConstructorDeclaration parameterHost,
) {
  var superConstructorName = '';
  final lastInit = parameterHost.initializers.isEmpty
      ? null
      : parameterHost.initializers.last;
  if (lastInit is SuperConstructorInvocation) {
    superConstructorName = lastInit.constructorName?.name ?? '';
  }
  final $class = parameterHost.parent!.parent as ClassDeclaration;
  final type = TypeRef.lookupDeclaration(ctx, decLibrary, $class);
  final $super =
      ctx.typeSystem.superclassOf(type) ??
      (throw CompileError(
        'Class $type has no super class, so cannot use super formals',
        param,
      ));
  final superCstr =
      ctx.topLevelDeclarationsMap[$super
          .file]!['${$super.name}.$superConstructorName']!;
  final positionalIndex = param.isNamed
      ? -1
      : parameterHost.parameters.parameters
            .where((p) => p is SuperFormalParameter && p.isPositional)
            .toList()
            .indexOf(param);
  if (superCstr.isBridge) {
    final fd = (superCstr.bridge as BridgeConstructorDef).functionDescriptor;
    if (positionalIndex >= 0) {
      return (superCstr, fd.params.elementAtOrNull(positionalIndex));
    }
    for (final bridgeParam in fd.namedParams) {
      if (bridgeParam.name == param.name.lexeme) {
        return (superCstr, bridgeParam);
      }
    }
    return (superCstr, null);
  }
  final cstr = superCstr.declaration as ConstructorDeclaration;
  final cstrPositional = cstr.parameters.parameters
      .where((p) => p.isPositional)
      .toList();
  return (
    superCstr,
    positionalIndex >= 0
        ? cstrPositional.elementAtOrNull(positionalIndex)
        : cstr.parameters.parameters
              .where((p) => p.name?.lexeme == param.name.lexeme)
              .firstOrNull,
  );
}

/// The default expression a `super` parameter inherits from the
/// super-constructor parameter it binds (super formals never declare their
/// own), along with the library the expression resolves in — the super
/// constructor's, not the caller's. Null when the target has no default.
(Expression?, int)? superFormalDefault(
  CompilerContext ctx,
  int decLibrary,
  SuperFormalParameter param,
  ConstructorDeclaration parameterHost,
) {
  final (superCstr, target) = superFormalTarget(
    ctx,
    decLibrary,
    param,
    parameterHost,
  );
  return switch (target) {
    FormalParameter(:final defaultClause?) => (
      defaultClause.value,
      superCstr.sourceLib,
    ),
    SuperFormalParameter target => superFormalDefault(
      ctx,
      superCstr.sourceLib,
      target,
      superCstr.declaration as ConstructorDeclaration,
    ),
    _ => null,
  };
}

/// A redirecting factory inherits defaults from the corresponding target
/// parameter, while retaining its own parameter types and calling shape.
(Expression?, int)? redirectFormalDefault(
  CompilerContext ctx,
  int library,
  FormalParameter parameter,
  ConstructorDeclaration constructor, [
  Set<ConstructorDeclaration>? visited,
]) {
  final redirect = constructor.redirectedConstructor;
  if (redirect == null) return null;
  final active = visited ?? <ConstructorDeclaration>{};
  if (!active.add(constructor)) {
    throw CompileError('Cyclic redirecting factory', constructor);
  }
  final resolved = redirectParameterTarget(
    ctx,
    library,
    parameter,
    constructor,
  );
  if (resolved == null) return null;
  final type = resolved.type;
  final target = resolved.constructor;
  final targetParameter = resolved.parameter;
  final expression = targetParameter.defaultClause?.value;
  if (expression != null) return (expression, type.file);
  if (targetParameter is SuperFormalParameter) {
    return superFormalDefault(ctx, type.file, targetParameter, target);
  }
  return redirectFormalDefault(ctx, type.file, targetParameter, target, active);
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
  FormalParameter parameter, {

  /// The parameter's declared type — the default expression's context
  /// type (e.g. the `Color` in `f([Color c = .red])`).
  TypeRef? bound,
}) {
  var expression = parameter.defaultClause?.value;
  if (expression == null && parameter is SuperFormalParameter) {
    // Super formals never declare their own default — they inherit the
    // super-constructor parameter's, which resolves in that library.
    final host = parameter.parent?.parent;
    if (host is ConstructorDeclaration) {
      final inherited = superFormalDefault(ctx, library, parameter, host);
      if (inherited != null) {
        (expression, library) = inherited;
      }
    }
  }
  final host = parameter.parent?.parent;
  if (expression == null &&
      host is ConstructorDeclaration &&
      host.redirectedConstructor != null) {
    final inherited = redirectFormalDefault(ctx, library, parameter, host);
    if (inherited != null) (expression, library) = inherited;
  }
  if (expression == null) return (null, -1);
  try {
    return (evaluateDefaultValue(ctx, library, expression, bound: bound), -1);
  } on CompileError {
    return (null, _compileDefaultThunk(ctx, library, expression, bound));
  }
}

/// Emits [expression] as a hidden 0-arg function returning its value, and
/// returns the new function's index. Identical expressions share one thunk
/// per compilation. Defaults are compile-time constants, so the thunk never
/// references enclosing locals.
int _compileDefaultThunk(
  CompilerContext ctx,
  int library,
  Expression expression, [
  TypeRef? bound,
]) {
  final cached = ctx.defaultThunkCache[expression];
  if (cached != null) return cached;

  final outer = NestedFunctionState(ctx);
  final previousLibrary = ctx.library;
  try {
    ctx.blockCode = [];
    ctx.labels.clear();
    ctx.caughtExceptionTargets.clear();
    ctx.finishMethod();
    ctx.library = library;
    return ctx.withTypeParameters(ctx.library, null, null, () {
      final thunkId = ctx.beginFunction('<default>');
      ctx.locals = [];
      ctx.exceptionDepth = 0;
      ctx.beginScope();
      ctx.functionSignatures[thunkId] = const MachineFunctionSignature(
        [],
        MachineRepresentation.object,
      );
      final value = withDefaultExpressionScope(
        ctx,
        library,
        expression,
        () => compileExpression(expression, ctx, bound).boxIfNeeded(ctx),
      );
      ctx.pushOp(Return(value.ssa));
      ctx.endScope();
      ctx.finishMethod();
      return ctx.defaultThunkCache[expression] = thunkId;
    });
  } finally {
    ctx.library = previousLibrary;
    outer.restore();
  }
}
