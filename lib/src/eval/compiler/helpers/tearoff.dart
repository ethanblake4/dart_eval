import 'const.dart';
import 'default_value.dart';
import 'extension.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import '../member/call_signature.dart';
import '../values/abi.dart';
import '../variable/value_facts.dart';
import '../member/member_name.dart';
import '../invocation/deferred.dart';
import '../../ir/function.dart' as ir;
import '../../ir/flow.dart';
import '../../ir/bridge.dart';
import '../../ir/representation.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';

/// Materializes a declaration's function reference. When [boundContext] supplies a
/// [FunctionTypeRef] (the assignment's destination type), a generic
/// callable's own type parameters instantiate through a compiler-generated
/// adapter.
Variable materializeTearOff(
  CompilerContext ctx,
  DeferredOrOffset offset, {
  Variable? implicitReceiver,
  TypeRef? boundContext,
  List<TypeRef>? typeArguments,
  Map<String, TypeRef>? memberTypeParameters,
}) {
  final Declaration declaration;
  if (offset.className != null) {
    // Position tables qualify private names as `uri::_x`; the declaration
    // map stores the raw `_x` — probe both spellings.
    final classMap =
        ctx.instanceDeclarationsMap[offset.file]![offset.className!]!;
    declaration = (classMap[offset.name] ??
            classMap[offset.name!.split('::').last])!
        as MethodDeclaration;
  } else {
    final declared = ctx.topLevelDeclarationsMap[offset.file]?[offset.name];
    if (declared == null) {
      throw CompileError(
        'Cannot tear off unresolved member ${offset.name} (file ${offset.file})',
      );
    }
    if (declared.isBridge) {
      return _bridgeTearOff(ctx, offset, declared, boundContext: boundContext, typeArguments: typeArguments);
    }
    declaration = declared.declaration!;
  }
  final parameters = switch (declaration) {
    MethodDeclaration() => declaration.parameters,
    ConstructorDeclaration() => declaration.parameters,
    _ => (declaration as FunctionDeclaration).functionExpression.parameters,
  };
  final positional =
      parameters?.parameters.where((param) => param.isPositional).toList() ??
      <FormalParameter>[];
  final named =
      parameters?.parameters.where((param) => param.isNamed).toList() ??
      <FormalParameter>[];
  var functionId = offset.offset;
  if (functionId == null) {
    if (offset.className == null) {
      final positions = ctx.topLevelDeclarationPositions[offset.file];
      if (positions != null && offset.name != null) {
        functionId = positions[offset.name];
      }
    } else {
      final classes = ctx.instanceDeclarationPositions[offset.file];
      final memberGroups = classes == null ? null : classes[offset.className];
      functionId = memberGroups == null
          ? null
          : memberGroups[MemberKind.method]?[offset.name];
    }
  }
  final parameterTypes = functionId == null
      ? const <TypeRef>[]
      : ctx.functionParameterTypes[functionId] ?? const <TypeRef>[];
  final allParameters = [...positional, ...named];
  final parameterTypeByNode = <FormalParameter, TypeRef>{
    for (
      var index = 0;
      index < allParameters.length && index < parameterTypes.length;
      index++
    )
      allParameters[index]: parameterTypes[index],
  };
  // Class member tear-offs resolve the class's own type parameters as
  // uninstantiated references (`L.foo` on `class L<T>` keeps `T`); a
  // generic function's own parameters stay resolvable too (`f<X>(X x)`).
  final memberHost = switch (declaration) {
    MethodDeclaration() => declaration.parent?.parent,
    ConstructorDeclaration() => declaration.parent?.parent,
    _ => null,
  };
  // An extension member's host is the extension; its type parameters bind
  // to the `on` bindings of the tear-off receiver, not the enclosing class.
  final memberExt = declaration is MethodDeclaration && !declaration.isStatic
      ? extensionOfMember(ctx, declaration)
      : null;
  final memberParams = <String, TypeRef>{
    if (memberTypeParameters != null)
      ...memberTypeParameters
    else if (memberExt != null && implicitReceiver != null)
      ...memberExtParams(ctx, memberExt, implicitReceiver.type)
    else if (memberHost is Declaration)
      ...classTypeParameterRefs(
        ctx,
        offset.file ?? ctx.library,
        declarationName(memberHost),
        classLikeClauses(memberHost).$4,
      ),
  };
  final ownTypeParams =
      (switch (declaration) {
        MethodDeclaration() => declaration.typeParameters,
        FunctionDeclaration() => declaration.functionExpression.typeParameters,
        _ => null,
      })?.typeParameters ??
      const <TypeParameter>[];
  final callableOwner = TypeParameterOwner(
    TypeParameterOwnerKind.tearOff,
    offset.file ?? ctx.library,
    memberHost is Declaration
        ? '${declarationName(memberHost)}.${offset.name ?? ''}'
        : offset.name ?? '',
    declaration.offset,
  );
  declareTypeParameters(ctx, callableOwner, ownTypeParams, memberParams);

  TypeRef parameterType(FormalParameter parameter) {
    final compiledType = parameterTypeByNode[parameter];
    if (compiledType != null) return compiledType;
    final annotation = parameter.type;
    return annotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : ctx.typeFactory.formalParameterAnnotationType(
            offset.file ?? ctx.library,
            parameter,
            typeParameters: memberParams,
          );
  }

  (Object?, int) parameterDefault(FormalParameter parameter) {
    final (value, thunk) = compileParameterDefault(
      ctx,
      offset.file ?? ctx.library,
      parameter,
      bound: parameterType(parameter),
    );
    return (
      value is int && parameterType(parameter).isSpec(CoreTypes.double)
          ? value.toDouble()
          : value,
      thunk,
    );
  }

  final functionType = switch (declaration) {
    MethodDeclaration() => ctx.typeFactory.declaredFunctionType(
      offset.file ?? ctx.library,
      declaration.parameters,
      declaration.returnType,
      declaration.typeParameters,
      memberTypeParameters: memberParams,
      ownTypeParameterOwner: callableOwner,
    ),
    FunctionDeclaration() => ctx.typeFactory.declaredFunctionType(
      offset.file ?? ctx.library,
      declaration.functionExpression.parameters,
      declaration.returnType,
      declaration.functionExpression.typeParameters,
      memberTypeParameters: memberParams,
      ownTypeParameterOwner: callableOwner,
    ),
    ConstructorDeclaration() => ctx.typeFactory.declaredFunctionType(
      offset.file ?? ctx.library,
      declaration.parameters,
      null,
      null,
      memberTypeParameters: memberParams,
    ),
    _ => CoreTypes.function.ref(ctx),
  };

  final captures = <SSA>[];
  if (declaration is MethodDeclaration && !declaration.isStatic) {
    final receiver = implicitReceiver != null
        ? implicitReceiver.boxIfNeeded(ctx).ssa
        : ctx.lookupBinding('#this')?.read(ctx).ssa;
    if (receiver == null) {
      throw CompileError('Missing receiver for method tearoff');
    }
    captures.add(receiver);
  }
  final callableAbi = CallableAbi.fromParameterTypes(
    [for (final parameter in allParameters) parameterType(parameter)],
    functionType is FunctionTypeRef
        ? functionType.signature.returnType
        : CoreTypes.dynamic.ref(ctx),
    declaration is FunctionDeclaration
        ? CallableKind.function
        : CallableKind.method,
    leadingBoxed: declaration is MethodDeclaration && !declaration.isStatic
        ? 1
        : 0,
  );
  final parameterOffset =
      declaration is MethodDeclaration && !declaration.isStatic ? 1 : 0;
  final positionalDefaults = positional.map(parameterDefault).toList();
  final namedDefaults = named.map(parameterDefault).toList();
  final created = Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('tearoff'),
      offset,
      captures,
      requiredPositional: positional.where((param) => param.isRequired).length,
      positionalCount: positional.length,
      namedNames: named.map((param) => param.name!.lexeme).toList(),
      hasEnvironment: false,
      positionalDefaults: [for (final d in positionalDefaults) d.$1],
      namedDefaults: [for (final d in namedDefaults) d.$1],
      defaultThunks: [
        for (final d in positionalDefaults) d.$2,
        for (final d in namedDefaults) d.$2,
      ],
      requiredNamed: [
        for (final parameter in named)
          if (parameter.isRequired) parameter.name!.lexeme,
      ],
      boundReceiver: declaration is MethodDeclaration && !declaration.isStatic,
      positionalUnboxed: [
        for (var i = 0; i < positional.length; i++)
          !callableAbi.parameters[i + parameterOffset].isBoxed,
      ],
      namedUnboxed: [
        for (var i = 0; i < named.length; i++)
          !callableAbi
              .parameters[i + positional.length + parameterOffset]
              .isBoxed,
      ],
      runtimeTypeId: ctx.runtimeTypes.idOf(functionType),
    ),
    functionType,
    facts: ValueFacts(
      callableSignature: CallSignature.returnOnly(
        functionType is FunctionTypeRef
            ? functionType.signature.returnType
            : CoreTypes.dynamic.ref(ctx),
      ),
    ),
  );
  // A captureless tear-off is a constant: the VM canonicalizes them, so
  // `identical(main, main)` is true.
  final callable = captures.isEmpty
      ? internConst(ctx, created, functionType)
      : created;
  // An extension member's callable environment leads with the extension's
  // own bindings (`[ext bindings..., method args...]`), which the runtime
  // adapter must forward alongside the method's instantiated arguments.
  final envTypeArguments = memberExt == null
      ? const <TypeRef>[]
      : [
          for (final parameter
              in memberExt.declaration.typeParameters?.typeParameters ??
                  const <TypeParameter>[])
            memberParams[parameter.name.lexeme] ??
                CoreTypes.dynamic.ref(ctx),
        ];
  return instantiateRuntimeCallable(
    ctx,
    callable,
    boundContext: boundContext,
    typeArguments: typeArguments,
    envTypeArguments: envTypeArguments,
    positionalDefaults: positionalDefaults,
    namedDefaults: {
      for (var i = 0; i < named.length; i++)
        if (named[i].name != null) named[i].name!.lexeme: namedDefaults[i],
    },
  );
}

/// Materializes a bridged (host-registered) function reference as a
/// captureless adapter closure whose body forwards its arguments to
/// `InvokeExternal`. Being captureless, the tear-off canonicalizes like any
/// other constant function reference.
Variable _bridgeTearOff(
  CompilerContext ctx,
  DeferredOrOffset offset,
  DeclarationOrBridge declared, {
  TypeRef? boundContext,
  List<TypeRef>? typeArguments,
}) {
  final bridge = declared.bridge! as BridgeFunctionDeclaration;
  final functionDef = bridge.function;
  final file = offset.file ?? ctx.library;
  final externalIndex = ctx.bridgeStaticFunctionIndices[file]?[offset.name];
  if (externalIndex == null) {
    throw CompileError('Cannot tear off unregistered bridged function ${offset.name}');
  }
  final functionType = CallSignature.bridge(
    ctx,
    functionDef,
    returnFallback: CoreTypes.dynamic.ref(ctx),
  ).toFunctionType(ctx);
  final positional = functionDef.params;
  final named = functionDef.namedParams;
  final outer = NestedFunctionState(ctx);
  late final int functionId;
  try {
    ctx.finishMethod();
    outer.resumeAfterFlush();
    ctx.labels.clear();
    ctx.caughtExceptionTargets.clear();
    functionId = ctx.beginFunction('<bridge function adapter>');
    ctx.locals = [];
    ctx.exceptionDepth = 0;
    ctx.beginScope();
    ctx.functionSignatures[functionId] = MachineFunctionSignature(
      List.filled(
        positional.length + named.length,
        MachineRepresentation.object,
      ),
      MachineRepresentation.object,
    );
    final args = <SSA>[];
    for (var i = 0; i < positional.length + named.length; i++) {
      final arg = SSA('arg_$i');
      ctx.pushOp(ir.Parameter(arg, i));
      args.add(arg);
    }
    final result = ctx.svar('bridge_result');
    ctx.pushOp(InvokeExternal(result, externalIndex, args));
    ctx.pushOp(Return(result));
    ctx.endScope();
    ctx.finishMethod();
  } finally {
    outer.restore();
  }
  final created = Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('tearoff'),
      DeferredOrOffset(offset: functionId),
      const [],
      hasEnvironment: false,
      requiredPositional: positional.where((p) => !p.optional).length,
      positionalCount: positional.length,
      namedNames: [for (final p in named) p.name],
      requiredNamed: [for (final p in named) if (!p.optional) p.name],
      runtimeTypeId: ctx.runtimeTypes.idOf(functionType),
    ),
    functionType,
    facts: ValueFacts(
      callableSignature: CallSignature.returnOnly(
        functionType.signature.returnType,
      ),
    ),
  );
  final callable = internConst(ctx, created, functionType);
  return instantiateRuntimeCallable(
    ctx,
    callable,
    boundContext: boundContext,
    typeArguments: typeArguments,
  );
}

/// Specializes a runtime generic callable while retaining runtime dispatch.
/// The adapter captures the evaluated callable and forwards its arguments with
/// the selected type arguments, so a method override remains authoritative.
Variable instantiateRuntimeCallable(
  CompilerContext ctx,
  Variable value, {
  TypeRef? boundContext,
  List<TypeRef>? typeArguments,
  List<TypeRef> envTypeArguments = const [],
  List<(Object?, int)> positionalDefaults = const [],
  Map<String, (Object?, int)> namedDefaults = const {},
}) {
  final type = value.type;
  if (type is! FunctionTypeRef ||
      type.signature.typeParameters.isEmpty ||
      (typeArguments == null && boundContext is! FunctionTypeRef)) {
    return value;
  }
  if (typeArguments == null &&
      boundContext is FunctionTypeRef &&
      boundContext.signature.typeParameters.isNotEmpty) {
    return value;
  }
  final signature = type.signature;
  final bindings = <TypeParameterDef, TypeRef>{};
  if (typeArguments != null) {
    if (typeArguments.length != signature.typeParameters.length) {
      throw CompileError('Wrong number of function type arguments');
    }
    for (var i = 0; i < typeArguments.length; i++) {
      bindings[signature.typeParameters[i]] = typeArguments[i];
    }
  } else {
    ctx.typeSystem.unify(type, boundContext!, bindings);
    if (signature.typeParameters.any((p) => bindings[p] == null)) return value;
  }
  // The adapter forwards optional parameters through its own defaults, which
  // only a fresh tear-off can supply — instantiating a stored closure loses
  // that provenance and can't model them.
  final hasOptionals =
      signature.requiredPositional != signature.positional.length ||
      signature.named.values.any((parameter) => !parameter.required);
  if (hasOptionals &&
      (positionalDefaults.length != signature.positional.length ||
          namedDefaults.length != signature.named.length)) {
    throw CompileError(
      'Instantiating a runtime function with optional parameters is not supported',
    );
  }
  final substitution = Substitution.of(bindings);
  final instantiated = FunctionTypeRef(
    FunctionSignature(
      positional: [
        for (final parameter in signature.positional)
          parameter.substituteTypeParameters(substitution),
      ],
      requiredPositional: signature.requiredPositional,
      named: {
        for (final entry in signature.named.entries)
          entry.key: (
            type: entry.value.type.substituteTypeParameters(substitution),
            required: entry.value.required,
          ),
      },
      returnType: signature.returnType.substituteTypeParameters(substitution),
    ),
    decl: type.decl,
  );
  final argumentIds = [
    for (final type in envTypeArguments) ctx.runtimeTypes.idOf(type),
    for (final parameter in signature.typeParameters)
      ctx.runtimeTypes.idOf(bindings[parameter]!),
  ];
  final named = instantiated.signature.named.keys.toList()..sort();
  final parameters = [
    ...instantiated.signature.positional,
    for (final name in named) instantiated.signature.named[name]!.type,
  ];

  // Identical instantiations share the adapter — the interned closure keys
  // on (functionId, captures), so `f<int>` at two sites canonicalizes.
  final adapterKey =
      '${ctx.runtimeTypes.idOf(instantiated)}:${argumentIds.join(',')}';
  var functionId = ctx.instantiatedAdapterIds[adapterKey];
  if (functionId == null) {
    final outer = NestedFunctionState(ctx);
    try {
      // Flush the outer block before compiling the adapter, preserving its builder.
      ctx.finishMethod();
      outer.resumeAfterFlush();
      ctx.labels.clear();
      ctx.caughtExceptionTargets.clear();
      functionId = ctx.beginFunction('<generic function adapter>');
      ctx.instantiatedAdapterIds[adapterKey] = functionId;
      ctx.locals = [];
      ctx.exceptionDepth = 0;
      ctx.beginScope();
      ctx.functionSignatures[functionId] = MachineFunctionSignature(
        List.filled(parameters.length + 1, MachineRepresentation.object),
        MachineRepresentation.object,
      );
      ctx.functionParameterTypes[functionId] = parameters;
      ctx.functionRuntimeTypes[functionId] = instantiated;
    ctx.pushOp(ir.Parameter(SSA('arg_0'), 0));
    final captured = ctx.svar('generic_function');
    ctx.pushOp(LoadCapture(captured, 0));
    final arguments = <SSA>[];
    for (var i = 0; i < parameters.length; i++) {
      final argument = SSA('arg_${i + 1}');
      ctx.pushOp(ir.Parameter(argument, i + 1));
      arguments.add(argument);
    }
    final result = ctx.svar('instantiated_result');
    ctx.pushOp(
      InvokeClosure(
        result,
        captured,
        arguments.take(signature.positional.length).toList(),
        {
          for (var i = 0; i < named.length; i++)
            named[i]: arguments[signature.positional.length + i],
        },
        typeArguments: argumentIds,
      ),
    );
    ctx.pushOp(Return(result));
    ctx.endScope();
    ctx.finishMethod();
    } finally {
      outer.restore();
    }
  }
  return internConst(ctx, Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('instantiated_function'),
      DeferredOrOffset(offset: functionId),
      [value.ssa],
      isInstantiationAdapter: true,
      requiredPositional: signature.requiredPositional,
      positionalCount: signature.positional.length,
      namedNames: named,
      positionalDefaults: [for (final d in positionalDefaults) d.$1],
      namedDefaults: [for (final name in named) namedDefaults[name]?.$1],
      defaultThunks: [
        for (final d in positionalDefaults) d.$2,
        for (final name in named) namedDefaults[name]?.$2 ?? -1,
      ],
      requiredNamed: [
        for (final name in named)
          if (instantiated.signature.named[name]!.required) name,
      ],
      runtimeTypeId: ctx.runtimeTypes.idOf(instantiated),
    ),
    instantiated,
    facts: ValueFacts(
      callableSignature: CallSignature.returnOnly(
        instantiated.signature.returnType,
      ),
    ),
  ), instantiated);
}
