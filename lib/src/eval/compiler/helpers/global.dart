import '../../ir/globals.dart';
import '../variable.dart';
import '../errors.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'conversion.dart';
import '../context.dart';
import '../type.dart';
import '../values/abi.dart';

final _resolving = Expando<Set<(int, String)>>();

/// Lazily registers a global that usage analysis missed — e.g. a private
/// top-level member referenced only from a mixin member folded into a class
/// in another library.
void ensureGlobalRegistered(CompilerContext ctx, int library, String name) {
  final indices = ctx.topLevelGlobalIndices.putIfAbsent(library, () => {});
  if (indices.containsKey(name)) return;
  indices[name] = ctx.globalIndex++;
  ctx.topLevelVariableInferredTypes.putIfAbsent(library, () => {});
}

/// Chooses a stable storage representation before compiling any initializer.
TypeRef resolveGlobalType(CompilerContext ctx, int library, String name) {
  ensureGlobalRegistered(ctx, library, name);
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
        ClassDeclaration(:final body) => body.members,
        EnumDeclaration(:final body) => body.members,
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
        );
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
    return _record(ctx, library, name, type);
  } finally {
    active.remove(key);
  }
}

TypeRef _record(CompilerContext ctx, int library, String name, TypeRef type) {
  ctx.topLevelVariableInferredTypes[library]![name] = type;
  final index = ctx.topLevelGlobalIndices[library]?[name];
  if (index != null) {
    ctx.globalRepresentations[index] = Abi.unboxedAcrossCalls(type).bank;
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
    final typeName = splitConstructorTypeName(
      ctx,
      library,
      expression.constructorName.type,
      expression.constructorName.name?.name,
    ).$1;
    final resolved = ctx.visibleTypes[library]?[typeName];
    if (resolved == null) return CoreTypes.dynamic.ref(ctx);
    final type = expression.constructorName.type;
    if (type.typeArguments == null) return resolved;
    return resolved.copyWith(
      specifiedTypeArgs: [
        for (final arg in type.typeArguments!.arguments)
          TypeRef.fromAnnotation(ctx, library, arg),
      ],
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
  if (expression is ConditionalExpression) {
    return TypeRef.commonBaseType(ctx, {
      _infer(ctx, library, expression.thenExpression),
      _infer(ctx, library, expression.elseExpression),
    });
  }
  if (expression is AwaitExpression) {
    final inner = _infer(
      ctx,
      library,
      expression.expression,
    ).resolveTypeChain(ctx);
    if (inner.isAssignableTo(
          ctx,
          CoreTypes.future.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        inner.specifiedTypeArgs.isNotEmpty) {
      return inner.specifiedTypeArgs.first;
    }
    return inner;
  }
  if (expression is CascadeExpression) {
    return _infer(ctx, library, expression.target);
  }
  if (expression is PostfixExpression) {
    final operand = _infer(ctx, library, expression.operand);
    return expression.operator.lexeme == '!'
        ? operand.copyWith(nullable: false)
        : operand;
  }
  if (expression is IsExpression) return CoreTypes.bool.ref(ctx);
  if (expression is AsExpression) {
    return TypeRef.fromAnnotation(ctx, library, expression.type);
  }
  if (expression is ThrowExpression) return CoreTypes.never.ref(ctx);
  if (expression is IndexExpression) {
    final target = _infer(
      ctx,
      library,
      expression.target,
    ).resolveTypeChain(ctx);
    final args = target.specifiedTypeArgs;
    if (target.isAssignableTo(
          ctx,
          CoreTypes.list.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        args.isNotEmpty) {
      return args[0];
    }
    if (target.isAssignableTo(
          ctx,
          CoreTypes.map.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        args.length >= 2) {
      return args[1];
    }
    return CoreTypes.dynamic.ref(ctx);
  }
  if (expression is ListLiteral) {
    return _collectionType(ctx, library, CoreTypes.list, expression.elements);
  }
  if (expression is SetOrMapLiteral) {
    final isMap =
        expression.typeArguments?.arguments.length == 2 ||
        expression.elements.any((e) => e is MapLiteralEntry);
    if (!isMap) {
      return _collectionType(ctx, library, CoreTypes.set, expression.elements);
    }
    return _mapType(ctx, library, expression.elements);
  }
  if (expression is PropertyAccess && expression.target != null) {
    final receiver = _infer(ctx, library, expression.target!);
    if (receiver != CoreTypes.dynamic.ref(ctx)) {
      try {
        return TypeRef.lookupFieldType(
              ctx,
              receiver.resolveTypeChain(ctx),
              expression.propertyName.name,
            )?.resolveTypeChain(ctx) ??
            CoreTypes.dynamic.ref(ctx);
      } on CompileError {
        return CoreTypes.dynamic.ref(ctx);
      }
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
  if (expression is MethodInvocation && expression.target != null) {
    // Receiver calls: infer the target, then ask the member signature for the
    // return type. Inference failures must not break compilation.
    final receiver = _infer(
      ctx,
      library,
      expression.target!,
    ).resolveTypeChain(ctx);
    if (receiver != CoreTypes.dynamic.ref(ctx)) {
      try {
        return AlwaysReturnType.fromInstanceMethodOrBuiltin(
              ctx,
              receiver,
              expression.methodName.name,
              [
                for (final arg in expression.argumentList.arguments)
                  if (arg is! NamedArgument)
                    _infer(ctx, library, arg.argumentExpression),
              ],
              {
                for (final arg in expression.argumentList.arguments)
                  if (arg is NamedArgument)
                    arg.name.lexeme: _infer(
                      ctx,
                      library,
                      arg.argumentExpression,
                    ),
              },
            )?.type ??
            CoreTypes.dynamic.ref(ctx);
      } on Object {
        return CoreTypes.dynamic.ref(ctx);
      }
    }
  }
  return CoreTypes.dynamic.ref(ctx);
}

/// Infers the element types of a collection literal, or null when an element
/// isn't a plain expression (spread/if/for), making the literal's element type
/// undeterminable statically.
Set<TypeRef>? _elementTypes(
  CompilerContext ctx,
  int library,
  NodeList<CollectionElement> elements,
) {
  final types = <TypeRef>{};
  for (final element in elements) {
    if (element is! Expression) return null;
    types.add(_infer(ctx, library, element));
  }
  return types;
}

/// The type of a List/Set literal: bare [core] when the element type is
/// unknown, otherwise [core] parameterized by the elements' common base type.
TypeRef _collectionType(
  CompilerContext ctx,
  int library,
  BridgeTypeSpec core,
  NodeList<CollectionElement> elements,
) {
  final elementTypes = _elementTypes(ctx, library, elements);
  if (elementTypes == null || elementTypes.isEmpty) return core.ref(ctx);
  return core
      .ref(ctx)
      .copyWith(specifiedTypeArgs: [TypeRef.commonBaseType(ctx, elementTypes)]);
}

/// The type of a map literal: bare `Map` when the entry types are unknown,
/// otherwise `Map` parameterized by the keys' and values' common base types.
TypeRef _mapType(
  CompilerContext ctx,
  int library,
  NodeList<CollectionElement> elements,
) {
  final keyTypes = <TypeRef>{};
  final valueTypes = <TypeRef>{};
  for (final element in elements) {
    // Spread/if/for elements — bail to untyped map.
    if (element is! MapLiteralEntry) return CoreTypes.map.ref(ctx);
    keyTypes.add(_infer(ctx, library, element.key));
    valueTypes.add(_infer(ctx, library, element.value));
  }
  if (keyTypes.isEmpty) return CoreTypes.map.ref(ctx);
  return CoreTypes.map
      .ref(ctx)
      .copyWith(
        specifiedTypeArgs: [
          TypeRef.commonBaseType(ctx, keyTypes),
          TypeRef.commonBaseType(ctx, valueTypes),
        ],
      );
}

Variable storeGlobalBinding(
  CompilerContext ctx,
  int library,
  String name,
  Variable value, [
  AstNode? source,
]) {
  ensureGlobalRegistered(ctx, library, name);
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
    representation: Abi.unboxedAcrossCalls(type).bank,
    source: source,
    description: 'Cannot assign ${value.type} to global $name of type $type',
  );
  ctx.pushOp(SetGlobal(index, stored.ssa));
  return stored;
}
