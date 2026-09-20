import '../../ir/globals.dart';
import '../variable.dart';
import '../errors.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import '../backend/representation.dart' show representationForType;
import 'conversion.dart';
import '../context.dart';
import '../type.dart';

final _resolving = Expando<Set<(int, String)>>();

/// Chooses a stable storage representation before compiling any initializer.
TypeRef resolveGlobalType(CompilerContext ctx, int library, String name) {
  final known = ctx.topLevelVariableInferredTypes[library]![name];
  if (known != null) return known;
  final active = _resolving[ctx] ??= {};
  final key = (library, name);
  if (!active.add(key)) return CoreTypes.dynamic.ref(ctx);
  try {
    VariableDeclaration? variable;
    final declaration =
        ctx.topLevelDeclarationsMap[library]?[name]?.declaration;
    if (declaration is VariableDeclaration) variable = declaration;
    final separator = name.indexOf('.');
    if (variable == null && separator >= 0) {
      final owner = ctx
          .topLevelDeclarationsMap[library]?[name.substring(0, separator)]
          ?.declaration;
      final members = switch (owner) {
        ClassDeclaration(:final members) => members,
        EnumDeclaration(:final members) => members,
        _ => <ClassMember>[],
      };
      for (final field in members.whereType<FieldDeclaration>()) {
        for (final candidate in field.fields.variables) {
          if (candidate.name.lexeme == name.substring(separator + 1)) {
            variable = candidate;
          }
        }
      }
      if (variable == null && owner is EnumDeclaration) {
        final type = TypeRef.lookupDeclaration(
          ctx,
          library,
          owner,
        ).copyWith(boxed: true);
        return _record(ctx, library, name, type);
      }
    }
    final index = ctx.topLevelGlobalIndices[library]?[name];
    if (index != null && variable != null) {
      final list = variable.parent! as VariableDeclarationList;
      if (variable.initializer != null) ctx.globalsWithInitializer.add(index);
      if (list.lateKeyword != null) ctx.globalsLate.add(index);
      if (list.isFinal || list.isConst) ctx.globalsFinal.add(index);
    }
    final annotation = (variable?.parent as VariableDeclarationList?)?.type;
    final type = annotation == null
        ? _infer(ctx, library, variable?.initializer)
        : TypeRef.fromAnnotation(ctx, library, annotation);
    return _record(
      ctx,
      library,
      name,
      type.copyWith(boxed: !type.isUnboxedAcrossFunctionBoundaries),
    );
  } finally {
    active.remove(key);
  }
}

TypeRef _record(CompilerContext ctx, int library, String name, TypeRef type) {
  ctx.topLevelVariableInferredTypes[library]![name] = type;
  final index = ctx.topLevelGlobalIndices[library]?[name];
  if (index != null) {
    ctx.globalRepresentations[index] = representationForType(type);
    ctx.globalNames[index] = name;
  }
  return type;
}

TypeRef _infer(CompilerContext ctx, int library, Expression? expression) {
  if (expression is IntegerLiteral) return CoreTypes.int.ref(ctx);
  if (expression is DoubleLiteral) return CoreTypes.double.ref(ctx);
  if (expression is BooleanLiteral) return CoreTypes.bool.ref(ctx);
  if (expression is StringLiteral) return CoreTypes.string.ref(ctx);
  if (expression is ParenthesizedExpression) {
    return _infer(ctx, library, expression.expression);
  }
  if (expression is PrefixExpression) {
    if (expression.operator.lexeme == '!') return CoreTypes.bool.ref(ctx);
    final operand = _infer(ctx, library, expression.operand);
    if (expression.operator.lexeme == '~' &&
        operand == CoreTypes.int.ref(ctx)) {
      return CoreTypes.int.ref(ctx);
    }
    if (expression.operator.lexeme == '-' &&
        {
          CoreTypes.int.ref(ctx),
          CoreTypes.double.ref(ctx),
          CoreTypes.num.ref(ctx),
        }.contains(operand)) {
      return operand;
    }
    return CoreTypes.dynamic.ref(ctx);
  }
  if (expression is FunctionExpression) return CoreTypes.function.ref(ctx);
  if (expression is InstanceCreationExpression) {
    return TypeRef.fromAnnotation(
      ctx,
      library,
      expression.constructorName.type,
    );
  }
  if (expression is BinaryExpression) {
    final operator = expression.operator.lexeme;
    if (['==', '!=', '&&', '||'].contains(operator)) {
      return CoreTypes.bool.ref(ctx);
    }
    final left = _infer(ctx, library, expression.leftOperand);
    final right = _infer(ctx, library, expression.rightOperand);
    final numeric = {
      CoreTypes.int.ref(ctx),
      CoreTypes.double.ref(ctx),
      CoreTypes.num.ref(ctx),
    };
    // Only infer operator results for known core numeric operands. User-defined
    // operators and other expression forms retain conservative object storage.
    if (!numeric.contains(left) || !numeric.contains(right)) {
      return CoreTypes.dynamic.ref(ctx);
    }
    if (['<', '<=', '>', '>='].contains(operator)) {
      return CoreTypes.bool.ref(ctx);
    }
    if (['~/', '&', '|', '^', '<<', '>>', '>>>'].contains(operator)) {
      return CoreTypes.int.ref(ctx);
    }
    if (operator == '/') return CoreTypes.double.ref(ctx);
    if (['+', '-', '*', '%'].contains(operator)) {
      return TypeRef.commonBaseType(ctx, {left, right});
    }
    return CoreTypes.dynamic.ref(ctx);
  }
  if (expression is SimpleIdentifier) {
    final declaration =
        ctx.visibleDeclarations[library]?[expression.name]?.declaration;
    if (declaration?.declaration is VariableDeclaration) {
      return resolveGlobalType(ctx, declaration!.sourceLib, expression.name);
    }
  }
  if (expression is MethodInvocation && expression.target == null) {
    final declaration = ctx
        .visibleDeclarations[library]?[expression.methodName.name]
        ?.declaration;
    final function = declaration?.declaration;
    final bridge = declaration?.bridge;
    if (bridge is BridgeClassDef) {
      return TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
    }
    if (function is ClassDeclaration) {
      return TypeRef.lookupDeclaration(ctx, declaration!.sourceLib, function);
    }
    if (function is FunctionDeclaration && function.returnType != null) {
      return TypeRef.fromAnnotation(
        ctx,
        declaration!.sourceLib,
        function.returnType!,
      );
    }
  }
  return CoreTypes.dynamic.ref(ctx);
}

Variable storeGlobalBinding(
  CompilerContext ctx,
  int library,
  String name,
  Variable value, [
  AstNode? source,
]) {
  final type = resolveGlobalType(ctx, library, name);
  final index = ctx.topLevelGlobalIndices[library]![name]!;
  if (ctx.globalsFinal.contains(index) &&
      (!ctx.globalsLate.contains(index) ||
          ctx.globalsWithInitializer.contains(index))) {
    throw CompileError('Cannot assign final global $name', source);
  }
  final stored = convertForAssignment(
    ctx,
    value,
    type,
    representation: representationForType(type),
    source: source,
    description: 'Cannot assign ${value.type} to global $name of type $type',
  );
  ctx.pushOp(SetGlobal(index, stored.ssa));
  return stored;
}
