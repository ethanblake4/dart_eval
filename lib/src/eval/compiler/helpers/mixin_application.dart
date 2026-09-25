import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';

/// Mixin-application resolution: which arguments a `with` clause binds to a
/// mixin's own type parameters, including through mixin-application chains.
/// These aren't type construction — they answer how one declaration's
/// parameters bind inside another's clause.
/// Finds an application of [mixinOwner] in [decl]'s `with` clause, including
/// through entries that are themselves mixin applications (`class C = S with
/// M`, `mixin class`). Returns the mixin's parameter names mapped to their
/// effective types under [substitutions], or null when [mixinOwner] is not
/// applied anywhere in the clause.
Map<String, TypeRef>? findMixinApplication(
  CompilerContext ctx,
    Declaration decl,
    int declFile,
    String declName,
    Declaration mixinOwner,
    int ownerLibrary,
    Substitution substitutions,
  ) {
    for (final mixinType in classLikeClauses(decl).$2) {
      final prefix = mixinType.importPrefix;
      final mixinName = prefix == null
          ? mixinType.name.lexeme
          : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
      final ref = ctx.visibleTypes[declFile]?[mixinName];
      if (ref == null) continue;
      final mixinDecl =
          ctx.topLevelDeclarationsMap[ref.file]?[ref.name]?.declaration;
      final mixinParams =
          switch (mixinDecl) {
            MixinDeclaration m => m.typeParameters?.typeParameters,
            ClassDeclaration c => c.namePart.typeParameters?.typeParameters,
            ClassTypeAlias a => a.typeParameters?.typeParameters,
            _ => null,
          } ??
          const <TypeParameter>[];
      final appliedArgs = mixinType.typeArguments?.arguments;
      final classParams = classLikeClauses(decl).$4?.typeParameters;
      // The mixin's own parameters scope over parameter bounds —
      // `mixin M<S, T extends S>` resolves `S` inside `T`'s bound to the
      // mixin's S so it substitutes to the applied argument below. Bounds are
      // written in the mixin declaration's own library (ref.file).
      final mixinDeclRef = nominalDeclOf(ref);
      final mixinDefs = [
        for (var i = 0; i < mixinParams.length; i++)
          mixinDeclRef != null && i < mixinDeclRef.typeParameters.length
              ? mixinDeclRef.typeParameters[i]
              : ctx.typeParameterDefs.key(
                  TypeParameterOwner(
                    TypeParameterOwnerKind.classLike,
                    ref.file,
                    ref.name,
                  ),
                  i,
                  '',
                ),
      ];
      // Each parameter's effective type under the substitutions accumulated so
      // far (bounds apply when the application omits an argument). Params
      // resolve in order and accumulate into [appliedSubs] so a bound naming
      // an earlier parameter sees its applied argument.
      final applied = <String, TypeRef>{};
      final appliedSubs = <TypeParameterDef, TypeRef>{};
      for (var i = 0; i < mixinParams.length; i++) {
        applied[mixinParams[i].name.lexeme] =
            _resolveAppliedMixinArg(
              ctx,
              declFile,
              declName,
              classParams,
              appliedArgs != null && i < appliedArgs.length
                  ? appliedArgs[i]
                  : null,
              substitutions,
            ) ??
            _substitutedParamBound(
              ctx,
              ref.file,
              mixinDeclRef?.ownTypeParams ?? const <String, TypeRef>{},
              mixinParams[i],
              appliedSubs.isEmpty
                  ? substitutions
                  : substitutions.extend(Substitution.of(appliedSubs)),
            );
        appliedSubs[mixinDefs[i]] = applied[mixinParams[i].name.lexeme]!;
      }
      if (identical(mixinDecl, mixinOwner)) {
        return applied;
      }
      if (mixinDecl is ClassDeclaration || mixinDecl is ClassTypeAlias) {
        final inner = findMixinApplication(
          ctx,
          mixinDecl!,
          ref.file,
          ref.name,
          mixinOwner,
          ownerLibrary,
          Substitution.of({...substitutions.bindings, ...appliedSubs}),
        );
        if (inner != null) return inner;
      }
    }
    return null;
  }

/// Resolves a type argument in a `with` clause entry: a bare name matching
/// one of the applying class's own type parameters resolves to that
/// parameter; other named types resolve with their arguments resolved
/// recursively (so `List<U>` resolves when `U` is the alias's parameter).
/// [substitutions] are applied to the result.
TypeRef? _resolveAppliedMixinArg(
  CompilerContext ctx,
    int declFile,
    String declName,
    List<TypeParameter>? classParams,
    TypeAnnotation? arg,
    Substitution substitutions,
  ) {
    if (arg == null) return null;
    return ctx.typeFactory
        .resolveAppliedTypeArgument(declFile, declName, classParams, arg)
        ?.substituteTypeParameters(substitutions);
  }

/// The bound of a mixin type parameter, substituted through [substitutions].
/// [boundScope] carries the mixin's own parameters so bounds like
/// `T extends S` resolve to the applied argument for `S`.
TypeRef _substitutedParamBound(
  CompilerContext ctx,
    int file,
    Map<String, TypeRef> boundScope,
    TypeParameter param,
    Substitution substitutions,
  ) {
    final bound = param.bound;
    return bound == null
        ? CoreTypes.dynamic.ref(ctx)
        : ctx.typeFactory
            .fromAnnotation(file, bound, typeParameters: boundScope)
            .substituteTypeParameters(substitutions);
  }

/// For [member] folded into [applier] from a mixin or mixin-class (possibly
/// through a chain of mixin applications), the parameter bindings to seed
/// into the member's declaring-library scope so its type parameters resolve
/// to the applied arguments, expressed in [applier]'s own type parameters —
/// or null when [member] is declared on [applier] itself or no application
/// is found.
Map<String, TypeRef>? foldedMemberTypeParams(
    CompilerContext ctx,
    Declaration applier,
    ClassMember member,
    int memberLibrary,
    int applierLibrary,
  ) {
    final owner = member.parent?.parent;
    if (owner is! Declaration || identical(owner, applier)) {
      return null;
    }
    return findMixinApplication(
      ctx,
      applier,
      applierLibrary,
      declarationName(applier),
      owner,
      memberLibrary,
      Substitution.empty,
    );
  }

