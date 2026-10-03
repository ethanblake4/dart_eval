import 'package:dart_eval/dart_eval_bridge.dart';
import '../context.dart';
import '../errors.dart';
import '../type.dart';

/// Infers a generic callable specialized as a subtype of [context].
/// Inputs constrain its parameters from below; outputs constrain from above.
Map<TypeParameterDef, TypeRef> inferCallableTypeArguments(
  CompilerContext ctx,
  FunctionTypeRef callable,
  FunctionTypeRef context,
) {
  final parameters = callable.signature.typeParameters.toSet();
  final lower = <TypeParameterDef, Set<TypeRef>>{};
  final upper = <TypeParameterDef, Set<TypeRef>>{};
  var useLegacyInference = false;
  void constrain(TypeRef pattern, TypeRef actual, bool covariant) {
    if (pattern is UnknownTypeRef || actual is UnknownTypeRef) return;
    if (pattern is TypeParameterTypeRef) {
      if (parameters.contains(pattern.parameter)) {
        // T? already admits null; its evidence constrains T without that null.
        // The Null-only case needs a separate oracle, so retain old behavior.
        if (pattern.nullable && actual.isSpec(CoreTypes.nullType)) {
          useLegacyInference = true;
          return;
        }
        (covariant ? upper : lower)
            .putIfAbsent(pattern.parameter, () => {})
            .add(
              ctx.typeSystem.typeParameterEvidence(
                pattern,
                pattern.nullable ? actual.withNullable(false) : actual,
              ),
            );
      }
      return;
    }
    if (pattern is FunctionTypeRef && actual is FunctionTypeRef) {
      final source = pattern.signature;
      final target = actual.signature;
      for (
        var i = 0;
        i < source.positional.length && i < target.positional.length;
        i++
      ) {
        constrain(source.positional[i], target.positional[i], !covariant);
      }
      for (final entry in source.named.entries) {
        final targetParameter = target.named[entry.key];
        if (targetParameter != null) {
          constrain(entry.value.type, targetParameter.type, !covariant);
        }
      }
      if (!target.returnType.isSpec(CoreTypes.voidType)) {
        constrain(source.returnType, target.returnType, covariant);
      }
      return;
    }
    if (pattern is RecordTypeRef && actual is RecordTypeRef) {
      if (pattern.positional.length != actual.positional.length ||
          pattern.named.length != actual.named.length ||
          !pattern.named.keys.every(actual.named.containsKey)) {
        return;
      }
      for (var i = 0; i < pattern.positional.length; i++) {
        constrain(pattern.positional[i], actual.positional[i], covariant);
      }
      for (final entry in pattern.named.entries) {
        constrain(entry.value, actual.named[entry.key]!, covariant);
      }
      return;
    }
    if (pattern is InterfaceTypeRef) {
      final view = ctx.typeSystem.asInstanceOf(actual, pattern.decl);
      if (view == null) {
        if (actual is InterfaceTypeRef) {
          final sourceView = ctx.typeSystem.asInstanceOf(pattern, actual.decl);
          if (sourceView != null) constrain(sourceView, actual, covariant);
        }
        return;
      }
      final arguments = interfaceArgumentsOf(view);
      for (
        var i = 0;
        i < pattern.arguments.length && i < arguments.length;
        i++
      ) {
        constrain(pattern.arguments[i], arguments[i], covariant);
      }
    }
  }

  constrain(callable, context, true);
  final bindings = <TypeParameterDef, TypeRef>{};
  for (final parameter in callable.signature.typeParameters) {
    final constraints = lower[parameter];
    if (constraints != null && constraints.isNotEmpty) {
      bindings[parameter] = ctx.typeSystem.leastUpperBound(constraints);
    }
  }
  final holes = Substitution.of({
    for (final parameter in parameters) parameter: UnknownTypeRef.instance,
  });
  for (final parameter in callable.signature.typeParameters) {
    if (bindings.containsKey(parameter)) continue;
    final bound = parameter.bound;
    // Recursive/dependent upper-only solving is outside this local correction.
    // Preserve the prior algorithm until those cases have a proved solution.
    if (bound != null && bound.substituteTypeParameters(holes) != bound) {
      useLegacyInference = true;
    }
    final constraints = upper[parameter];
    if (constraints != null && constraints.isNotEmpty) {
      final upperBound = constraints.reduce(ctx.typeSystem.greatestLowerBound);
      bindings[parameter] = bound == null
          ? upperBound
          : ctx.typeSystem.greatestLowerBound(upperBound, bound);
    }
  }
  if (useLegacyInference) {
    bindings.clear();
    ctx.typeSystem.unify(callable, context, bindings);
  }
  // Unconstrained parameters retain the existing bound-defaulting behavior.
  for (final parameter in callable.signature.typeParameters) {
    bindings.putIfAbsent(
      parameter,
      () => (parameter.bound ?? CoreTypes.dynamic.ref(ctx))
          .substituteTypeParameters(Substitution.of(bindings))
          .lowerTypeParameters(ctx),
    );
  }
  if (useLegacyInference) return bindings;
  final substitution = Substitution.of(bindings);
  for (final parameter in callable.signature.typeParameters) {
    final bound = parameter.bound;
    if (bound != null &&
        !ctx.typeSystem.isAssignable(
          bindings[parameter]!,
          bound.substituteTypeParameters(substitution),
        )) {
      throw CompileError('Inferred ${bindings[parameter]} violates $bound');
    }
  }
  for (final entry in upper.entries) {
    for (final bound in entry.value) {
      if (!ctx.typeSystem.isAssignable(
        bindings[entry.key]!,
        bound.substituteTypeParameters(substitution),
      )) {
        throw CompileError('Cannot instantiate $callable as $context');
      }
    }
  }
  return bindings;
}
