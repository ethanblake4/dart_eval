import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import '../errors.dart';
import '../expression/expression.dart';
import '../type.dart';
import '../variable.dart';
import '../builtins.dart';
import 'conversion.dart';
import '../invocation/binder.dart';
import 'default_value.dart';
import '../member/call_signature.dart';
import '../declaration/extension_type.dart';
import '../invocation/call.dart';
import '../invocation/bound_call.dart';
import '../invocation/deferred.dart';
import '../invocation/targets.dart';
import '../../ir/flow.dart';
import 'assert.dart';

/// An extension type's representation field is an identity projection.
TypeRef? extensionRepresentationField(
  CompilerContext ctx,
  TypeRef type,
  String name,
) {
  if (type is TypeParameterTypeRef) {
    type = ctx.typeSystem.throughTypeParameters(type);
  }
  if (type.nullable) return null;
  final decl = nominalDeclOf(type);
  if (decl is! SourceTypeDecl ||
      decl.extensionRepresentationParameter?.name?.lexeme != name ||
      name.startsWith('_') && decl.library != ctx.library) {
    return null;
  }
  return decl.extensionRepresentationFor(type);
}

/// Whether the selector names a declared extension type constructor.
bool isExtensionTypeConstructor(SourceTypeDecl declaration, String name) {
  final node = declaration.node as ExtensionTypeDeclaration;
  final primary = node.namePart as PrimaryConstructorDeclaration;
  final primaryName = primary.constructorName?.name.lexeme ?? '';
  return name == primaryName ||
      name == 'new' && primaryName.isEmpty ||
      node.body.members.whereType<ConstructorDeclaration>().any(
        (constructor) => (constructor.name?.lexeme ?? '') == name,
      );
}

/// Constructs the source type while preserving its representation value.
Variable constructExtensionType(
  CompilerContext ctx,
  SourceTypeDecl declaration,
  TypeRef instantiatedType,
  String name,
  ArgumentList? arguments, {
  required bool isConst,
  required AstNode source,
  CallShape? suppliedShape,
}) {
  // Check the initial selector in the caller's scope. Redirects below enter
  // the declaring scope and may name its private constructors.
  if (name.startsWith('_') && declaration.library != ctx.library) {
    throw CompileError('Private extension type constructor $name', source);
  }
  return _ExtensionConstruction(
    ctx,
    declaration,
    instantiatedType,
    isConst,
    source,
  ).emit(name, arguments, suppliedShape: suppliedShape);
}

/// Secondary constructors compile in their declaring scope, with each supplied
/// argument evaluated once before entering that scope.
final class _ExtensionConstruction {
  _ExtensionConstruction(
    this.ctx,
    this.declaration,
    this.instantiatedType,
    this.isConst,
    this.source, {
    Set<ConstructorDeclaration>? active,
  }) : _active = active ?? <ConstructorDeclaration>{};

  final CompilerContext ctx;
  final SourceTypeDecl declaration;
  TypeRef instantiatedType;
  final bool isConst;
  final AstNode source;
  final Set<ConstructorDeclaration> _active;

  Variable emit(
    String name,
    ArgumentList? arguments, {
    CallShape? suppliedShape,
  }) {
    final node = declaration.node as ExtensionTypeDeclaration;
    final primary = node.namePart as PrimaryConstructorDeclaration;
    final primaryName = primary.constructorName?.name.lexeme ?? '';
    if (name == primaryName || name == 'new' && primaryName.isEmpty) {
      return _primary(primary, arguments, suppliedShape: suppliedShape);
    }
    final constructor = node.body.members
        .whereType<ConstructorDeclaration>()
        .where((member) => (member.name?.lexeme ?? '') == name)
        .firstOrNull;
    if (constructor == null) {
      throw CompileError('Unknown extension type constructor $name', source);
    }
    if (isConst && constructor.constKeyword == null) {
      throw CompileError('Extension type constructor is not const', source);
    }
    if (!_active.add(constructor)) {
      throw CompileError('Cyclic extension type constructor redirect', source);
    }
    final inferArguments = _needsTypeInference;
    final declaredSignature = CallSignature.forDeclaration(
      ctx,
      declaration.library,
      constructor,
    );
    final signature = inferArguments
        ? declaredSignature
        : declaredSignature.substitute(
            Substitution.forInterface(instantiatedType),
          );
    final inferred = <TypeParameterDef, TypeRef>{};
    final bound = ArgumentBinder(ctx).bindParameterList(
      arguments,
      declaration.library,
      signature,
      constructor,
      resolveGenerics: inferred,
      source: source,
      suppliedShape: suppliedShape,
    );
    if (inferArguments) _applyInferredArguments(inferred);
    try {
      return withDefaultExpressionScope(
        ctx,
        declaration.library,
        constructor,
        () {
          final substitution = Substitution.forInterface(instantiatedType);
          ctx.typeParameterScope(declaration.library).addAll({
            for (final entry in declaration.ownTypeParams.entries)
              entry.key: entry.value.substituteTypeParameters(substitution),
          });
          for (var i = 0; i < signature.positional.length; i++) {
            ctx.setLocal(signature.positional[i].name, bound.positional[i]);
          }
          for (final (name, value) in bound.named) {
            ctx.setLocal(name, value);
          }
          if (constructor.factoryKeyword != null) {
            final redirect = constructor.redirectedConstructor;
            if (redirect != null) {
              final (typeName, constructorName) = splitConstructorTypeName(
                ctx,
                declaration.library,
                redirect.type,
                redirect.name?.name,
              );
              var target =
                  ctx.visibleTypes[declaration.library]?[typeName] ??
                  (throw CompileError(
                    'Unknown factory target $typeName',
                    redirect,
                  ));
              final typeArguments = redirect.type.typeArguments;
              if (typeArguments != null) {
                target = nominalDeclOf(target)!.instantiate([
                  for (final argument in typeArguments.arguments)
                    TypeRef.fromAnnotation(ctx, declaration.library, argument),
                ]);
              }
              final targetDecl = nominalDeclOf(target);
              if (targetDecl is! SourceTypeDecl ||
                  targetDecl.node is! ExtensionTypeDeclaration) {
                throw CompileError(
                  'Expected extension type factory target',
                  redirect,
                );
              }
              final result =
                  _ExtensionConstruction(
                    ctx,
                    targetDecl,
                    target,
                    isConst,
                    source,
                    active: _active,
                  ).emit(
                    constructorName,
                    arguments,
                    suppliedShape: CallShape.values(
                      bound.positional,
                      bound.namedValues,
                    ),
                  );
              return _finish(
                result.copyWith(
                  type: targetDecl.extensionRepresentationFor(target)!,
                ),
              );
            }
            final result =
                StaticCall(
                  DeferredOrOffset.lookupStatic(
                    ctx,
                    declaration.library,
                    declaration.name,
                    name,
                  ),
                  sourceDeclaration: constructor,
                  signature: signature,
                ).emit(
                  ctx,
                  BoundCall(
                    positional: bound.positional,
                    named: bound.named,
                    returnType: instantiatedType,
                    runtimeTypeArguments: [
                      for (final argument in interfaceArgumentsOf(
                        instantiatedType,
                      ))
                        ctx.runtimeTypes.idOf(argument),
                    ],
                  ),
                );
            return result.copyWith(type: instantiatedType)..binding = null;
          }
          final initializer = constructor.initializers.firstOrNull;
          if (initializer is RedirectingConstructorInvocation) {
            return emit(
              initializer.constructorName?.name ?? '',
              initializer.argumentList,
            );
          }
          final representationName =
              declaration.extensionRepresentationParameter!.name!.lexeme;
          final value = initializer is ConstructorFieldInitializer
              ? compileExpression(
                  initializer.expression,
                  ctx,
                  declaration.extensionRepresentationFor(instantiatedType),
                )
              : ctx.lookupLocal(representationName)!;
          return _finish(value);
        },
      );
    } finally {
      _active.remove(constructor);
    }
  }

  bool get _needsTypeInference =>
      interfaceArgumentsOf(instantiatedType).isEmpty &&
      declaration.typeParameters.isNotEmpty;

  void _applyInferredArguments(Map<TypeParameterDef, TypeRef> inferred) {
    final defaults = ctx.typeSystem.instantiateToBounds(
      declaration.typeParameters,
      knownTypes: inferred,
    );
    instantiatedType = declaration.instantiate([
      for (final parameter in declaration.typeParameters)
        inferred[parameter] ?? defaults[parameter]!,
    ]);
  }

  Variable _primary(
    PrimaryConstructorDeclaration primary,
    ArgumentList? arguments, {
    CallShape? suppliedShape,
  }) {
    final parameter = declaration.extensionRepresentationParameter!;
    final shape = suppliedShape ?? CallShape.fromArgumentList(arguments!);
    final ArgSource? argument = parameter.isNamed
        ? shape.named.firstOrNull?.$2
        : shape.positional.firstOrNull;
    if (shape.positional.length + shape.named.length > 1 ||
        parameter.isRequired && argument == null ||
        (parameter.isNamed
            ? shape.positional.isNotEmpty ||
                  shape.named.any((entry) => entry.$1 != parameter.name!.lexeme)
            : shape.named.isNotEmpty)) {
      throw CompileError(
        'Invalid extension type representation arguments',
        source,
      );
    }
    if (isConst && primary.constKeyword == null) {
      throw CompileError('Extension type constructor is not const', source);
    }
    final inferArguments = _needsTypeInference;
    final representation = inferArguments
        ? null
        : declaration.extensionRepresentationFor(instantiatedType)!;
    final defaultValue = parameter.defaultClause?.value;
    final Variable value = switch (argument) {
      ValueArg(:final value) => value,
      ExpressionArg(:final expression) => compileExpression(
        expression,
        ctx,
        representation,
      ),
      null =>
        defaultValue != null
            ? withDefaultExpressionScope(
                ctx,
                declaration.library,
                defaultValue,
                () => compileExpression(defaultValue, ctx, representation),
              )
            : BuiltinValue().push(ctx),
      _ => throw CompileError('Unsupported representation argument', source),
    };
    final result = _finish(value);
    final body = primary.body;
    if (body == null) return result;
    withDefaultExpressionScope(ctx, declaration.library, body, () {
      ctx.typeParameterScope(declaration.library).addAll({
        for (final entry in declaration.ownTypeParams.entries)
          entry.key: entry.value.substituteTypeParameters(
            Substitution.forInterface(instantiatedType),
          ),
      });
      ctx.setLocal(
        parameter.name!.lexeme,
        result.copyWith(
          type: declaration.extensionRepresentationFor(instantiatedType)!,
        ),
      );
      for (final initializer in body.initializers) {
        final assertion = initializer as AssertInitializer;
        doAssert(
          ctx,
          compileExpression(assertion.condition, ctx),
          message: assertion.message == null
              ? (ctx) => BuiltinValue().push(ctx)
              : (ctx) => compileExpression(assertion.message!, ctx),
        );
      }
      if (body.body is BlockFunctionBody) {
        ctx.pushOp(
          Call(
            DeferredOrOffset(
              file: declaration.library,
              className: declaration.name,
              name: extensionPrimaryBodyName,
            ),
            [result.boxIntoFreshSlot(ctx).ssa],
            result: ctx.svar('constructor_body'),
            typeArguments: [
              for (final argument in interfaceArgumentsOf(instantiatedType))
                ctx.runtimeTypes.idOf(argument),
            ],
          ),
        );
      }
    });
    return result;
  }

  Variable _finish(Variable value) {
    if (_needsTypeInference) {
      final inferred = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(
        declaration.extensionRepresentation!,
        value.type,
        inferred,
      );
      _applyInferredArguments(inferred);
    }
    final representation = declaration.extensionRepresentationFor(
      instantiatedType,
    )!;
    final parameters = declaration.typeParameters;
    final applied = interfaceArgumentsOf(instantiatedType);
    if (applied.length != parameters.length) {
      throw CompileError('Wrong number of extension type arguments', source);
    }
    final substitution = Substitution.forInterface(instantiatedType);
    for (var i = 0; i < parameters.length; i++) {
      final bound = parameters[i].bound?.substituteTypeParameters(substitution);
      if (bound != null && !applied[i].isAssignableTo(ctx, bound)) {
        throw CompileError(
          'Extension type argument does not satisfy its bound',
          source,
        );
      }
    }
    if (isConst && !value.isConst) {
      throw CompileError('Representation argument is not constant', source);
    }
    return convertForAssignment(
      ctx,
      value,
      representation,
      source: source,
    ).copyWith(type: instantiatedType, isConst: isConst)..binding = null;
  }
}
