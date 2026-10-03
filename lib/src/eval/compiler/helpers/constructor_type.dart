import 'package:dart_eval/dart_eval_bridge.dart' show CoreTypes;

import '../context.dart';
import '../type.dart';
import 'context_type.dart';

/// Only a context that constrains class parameters supplies constructor types.
/// An Object context, for example, leaves argument inference unchanged.
Map<TypeParameterDef, TypeRef> constructorContextArguments(
  CompilerContext ctx,
  TypeRef constructed,
  TypeRef? context,
) {
  final owner = nominalDeclOf(constructed);
  if (context == null || owner == null || owner.typeParameters.isEmpty) {
    return const {};
  }
  context = inferContextType(ctx, constructed, context);
  // A raw annotation is an instantiate-to-bound context, not an
  // unconstrained constructor application.
  if (context is InterfaceTypeRef && context.arguments.isEmpty) {
    final parameters = context.decl.typeParameters;
    if (parameters.isNotEmpty) {
      final defaults = ctx.typeSystem.instantiateToBounds(parameters);
      context = context.copyWith(
        arguments: [for (final parameter in parameters) defaults[parameter]!],
      );
    }
  }
  final view = ctx.typeSystem.asInstanceOf(
    owner.thisType,
    nominalDeclOf(context),
  );
  if (view == null) return const {};
  final inferred = <TypeParameterDef, TypeRef>{};
  ctx.typeSystem.unify(view, context, inferred);
  inferred.removeWhere(
    (parameter, _) => !owner.typeParameters.contains(parameter),
  );
  constrainInferredTypeArguments(ctx, inferred);
  return inferred;
}

/// Applies resolved source-constructor parameters to its result type.
TypeRef inferredConstructorType(
  CompilerContext ctx,
  TypeRef type,
  List<TypeParameterDef> parameters,
  Map<String, TypeRef> arguments,
) {
  if (type is! InterfaceTypeRef || parameters.isEmpty) return type;
  final argumentsByParameter = {
    for (final parameter in parameters)
      if (arguments[parameter.name] case final argument?) parameter: argument,
  };
  final defaults =
      parameters.any(
        (parameter) => !argumentsByParameter.containsKey(parameter),
      )
      ? ctx.typeSystem.instantiateToBounds(
          parameters,
          knownTypes: argumentsByParameter,
        )
      : argumentsByParameter;
  if (type.arguments.isNotEmpty) {
    return type.substituteTypeParameters(
      Substitution.of({...defaults, ...argumentsByParameter}),
    );
  }
  return type.copyWith(
    arguments: [
      for (final parameter in parameters)
        argumentsByParameter[parameter] ?? defaults[parameter]!,
    ],
  );
}

/// Contextual arguments must satisfy the parameters' declared upper bounds.
/// For `T<X extends int> = C<List<X>>`, a `C<Iterable<num>>` context permits
/// `X = int`; it cannot widen the alias parameter to `num`.
void constrainInferredTypeArguments(
  CompilerContext ctx,
  Map<TypeParameterDef, TypeRef> arguments,
) {
  // A bound may name a later parameter; propagate refinements back through
  // that dependency chain, with at most one pass per parameter.
  for (var pass = 0; pass < arguments.length; pass++) {
    var changed = false;
    for (final parameter in arguments.keys) {
      final bound = parameter.bound;
      if (bound == null) continue;
      final resolvedBound = ctx.typeSystem.lowerTypeParameters(
        bound.substituteTypeParameters(Substitution.of(arguments)),
        only: const {},
        kinds: const {TypeParameterOwnerKind.typeAlias},
      );
      final inferred = arguments[parameter]!;
      if (inferred.isAssignableTo(
        ctx,
        resolvedBound,
        forceAllowDynamic: false,
      )) {
        continue;
      }
      arguments[parameter] =
          resolvedBound.isAssignableTo(ctx, inferred, forceAllowDynamic: false)
          ? resolvedBound
          : CoreTypes.never.ref(ctx);
      changed = true;
    }
    if (!changed) break;
  }
}
