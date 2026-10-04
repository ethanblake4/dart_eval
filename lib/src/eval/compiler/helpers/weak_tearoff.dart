import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import '../errors.dart';
import '../expression/expression.dart';
import '../invocation/binder.dart';
import '../invocation/call.dart';
import '../invocation/targets.dart';
import '../member/call_signature.dart';
import '../reference.dart';
import '../type.dart';
import '../variable.dart';
import 'external.dart';
import 'tearoff.dart';

/// A weak-reference call becomes a nullable tear-off at link time. Its
/// annotated body does not execute and its argument does not retain a target.
Variable? compileWeakTearOffReference(
  CompilerContext ctx,
  int library,
  Declaration declaration,
  MethodInvocation invocation, {
  TypeRef? bound,
}) {
  if (!declaration.metadata.any((annotation) {
    final arguments = annotation.arguments?.arguments;
    return arguments?.isNotEmpty == true &&
        arguments!.first is SimpleStringLiteral &&
        (arguments.first as SimpleStringLiteral).value ==
            'weak-tearoff-reference' &&
        isCorePragma(ctx, library, annotation);
  })) {
    return null;
  }
  final signature = CallSignature.forDeclaration(ctx, library, declaration);
  if (declaration is MethodDeclaration && !declaration.isStatic ||
      signature.positional.length != 1 ||
      signature.requiredPositional != 1 ||
      signature.named.isNotEmpty ||
      !signature.returnType.hasNullableRepresentation ||
      signature.positional.single.type != signature.returnType) {
    throw CompileError(
      'Invalid weak tear-off reference signature',
      declaration,
    );
  }
  final arguments = invocation.argumentList.arguments;
  if (arguments.length != 1 || arguments.single is! Expression) {
    throw CompileError(
      'Weak reference requires one static tear-off',
      invocation,
    );
  }
  final target = _weakTarget(ctx, arguments.single as Expression, {});
  if (target.signature!.positional.isNotEmpty ||
      target.signature!.named.isNotEmpty ||
      target.signature!.typeParameters.isNotEmpty) {
    throw CompileError(
      'Weak reference target must take no parameters',
      invocation,
    );
  }
  final value = materializeTearOff(ctx, target.offset!, weak: true);
  ctx.hasWeakTearOffReferences = true;
  final call = ArgumentBinder(ctx).bindDeclaration(
    library,
    declaration,
    null,
    suppliedShape: CallShape.values([value]),
    typeArguments: invocation.typeArguments,
    source: invocation,
    returnContext: bound,
    targetSignature: signature,
  );
  return call.positional.single.withType(call.returnType);
}

StaticCall _weakTarget(
  CompilerContext ctx,
  Expression expression,
  Set<AstNode> aliases,
) {
  while (expression is ParenthesizedExpression) {
    expression = expression.expression;
  }
  if (expression is SimpleIdentifier) {
    final alias = ctx.lookupBinding(expression.name)?.captureDeclaration;
    if (alias is VariableDeclaration &&
        alias.parent is VariableDeclarationList &&
        (alias.parent as VariableDeclarationList).isConst &&
        alias.initializer != null &&
        aliases.add(alias)) {
      return _weakTarget(ctx, alias.initializer!, aliases);
    }
  }
  if (expression is Identifier || expression is PropertyAccess) {
    final reference = compileExpressionAsReference(expression, ctx);
    if (reference is IdentifierReference) {
      final denotation = reference.denotation(ctx, source: expression);
      if (denotation is FunctionDenotation ||
          denotation is StaticMemberDenotation ||
          denotation is ExtensionMemberDenotation) {
        final target = denotation.call(ctx, source: expression);
        if (target is StaticCall &&
            target.receiver == null &&
            target.offset != null &&
            target.signature != null) {
          return target;
        }
      }
    }
  }
  throw CompileError(
    'Weak reference target must be a static tear-off',
    expression,
  );
}
