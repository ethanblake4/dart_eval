import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/collection.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';

import '../member/member.dart';
import 'dot_shorthand.dart';
import 'expression.dart';
import 'identifier.dart';
import 'null_aware.dart';
import '../values/abi.dart';
import '../member/member_name.dart';
import '../invocation/call.dart';
import '../invocation/resolver.dart';

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
    try {
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
    } on PrefixError {
      isPrefix = true;
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
      return base.copyWith(typeArguments: inferredArgs);
    }
    return base.substituteTypeParameters(
      Substitution.of({
        for (var i = 0; i < inferredArgs.length; i++)
          (base.decl?.typeParameters[i] ??
              TypeParameterDef(
                TypeParameterOwner(
                  TypeParameterOwnerKind.classLike,
                  base.file,
                  base.name,
                ),
                i,
                '',
              )): inferredArgs[i],
      }),
    );
  }
  return base.copyWith(
    typeArguments: [
      for (final argument in arguments)
        TypeRef.fromAnnotation(ctx, ctx.library, argument),
    ],
  );
}

void _resolveInvocationGenerics(
  CompilerContext ctx,
  int declarationLibrary,
  List<TypeParameter>? parameters,
  List<TypeAnnotation>? explicitArguments,
  Map<String, TypeRef> resolved,
  AstNode source,
) {
  if (parameters == null || parameters.isEmpty) {
    if (explicitArguments?.isNotEmpty ?? false) {
      throw CompileError('Function does not declare type parameters', source);
    }
    return;
  }
  if (explicitArguments != null &&
      explicitArguments.length != parameters.length) {
    throw CompileError(
      'Expected ${parameters.length} type arguments, '
      'but found ${explicitArguments.length}',
      source,
    );
  }
  // Seed every parameter name before resolving bounds so F-bounds can
  // self-reference (`f<T extends Foo<T>>(...)`).
  final callOwner = TypeParameterOwner(
    TypeParameterOwnerKind.callSite,
    declarationLibrary,
    '',
  );
  for (var index = 0; index < parameters.length; index++) {
    final name = parameters[index].name.lexeme;
    resolved[name] = TypeParameterTypeRef(
      TypeParameterDef(callOwner, index, name),
      file: declarationLibrary,
    );
  }
  for (var index = 0; index < parameters.length; index++) {
    final parameter = parameters[index];
    final name = parameter.name.lexeme;
    final boundAnnotation = parameter.bound;
    final bound = boundAnnotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(
            ctx,
            declarationLibrary,
            boundAnnotation,
            typeParameters: resolved,
          );
    if (explicitArguments == null) {
      resolved[name] = bound;
      continue;
    }
    final argument = TypeRef.fromAnnotation(
      ctx,
      ctx.library,
      explicitArguments[index],
    );
    // The bound may self-reference (`T extends Generator<T>`); substitute
    // the actual argument before checking assignability.
    final substitutedBound = bound.substituteTypeParameters(
      Substitution.of({(resolved[name]! as TypeParameterTypeRef).parameter: argument}),
    );
    if (!argument.isSpec(CoreTypes.dynamic) &&
        !substitutedBound.isSpec(CoreTypes.dynamic) &&
        !argument.isAssignableTo(
          ctx,
          substitutedBound,
          forceAllowDynamic: false,
        )) {
      throw CompileError(
        'Type argument $argument does not satisfy the bound $bound of $name',
        source,
      );
    }
    resolved[name] = argument;
  }
}

bool _annotationUsesTypeParameters(
  TypeAnnotation annotation,
  Map<String, TypeRef> parameters,
) {
  if (annotation is NamedType) {
    if (parameters.containsKey(annotation.name.lexeme)) return true;
    return annotation.typeArguments?.arguments.any(
          (argument) => _annotationUsesTypeParameters(argument, parameters),
        ) ??
        false;
  }
  return annotation.childEntities.whereType<TypeAnnotation>().any(
    (child) => _annotationUsesTypeParameters(child, parameters),
  );
}

/// Positional argument count of a method invocation, for disambiguating
/// extension members that differ only by arity (`operator -`).
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
  final extParams =
      ext.declaration.typeParameters?.typeParameters ?? const <TypeParameter>[];
  final List<TypeRef> bindings;
  if (e.typeArguments != null) {
    final tas = e.typeArguments!.arguments;
    if (tas.length != extParams.length) {
      throw CompileError(
        'Extension ${ext.name} takes ${extParams.length} type arguments',
        e,
      );
    }
    bindings = [
      for (final ta in tas) TypeRef.fromAnnotation(ctx, ext.library, ta),
    ];
  } else {
    // `E(c)?.m` applies `on C` to a nullable `C?` receiver; the `?.` guard
    // (or a later runtime null check) makes that legal.
    final receiverType = receiver.type.copyWith(nullable: false);
    bindings =
        matchExtensionOn(ctx, receiverType, ext) ??
        (throw CompileError(
          'Extension ${ext.name} does not apply to ${receiver.type}',
          e,
        ));
  }
  // The application result shares the receiver's SSA but is a distinct
  // value — dropping `binding` keeps `updated()` from re-resolving the
  // bound wrapper back to the unbound local.
  return receiver.copyWith()
    ..binding = null
    ..boundExtension = BoundExtension(ext, bindings);
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
  final result = compileNonBridgeArgs(
    ctx,
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
      result.args.ssa,
      result: s,
      typeArguments:
          extensionCallTypeArguments(
            ctx,
            ext,
            member,
            bindings,
            result.resolveGenerics,
          ) ??
          runtimeTypeArguments(ctx, call),
    ),
  );
  return Variable.of(
    ctx,
    s,
    result.returnType?.type ?? CoreTypes.dynamic.ref(ctx),
    rep: ValueRep.boxed,
  );
}

List<int> runtimeTypeArguments(CompilerContext ctx, MethodInvocation call) =>
    call.typeArguments?.arguments
        .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
        .map((type) => ctx.runtimeTypes.idOf(type))
        .toList() ??
    const [];

/// Maps the declaring class's type parameters to [receiver]'s applied
/// arguments by walking the supertype graph to [method]'s owner — so a param
/// annotated `WriteType` on `Indexable` resolves to `Function?` when the
/// receiver is `Test5 extends Indexable<Function?, Function?>`.
Map<String, TypeRef> classTypeArguments(
  CompilerContext ctx,
  TypeRef receiver,
  int ownerLibrary,
  MethodDeclaration method,
) {
  final owner = method.parent?.parent;
  if (owner is! ClassDeclaration && owner is! MixinDeclaration) {
    return const {};
  }
  // Worklist over supertypes: extends, `with` applications, and implements
  // edges each carry the substitutions accumulated along their own path.
  final worklist = <(TypeRef, Substitution)>[(receiver, Substitution.empty)];
  final seen = <String>{};
  while (worklist.isNotEmpty) {
    final (current, substitutions) = worklist.removeLast();
    if (!seen.add('${current.file}:${current.name}')) continue;
    if (owner is ClassDeclaration &&
        current.file == ownerLibrary &&
        current.name == owner.namePart.typeName.lexeme) {
      final parameters =
          owner.namePart.typeParameters?.typeParameters ?? const [];
      return {
        for (var index = 0; index < parameters.length; index++)
          parameters[index].name.lexeme:
              index < current.typeArguments.length
              ? current.typeArguments[index]
              : CoreTypes.dynamic.ref(ctx),
      };
    }
    final decl =
        ctx.topLevelDeclarationsMap[current.file]?[current.name]?.declaration;
    if (decl == null) continue;
    // Fold the current type's arguments into the substitution map so a
    // `with M<T>` clause resolves `T` to the receiver-provided argument.
    final levelParams =
        current.decl?.typeParameters ?? const <TypeParameterDef>[];
    final nextSubstitutions = substitutions.extend(
      Substitution.of({
        for (var index = 0; index < levelParams.length; index++)
          levelParams[index]:
              index < current.typeArguments.length
                  ? current.typeArguments[index]
                  : levelParams[index].bound ?? CoreTypes.dynamic.ref(ctx),
      }),
    );
    if (owner is MixinDeclaration) {
      // The folded method's owner is a mixin: find the `with M<args>` entry
      // on the current class (or on a mixin it applies) and map the mixin's
      // parameters to its applied arguments.
      final applied = findMixinApplication(
        ctx,
        decl,
        current.file,
        current.name,
        owner,
        ownerLibrary,
        nextSubstitutions,
      );
      if (applied != null) {
        return applied;
      }
    }
    final parent = ctx.typeSystem.superclassOf(current);
    if (parent != null && !sameDeclaration(parent, current)) {
      worklist.add((
        parent.substituteTypeParameters(nextSubstitutions),
        nextSubstitutions,
      ));
    }
    final (_, mixinTypes, interfaceTypes, _) = classLikeClauses(decl);
    for (final supertype in [...mixinTypes, ...interfaceTypes]) {
      final resolved2 = _resolveAppliedInterface(
        ctx,
        current,
        decl,
        supertype,
        nextSubstitutions,
      );
      if (resolved2 != null) worklist.add((resolved2, nextSubstitutions));
    }
  }
  return const {};
}

/// Resolves an `implements`/`on` entry of [decl] (on receiver [current]) to
/// a concrete [TypeRef]: bare arguments naming one of [current]'s type
/// parameters become parameter references, then [substitutions] maps those
/// to the receiver-provided arguments.
TypeRef? _resolveAppliedInterface(
  CompilerContext ctx,
  TypeRef current,
  Declaration decl,
  NamedType interface,
  Substitution substitutions,
) {
  final prefix = interface.importPrefix;
  final name = prefix == null
      ? interface.name.lexeme
      : '${prefix.name.lexeme}.${interface.name.lexeme}';
  final base = ctx.visibleTypes[current.file]?[name];
  if (base == null) return null;
  final args = interface.typeArguments?.arguments;
  if (args == null) return base;
  final classParams = classLikeClauses(decl).$4?.typeParameters;
  return base.copyWith(
    typeArguments: [
      for (var i = 0; i < args.length; i++)
        (resolveAppliedTypeArgument(
                  ctx,
                  current.file,
                  current.name,
                  classParams,
                  args[i],
                ) ??
                TypeRef.fromAnnotation(ctx, current.file, args[i]))
            .substituteTypeParameters(substitutions),
    ],
  );
}

/// Resolves [methodName] on [instanceType] to its declaration or bridge. The
/// declaration is normally a [MethodDeclaration]; when [methodName] names a
/// *field* holding a callable (invoked via implicit `.call`), it is the
/// enclosing [FieldDeclaration] instead.
DeclarationOrBridge<ClassMember, BridgeMethodDef> resolveInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName, [
  AstNode? source,
  TypeRef? bottomType,
]) {
  final result = _resolveInstanceMethodImpl(
    ctx,
    instanceType,
    methodName,
    source,
    bottomType,
  );
  assert(() {
    final resolved = ctx.memberLookup.interfaceMember(
      instanceType,
      ctx.memberNameOf(methodName, MemberKind.method),
      superclassFirst: true,
      source: source,
      bottomType: bottomType,
    );
    final member = resolved.member;
    final oldDecl = result.declaration;
    final oldBridge = result.bridge;
    final newNode = member is SourceMember
        ? member.node
        : member is BridgeMember
        ? member.def
        : null;
    final oldNode = oldDecl ?? oldBridge;
    assert(
      identical(newNode, oldNode),
      'MemberLookup.interfaceMember disagreed with resolveInstanceMethod '
      'on $instanceType.$methodName: new=$newNode old=$oldNode',
    );
    return true;
  }());
  return result;
}

DeclarationOrBridge<ClassMember, BridgeMethodDef> _resolveInstanceMethodImpl(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName, [
  AstNode? source,
  TypeRef? bottomType,
]) {
  if (instanceType.isTypeParameter) {
    final bound = (instanceType as TypeParameterTypeRef).parameter.bound ??
        CoreTypes.dynamic.ref(ctx);
    if (bound.isSpec(CoreTypes.dynamic)) {
      throw CompileError(
        'Cannot resolve $methodName on unbounded type parameter $instanceType',
        source,
      );
    }
    return _resolveInstanceMethodImpl(
      ctx,
      bound,
      methodName,
      source,
      bottomType ?? instanceType,
    );
  }
  final dec0 =
      ctx.topLevelDeclarationsMap[instanceType.file]?[instanceType.name];
  if (dec0 == null) {
    // Structural types (records, function types) have no declaration of
    // their own; their members come from the nominal supertype.
    final extendsType = ctx.typeSystem.superclassOf(instanceType);
    if (extendsType != null) {
      return _resolveInstanceMethodImpl(
        ctx,
        extendsType,
        methodName,
        source,
        bottomType ?? instanceType,
      );
    }
    throw CompileError(
      'Missing declaration for instance method $methodName on '
      '${instanceType.name}',
      source,
    );
  }
  final bottomType0 = bottomType ?? instanceType;
  if (dec0.isBridge) {
    // Bridge
    final bridge = dec0.bridge!;
    final method = bridge is BridgeClassDef
        ? bridge.methods[methodName]
        : (bridge as BridgeEnumDef).methods[methodName];
    if (method == null) {
      final $extendsBridgeType = bridge is BridgeClassDef
          ? bridge.type.$extends
          : null;
      if ($extendsBridgeType == null && bridge is! BridgeEnumDef) {
        throw CompileError('Unknown method $bottomType0.$methodName', source);
      }
      final $extendsType = bridge is BridgeEnumDef
          ? CoreTypes.enumType.ref(ctx)
          : TypeRef.fromBridgeTypeRef(
              ctx,
              $extendsBridgeType!,
              specifiedType: bottomType0,
            );
      return _resolveInstanceMethodImpl(
        ctx,
        $extendsType,
        methodName,
        source,
        bottomType0,
      );
    }
    return DeclarationOrBridge(instanceType.file, bridge: method);
  }

  final dec =
      ctx.instanceDeclarationsMap[instanceType.file]![instanceType
          .name]![methodName] ??
      ctx.instanceDeclarationsMap[instanceType.file]![instanceType
          .name]!['$methodName*g'];

  if (dec != null) {
    // A field holding a callable resolves to its FieldDeclaration, so callers
    // can distinguish `a.field()` (invoke `.call` on the field's value) from a
    // true method invocation.
    return DeclarationOrBridge(
      instanceType.file,
      declaration: dec is VariableDeclaration
          ? dec.parent!.parent as ClassMember
          : dec as ClassMember,
    );
  } else if (dec0.declaration is EnumDeclaration) {
    // Enum declarations resolve undeclared members through the Enum bridge
    // declaration (and transitively Object).
    return _resolveInstanceMethodImpl(
      ctx,
      CoreTypes.enumType.ref(ctx),
      methodName,
      source,
      bottomType0,
    );
  } else {
    final (extendsNamed, mixins, interfaces, _) = classLikeClauses(
      dec0.declaration,
    );
    TypeRef? resolveClauseType(NamedType named) {
      final prefix = named.importPrefix;
      final name = prefix == null
          ? named.name.lexeme
          : '${prefix.name.lexeme}.${named.name.lexeme}';
      final direct = ctx.visibleTypes[instanceType.file]![name];
      if (direct != null) return direct;
      final alias = ctx.typeAliases[instanceType.file]?[name];
      return alias == null
          ? null
          : resolveTypeAlias(
              ctx,
              instanceType.file,
              alias,
              typeArgs: named.typeArguments?.arguments,
            );
    }

    if (extendsNamed != null) {
      final $supertype =
          resolveClauseType(extendsNamed) ??
          (throw CompileError(
            'Superclass ${extendsNamed.name.lexeme} not found',
            source,
          ));
      final result = _tryResolveInstanceMethod(
        ctx,
        $supertype,
        methodName,
        source,
        bottomType0,
      );
      if (result != null) return result;
    }
    for (final interface in [...mixins, ...interfaces]) {
      final ifaceType = resolveClauseType(interface);
      if (ifaceType == null) continue;
      final result = _tryResolveInstanceMethod(
        ctx,
        ifaceType,
        methodName,
        source,
        bottomType0,
      );
      if (result != null) return result;
    }
    return _resolveInstanceMethodImpl(
      ctx,
      CoreTypes.object.ref(ctx),
      methodName,
      source,
      bottomType0,
    );
  }
}

/// Whether [instanceType] declares or inherits an instance member named
/// [methodName] — probes [resolveInstanceMethod] so callers can fall back to
/// extension members when instance lookup fails.
bool hasInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName,
) {
  try {
    resolveInstanceMethod(ctx, instanceType, methodName);
    return true;
  } on CompileError {
    return false;
  }
}

/// [resolveInstanceMethod], returning null when [instanceType] and its chain
/// lack [methodName] instead of throwing.
DeclarationOrBridge<ClassMember, BridgeMethodDef>? _tryResolveInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName,
  AstNode? source,
  TypeRef bottomType0,
) {
  try {
    return _resolveInstanceMethodImpl(
      ctx,
      instanceType,
      methodName,
      source,
      bottomType0,
    );
  } on CompileError catch (e) {
    if (e.message.startsWith('Unknown method')) return null;
    rethrow;
  }
}

DeclarationOrBridge<ClassMember, BridgeDeclaration> resolveStaticMethod(
  CompilerContext ctx,
  TypeRef classType,
  String methodName,
) {
  final method =
      ctx.topLevelDeclarationsMap[classType
          .file]!['${classType.name}.$methodName'] ??
      ctx.topLevelDeclarationsMap[classType
          .file]!['${classType.name}.$methodName*g'];
  if (method != null) {
    if (method.declaration != null) {
      final member = method.declaration!;
      final oldMember = member is VariableDeclaration
          ? member.parent!.parent as ClassMember
          : member as ClassMember;
      assert(() {
        final decl =
            classType.decl ?? ctx.types.find(classType.file, classType.name);
        // Extensions have no TypeDecl — `E.member` keys live in the
        // static namespace but extension application is handled elsewhere.
        if (decl == null) return true;
        final newMember = decl.staticMember(methodName, MemberKind.method) ??
            decl.staticMember(methodName, MemberKind.getter);
        final newNode = newMember is SourceMember
            ? newMember.node
            : newMember is BridgeMember
            ? newMember.def
            : null;
        assert(
          identical(newNode, oldMember),
          'TypeDecl.staticMember disagreed with resolveStaticMethod on '
          '$classType.$methodName: new=$newNode old=$oldMember',
        );
        return true;
      }());
      return DeclarationOrBridge(
        classType.file,
        declaration: oldMember,
      );
    } else {
      assert(() {
        final decl =
            classType.decl ?? ctx.types.find(classType.file, classType.name);
        // Extensions have no TypeDecl — `E.member` keys live in the
        // static namespace but extension application is handled elsewhere.
        if (decl == null) return true;
        final newMember = decl.staticMember(methodName, MemberKind.method) ??
            decl.staticMember(methodName, MemberKind.getter);
        final newNode = newMember is BridgeMember ? newMember.def : null;
        assert(
          identical(newNode, method.bridge),
          'TypeDecl.staticMember disagreed with resolveStaticMethod on '
          '$classType.$methodName: new=$newNode old=${method.bridge}',
        );
        return true;
      }());
      return DeclarationOrBridge(classType.file, bridge: method.bridge!);
    }
  }

  throw CompileError('Cannot find static method $classType.$methodName');
}

/// The callable signature of a function/method/constructor declaration:
/// (formal parameters, declared type parameters, declared return type).
(List<FormalParameter>, List<TypeParameter>?, TypeAnnotation?)
_invocationSignature(Declaration dec) => switch (dec) {
  FunctionDeclaration() => (
    dec.functionExpression.parameters?.parameters ?? <FormalParameter>[],
    dec.functionExpression.typeParameters?.typeParameters,
    dec.returnType,
  ),
  MethodDeclaration() => (
    dec.parameters?.parameters ?? <FormalParameter>[],
    dec.typeParameters?.typeParameters,
    dec.returnType,
  ),
  ConstructorDeclaration() => (dec.parameters.parameters, null, null),
  _ => throw CompileError('Invalid declaration type ${dec.runtimeType}'),
};

/// The result of [compileNonBridgeArgs].
class ResolvedArgs {
  ResolvedArgs(
    this.args,
    this.returnType,
    this.boxedBySubstitution,
    this.resolveGenerics,
    this.classTypeParameters,
  );

  final ArgumentListResult args;

  /// The return type after substituting resolved generics into the declared
  /// return annotation, or null when the annotation isn't generic-dependent.
  final AlwaysReturnType? returnType;

  /// Whether generic substitution narrowed the language return type without
  /// changing the callee's compiled ABI, forcing the result to stay boxed.
  /// Null when the return annotation doesn't reference type parameters.
  final bool? boxedBySubstitution;

  /// The call's resolved generic bindings by parameter name — for constructor
  /// calls these hold the class type arguments inferred from the arguments
  /// (or the parameters' bounds when unconstrained).
  final Map<String, TypeRef> resolveGenerics;

  /// The declaring class's type parameters, in order, when [args] belongs to
  /// a constructor declaration.
  final List<TypeParameter>? classTypeParameters;
}

/// Compiles the argument list for a call to a non-bridge declaration [dec],
/// resolving generic type parameters at the call site. [seedGenerics] provides
/// receiver-class type arguments (for instance calls); [typeArguments] are the
/// call's explicit type arguments, whose presence disables inference.
ResolvedArgs compileNonBridgeArgs(
  CompilerContext ctx,
  int sourceLib,
  Declaration dec,
  ArgumentList argumentList, {
  List<Variable> before = const [],
  TypeArgumentList? typeArguments,
  AstNode? source,
  Map<String, TypeRef> seedGenerics = const {},
  // Skips this many leading positional arguments (explicit extension
  // application `E.m(receiver, ...)` carries the receiver in the list).
  int argIndexOffset = 0,

  /// The expression's context type. Method type parameters left unconstrained
  /// by argument inference are bound from the declared return type matched
  /// against it (`x.cast()` under `C<bool>` binds `U` to `bool`).
  TypeRef? returnContext,
}) {
  final (fpl, typeParams, returnAnnotation) = _invocationSignature(dec);
  final isCallableDecl = dec is FunctionDeclaration || dec is MethodDeclaration;
  final resolveGenerics = <String, TypeRef>{...seedGenerics};
  List<TypeParameter>? classParams;
  if (dec is ConstructorDeclaration) {
    // Constructor signatures reference the declaring class's type parameters;
    // seed them from the call's explicit type arguments (or bounds).
    final owner = dec.thisOrAncestorMatching(
      (node) =>
          node is ClassDeclaration ||
          node is MixinDeclaration ||
          node is ClassTypeAlias,
    );
    classParams = switch (owner) {
      ClassDeclaration() || MixinDeclaration() || ClassTypeAlias() =>
        classLikeClauses(owner as Declaration).$4?.typeParameters,
      _ => null,
    };
    if (classParams != null) {
      final explicitArgs = typeArguments?.arguments;
      for (var i = 0; i < classParams.length; i++) {
        final bound = classParams[i].bound;
        resolveGenerics[classParams[i].name.lexeme] =
            explicitArgs != null && i < explicitArgs.length
            ? TypeRef.fromAnnotation(ctx, sourceLib, explicitArgs[i])
            : bound == null
            ? CoreTypes.dynamic.ref(ctx)
            : TypeRef.fromAnnotation(
                ctx,
                sourceLib,
                bound,
                typeParameters: resolveGenerics,
              );
      }
    }
  }
  if (isCallableDecl) {
    _resolveInvocationGenerics(
      ctx,
      sourceLib,
      typeParams,
      typeArguments?.arguments.toList(),
      resolveGenerics,
      source!,
    );
  }

  bool? boxedBySubstitution;
  if (returnAnnotation != null &&
      _annotationUsesTypeParameters(returnAnnotation, resolveGenerics)) {
    // Substitution narrows the language type, not the compiled callee's ABI.
    boxedBySubstitution = true;
  }

  // Snapshot the pre-inference bindings: entries still identical after the
  // argument list compiles were never constrained by the arguments.
  final unboundGenerics = Map<String, TypeRef>.of(resolveGenerics);
  final argsPair = compileArgumentList(
    ctx,
    argumentList,
    sourceLib,
    fpl,
    dec,
    before: before,
    source: source,
    argIndexOffset: argIndexOffset,
    resolveGenerics: resolveGenerics,
    // Only function/method declarations take explicit type arguments at the
    // call site; constructor calls infer regardless (e.g. List<int>() still
    // infers the constructor's own generics).
    inferGenerics: !isCallableDecl || typeArguments == null,
  );

  // Downward inference: parameters untouched by argument inference bind
  // from the declared return type matched against the context type.
  if (returnContext != null &&
      typeArguments == null &&
      typeParams != null &&
      returnAnnotation != null) {
    final callOwner = TypeParameterOwner(
      TypeParameterOwnerKind.callSite,
      sourceLib,
      '',
    );
    final placeholders = <String, TypeRef>{
      for (var i = 0; i < typeParams.length; i++)
        typeParams[i].name.lexeme: TypeParameterTypeRef(
          TypeParameterDef(callOwner, i, typeParams[i].name.lexeme),
          file: sourceLib,
        ),
    };
    final pattern = TypeRef.fromAnnotation(
      ctx,
      sourceLib,
      returnAnnotation,
      typeParameters: placeholders,
    );
    final substitutions = Substitution.wrap(<TypeParameterDef, TypeRef>{});
    ctx.typeSystem.unify(pattern, returnContext, substitutions);
    for (var i = 0; i < typeParams.length; i++) {
      final name = typeParams[i].name.lexeme;
      if (!identical(resolveGenerics[name], unboundGenerics[name])) continue;
      final bound = substitutions[(placeholders[name]! as TypeParameterTypeRef).parameter];
      if (bound != null) resolveGenerics[name] = bound;
    }
  }

  AlwaysReturnType? returnType;
  if (returnAnnotation != null && resolveGenerics.isNotEmpty) {
    final resolvedReturn = TypeRef.fromAnnotation(
      ctx,
      sourceLib,
      returnAnnotation,
      typeParameters: resolveGenerics,
    );
    returnType = AlwaysReturnType(
      resolvedReturn,
      returnAnnotation.question != null,
    );
  }
  return ResolvedArgs(
    argsPair,
    returnType,
    boxedBySubstitution,
    resolveGenerics,
    classParams,
  );
}

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
    L = Variable.of(ctx, L.ssa, appType, concreteTypes: [appType]);
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
    if (concreteMemberDecl(ctx, owner, memberName, kind: 2) != null ||
        concreteMemberDecl(ctx, owner, memberName, kind: 0) != null) {
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
    return (L, _invokeSuperNoSuchMethod(ctx, e, abstractGetter ?? false));
  }
  for (final superType in superTypes) {
    L = Variable.ssa(
      ctx,
      LoadSuper(ctx.svar('super'), L.ssa),
      superType,
      concreteTypes: [superType],
    );
  }
  return (L, null);
}

/// `super.m(args)` where no concrete `m` exists above `this` dispatches to
/// `noSuchMethod` on the real receiver with an Invocation describing the
/// call — the semantics for abstract super-members.
Variable _invokeSuperNoSuchMethod(
  CompilerContext ctx,
  MethodInvocation e,
  bool abstractGetter,
) {
  final coreLib = ctx.libraryMap['dart:core']!;
  final bridge = ctx.bridgeStaticFunctionIndices[coreLib]!;

  Variable symbolFor(String name) {
    final arg = BuiltinValue(stringval: name).push(ctx).boxIfNeeded(ctx);
    return Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('sym'), bridge['Symbol.']!, [arg.ssa]),
      CoreTypes.symbol.ref(ctx),
    );
  }

  final $this = ctx.lookupLocal('#this')!;

  // `super.m(args)` on an abstract getter is a function-expression
  // invocation: fetch the getter's value via noSuchMethod, then invoke it.
  if (abstractGetter) {
    final invocation = Variable.ssa(
      ctx,
      InvokeExternal(ctx.svar('inv'), bridge['Invocation.getter']!, [
        symbolFor(e.methodName.name).ssa,
      ]),
      CoreTypes.invocation.ref(ctx),
    );
    final getterValue = $this.invoke(ctx, 'noSuchMethod', [invocation]).result;
    return _invokeValue(ctx, getterValue, e);
  }

  final (positional, named) = compileCallArgs(ctx, e);
  final listType = CoreTypes.list
      .ref(ctx)
      .copyWith(typeArguments: [CoreTypes.dynamic.ref(ctx)]);
  final list = Variable.ssa(
    ctx,
    NewList(ctx.svar('list')),
    listType,
    rep: ValueRep.nativeList,
  );
  for (final arg in positional) {
    ctx.pushOp(ListAppend(list.ssa, arg.boxIfNeeded(ctx).ssa));
  }
  final invArgs = [symbolFor(e.methodName.name).ssa, list.boxIfNeeded(ctx).ssa];
  if (named.isNotEmpty) {
    final mapType = CoreTypes.map
        .ref(ctx)
        .copyWith(
          typeArguments: [
            CoreTypes.symbol.ref(ctx),
            CoreTypes.dynamic.ref(ctx),
          ],
        );
    final map = Variable.ssa(
      ctx,
      NewMap(ctx.svar('map')),
      mapType,
      rep: ValueRep.nativeMap,
    );
    for (final entry in named.entries) {
      ctx.pushOp(
        MapSet(
          map.ssa,
          symbolFor(entry.key).ssa,
          entry.value.boxIfNeeded(ctx).ssa,
        ),
      );
    }
    invArgs.add(map.boxIfNeeded(ctx).ssa);
  }
  final invocation = Variable.ssa(
    ctx,
    InvokeExternal(ctx.svar('inv'), bridge['Invocation.method']!, invArgs),
    CoreTypes.invocation.ref(ctx),
  );
  return $this.invoke(ctx, 'noSuchMethod', [invocation]).result;
}

/// Invokes [value] — the read result of a member *value* (field/getter/
/// callable) — with the call's argument list. The member read already
/// happened; this is the function-expression invocation.
Variable _invokeValue(CompilerContext ctx, Variable value, MethodInvocation e) {
  return CallResolver(ctx).invokeValue(
    CallSite(
      shape: CallShape.fromArgumentList(
        e.argumentList,
        e.typeArguments?.arguments.toList(),
      ),
      source: e,
    ),
    callee: value,
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
