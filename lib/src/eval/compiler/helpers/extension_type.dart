import 'package:analyzer/dart/ast/ast.dart';

import '../context.dart';
import '../errors.dart';
import '../expression/expression.dart';
import '../type.dart';
import '../variable.dart';
import 'conversion.dart';
import '../invocation/binder.dart';
import 'default_value.dart';
import '../member/call_signature.dart';

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
  ArgumentList arguments, {
  required bool isConst,
  required AstNode source,
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
  ).emit(name, arguments);
}

/// Redirects are compiled in their declaring scope, with each supplied
/// argument evaluated once before entering that scope.
final class _ExtensionConstruction {
  _ExtensionConstruction(
    this.ctx,
    this.declaration,
    this.instantiatedType,
    this.isConst,
    this.source,
  );

  final CompilerContext ctx;
  final SourceTypeDecl declaration;
  TypeRef instantiatedType;
  final bool isConst;
  final AstNode source;
  final _active = <ConstructorDeclaration>{};

  Variable emit(String name, ArgumentList arguments) {
    final node = declaration.node as ExtensionTypeDeclaration;
    final primary = node.namePart as PrimaryConstructorDeclaration;
    final primaryName = primary.constructorName?.name.lexeme ?? '';
    if (name == primaryName || name == 'new' && primaryName.isEmpty) {
      return _primary(primary, arguments);
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
    final redirect =
        constructor.initializers.single as RedirectingConstructorInvocation;
    final signature = CallSignature.forDeclaration(
      ctx,
      declaration.library,
      constructor,
    ).substitute(Substitution.forInterface(instantiatedType));
    final bound = ArgumentBinder(ctx).bindParameterList(
      arguments,
      declaration.library,
      signature,
      constructor,
      source: source,
    );
    try {
      return withDefaultExpressionScope(
        ctx,
        declaration.library,
        constructor,
        () {
          for (var i = 0; i < signature.positional.length; i++) {
            ctx.setLocal(signature.positional[i].name, bound.positional[i]);
          }
          for (final (name, value) in bound.named) {
            ctx.setLocal(name, value);
          }
          return emit(
            redirect.constructorName?.name ?? '',
            redirect.argumentList,
          );
        },
      );
    } finally {
      _active.remove(constructor);
    }
  }

  Variable _primary(
    PrimaryConstructorDeclaration primary,
    ArgumentList arguments,
  ) {
    if (arguments.arguments.length != 1 ||
        arguments.arguments.single is NamedArgument) {
      throw CompileError(
        'Expected one positional representation argument',
        source,
      );
    }
    if (isConst && primary.constKeyword == null) {
      throw CompileError('Extension type constructor is not const', source);
    }
    final inferArguments =
        interfaceArgumentsOf(instantiatedType).isEmpty &&
        declaration.typeParameters.isNotEmpty;
    var representation = inferArguments
        ? null
        : declaration.extensionRepresentationFor(instantiatedType)!;
    final value = compileExpression(
      arguments.arguments.single.argumentExpression,
      ctx,
      representation,
    );
    if (inferArguments) {
      final inferred = <TypeParameterDef, TypeRef>{};
      ctx.typeSystem.unify(
        declaration.extensionRepresentation!,
        value.type,
        inferred,
      );
      final defaults = ctx.typeSystem.instantiateToBounds(
        declaration.typeParameters,
        knownTypes: inferred,
      );
      instantiatedType = declaration.instantiate([
        for (final parameter in declaration.typeParameters)
          inferred[parameter] ?? defaults[parameter]!,
      ]);
      representation = declaration.extensionRepresentationFor(
        instantiatedType,
      )!;
    }
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
      representation!,
      source: source,
    ).copyWith(type: instantiatedType, isConst: isConst);
  }
}
