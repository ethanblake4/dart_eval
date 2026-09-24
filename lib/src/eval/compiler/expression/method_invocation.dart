import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import '../invocation/deferred.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

import 'dot_shorthand.dart';
import 'expression.dart';
import '../reference.dart';
import 'identifier.dart';
import 'null_aware.dart';
import '../values/abi.dart';
import '../member/member_name.dart';
import '../invocation/call.dart';
import '../invocation/binder.dart';
import '../invocation/resolver.dart';
import '../invocation/targets.dart';
import '../variable/value_facts.dart';

Variable compileMethodInvocation(
  CompilerContext ctx,
  MethodInvocation e, {
  TypeRef? bound,
}) {
  Variable? L;
  var isPrefix = false;
  if (e.isCascaded) {
    L = ctx.cascadeTarget;
  } else if (e.target != null) {
    // `p.m(...)` — the target compiles to an import prefix, which has no
    // runtime value; detect it syntactically instead of catching an error.
    if (e.target case SimpleIdentifier target) {
      final d = IdentifierReference(
        null,
        target.name,
      ).denotation(ctx, source: e);
      if (d is PrefixDenotation) {
        isPrefix = true;
      }
    }
    if (!isPrefix) {
      L = compileExpression(
        e.target!,
        ctx,
        // `.member().rest()` — the chain's context type reaches the
        // leading shorthand through its selector targets.
        containsLeadingShorthand(e.target!) ? bound : null,
      );
      if (e.target is SuperExpression) {
        final (receiver, dispatched) = _resolveSuperReceiver(ctx, e, L);
        if (dispatched != null) return dispatched;
        L = receiver;
      }
    }
  }

  if (L != null) {
    // `a?.m()` and calls continuing a null-shorted chain (`a?.b.m()`): a
    // null receiver nulls the whole expression — argument evaluation is
    // skipped.
    if (isNullShortedSelector(e)) {
      return emitNullGuard(
        ctx,
        L,
        (t) => invokeMethodWithTarget(ctx, t, e, bound: bound),
        source: e,
      );
    }
    return invokeMethodWithTarget(ctx, L, e, bound: bound);
  }
  return CallResolver(ctx).invokeBare(
    e.methodName.name,
    CallSite(
      shape: CallShape.fromArgumentList(
        e.argumentList,
        e.typeArguments?.arguments,
      ),
      source: e,
      inConstContext: e.inConstantContext,
    ),
    prefix: isPrefix ? (e.target as Identifier).name : null,
    bound: bound,
  );
}

TypeRef instantiateConstructorType(
  CompilerContext ctx,
  MethodInvocation invocation,
  TypeRef base, [
  List<TypeRef>? inferredArgs,
]) {
  final arguments = invocation.typeArguments?.arguments;
  if (arguments == null || arguments.isEmpty) {
    if (inferredArgs == null) return base;
    final baseArgs = base.typeArguments;
    if (baseArgs.isEmpty || baseArgs.every((a) => a.isTypeParameter)) {
      return (base as InterfaceTypeRef).copyWith(arguments: inferredArgs);
    }
    return base.substituteTypeParameters(
      Substitution.of({
        for (var i = 0; i < inferredArgs.length; i++)
          (base.decl?.typeParameters[i] ??
                  ctx.typeParameterDefs.key(
                    TypeParameterOwner(
                      TypeParameterOwnerKind.classLike,
                      base.file,
                      base.name,
                    ),
                    i,
                    '',
                  )):
              inferredArgs[i],
      }),
    );
  }
  return (base as InterfaceTypeRef).copyWith(
    arguments: [
      for (final argument in arguments)
        TypeRef.fromAnnotation(ctx, ctx.library, argument),
    ],
  );
}

/// Compiles a call's argument list into positional/named variable pairs. Used
/// when the callee is a member *value* (field or getter) whose read must be
/// sequenced after the arguments per method-invocation evaluation order.
(List<Variable>, Map<String, Variable>) compileCallArgs(
  CompilerContext ctx,
  MethodInvocation e,
) {
  final positional = <Variable>[];
  final named = <String, Variable>{};
  for (final arg in e.argumentList.arguments) {
    if (arg is NamedArgument) {
      named[arg.name.lexeme] = compileExpression(arg.argumentExpression, ctx);
    } else {
      positional.add(compileExpression(arg.argumentExpression, ctx));
    }
  }
  return (positional, named);
}

int positionalArity(MethodInvocation e) =>
    e.argumentList.arguments.where((a) => a is! NamedArgument).length;

/// Compiles `E(receiver)` — explicit extension application. The receiver
/// keeps its own type but carries a [BoundExtension] so member lookups on
/// the result resolve only within [ext].
Variable applyExtension(
  CompilerContext ctx,
  MethodInvocation e,
  EvalExtension ext,
) {
  final args = e.argumentList.arguments;
  if (args.length != 1 || args.first is NamedArgument) {
    throw CompileError(
      'Extension application ${ext.name}(...) requires exactly one '
      'positional argument',
      e,
    );
  }
  final receiver = compileExpression(
    args.first.argumentExpression,
    ctx,
  ).boxIfNeeded(ctx);
  boundExtensionFor(ctx, e, ext, receiver.type); // validates `on` bindings
  // The application result shares the receiver's SSA but is a distinct
  // value — dropping `binding` keeps `updated()` from re-resolving the
  // bound wrapper back to the unbound local.
  return receiver.copyWith()..binding = null;
}

/// `receiver.m(args)` — delegates to [CallResolver.invokeMethod]; the
/// resolution cascade and emission live in the invocation package.
Variable invokeMethodWithTarget(
  CompilerContext ctx,
  Variable L,
  MethodInvocation e, {
  TypeRef? bound,
}) => CallResolver(ctx).invokeMethod(L, e, bound: bound);

/// Emits a call to a resolved extension member: `E.m(receiver, args...)` —
/// the receiver prepended to the argument vector, the extension's `on`
/// bindings plus the method's resolved type arguments passed in the type
/// environment.
Variable invokeExtensionMethod(
  CompilerContext ctx,
  Variable receiver,
  MethodInvocation call,
  EvalExtension ext,
  MethodDeclaration member,
  List<TypeRef> bindings,
) {
  final extParams =
      ext.declaration.typeParameters?.typeParameters ?? const <TypeParameter>[];
  final result = ArgumentBinder(ctx).bindDeclaration(
    ext.library,
    member,
    call.argumentList,
    before: [receiver.boxIfNeeded(ctx)],
    typeArguments: call.typeArguments,
    seedGenerics: {
      for (var i = 0; i < bindings.length && i < extParams.length; i++)
        extParams[i].name.lexeme: bindings[i],
    },
    source: call,
  );

  final s = ctx.svar('method_result');
  ctx.pushOp(
    Call(
      DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
      result.vector(),
      result: s,
      typeArguments:
          extensionCallTypeArguments(
            ctx,
            ext,
            member,
            bindings,
            result.typeArguments,
          ) ??
          runtimeTypeArguments(ctx, call),
    ),
  );
  return Variable.of(
    ctx,
    s,
    result.declaredReturn ?? CoreTypes.dynamic.ref(ctx),
    rep: ValueRep.boxed,
  );
}

List<int> runtimeTypeArguments(CompilerContext ctx, MethodInvocation call) =>
    call.typeArguments?.arguments
        .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
        .map((type) => ctx.runtimeTypes.idOf(type))
        .toList() ??
    const [];

/// Resolves the receiver for a `super.m(args)` call: finds the nearest
/// concrete member above `this` — mixin-clause members first (below the
/// member's own layer), then the superclass chain — and returns the
/// appropriately-levelled super-link variable.
///
/// When no concrete member exists (only abstract declarations or none),
/// the call is dispatched to `noSuchMethod` on the real receiver and the
/// result is returned in the second position.
(Variable, Variable?) _resolveSuperReceiver(
  CompilerContext ctx,
  MethodInvocation e,
  Variable L,
) {
  final memberName = e.methodName.name;
  final lib = ctx.enclosingLibrary ?? ctx.library;
  final (_, withClause, _, _) = classLikeClauses(ctx.currentClass!);
  // `with` mixins below the member's own layer, nearest first (all of them
  // for the class's own members); their members fold onto the applying
  // class, so a hit dispatches against it. Then the superclass's own chain.
  var stop = withClause.length;
  final declaring = ctx.memberDeclaringClass;
  if (declaring != null) {
    final declaringName = switch (declaring) {
      ClassDeclaration() ||
      MixinDeclaration() ||
      ClassTypeAlias() ||
      EnumDeclaration() => declarationName(declaring),
      _ => null,
    };
    for (var j = 0; j < withClause.length; j++) {
      if (withClause[j].name.lexeme == declaringName) {
        stop = j;
        break;
      }
    }
  }
  var found = false;
  for (var j = stop - 1; !found && j >= 0; j--) {
    final mixinRef = clauseNamedType(ctx, lib, withClause[j]);
    if (mixinRef == null) continue;
    final memberDecl =
        ctx.instanceDeclarationsMap[mixinRef.file]?[mixinRef
            .name]?[memberName] ??
        ctx.instanceDeclarationsMap[mixinRef.file]?[mixinRef
            .name]?[MemberName.getter(memberName).key];
    if (memberDecl == null) continue;
    // Abstract mixin members defer to the next mixin or superclass.
    if (memberDecl is MethodDeclaration && !memberDecl.isComplete) {
      continue;
    }
    final appType = TypeRef.lookupDeclaration(ctx, lib, ctx.currentClass!);
    L = Variable.of(
      ctx,
      L.ssa,
      appType,
      facts: ValueFacts(possibleClasses: [appType]),
    );
    found = true;
  }
  var owner = L.type;
  // Search the superclass chain for a concrete member without emitting
  // `loadsuper` ops yet — a failed walk must not leave dead loads that
  // execute on a null receiver.
  final superTypes = <TypeRef>[];
  // Kind of the nearest *abstract* declaration, if any is seen before a
  // concrete implementation: decides the Invocation shape for a noSuchMethod
  // dispatch (getter read vs. method call).
  bool? abstractGetter;
  while (!found) {
    // `Object.noSuchMethod` exists on every class but is implicit — it is
    // not present in bridge/declaration metadata.
    if (memberName == 'noSuchMethod') {
      found = true;
      break;
    }
    // Abstract re-declarations have no body — skip them like runtime
    // dispatch does; the implementation lives deeper in the chain.
    if (ctx.memberLookup.concreteMemberOn(
              owner,
              MemberName(memberName, MemberKind.method),
            ) !=
            null ||
        ctx.memberLookup.concreteMemberOn(
              owner,
              MemberName(memberName, MemberKind.getter),
            ) !=
            null) {
      found = true;
      break;
    }
    if (abstractGetter == null) {
      final decls = ctx.instanceDeclarationsMap[owner.file]?[owner.name];
      if (decls != null) {
        if (decls.containsKey(MemberName.getter(memberName).key)) {
          abstractGetter = true;
        } else if (decls.containsKey(memberName)) {
          abstractGetter = false;
        }
      }
    }
    final bridgeOwner =
        ctx.topLevelDeclarationsMap[owner.file]?[owner.name]?.bridge;
    if (bridgeOwner is BridgeClassDef &&
        bridgeOwner.methods.containsKey(memberName)) {
      found = true;
      break;
    }
    final parent = ctx.typeSystem.superclassOf(owner);
    if (parent == null) break;
    owner = parent;
    superTypes.add(owner);
  }
  if (!found) {
    // A getter-shaped `super.m(...)` is a function-expression invocation:
    // the `noSuchMethod` read evaluates before the arguments.
    if (abstractGetter ?? false) {
      final getterValue = NoSuchMethodCall(
        name: memberName,
        getterShaped: true,
      ).emitGetterValue(ctx);
      return (
        L,
        CallResolver(ctx).invokeValue(
          CallSite(
            shape: CallShape.fromArgumentList(
              e.argumentList,
              e.typeArguments?.arguments,
            ),
            source: e,
          ),
          callee: getterValue,
        ),
      );
    }
    final target = NoSuchMethodCall(name: memberName);
    final bound = ArgumentBinder(ctx).bindSuppliedOnly(
      target,
      CallSite(
        shape: CallShape.fromArgumentList(
          e.argumentList,
          e.typeArguments?.arguments,
        ),
        source: e,
      ),
      callee: null,
    );
    return (L, target.emit(ctx, bound));
  }
  for (final superType in superTypes) {
    L = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), L.ssa),
      superType,
      facts: ValueFacts(possibleClasses: [superType]),
    );
  }
  return (L, null);
}
