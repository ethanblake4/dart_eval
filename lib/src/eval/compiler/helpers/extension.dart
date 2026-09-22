import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';

/// An `extension` declaration with the library it was declared in and the
/// name used to register its members (`E.foo`), synthesized when unnamed.
class EvalExtension {
  EvalExtension(this.library, this.declaration, this.name);

  final int library;
  final ExtensionDeclaration declaration;
  final String name;

  /// The members declared in the extension body.
  List<ClassMember> get members => switch (declaration.body) {
    BlockClassBody b => b.members,
    _ => const [],
  };

  /// Member registration key in `topLevelDeclarationPositions`.
  String memberKey(MethodDeclaration member) =>
      extensionMemberKey(name, member);

  /// The `on` type, or null when it can't be resolved. For generic
  /// extensions this is the *pattern* — type parameters appear as
  /// type-parameter TypeRefs keyed by `extension:library:name` — to be bound
  /// per call site by [matchExtensionOn].
  TypeRef? resolveOnType(CompilerContext ctx) {
    final tps = declaration.typeParameters?.typeParameters;
    if (tps == null || tps.isEmpty) {
      try {
        return TypeRef.fromAnnotation(
          ctx,
          library,
          declaration.onClause!.extendedType,
        );
      } catch (_) {
        return null;
      }
    }
    // Seed the extension's own parameters as visible type parameters so the
    // `on` annotation resolves into a pattern; restore the scope afterwards.
    final temps = ctx.temporaryTypes[library] ??= {};
    final saved = <String, TypeRef?>{};
    for (var i = 0; i < tps.length; i++) {
      final param = tps[i];
      saved[param.name.lexeme] = temps[param.name.lexeme];
      temps[param.name.lexeme] = TypeRef(
        library,
        param.name.lexeme,
        resolved: true,
        typeParameterOwner: 'extension:$library:$name',
        typeParameterIndex: i,
      );
    }
    try {
      return TypeRef.fromAnnotation(
        ctx,
        library,
        declaration.onClause!.extendedType,
      );
    } catch (_) {
      return null;
    } finally {
      for (final entry in saved.entries) {
        if (entry.value == null) {
          temps.remove(entry.key);
        } else {
          temps[entry.key] = entry.value!;
        }
      }
    }
  }
}

/// The binding produced by explicit extension application `E(receiver)`:
/// member lookups on the value resolve only within [ext], with
/// [onBindings] holding the resolved `on` type-parameter bindings.
class BoundExtension {
  const BoundExtension(this.ext, this.onBindings);

  final EvalExtension ext;
  final List<TypeRef> onBindings;
}

/// The extension declaring namespace [type] names, or null. Type literals
/// produced for `extension E` declarations carry a pseudo-type whose
/// (file, name) pair identifies the extension.
EvalExtension? extensionForType(CompilerContext ctx, TypeRef type) {
  for (final ext in ctx.extensions) {
    if (ext.library == type.file && ext.name == type.name) return ext;
  }
  return null;
}

/// Maps [ext]'s `on` type-parameter names to resolved [bindings] for use as
/// the `typeParameters:` argument of annotation resolvers.
Map<String, TypeRef> extBindingsMap(EvalExtension ext, List<TypeRef> bindings) {
  final params =
      ext.declaration.typeParameters?.typeParameters ?? const <TypeParameter>[];
  return {
    for (var i = 0; i < params.length && i < bindings.length; i++)
      params[i].name.lexeme: bindings[i],
  };
}

/// The instance member of [ext] named [name] of the given kind, or null.
MethodDeclaration? extensionMember(
  EvalExtension ext,
  String name, {
  bool getter = false,
  bool setter = false,
}) {
  for (final member in ext.members) {
    if (member is! MethodDeclaration || member.isStatic) continue;
    if (member.name.lexeme != name) continue;
    if (member.isGetter != getter || member.isSetter != setter) continue;
    return member;
  }
  return null;
}

/// The static member of [ext] named [name] of the given kind, or null.
/// Static members are only reachable inside the extension's own body (as
/// unqualified names) or through the `E.` namespace — never via a receiver.
MethodDeclaration? extensionStaticMember(
  EvalExtension ext,
  String name, {
  bool getter = false,
  bool setter = false,
}) {
  for (final member in ext.members) {
    if (member is! MethodDeclaration || !member.isStatic) continue;
    if (member.name.lexeme != name) continue;
    if (member.isGetter != getter || member.isSetter != setter) continue;
    return member;
  }
  return null;
}

/// The variable of a static field of [ext] named [name], or null.
/// Static extension fields behave like library-level `E.name` globals.
VariableDeclaration? extensionStaticField(EvalExtension ext, String name) {
  for (final member in ext.members) {
    if (member is! FieldDeclaration || !member.isStatic) continue;
    for (final variable in member.fields.variables) {
      if (variable.name.lexeme == name) return variable;
    }
  }
  return null;
}

/// Binds [pattern] (an extension `on` clause, possibly containing the
/// extension's type parameters) against [actual] or one of its instantiated
/// supertypes, writing bindings into [bound] indexed by parameter position.
/// Returns false when no supertype matches or a parameter is bound
/// inconsistently.
bool _unifyOnPattern(
  CompilerContext ctx,
  TypeRef pattern,
  TypeRef actual,
  List<TypeRef?> bound,
) {
  if (pattern.isTypeParameter) {
    final index = pattern.typeParameterIndex!;
    final previous = bound[index];
    if (previous == null) {
      bound[index] = actual;
      return true;
    }
    return previous == actual ||
        previous.isAssignableTo(ctx, actual) ||
        actual.isAssignableTo(ctx, previous);
  }
  final candidates = [
    actual,
    ...actual
        .resolveTypeChain(ctx)
        .allSupertypes
        .map(
          (s) =>
              s.substituteTypeParameters(actual.appliedTypeArguments(ctx)),
        ),
  ];
  for (final candidate in candidates) {
    if (candidate.file != pattern.file || candidate.name != pattern.name) {
      continue;
    }
    final args = pattern.specifiedTypeArgs;
    final actualArgs = candidate.specifiedTypeArgs;
    var ok = true;
    for (var i = 0; i < args.length && i < actualArgs.length; i++) {
      if (!_unifyOnPattern(ctx, args[i], actualArgs[i], bound)) ok = false;
    }
    if (ok) return true;
  }
  return false;
}

/// Matches [receiverType] against [ext]'s `on` clause. Returns null when the
/// extension does not apply, else the resolved bindings for the extension's
/// type parameters (empty for non-generic extensions).
List<TypeRef>? matchExtensionOn(
  CompilerContext ctx,
  TypeRef receiverType,
  EvalExtension ext,
) {
  final onType = ext.resolveOnType(ctx);
  if (onType == null) return null;
  final tps = ext.declaration.typeParameters?.typeParameters;
  if (tps == null || tps.isEmpty) {
    return receiverType.isAssignableTo(ctx, onType)
        ? const <TypeRef>[]
        : null;
  }
  final bound = List<TypeRef?>.filled(tps.length, null);
  if (!_unifyOnPattern(ctx, onType, receiverType, bound)) return null;
  // Unbound parameters (not constrained by the pattern) take their declared
  // bound, or dynamic when unbounded.
  return [
    for (var i = 0; i < tps.length; i++)
      bound[i] ??
          (tps[i].bound == null
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(ctx, ext.library, tps[i].bound!)),
  ];
}

/// [ext]'s `on` type with [bindings] substituted for its type parameters —
/// the instantiated type the receiver was matched against, used to order
/// candidates by specificity.
TypeRef _instantiateOnType(
  EvalExtension ext,
  TypeRef onType,
  List<TypeRef> bindings,
) {
  if (bindings.isEmpty) return onType;
  return onType.substituteTypeParameters({
    for (var i = 0; i < bindings.length; i++)
      ('extension:${ext.library}:${ext.name}', i): bindings[i],
  });
}

/// Finds the most specific extension member applicable to [receiverType]
/// named [memberName], or null when none apply. Specificity compares each
/// candidate's `on` type after substituting the bindings inferred for the
/// receiver — `on SubTarget<Object>` loses to `on T` bound to
/// `SubTarget<int>`. Ambiguity between equally specific candidates reports
/// the last seen.
(EvalExtension, MethodDeclaration, List<TypeRef>)? resolveExtensionMember(
  CompilerContext ctx,
  TypeRef receiverType,
  String memberName, {
  bool getter = false,
  bool setter = false,
  int? arity,
}) {
  EvalExtension? bestExt;
  MethodDeclaration? best;
  TypeRef? bestOnType;
  List<TypeRef>? bestBindings;
  for (final ext in ctx.visibleExtensions[ctx.library] ?? const []) {
    final onType = ext.resolveOnType(ctx);
    if (onType == null) continue;
    final bindings = matchExtensionOn(ctx, receiverType, ext);
    if (bindings == null) continue;
    final instantiatedOn = _instantiateOnType(ext, onType, bindings);
    for (final member in ext.members) {
      if (member is! MethodDeclaration || member.isStatic) continue;
      if (member.name.lexeme != memberName) continue;
      if (member.isGetter != getter || member.isSetter != setter) continue;
      if (arity != null && !_acceptsArity(member, arity)) continue;
      var wins = best == null;
      if (!wins) {
        final forward = instantiatedOn.isAssignableTo(ctx, bestOnType!);
        final reverse = bestOnType.isAssignableTo(ctx, instantiatedOn);
        // Equal-specificity tie: an `on T` variable pattern loses to a
        // concrete on-type (`on Target<T>` beats `on T` bound to Target<num>).
        wins = forward && (!reverse || !onType.isTypeParameter);
      }
      if (wins) {
        bestExt = ext;
        best = member;
        bestOnType = instantiatedOn;
        bestBindings = bindings;
      }
    }
  }
  return best == null ? null : (bestExt!, best, bestBindings!);
}

/// Member registration key for [member] of the extension named [extName].
/// `operator -` is the only arity-overloadable operator — unary and binary
/// forms can coexist in one extension — so it is keyed by positional arity.
String extensionMemberKey(String extName, MethodDeclaration member) {
  final suffix = member.isGetter
      ? '*g'
      : member.isSetter
      ? '*s'
      : member.name.lexeme == '-'
      ? ':${positionalArityOf(member)}'
      : '';
  return '$extName.${member.name.lexeme}$suffix';
}

/// Total positional parameter count (required + optional) of [member].
int positionalArityOf(MethodDeclaration member) =>
    member.parameters?.parameters.where((p) => p.isPositional).length ?? 0;

/// Whether [member]'s parameter list can be invoked with [arity] positional
/// arguments: between its required and total positional parameter count.
bool _acceptsArity(MethodDeclaration member, int arity) {
  final positional =
      member.parameters?.parameters.where((p) => p.isPositional).toList() ??
      const [];
  final required = positional.where((p) => p.isRequired).length;
  return arity >= required && arity <= positional.length;
}

/// Runtime type-argument ids for an invocation of [member]: the extension's
/// own [bindings] first, then one entry per method type parameter taken from
/// [resolveGenerics] (explicit or inferred) or its declared bound. Returns
/// null when every slot resolves trivially — an empty `typeArguments` list
/// means the callee's parameters default to their bounds.
List<int>? extensionCallTypeArguments(
  CompilerContext ctx,
  EvalExtension ext,
  MethodDeclaration member,
  List<TypeRef> bindings,
  Map<String, TypeRef> resolveGenerics,
) {
  final methodParams =
      member.typeParameters?.typeParameters ?? const <TypeParameter>[];
  if (bindings.length + methodParams.length == 0) return null;
  final ids = <int>[];
  for (final bound in bindings) {
    ids.add(bound.runtimeTypeId(ctx));
  }
  for (final param in methodParams) {
    final resolved =
        resolveGenerics[param.name.lexeme] ??
        (param.bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(
                ctx,
                ext.library,
                param.bound!,
                typeParameters: resolveGenerics,
              ));
    ids.add(resolved.runtimeTypeId(ctx));
  }
  return ids;
}

/// The extension declaring [member], or null.
EvalExtension? extensionOfMember(CompilerContext ctx, MethodDeclaration member) {
  for (final ext in ctx.extensions) {
    if (ext.members.contains(member)) return ext;
  }
  return null;
}

/// Maps [ext]'s type parameter names to their bindings on [receiverType]
/// (declared bound or dynamic where the `on` pattern leaves them free), for
/// use as the `typeParameters:` argument of annotation resolvers.
Map<String, TypeRef> memberExtParams(
  CompilerContext ctx,
  EvalExtension ext,
  TypeRef receiverType,
) {
  final params =
      ext.declaration.typeParameters?.typeParameters ?? const <TypeParameter>[];
  if (params.isEmpty) return const {};
  final bindings = matchExtensionOn(ctx, receiverType, ext) ?? const [];
  return {
    for (var i = 0; i < params.length; i++)
      params[i].name.lexeme:
          i < bindings.length
              ? bindings[i]
              : (params[i].bound == null
                  ? CoreTypes.dynamic.ref(ctx)
                  : TypeRef.fromAnnotation(ctx, ext.library, params[i].bound!)),
  };
}

/// Emits a call to an extension getter: `E.name*g(receiver)` is a static
/// call whose only argument is the receiver. [bindings] holds the resolved
/// `on` bindings for generic extensions (empty otherwise).
Variable invokeExtensionGetter(
  CompilerContext ctx,
  Variable receiver,
  EvalExtension ext,
  MethodDeclaration member, [
  List<TypeRef> bindings = const [],
]) {
  final s = ctx.svar('method_result');
  ctx.pushOp(
    Call(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      [receiver.boxIfNeeded(ctx).ssa],
      result: s,
      typeArguments: bindings.isEmpty
          ? const []
          : extensionCallTypeArguments(ctx, ext, member, bindings, const {}) ??
              const [],
    ),
  );
  final returnType =
      AlwaysReturnType.fromAnnotation(
        ctx,
        ext.library,
        member.returnType,
        CoreTypes.dynamic.ref(ctx),
        typeParameters: memberExtParams(ctx, ext, receiver.type),
      ).type ??
      CoreTypes.dynamic.ref(ctx);
  return Variable.of(ctx, s, returnType.copyWith(boxed: true));
}
