import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../errors.dart';
import '../type.dart';
import 'formal_parameter.dart' show formalParameterName;

/// A structural inference preview. It emits no operations and leaves unknown
/// expressions for ordinary compilation instead of treating them as dynamic.
TypeRef? previewArgumentType(
  CompilerContext ctx,
  Expression expression, {
  TypeRef? context,
  Map<String, TypeRef> locals = const {},
}) {
  TypeRef? preview(Expression expression, [TypeRef? bound]) =>
      previewArgumentType(ctx, expression, context: bound, locals: locals);
  TypeRef? fieldType(TypeRef receiver, String name) {
    try {
      return ctx.memberLookup.fieldType(receiver, name);
    } on CompileError {
      // Extension and other unsupported selectors are resolved by compilation.
      return null;
    }
  }

  if (expression is ParenthesizedExpression) {
    return preview(expression.expression, context);
  }
  if (expression is IntegerLiteral) return CoreTypes.int.ref(ctx);
  if (expression is DoubleLiteral) return CoreTypes.double.ref(ctx);
  if (expression is StringLiteral) return CoreTypes.string.ref(ctx);
  if (expression is BooleanLiteral) return CoreTypes.bool.ref(ctx);
  if (expression is NullLiteral) return CoreTypes.nullType.ref(ctx);
  if (expression is SimpleIdentifier) {
    final local = locals[expression.name];
    if (local != null) return local;
    final binding = ctx.lookupBinding(expression.name);
    return binding?.isFinal == true ? binding!.current.type : null;
  }
  if (expression is CascadeExpression) {
    return preview(expression.target, context);
  }
  if (expression is AsExpression) {
    return TypeRef.fromAnnotation(ctx, ctx.library, expression.type);
  }
  if (expression is ThrowExpression) return CoreTypes.never.ref(ctx);
  if (expression is FunctionExpression) {
    if (expression.typeParameters != null || expression.body.isGenerator) {
      return null;
    }
    final signature = context is FunctionTypeRef ? context.signature : null;
    final parameters = <TypeRef>[];
    final named = <String, ({TypeRef type, bool required})>{};
    final innerLocals = <String, TypeRef>{...locals};
    var required = 0;
    for (final parameter
        in expression.parameters?.parameters ?? <FormalParameter>[]) {
      final name = formalParameterName(parameter);
      final type =
          parameter.type != null || parameter.functionTypedSuffix != null
          ? ctx.typeFactory.formalParameterAnnotationType(
              ctx.library,
              parameter,
            )
          : parameter.isNamed
          ? signature?.named[name]?.type
          : parameters.length < (signature?.positional.length ?? 0)
          ? signature!.positional[parameters.length]
          : CoreTypes.dynamic.ref(ctx);
      if (type == null || type.hasSchemaHoles) return null;
      innerLocals[name] = type;
      if (parameter.isNamed) {
        named[name] = (type: type, required: parameter.isRequired);
      } else {
        parameters.add(type);
        if (parameter.isRequired) required++;
      }
    }
    final body = expression.body;
    TypeRef? result;
    if (body is ExpressionFunctionBody) {
      result = previewArgumentType(
        ctx,
        body.expression,
        context: signature?.returnType,
        locals: innerLocals,
      );
    } else if (body is BlockFunctionBody) {
      final returns = <TypeRef>{};
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          final type = statement.expression == null
              ? CoreTypes.nullType.ref(ctx)
              : previewArgumentType(
                  ctx,
                  statement.expression!,
                  context: signature?.returnType,
                  locals: innerLocals,
                );
          if (type == null) return null;
          returns.add(type);
        } else if (statement is! ExpressionStatement) {
          // Branches and local declarations need the normal flow analysis.
          return null;
        }
      }
      result = returns.isEmpty
          ? CoreTypes.voidType.ref(ctx)
          : ctx.typeSystem.leastUpperBound(returns);
    }
    if (result == null) return null;
    if (body.isAsynchronous) {
      result = ctx.types.bySpec(CoreTypes.future).instantiate([
        ctx.typeSystem.flatten(result),
      ]);
    }
    return FunctionTypeRef(
      FunctionSignature(
        positional: parameters,
        requiredPositional: required,
        named: named,
        returnType: result,
      ),
      decl: ctx.types.bySpec(CoreTypes.function),
    );
  }
  if (expression is ListLiteral || expression is SetOrMapLiteral) {
    final elements = expression is ListLiteral
        ? expression.elements
        : (expression as SetOrMapLiteral).elements;
    final annotations = expression is ListLiteral
        ? expression.typeArguments
        : (expression as SetOrMapLiteral).typeArguments;
    final isMap =
        expression is SetOrMapLiteral &&
        (annotations?.arguments.length == 2 ||
            elements.any((e) => e is MapLiteralEntry) ||
            elements.isEmpty);
    final spec = expression is ListLiteral
        ? CoreTypes.list
        : isMap
        ? CoreTypes.map
        : CoreTypes.set;
    if (annotations != null) {
      return ctx.types.bySpec(spec).instantiate([
        for (final annotation in annotations.arguments)
          TypeRef.fromAnnotation(ctx, ctx.library, annotation),
      ]);
    }
    final fields = List.generate(isMap ? 2 : 1, (_) => <TypeRef>{});
    for (final element in elements) {
      if (element is MapLiteralEntry && isMap) {
        final key = preview(element.key);
        final value = preview(element.value);
        if (key == null || value == null) return null;
        fields[0].add(key);
        fields[1].add(value);
      } else if (element is Expression && !isMap) {
        final type = preview(element);
        if (type == null) return null;
        fields[0].add(type);
      } else {
        return null;
      }
    }
    return ctx.types.bySpec(spec).instantiate([
      for (final field in fields)
        field.isEmpty
            ? UnknownTypeRef.instance
            : ctx.typeSystem.leastUpperBound(field),
    ]);
  }
  if (expression is MethodInvocation && expression.target == null) {
    final callable = locals[expression.methodName.name];
    if (callable is FunctionTypeRef) return callable.signature.returnType;
    if (ctx.lookupBinding(expression.methodName.name) != null) return null;
    final declaration = ctx
        .visibleDeclarations[ctx.library]?[expression.methodName.name]
        ?.declaration;
    final node = declaration?.declaration;
    if (node is FunctionDeclaration &&
        node.returnType != null &&
        node.functionExpression.typeParameters == null) {
      return TypeRef.fromAnnotation(
        ctx,
        declaration!.sourceLib,
        node.returnType!,
      );
    }
    return null;
  }
  if (expression is PropertyAccess && expression.target != null) {
    final receiver = preview(expression.target!);
    if (receiver == null) return null;
    return fieldType(receiver, expression.propertyName.name);
  }
  if (expression is PrefixedIdentifier) {
    final receiver = locals[expression.prefix.name];
    return receiver == null
        ? null
        : fieldType(receiver, expression.identifier.name);
  }
  if (expression is BinaryExpression) {
    final left = preview(expression.leftOperand);
    final right = preview(expression.rightOperand);
    if (left == null || right == null) return null;
    if (expression.operator.lexeme == '??') {
      return ctx.typeSystem.leastUpperBound({left.withNullable(false), right});
    }
    if ({'+', '-', '*', '%'}.contains(expression.operator.lexeme) &&
        left.isAssignableTo(
          ctx,
          CoreTypes.num.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        right.isAssignableTo(
          ctx,
          CoreTypes.num.ref(ctx),
          forceAllowDynamic: false,
        )) {
      return ctx.typeSystem.leastUpperBound({left, right});
    }
  }
  return null;
}
