import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import '../invocation/bound_call.dart';
import '../invocation/deferred.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

import 'dot_shorthand.dart';
import 'expression.dart';
import '../reference.dart';
import 'null_aware.dart';
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
  Receiver? receiver;
  if (e.isCascaded) {
    receiver = ValueReceiver(ctx.cascadeTarget!);
  } else if (e.target != null) {
    receiver = compileReceiver(
      ctx,
      e.target!,
      bound: containsLeadingShorthand(e.target!) ? bound : null,
    );
    if (receiver case SuperReceiver(:final self)) {
      final (owner, dispatched) = _resolveSuperReceiver(ctx, e, self);
      if (dispatched != null) return dispatched;
      receiver = SuperReceiver(owner);
    }
  }

  final L = receiver?.value;
  if (L != null) {
    final compiledReceiver = receiver!;
    // `a?.m()` and calls continuing a null-shorted chain (`a?.b.m()`): a
    // null receiver nulls the whole expression — argument evaluation is
    // skipped.
    if (isNullShortedSelector(e)) {
      return emitNullGuard(
        ctx,
        L,
        (t) => invokeMethodWithTarget(
          ctx,
          t,
          e,
          bound: bound,
          receiver: compiledReceiver.withValue(t),
        ),
        source: e,
      );
    }
    return invokeMethodWithTarget(
      ctx,
      L,
      e,
      bound: bound,
      receiver: compiledReceiver,
    );
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
    prefix: receiver is PrefixReceiver ? receiver.prefix.prefix : null,
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
    final baseArgs = interfaceArgumentsOf(base);
    if (baseArgs.isEmpty || baseArgs.every((a) => a.isTypeParameter)) {
      return (base as InterfaceTypeRef).copyWith(arguments: inferredArgs);
    }
    return base.substituteTypeParameters(
      Substitution.of({
        for (var i = 0; i < inferredArgs.length; i++)
          (nominalDeclOf(base)?.typeParameters[i] ??
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
  Receiver? receiver,
}) => CallResolver(ctx).invokeMethod(L, e, bound: bound, receiver: receiver);

/// Emits a call to a resolved extension member: `x.m(args)` and the
/// explicit `E.m(x, args)` both land here — the receiver binds through the
/// vector's leading slot and is skipped in the arg list for the explicit
/// form ([argIndexOffset]); the extension's `on` bindings plus the
/// method's resolved type arguments go in the type environment.
Variable invokeExtensionMethod(
  CompilerContext ctx,
  Variable receiver,
  MethodInvocation call,
  EvalExtension ext,
  MethodDeclaration member,
  List<TypeRef> bindings, {
  int argIndexOffset = 0,
}) {
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
    argIndexOffset: argIndexOffset,
    source: call,
  );

  return StaticCall(
    DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
  ).emit(
    ctx,
    BoundCall(
      positional: const [],
      named: const [],
      runtimeTypeArguments:
          extensionCallTypeArguments(
            ctx,
            ext,
            member,
            bindings,
            result.typeArguments,
          ) ??
          runtimeTypeArguments(ctx, call),
      returnType: result.declaredReturn ?? CoreTypes.dynamic.ref(ctx),
      vectorOverride: result.vector(),
    ),
  );
}

List<int> runtimeTypeArguments(CompilerContext ctx, MethodInvocation call) =>
    call.typeArguments?.arguments
        .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
        .map((type) => ctx.runtimeTypes.idOf(type))
        .toList() ??
    const [];

/// Resolves the receiver for a `super.m(args)` call. A missing concrete
/// member dispatches to noSuchMethod on the real receiver.
(Variable, Variable?) _resolveSuperReceiver(
  CompilerContext ctx,
  MethodInvocation e,
  Variable receiver,
) {
  final name = e.methodName.name;
  final target = ctx.memberLookup.superMemberTarget(
    receiver.type,
    name,
    kind: MemberKind.getter,
    methodCall: true,
  );
  if (!target.found) {
    // A getter-shaped call reads before evaluating the arguments.
    if (target.abstractGetter ?? false) {
      final getterValue = NoSuchMethodCall(
        name: name,
        getterShaped: true,
      ).emitGetterValue(ctx);
      return (
        receiver,
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
    final fallback = NoSuchMethodCall(name: name);
    final bound = ArgumentBinder(ctx).bindSuppliedOnly(
      fallback,
      CallSite(
        shape: CallShape.fromArgumentList(
          e.argumentList,
          e.typeArguments?.arguments,
        ),
        source: e,
      ),
      callee: null,
    );
    return (receiver, fallback.emit(ctx, bound));
  }

  if (target.hops.isEmpty && target.owner != receiver.type) {
    receiver = Variable.of(
      ctx,
      receiver.ssa,
      target.owner,
      rep: receiver.rep,
      facts: ValueFacts(possibleClasses: [target.owner]),
    );
  }
  for (final parent in target.hops) {
    receiver = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), receiver.ssa),
      parent,
      facts: ValueFacts(possibleClasses: [parent]),
    );
  }
  return (receiver, null);
}
