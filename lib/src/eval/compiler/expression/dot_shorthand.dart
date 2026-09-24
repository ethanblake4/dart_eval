import 'package:analyzer/dart/ast/ast.dart';
import '../invocation/binder.dart';
import '../invocation/bound_call.dart';
import '../invocation/targets.dart';
import '../member/call_signature.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import '../invocation/deferred.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/instance_creation.dart';
import 'package:dart_eval/src/eval/compiler/helpers/tearoff.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../values/value_rep.dart';
import '../invocation/call.dart';
import '../invocation/resolver.dart';
import '../variable/value_facts.dart';

/// Resolves the context type a `.member` shorthand selects: the bound type
/// with nullability stripped and `FutureOr` unwrapped. Throws when the
/// shorthand sees no concrete type (dynamic context, missing bound).
TypeRef _shorthandContextType(
  CompilerContext ctx,
  TypeRef? bound,
  AstNode source,
) {
  if (bound == null) {
    throw CompileError('Dot shorthand requires a context type', source);
  }
  var type = bound;
  while (type.name == 'FutureOr' && interfaceArgumentsOf(type).isNotEmpty) {
    type = interfaceArgumentsOf(type).first;
  }
  type = type.withNullable(false);
  if (type.isTypeParameter || type.isSpec(CoreTypes.dynamic)) {
    throw CompileError(
      'Dot shorthand requires a concrete context type, got $type',
      source,
    );
  }
  return type;
}

/// Whether [e]'s leftmost primary expression is a dot shorthand — inside a
/// selector chain like `.member().field.method()`, or under a postfix
/// operator like `.nullable!`, the context type propagates inward to the
/// shorthand, so selector compilers pass their bound to such targets.
bool containsLeadingShorthand(Expression e) => switch (e) {
  DotShorthandPropertyAccess() ||
  DotShorthandInvocation() ||
  DotShorthandConstructorInvocation() => true,
  PostfixExpression(:final operand) => containsLeadingShorthand(operand),
  ParenthesizedExpression(:final expression) => containsLeadingShorthand(
    expression,
  ),
  PropertyAccess(:final target?) => containsLeadingShorthand(target),
  MethodInvocation(:final target?) => containsLeadingShorthand(target),
  IndexExpression(:final target?) => containsLeadingShorthand(target),
  _ => false,
};

/// A type-namespace variable for [type], standing in for the `C` of `C.member`
/// so [IdentifierReference] resolves the shorthand's static members.
Variable _typeNamespace(CompilerContext ctx, TypeRef type) => Variable(
  CoreTypes.type.ref(ctx),
  rep: ValueRep.boxed,
  facts: ValueFacts(denotedType: type, possibleClasses: [type]),
);

/// `.member` — a static member (enum value, static field, getter, method
/// tear-off) of the context type.
Variable compileDotShorthandPropertyAccess(
  CompilerContext ctx,
  DotShorthandPropertyAccess e,
  TypeRef? bound,
) {
  final type = _shorthandContextType(ctx, bound, e);
  return IdentifierReference(
    _typeNamespace(ctx, type),
    e.propertyName.name,
  ).getValue(ctx, e);
}

/// `.member(args)` / `.new(args)` / `.name(args)` — a constructor invocation
/// when `C.member` names a constructor, otherwise a static member call.
Variable compileDotShorthandInvocation(
  CompilerContext ctx,
  DotShorthandInvocation e,
  TypeRef? bound,
) {
  final type = _shorthandContextType(ctx, bound, e);
  return _invokeShorthandMember(
    ctx,
    type,
    e.memberName.name,
    e.argumentList,
    e.typeArguments,
    e.inConstantContext,
    e,
    bound,
  );
}

/// `const .name(args)` — always a constructor invocation of the context type.
Variable compileDotShorthandConstructorInvocation(
  CompilerContext ctx,
  DotShorthandConstructorInvocation e,
  TypeRef? bound,
) {
  final type = _shorthandContextType(ctx, bound, e);
  return compileInstanceOf(
    ctx,
    staticType: type,
    instantiatedType: type,
    name: ctorNameOf(e.constructorName.name),
    argumentList: e.argumentList,
    isConst: e.isConst,
    source: e,
  );
}

Variable _invokeShorthandMember(
  CompilerContext ctx,
  TypeRef type,
  String memberName,
  ArgumentList argumentList,
  TypeArgumentList? typeArguments,
  bool inConstantContext,
  AstNode source,
  TypeRef? bound,
) {
  final name = ctorNameOf(memberName);
  final member = ctx.topLevelDeclarationsMap[type.file]?['${type.name}.$name'];
  final decl = member?.declaration;
  if (decl is ConstructorDeclaration ||
      (member != null &&
          member.isBridge &&
          member.bridge is BridgeConstructorDef)) {
    return compileInstanceOf(
      ctx,
      staticType: type,
      instantiatedType: type,
      name: name,
      argumentList: argumentList,
      isConst: inConstantContext,
      source: source,
    );
  }
  // A non-bridge static method — bounded argument compilation plus a direct
  // Call, the same path `C.member(...)` takes.
  if (decl is MethodDeclaration && decl.isStatic) {
    final result = ArgumentBinder(ctx).bindDeclaration(
      member!.sourceLib,
      decl,
      argumentList,
      typeArguments: typeArguments,
      source: source,
      returnContext: bound,
    );

    return StaticCall(
      DeferredOrOffset.lookupStatic(ctx, type.file, type.name, memberName),
    ).emit(
      ctx,
      BoundCall(
        positional: result.positional,
        named: result.named,
        vectorOverride: result.vector(),
        runtimeTypeArguments:
            typeArguments?.arguments
                .map((t) => TypeRef.fromAnnotation(ctx, ctx.library, t))
                .map((t) => ctx.runtimeTypes.idOf(t))
                .toList() ??
            const [],
        returnType: result.declaredReturn ?? CoreTypes.dynamic.ref(ctx),
        rep: ValueRep.boxed,
      ),
    );
  }
  if (member != null && member.isBridge && member.bridge is BridgeMethodDef) {
    final fd = (member.bridge as BridgeMethodDef).functionDescriptor;
    final arguments = ArgumentBinder(
      ctx,
    ).bindBridgeVector(argumentList, fd, typeParameters: const {});
    final returnType =
        resolveCallResultType(
          ctx,
          signature: CallSignature.bridge(
            ctx,
            fd,
            returnFallback: CoreTypes.dynamic.ref(ctx),
            owner: type,
          ),
          targetType: type,
          argTypes: arguments.positionalValues.map((a) => a.type).toList(),
          namedArgTypes: arguments.namedValues.map(
            (k, v) => MapEntry(k, v.type),
          ),
        ) ??
        CoreTypes.dynamic.ref(ctx);
    return StaticCall(
      null,
      externalIndex:
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.$name']!,
    ).emit(
      ctx,
      BoundCall(
        positional: arguments.positional,
        named: arguments.named,
        vectorOverride: arguments.vector(),
        returnType: returnType,
        rep: ValueRep.boxed,
      ),
    );
  }
  // A static method, a static field/getter holding a callable, or a named
  // constructor of a class without declared ctors — resolve the member value
  // first, then invoke it.
  if (name.isEmpty) {
    // `.new(...)` on a class with only the implicit default constructor.
    return compileInstanceOf(
      ctx,
      staticType: type,
      instantiatedType: type,
      name: '',
      argumentList: argumentList,
      isConst: inConstantContext,
      source: source,
    );
  }
  var fn = IdentifierReference(
    _typeNamespace(ctx, type),
    memberName,
  ).getValue(ctx, source);
  // A static method resolves lazily (no SSA value) — materialize its
  // tear-off so it can be invoked like any other function value.
  if (fn.unmaterializedCallable != null) {
    fn = fn.tearOff(ctx);
  }
  return CallResolver(ctx).invokeValue(
    CallSite(
      shape: CallShape.fromArgumentList(
        argumentList,
        typeArguments?.arguments.toList(),
      ),
      source: argumentList,
    ),
    callee: fn,
  );
}
