import '../../ir/globals.dart';
import '../variable.dart';
import '../errors.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import '../invocation/binder.dart';
import 'conversion.dart';
import 'field_storage.dart';
import 'external.dart';
import 'constructor_tearoff.dart';
import '../context.dart';
import '../type.dart';
import '../values/abi.dart';
import '../member/member_name.dart';
import '../member/call_signature.dart';
import '../declaration/enum.dart' show resolveEnumValueType;

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
        final type = TypeRef.lookupDeclaration(ctx, library, owner);
        return _record(
          ctx,
          library,
          name,
          resolveEnumValueType(ctx, type, name.substring(separator + 1)),
        );
      }
    }
    final index = ctx.topLevelGlobalIndices[library]?[name];
    if (index != null && variable != null) {
      final list = variable.parent! as VariableDeclarationList;
      if (variable.initializer != null) ctx.globalsWithInitializer.add(index);
      if (list.lateKeyword != null) ctx.globalsLate.add(index);
      if (list.isFinal || list.isConst) ctx.globalsFinal.add(index);
      if (list.isConst) ctx.globalsConst.add(index);
    }
    final annotation = (variable?.parent as VariableDeclarationList?)?.type;
    final type = annotation == null
        ? ctx.typeFactory.widenedInferredType(
            _infer(ctx, library, variable?.initializer),
          )
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
    ctx.globalRepresentations[index] = Abi.storageSlot(type).bank;
    ctx.globalNames[index] = name;
  }
  return type;
}

/// Conservative expression type inference without emitting bytecode.
TypeRef inferStaticExpressionType(
  CompilerContext ctx,
  int library,
  Expression? expression,
) => _infer(ctx, library, expression);

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
    if (expression.operator.lexeme == '~' && operand.isSpec(CoreTypes.int)) {
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
  final constructorTearOff = _constructorTearOffType(ctx, library, expression);
  if (constructorTearOff != null) return constructorTearOff;
  if (expression is PrefixedIdentifier) {
    final type = ctx.visibleTypes[library]?[expression.prefix.name];
    if (type != null &&
        ctx.enumValueIndices[type.file]?[type.name]?.containsKey(
              expression.identifier.name,
            ) ==
            true) {
      return resolveEnumValueType(ctx, type, expression.identifier.name);
    }
  }
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
    return (resolved as InterfaceTypeRef).copyWith(
      arguments: [
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
    // Unqualified names in a static field initializer first resolve against
    // its declaring class. Losing these dependencies turns integer constants
    // into dynamic operands and widens later arithmetic to num.
    final field = expression.thisOrAncestorOfType<FieldDeclaration>();
    final owner = field?.parent?.parent;
    if (field?.isStatic == true && owner is Declaration) {
      final name = '${declarationName(owner)}.${expression.name}';
      final member = ctx.topLevelDeclarationsMap[library]?[name]?.declaration;
      final memberField = member?.parent?.parent;
      if (member is VariableDeclaration &&
          memberField is FieldDeclaration &&
          memberField.isStatic) {
        return resolveGlobalType(ctx, library, name);
      }
    }
    final declaration =
        ctx.visibleDeclarations[library]?[expression.name]?.declaration;
    if (declaration?.declaration is VariableDeclaration) {
      return resolveGlobalType(ctx, declaration!.sourceLib, expression.name);
    }
    final getterDeclaration = ctx
        .visibleDeclarations[library]?[MemberName.getter(expression.name).key]
        ?.declaration;
    if (getterDeclaration?.declaration case FunctionDeclaration getter
        when getter.isGetter && getter.returnType != null) {
      return TypeRef.fromAnnotation(
        ctx,
        getterDeclaration!.sourceLib,
        getter.returnType!,
      );
    }
  }
  if (expression is ConditionalExpression) {
    return TypeRef.commonBaseType(ctx, {
      _infer(ctx, library, expression.thenExpression),
      _infer(ctx, library, expression.elseExpression),
    });
  }
  if (expression is AwaitExpression) {
    final inner = _infer(ctx, library, expression.expression);
    if (inner.isAssignableTo(
          ctx,
          CoreTypes.future.ref(ctx),
          forceAllowDynamic: false,
        ) &&
        interfaceArgumentsOf(inner).isNotEmpty) {
      return interfaceArgumentsOf(inner).first;
    }
    return inner;
  }
  if (expression is CascadeExpression) {
    return _infer(ctx, library, expression.target);
  }
  if (expression is PostfixExpression) {
    final operand = _infer(ctx, library, expression.operand);
    return expression.operator.lexeme == '!'
        ? operand.withNullable(false)
        : operand;
  }
  if (expression is IsExpression) return CoreTypes.bool.ref(ctx);
  if (expression is AsExpression) {
    return TypeRef.fromAnnotation(ctx, library, expression.type);
  }
  if (expression is ThrowExpression) return CoreTypes.never.ref(ctx);
  if (expression is IndexExpression) {
    final target = _infer(ctx, library, expression.target);
    final args = interfaceArgumentsOf(target);
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
    final annotations = expression.typeArguments;
    if (annotations != null) {
      return _annotatedCollectionType(
        ctx,
        library,
        CoreTypes.list,
        annotations,
      );
    }
    return _collectionType(ctx, library, CoreTypes.list, expression.elements);
  }
  if (expression is SetOrMapLiteral) {
    final annotations = expression.typeArguments;
    final isMap =
        annotations?.arguments.length == 2 ||
        (annotations == null && expression.elements.isEmpty) ||
        expression.elements.any((e) => e is MapLiteralEntry);
    if (annotations != null) {
      return _annotatedCollectionType(
        ctx,
        library,
        isMap ? CoreTypes.map : CoreTypes.set,
        annotations,
      );
    }
    if (!isMap) {
      return _collectionType(ctx, library, CoreTypes.set, expression.elements);
    }
    return _mapType(ctx, library, expression.elements);
  }
  if (expression is PropertyAccess && expression.target != null) {
    final receiver = _infer(ctx, library, expression.target!);
    if (!receiver.isSpec(CoreTypes.dynamic)) {
      try {
        return ctx.memberLookup.fieldType(
              receiver,
              expression.propertyName.name,
            ) ??
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
      final type = TypeRef.lookupDeclaration(
        ctx,
        declaration!.sourceLib,
        function,
      );
      if (expression.typeArguments == null) return type;
      return (type as InterfaceTypeRef).copyWith(
        arguments: [
          for (final argument in expression.typeArguments!.arguments)
            TypeRef.fromAnnotation(ctx, library, argument),
        ],
      );
    }
    if (function is FunctionDeclaration && function.returnType != null) {
      return ArgumentBinder(ctx).inferStaticCallResult(
        CallSignature.forDeclaration(ctx, declaration!.sourceLib, function),
        [
          for (final arg in expression.argumentList.arguments)
            if (arg is! NamedArgument)
              _infer(ctx, library, arg.argumentExpression),
        ],
        {
          for (final arg in expression.argumentList.arguments)
            if (arg is NamedArgument)
              arg.name.lexeme: _infer(ctx, library, arg.argumentExpression),
        },
        explicitArguments: expression.typeArguments == null
            ? null
            : [
                for (final type in expression.typeArguments!.arguments)
                  TypeRef.fromAnnotation(ctx, library, type),
              ],
        source: expression,
      );
    }
  }
  if (expression is MethodInvocation && expression.target != null) {
    // Receiver calls: infer the target, then ask the member signature for the
    // return type. Inference failures must not break compilation.
    final receiver = _infer(ctx, library, expression.target!);
    if (!receiver.isSpec(CoreTypes.dynamic)) {
      try {
        return memberCallResultType(
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
            ) ??
            CoreTypes.dynamic.ref(ctx);
      } on Object {
        return CoreTypes.dynamic.ref(ctx);
      }
    }
  }
  return CoreTypes.dynamic.ref(ctx);
}

TypeRef _annotatedCollectionType(
  CompilerContext ctx,
  int library,
  BridgeTypeSpec core,
  TypeArgumentList annotations,
) => core
    .ref(ctx)
    .copyWith(
      arguments: [
        for (final type in annotations.arguments)
          TypeRef.fromAnnotation(ctx, library, type),
      ],
    );

TypeRef? _constructorTearOffType(
  CompilerContext ctx,
  int library,
  Expression? expression,
) {
  final (receiver, name) = switch (expression) {
    PrefixedIdentifier(:final prefix, :final identifier) => (
      prefix,
      identifier.name,
    ),
    PropertyAccess(:final target, :final propertyName, isNullAware: false) => (
      target,
      propertyName.name,
    ),
    _ => (null, null),
  };
  if (receiver == null || name == null) return null;
  final base = receiver is FunctionReference ? receiver.function : receiver;
  final typeName = switch (base) {
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(:final prefix, :final identifier) =>
      '${prefix.name}.${identifier.name}',
    _ => null,
  };
  var type = ctx.visibleTypes[library]?[typeName];
  if (type == null || nominalDeclOf(type) is! SourceTypeDecl) return null;
  if (receiver is FunctionReference && receiver.typeArguments != null) {
    type = (type as InterfaceTypeRef).copyWith(
      arguments: [
        for (final argument in receiver.typeArguments!.arguments)
          TypeRef.fromAnnotation(ctx, library, argument),
      ],
    );
  }
  final key = '${type.name}.${name == 'new' ? '' : name}';
  final declaration = ctx.topLevelDeclarationsMap[type.file]?[key]?.declaration;
  if (declaration is! ConstructorDeclaration &&
      !(declaration == null && name == 'new')) {
    return null;
  }
  return constructorTearOffSignature(
    ctx,
    type,
    declaration as ConstructorDeclaration?,
  ).toFunctionType(ctx);
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
      .copyWith(arguments: [TypeRef.commonBaseType(ctx, elementTypes)]);
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
        arguments: [
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
    representation: Abi.storageSlot(type).bank,
    source: source,
    description: 'Cannot assign ${value.type} to global $name of type $type',
  );
  final declaration = ctx.topLevelDeclarationsMap[library]?[name]?.declaration;
  if (declaration is VariableDeclaration && isExternalVariable(declaration)) {
    return emitMissingExternal(
      ctx,
      name,
      kind: InvocationKind.setter,
      positional: [stored],
    );
  }
  ctx.pushOp(SetGlobal(index, stored.ssa));
  return stored;
}
