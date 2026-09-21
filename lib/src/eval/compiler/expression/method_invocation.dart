import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/function.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/closure.dart';
import 'package:dart_eval/src/eval/compiler/helpers/equality.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/compiler/helpers/extension.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/dispatch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/ir/bridge.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/ir/objects.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

import '../reference.dart';
import 'expression.dart';
import 'identifier.dart';

Variable compileMethodInvocation(
  CompilerContext ctx,
  MethodInvocation e, {
  Variable? cascadeTarget,
  TypeRef? bound,
}) {
  Variable? L = cascadeTarget;
  var isPrefix = false;
  if (e.target != null && cascadeTarget == null) {
    try {
      L = compileExpression(e.target!, ctx);
      if (e.target is SuperExpression) {
        final memberName = e.methodName.name;
        final lib = ctx.enclosingLibrary ?? ctx.library;
        final (_, withClause, _, _) = classLikeClauses(ctx.currentClass!);
        // `with` mixins below the member's own layer, nearest first (all of
        // them for the class's own members); their members fold onto the
        // applying class, so a hit dispatches against it. Then the
        // superclass's own chain.
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
          final memberDecl = ctx
              .instanceDeclarationsMap[mixinRef.file]?[mixinRef.name]
                  ?[memberName] ??
              ctx.instanceDeclarationsMap[mixinRef
                  .file]?[mixinRef.name]?['$memberName*g'];
          if (memberDecl == null) continue;
          _checkConcreteSuperMember(memberDecl, memberName, e);
          final appType = TypeRef.lookupDeclaration(
            ctx,
            lib,
            ctx.currentClass!,
          );
          L = Variable.of(ctx, L!.ssa, appType, concreteTypes: [appType]);
          found = true;
        }
        var owner = L!.type.resolveTypeChain(ctx);
        while (!found) {
          final members =
              ctx.instanceDeclarationsMap[owner.file]?[owner.name];
          if (members != null &&
              (members.containsKey(memberName) ||
                  members.containsKey('$memberName*g'))) {
            _checkConcreteSuperMember(
              members[memberName] ?? members['$memberName*g'],
              memberName,
              e,
            );
            found = true;
            break;
          }
          final bridgeOwner =
              ctx.topLevelDeclarationsMap[owner.file]?[owner.name]?.bridge;
          if (bridgeOwner is BridgeClassDef &&
              bridgeOwner.methods.containsKey(memberName)) {
            found = true;
            break;
          }
          final parent = owner.extendsType;
          if (parent == null) break;
          owner = parent.resolveTypeChain(ctx);
          L = Variable.ssa(
            ctx,
            LoadSuper(ctx.svar('super'), L!.ssa),
            owner,
            concreteTypes: [owner],
          );
        }
        if (!found) {
          throw CompileError(
            'Superclass has no member "$memberName"',
            e,
          );
        }
      }
    } on PrefixError {
      isPrefix = true;
    }
  }

  AlwaysReturnType? mReturnType;
  bool? genericReturnBoxed;

  if (L != null) {
    if (e.operator?.type == TokenType.QUESTION_PERIOD) {
      var out = BuiltinValue().push(ctx).boxIfNeeded(ctx);
      if (L.concreteTypes.length == 1 &&
          L.concreteTypes[0] == CoreTypes.nullType.ref(ctx)) {
        return out;
      }
      macroBranch(
        ctx,
        null,
        condition: (ctx) {
          return checkNotEqual(ctx, L!, out);
        },
        thenBranch: (ctx, rt) {
          final V = _invokeWithTarget(ctx, L!, e);
          out = out.copyWith(type: V.type.copyWith(nullable: true));
          ctx.pushOp(Assign(out.ssa, V.boxIfNeeded(ctx).ssa));
          return StatementInfo();
        },
      );
      return out;
    }
    return _invokeWithTarget(ctx, L, e);
  }
  final method = isPrefix
      ? compilePrefixedIdentifier(
          (e.target as Identifier).name,
          e.methodName.name,
          ctx,
        )
      : compileIdentifier(e.methodName, ctx);

  if (method.type == CoreTypes.dynamic.ref(ctx) ||
      method.callingConvention == CallingConvention.dynamic ||
      (method.type == CoreTypes.function.ref(ctx) &&
          method.methodOffset == null)) {
    return invokeClosure(
      ctx,
      null,
      method,
      e.argumentList,
      typeArguments: e.typeArguments?.arguments.toList(),
    ).result;
  }

  if (method.methodOffset == null) {
    // The receiver isn't a known function — it may still be a callable object
    // (an implicit `.call` invocation, e.g. `c1(1)` on `C1 c1`). Dispatch
    // dynamically: objects without a `call` method raise NoSuchMethodError at
    // runtime, matching Dart semantics.
    return invokeClosure(
      ctx,
      null,
      method,
      e.argumentList,
      typeArguments: e.typeArguments?.arguments.toList(),
    ).result;
  }

  var offset = method.methodOffset!;
  if (method.implicitReceiver != null) {
    // A member of the enclosing extension invoked on `this`.
    final ext = ctx.extensions.firstWhereOrNull(
      (ext) => ext.declaration == ctx.currentExtension,
    )!;
    final member = ext.members
        .whereType<MethodDeclaration>()
        .firstWhereOrNull(
          (m) =>
              !m.isStatic &&
              !m.isGetter &&
              !m.isSetter &&
              m.name.lexeme == e.methodName.name,
        )!;
    final result = _compileNonBridgeArgs(
      ctx,
      ext.library,
      member,
      e.argumentList,
      before: [method.implicitReceiver!.boxIfNeeded(ctx)],
      typeArguments: e.typeArguments,
      source: e,
    );
    final s = ctx.svar('method_result');
    ctx.pushOp(
      Call(
        DeferredOrOffset(file: ext.library, name: ext.memberKey(member)),
        result.args.ssa,
        result: s,
        typeArguments: _runtimeTypeArguments(ctx, e),
      ),
    );
    final returnType =
        result.returnType?.type ??
        method.methodReturnType
            ?.toAlwaysReturnType(
              ctx,
              method.implicitReceiver!.type,
              result.args.args.map((a) => a.type).toList(),
              const {},
            )
            ?.type;
    return Variable.of(
      ctx,
      s,
      returnType?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx),
    );
  }
  if (offset.file == ctx.library &&
      offset.className != null &&
      offset.className == ctx.currentClassName) {
    final $this = ctx.lookupLocal('#this')!;
    return _invokeWithTarget(ctx, $this, e);
  }

  // `name` can resolve to a class rather than a callable (e.g. `List()`) —
  // then the callable declaration lives under the offset's `name.ctor` key.
  var dec0 = ctx.topLevelDeclarationsMap[offset.file]![e.methodName.name];
  if (dec0 == null ||
      (!dec0.isBridge &&
          (dec0.declaration! is ClassDeclaration ||
              dec0.declaration! is ClassTypeAlias))) {
    dec0 =
        ctx.topLevelDeclarationsMap[offset.file]![offset.name ??
            '${e.methodName.name}.'];
    if (dec0 == null) {
      // Call to default constructor
      final result = ctx.svar('constructor');
      mReturnType =
          method.methodReturnType?.toAlwaysReturnType(
            ctx,
            TypeRef.$this(ctx),
            [],
            {},
          ) ??
          AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
      final returnType = (mReturnType.type ?? CoreTypes.dynamic.ref(ctx))
          .copyWith(
            boxed:
                L != null ||
                !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false),
          );
      final instantiatedType = _instantiateConstructorType(ctx, e, returnType);
      ctx.pushOp(
        Call(offset, [
          pushRuntimeTypeId(ctx, instantiatedType),
        ], result: result),
      );
      final v = Variable.of(
        ctx,
        result,
        instantiatedType,
        concreteTypes: [instantiatedType],
      );

      return v;
    }
  }

  // An invocation `T(args)` where `T` is a type alias to a class is a
  // constructor call on the aliased type.
  TypeRef? aliasType;
  if (!dec0.isBridge && dec0.declaration is TypeAlias) {
    var resolved = resolveTypeAlias(
      ctx,
      ctx.library,
      dec0.declaration! as TypeAlias,
      typeArgs: e.typeArguments?.arguments.toList(),
      rawParams: true,
    );
    // Downward inference: `C<num> x = T(num)` instantiates `T` as `C<num>`,
    // matching alias parameters structurally (`T<X> = C<List<X>>` against
    // `C<List<num>>` binds `X → num`).
    final boundChain = bound?.resolveTypeChain(ctx);

    if (e.typeArguments == null &&
        boundChain != null &&
        boundChain.file == resolved.file &&
        boundChain.name == resolved.name &&
        boundChain.specifiedTypeArgs.isNotEmpty) {
      final substitutions = <(String, int), TypeRef>{};
      for (var i = 0;
          i < resolved.specifiedTypeArgs.length &&
              i < boundChain.specifiedTypeArgs.length;
          i++) {
        collectTypeParameterSubstitutions(
          ctx,
          resolved.specifiedTypeArgs[i],
          boundChain.specifiedTypeArgs[i],
          substitutions,
        );
      }
      if (substitutions.isNotEmpty) {
        resolved = resolved.substituteTypeParameters(substitutions);
      }
    }
    aliasType = resolved;
    dec0 = ctx.topLevelDeclarationsMap[resolved.file]!['${resolved.name}.'];
    offset = DeferredOrOffset(file: resolved.file, name: '${resolved.name}.');
    if (dec0 == null) {
      // The aliased class has an implicit default constructor — call the
      // synthesized `resolved.` body with just the runtime-type argument.
      final callResult = ctx.svar('constructor');
      final boxed = resolved.copyWith(boxed: true);
      ctx.pushOp(
        Call(
          offset,
          [pushRuntimeTypeId(ctx, resolved)],
          result: callResult,
        ),
      );
      return Variable.of(
        ctx,
        callResult,
        boxed,
        concreteTypes: [boxed],
      );
    }
  }

  final List<Variable> args;
  final Map<String, Variable> namedArgs;
  final List<SSA> callArgs;

  var isConstructor = false;
  List<TypeRef>? inferredCtorArgs;

  if (dec0.isBridge) {
    final bridge = dec0.bridge;

    /// If we're invoking a class identifier directly (like ClassName()), call
    /// its default constructor
    final fnDescriptor = bridge is BridgeClassDef
        ? (bridge.constructors['']?.functionDescriptor ??
              (throw CompileError(
                'Class "${e.methodName.name}" does not have a default constructor',
                e,
              )))
        : (bridge as BridgeFunctionDeclaration).function;

    final argsPair = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fnDescriptor,
      before: L != null ? [L] : [],
    );

    args = argsPair.args;
    namedArgs = argsPair.namedArgs;
    callArgs = argsPair.ssa;
    isConstructor = bridge is BridgeClassDef;
  } else {
    final dec = dec0.declaration!;
    isConstructor = dec is ConstructorDeclaration;

    final result = _compileNonBridgeArgs(
      ctx,
      offset.file!,
      dec,
      e.argumentList,
      before: L != null ? [L] : [],
      typeArguments: e.typeArguments,
      source: e,
    );
    mReturnType = result.returnType;
    genericReturnBoxed = result.boxedBySubstitution;
    args = result.args.args;
    namedArgs = result.args.namedArgs;
    callArgs = result.args.ssa;

    // Upward inference for constructors: the class type arguments inferred
    // from the argument list (or the parameters' bounds), in declaration order.
    if (isConstructor && result.classTypeParameters != null) {
      inferredCtorArgs = [
        for (final param in result.classTypeParameters!)
          result.resolveGenerics[param.name.lexeme] ??
              CoreTypes.dynamic.ref(ctx),
      ];
      if (aliasType != null && e.typeArguments == null) {
        // The alias's instantiated arguments were left as parameter references
        // for inference; bind them from what the constructor's arguments gave.
        final substitutions = <(String, int), TypeRef>{};
        final aliasArgs = aliasType.specifiedTypeArgs;
        for (var i = 0; i < aliasArgs.length && i < inferredCtorArgs.length; i++) {
          collectTypeParameterSubstitutions(
            ctx,
            aliasArgs[i],
            inferredCtorArgs[i],
            substitutions,
          );
        }
        if (substitutions.isNotEmpty) {
          aliasType = aliasType.substituteTypeParameters(substitutions);
        }
      }
    }
  }

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes = namedArgs.map(
    (key, value) => MapEntry(key, value.type),
  );

  TypeRef? thisType;
  if (ctx.currentClass != null) {
    thisType =
        ctx.visibleTypes[ctx.enclosingLibrary ?? ctx.library]![ctx
            .currentClassName!]!;
  }

  mReturnType ??=
      method.methodReturnType?.toAlwaysReturnType(
        ctx,
        thisType,
        argTypes,
        namedArgTypes,
      ) ??
      AlwaysReturnType(CoreTypes.dynamic.ref(ctx), true);
  final returnType = mReturnType.type?.copyWith(
    boxed:
        dec0.isBridge ||
        (genericReturnBoxed ??
            !(mReturnType.type?.isUnboxedAcrossFunctionBoundaries ?? false)),
  );
  final instantiatedReturnType = isConstructor && returnType != null
      ? (aliasType ??
          _instantiateConstructorType(ctx, e, returnType, inferredCtorArgs))
      : returnType;
  final declaration = dec0.isBridge ? null : dec0.declaration;
  final effectiveCallArgs = [...callArgs];
  if (isConstructor &&
      declaration is ConstructorDeclaration &&
      declaration.factoryKeyword == null) {
    effectiveCallArgs.add(pushRuntimeTypeId(ctx, instantiatedReturnType!));
  }

  final result = ctx.svar('call');
  if (dec0.isBridge) {
    final bridge = dec0.bridge!;
    if (bridge is BridgeClassDef && !bridge.wrap) {
      final type = TypeRef.fromBridgeTypeRef(ctx, bridge.type.type);
      final subclass = BuiltinValue().push(ctx);
      ctx.pushOp(
        BridgeInstantiate(
          result,
          ctx.bridgeStaticFunctionIndices[type.file]!['${type.name}.']!,
          subclass.ssa,
          effectiveCallArgs,
          runtimeTypeId: type.runtimeTypeId(ctx),
        ),
      );
    } else {
      ctx.pushOp(
        InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[offset.file]![offset.name]!,
          effectiveCallArgs,
        ),
      );
    }
  } else {
    ctx.pushOp(
      Call(
        offset,
        effectiveCallArgs,
        result: result,
        // Factories have no receiver, so the class's instantiated type
        // arguments are delivered through the callable-type-argument channel.
        typeArguments:
            declaration is ConstructorDeclaration &&
                declaration.factoryKeyword != null
            ? [
                for (final arg
                    in instantiatedReturnType?.specifiedTypeArgs ??
                        const <TypeRef>[])
                  arg.runtimeTypeId(ctx),
              ]
            : isConstructor
            ? const []
            : _runtimeTypeArguments(ctx, e),
      ),
    );
  }

  final v = Variable.of(
    ctx,
    result,
    instantiatedReturnType ?? CoreTypes.dynamic.ref(ctx),
    concreteTypes: [
      if (isConstructor && instantiatedReturnType != null)
        instantiatedReturnType,
    ],
  );

  return v;
}

TypeRef _instantiateConstructorType(
  CompilerContext ctx,
  MethodInvocation invocation,
  TypeRef base, [
  List<TypeRef>? inferredArgs,
]) {
  final arguments = invocation.typeArguments?.arguments;
  if (arguments == null || arguments.isEmpty) {
    if (inferredArgs == null) return base;
    final baseArgs = base.specifiedTypeArgs;
    if (baseArgs.isEmpty || baseArgs.every((a) => a.isTypeParameter)) {
      return base.copyWith(specifiedTypeArgs: inferredArgs);
    }
    return base.substituteTypeParameters({
      for (var i = 0; i < inferredArgs.length; i++)
        ('class:${base.resolveTypeChain(ctx).file}:${base.name}', i):
            inferredArgs[i],
    });
  }
  return base.copyWith(
    specifiedTypeArgs: [
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
  for (var index = 0; index < parameters.length; index++) {
    final name = parameters[index].name.lexeme;
    resolved[name] = TypeRef(
      declarationLibrary,
      name,
      resolved: true,
      typeParameterOwner: 'call:$declarationLibrary',
      typeParameterIndex: index,
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
    final substitutedBound = bound.substituteTypeParameters({
      ('call:$declarationLibrary', index): argument,
    });
    if (argument != CoreTypes.dynamic.ref(ctx) &&
        substitutedBound != CoreTypes.dynamic.ref(ctx) &&
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

Variable _invokeWithTarget(
  CompilerContext ctx,
  Variable L,
  MethodInvocation e,
) {
  AlwaysReturnType? mReturnType;
  final bridgeTypeParameters = <String, TypeRef>{};

  DeclarationOrBridge<ClassMember, BridgeDeclaration>? dec0;
  final bool isStatic;
  TypeRef? staticType;

  ArgumentListResult argsPair;

  // `C.new(...)` invokes the unnamed constructor.
  final staticMemberName = ctorNameOf(e.methodName.name);

  if (L.type == CoreTypes.type.ref(ctx) && L.concreteTypes.length == 1) {
    // Static method
    staticType = L.concreteTypes[0];
    if (ctx.topLevelDeclarationsMap[staticType.file]?['${staticType.name}.$staticMemberName'] ==
        null) {
      // Not a static member of the class — it's an instance method of the
      // `Type` object itself (`Foo.toString()`, `Foo.hashCode`, ...).
      final args = [
        for (final arg in e.argumentList.arguments)
          if (arg is! NamedArgument)
            compileExpression(arg.argumentExpression, ctx),
      ];
      return L.invoke(ctx, e.methodName.name, args).result;
    }
    dec0 = resolveStaticMethod(ctx, staticType, staticMemberName);
    // `C.field(args)` where `field` holds a closure reads the field and
    // invokes its value rather than calling a function named `C.field`.
    if (dec0.declaration is FieldDeclaration) {
      final fieldValue = IdentifierReference(
        L,
        staticMemberName,
      ).getValue(ctx, e);
      return invokeClosure(
        ctx,
        null,
        fieldValue,
        e.argumentList,
        typeArguments: e.typeArguments?.arguments.toList(),
      ).result;
    }
    isStatic = true;
  } else if (L.type == CoreTypes.function.ref(ctx) &&
      e.methodName.name == 'call') {
    // `fn.call(...)`: Function has no declared `call` member; the call is the
    // invocation itself, typed by the callee's own signature.
    return invokeClosure(
      ctx,
      null,
      L,
      e.argumentList,
      typeArguments: e.typeArguments?.arguments.toList(),
    ).result;
  } else if (L.type != CoreTypes.dynamic.ref(ctx)) {
    try {
      dec0 = resolveInstanceMethod(ctx, L.type, e.methodName.name, e);
    } on CompileError {
      // No such instance member: an extension method may apply.
      final found = resolveExtensionMember(
        ctx,
        L.type,
        e.methodName.name,
      );
      if (found == null) rethrow;
      final (ext, member) = found;
      final result = _compileNonBridgeArgs(
        ctx,
        ext.library,
        member,
        e.argumentList,
        before: [L.boxIfNeeded(ctx)],
        typeArguments: e.typeArguments,
        source: e,
      );
      final s = ctx.svar('method_result');
      ctx.pushOp(
        Call(
          DeferredOrOffset(
            file: ext.library,
            name: ext.memberKey(member),
          ),
          result.args.ssa,
          result: s,
          typeArguments: _runtimeTypeArguments(ctx, e),
        ),
      );
      return Variable.of(
        ctx,
        s,
        result.returnType?.type?.copyWith(boxed: true) ??
            CoreTypes.dynamic.ref(ctx),
      );
    }
    final member = dec0.declaration;
    final isFieldOrGetter =
        member is FieldDeclaration ||
        (member is MethodDeclaration && member.isGetter);
    if (isFieldOrGetter) {
      // `receiver.field(...)` / `receiver.getter(...)`: the member's *value* is
      // invoked, not a method — property read then implicit `.call`.
      final property = L.getProperty(ctx, e.methodName.name);
      return invokeClosure(
        ctx,
        null,
        property,
        e.argumentList,
        typeArguments: e.typeArguments?.arguments.toList(),
      ).result;
    }
    isStatic = false;
  } else {
    isStatic = false;
  }

  if (dec0?.isBridge == true) {
    final br = dec0!.bridge!;
    final fd = br is BridgeMethodDef
        ? br.functionDescriptor
        : (br as BridgeConstructorDef).functionDescriptor;
    final receiverTypeParameters = isStatic
        ? const <String, TypeRef>{}
        : _bridgeClassTypeArguments(ctx, L.type, dec0.sourceLib);
    argsPair = compileArgumentListWithBridge(
      ctx,
      e.argumentList,
      fd,
      before: [],
      typeParameters: receiverTypeParameters,
    );
    _inferBridgeTypeParameters(fd, argsPair.args, bridgeTypeParameters);
    mReturnType =
        bridgeFunctionReturnType(
          ctx,
          fd,
          specifiedType: isStatic ? staticType : L.type,
          typeParameters: bridgeTypeParameters,
        ).toAlwaysReturnType(
          ctx,
          isStatic ? staticType : L.type,
          argsPair.args.map((a) => a.type).toList(),
          argsPair.namedArgs.map((k, v) => MapEntry(k, v.type)),
          typeArgs:
              e.typeArguments?.arguments
                  .map((t) => TypeRef.fromAnnotation(ctx, ctx.library, t))
                  .toList() ??
              const [],
        );
    // Instance calls that carry no named or explicit type arguments route
    // through the modern invocation path, which preserves intrinsic
    // optimizations for core types. The argument vector stays padded with
    // null placeholders so generated wrappers keep the legacy flattened ABI.
    // The declared return type (including inferred generics and
    // parameter-type dependencies) still applies to the result.
    if (!isStatic && e.typeArguments == null && argsPair.namedArgs.isEmpty) {
      final invokeResult = L
          .invoke(ctx, e.methodName.name, argsPair.args)
          .result;
      final preciseType = mReturnType?.type;
      if (preciseType != null) {
        return invokeResult.copyWith(
          type: preciseType.copyWith(boxed: invokeResult.type.boxed),
        );
      }
      return invokeResult;
    }
  } else if (L.type == CoreTypes.dynamic.ref(ctx)) {
    argsPair = compileArgumentListWithDynamic(ctx, e.argumentList, before: [L]);
  } else {
    final dec = dec0!.declaration!;
    final result = _compileNonBridgeArgs(
      ctx,
      dec0.sourceLib,
      dec,
      e.argumentList,
      before: [if (!isStatic) L],
      typeArguments: e.typeArguments,
      source: e,
      seedGenerics: !isStatic && dec is MethodDeclaration
          ? _classTypeArguments(ctx, L.type, dec0.sourceLib, dec)
          : const {},
    );
    argsPair = result.args;
    mReturnType = result.returnType;
  }

  final args = argsPair.args;
  final namedArgs = argsPair.namedArgs;

  final argTypes = args.map((e) => e.type).toList();
  final namedArgTypes = namedArgs.map(
    (key, value) => MapEntry(key, value.type),
  );

  final result = ctx.svar('method_result');
  if (isStatic) {
    if (dec0!.isBridge) {
      ctx.pushOp(
        InvokeExternal(
          result,
          ctx.bridgeStaticFunctionIndices[staticType!
              .file]!['${staticType.name}.$staticMemberName']!,
          argsPair.ssa,
        ),
      );
    } else {
      final offset = DeferredOrOffset.lookupStatic(
        ctx,
        staticType!.file,
        staticType.name,
        staticMemberName,
      );
      final callArguments = [...argsPair.ssa];
      final declaration = dec0.declaration;
      if (declaration is ConstructorDeclaration &&
          declaration.factoryKeyword == null) {
        callArguments.add(pushRuntimeTypeId(ctx, staticType));
      }
      ctx.pushOp(
        Call(
          offset,
          callArguments,
          result: result,
          typeArguments: _runtimeTypeArguments(ctx, e),
        ),
      );
    }
  } else if (L.concreteTypes.length == 1 &&
      dec0?.isBridge == false &&
      (e.target is SuperExpression ||
          _isDirectlyCallable(
            ctx,
            L.concreteTypes.single,
            e.methodName.name,
          ))) {
    final actualType = L.concreteTypes[0];
    final offset = DeferredOrOffset(
      file: actualType.file,
      className: actualType.name,
      methodType: 2,
      name: e.methodName.name,
    );
    ctx.pushOp(
      Call(
        offset,
        argsPair.ssa,
        result: result,
        typeEnvironmentReceiver: L.boxIfNeeded(ctx).ssa,
        typeArguments: _runtimeTypeArguments(ctx, e),
      ),
    );
  } else {
    ctx.pushOp(
      InvokeDynamic(
        result,
        L.boxIfNeeded(ctx).ssa,
        e.methodName.name,
        dec0?.isBridge == true ? argsPair.ssa : argsPair.ssa.skip(1).toList(),
        // Bridge methods use their legacy padded positional ABI. Evaluated
        // methods keep source-level positional and named call metadata.
        positionalCount: dec0?.isBridge == true
            ? argsPair.ssa.length
            : argsPair.args.length,
        namedNames: dec0?.isBridge == true
            ? const []
            : argsPair.namedArgs.keys.toList(),
        callerLibrary: ctx.library,
        typeArguments:
            e.typeArguments?.arguments
                .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
                .map((type) => type.runtimeTypeId(ctx))
                .toList() ??
            const [],
      ),
    );
  }

  mReturnType ??= AlwaysReturnType.fromInstanceMethodOrBuiltin(
    ctx,
    isStatic ? staticType! : L.type,
    staticMemberName,
    argTypes,
    namedArgTypes,
    $static: isStatic,
  );

  final v = Variable.of(
    ctx,
    result,
    mReturnType?.type?.copyWith(boxed: true) ?? CoreTypes.dynamic.ref(ctx),
  );

  return v;
}

Map<String, TypeRef> _bridgeClassTypeArguments(
  CompilerContext ctx,
  TypeRef receiver,
  int declarationLibrary,
) {
  final resolved = receiver.resolveTypeChain(ctx);
  final declaration =
      ctx.topLevelDeclarationsMap[declarationLibrary]?[resolved.name];
  final bridge = declaration?.bridge;
  if (bridge is! BridgeClassDef) return const {};
  final names = bridge.type.generics.keys.toList();
  return {
    for (
      var index = 0;
      index < names.length && index < resolved.specifiedTypeArgs.length;
      index++
    )
      names[index]: resolved.specifiedTypeArgs[index],
  };
}

void _inferBridgeTypeParameters(
  BridgeFunctionDef function,
  List<Variable> arguments,
  Map<String, TypeRef> inferred,
) {
  void infer(BridgeTypeRef formal, TypeRef actual) {
    final reference = formal.ref;
    if (reference != null && function.generics.containsKey(reference)) {
      inferred[reference] = actual;
      return;
    }
    final genericFunction = formal.gft;
    final actualFunction = actual.functionType;
    if (genericFunction != null && actualFunction != null) {
      final actualReturn = actualFunction.returnType.type;
      if (actualReturn != null) {
        infer(genericFunction.returns.type, actualReturn);
      }
      return;
    }
    final formalArguments = formal.typeArgs;
    final actualArguments = actual.specifiedTypeArgs;
    for (
      var index = 0;
      index < formalArguments.length && index < actualArguments.length;
      index++
    ) {
      infer(formalArguments[index].type, actualArguments[index]);
    }
  }

  for (
    var index = 0;
    index < function.params.length && index < arguments.length;
    index++
  ) {
    infer(function.params[index].type.type, arguments[index].type);
  }
}

List<int> _runtimeTypeArguments(CompilerContext ctx, MethodInvocation call) =>
    call.typeArguments?.arguments
        .map((type) => TypeRef.fromAnnotation(ctx, ctx.library, type))
        .map((type) => type.runtimeTypeId(ctx))
        .toList() ??
    const [];

Map<String, TypeRef> _classTypeArguments(
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
  final worklist = <(TypeRef, Map<(String, int), TypeRef>)>[(receiver, {})];
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
              index < current.specifiedTypeArgs.length
              ? current.specifiedTypeArgs[index]
              : CoreTypes.dynamic.ref(ctx),
      };
    }
    final decl =
        ctx.topLevelDeclarationsMap[current.file]?[current.name]?.declaration;
    if (decl == null) continue;
    // Fold the current type's arguments into the substitution map so a
    // `with M<T>` clause resolves `T` to the receiver-provided argument.
    final levelParams = current.resolveTypeChain(ctx).genericParams;
    final nextSubstitutions = {
      ...substitutions,
      for (var index = 0; index < levelParams.length; index++)
        (
          'class:${current.file}:${current.name}',
          index,
        ): index < current.specifiedTypeArgs.length
            ? current.specifiedTypeArgs[index]
            : levelParams[index].extendsType ?? CoreTypes.dynamic.ref(ctx),
    };
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
    final resolved = current.resolveTypeChain(ctx);
    final parent = resolved.extendsType;
    if (parent != null && !parent.hasSameDeclarationAs(current)) {
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
  Map<(String, int), TypeRef> substitutions,
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
    specifiedTypeArgs: [
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


bool _hasBridgeSuperclass(CompilerContext ctx, TypeRef type) {
  for (final parent in type.resolveTypeChain(ctx).extendsChain) {
    final bridge =
        ctx.topLevelDeclarationsMap[parent.file]?[parent.name]?.bridge;
    if (bridge is BridgeClassDef && bridge.bridge) return true;
  }
  return false;
}

/// Whether a call to [method] on a receiver statically known to be [type] can
/// use a fixed offset: the method must be declared on [type] itself and [type]
/// must be neither bridged nor subclassed anywhere in the program (a subclass
/// could override the method, requiring virtual dispatch).
bool _isDirectlyCallable(CompilerContext ctx, TypeRef type, String method) {
  if (_hasBridgeSuperclass(ctx, type) ||
      ctx.subclassedTypes.contains('${type.file}:${type.name}')) {
    return false;
  }
  final methods =
      ctx.instanceDeclarationPositions[type.file]?[type.name]?[2] as Map?;
  return methods?.containsKey(method) == true;
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
  if (instanceType.isTypeParameter) {
    final bound = instanceType.typeParameterBound ?? CoreTypes.dynamic.ref(ctx);
    if (bound == CoreTypes.dynamic.ref(ctx)) {
      throw CompileError(
        'Cannot resolve $methodName on unbounded type parameter $instanceType',
        source,
      );
    }
    return resolveInstanceMethod(
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
    throw StateError(
      'Missing declaration for instance method $methodName on '
      '${instanceType.name} (file ${instanceType.file}, '
      'parameter ${instanceType.typeParameterOwner}:'
      '${instanceType.typeParameterIndex}, key ${instanceType.semanticKey})',
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
      return resolveInstanceMethod(
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
    return resolveInstanceMethod(
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
    return resolveInstanceMethod(
      ctx,
      CoreTypes.object.ref(ctx),
      methodName,
      source,
      bottomType0,
    );
  }
}

/// [resolveInstanceMethod], returning null when [instanceType] and its chain
/// lack [methodName] instead of throwing.
DeclarationOrBridge<ClassMember, BridgeMethodDef>?
_tryResolveInstanceMethod(
  CompilerContext ctx,
  TypeRef instanceType,
  String methodName,
  AstNode? source,
  TypeRef bottomType0,
) {
  try {
    return resolveInstanceMethod(
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
          .file]!['${classType.name}.$methodName'];
  if (method != null) {
    if (method.declaration != null) {
      final member = method.declaration!;
      return DeclarationOrBridge(
        classType.file,
        declaration:
            member is VariableDeclaration
                ? member.parent!.parent as ClassMember
                : member as ClassMember,
      );
    } else {
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

/// The result of [_compileNonBridgeArgs].
class _ResolvedArgs {
  _ResolvedArgs(
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
_ResolvedArgs _compileNonBridgeArgs(
  CompilerContext ctx,
  int sourceLib,
  Declaration dec,
  ArgumentList argumentList, {
  List<Variable> before = const [],
  TypeArgumentList? typeArguments,
  AstNode? source,
  Map<String, TypeRef> seedGenerics = const {},
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
      ClassDeclaration() ||
      MixinDeclaration() ||
      ClassTypeAlias() => classLikeClauses(owner as Declaration).$4?.typeParameters,
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

  final argsPair = compileArgumentList(
    ctx,
    argumentList,
    sourceLib,
    fpl,
    dec,
    before: before,
    source: source,
    resolveGenerics: resolveGenerics,
    // Only function/method declarations take explicit type arguments at the
    // call site; constructor calls infer regardless (e.g. List<int>() still
    // infers the constructor's own generics).
    inferGenerics: !isCallableDecl || typeArguments == null,
  );

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
  return _ResolvedArgs(
    argsPair,
    returnType,
    boxedBySubstitution,
    resolveGenerics,
    classParams,
  );
}

/// `super.<name>` must dispatch to a concrete implementation: an abstract
/// declaration in the searched layer is a compile-time error.
void _checkConcreteSuperMember(
  Declaration? member,
  String memberName,
  AstNode source,
) {
  if (member is MethodDeclaration && member.body is EmptyFunctionBody) {
    throw CompileError(
      'Super-invoked member "$memberName" has no concrete implementation',
      source,
    );
  }
}
