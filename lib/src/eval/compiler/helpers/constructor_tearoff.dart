import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../invocation/bound_call.dart';
import '../invocation/deferred.dart';
import '../invocation/targets.dart';
import '../member/call_signature.dart';
import '../type.dart';
import '../values/abi.dart';
import '../variable.dart';
import '../variable/value_facts.dart';
import '../../ir/closures.dart';
import '../../ir/flow.dart';
import '../../ir/function.dart' as ir;
import 'const.dart';
import 'default_value.dart';
import 'tearoff.dart';

CallSignature constructorTearOffSignature(
  CompilerContext ctx,
  TypeRef type,
  ConstructorDeclaration? constructor,
) {
  final owner = nominalDeclOf(type)!;
  if (owner is SourceTypeDecl && owner.kind == TypeDeclKind.extensionType) {
    final parameter = owner.extensionRepresentationParameter!;
    return CallSignature(
      positional: [
        ParameterSpec(
          parameter.name!.lexeme,
          owner.extensionRepresentation!,
          isRequired: true,
          node: parameter,
        ),
      ],
      requiredPositional: 1,
      returnType: type,
    );
  }
  final generic = interfaceArgumentsOf(type).isEmpty;
  final result = generic ? owner.thisType : type;
  final declared = constructor == null
      ? CallSignature.returnOnly(result)
      : CallSignature.forDeclaration(ctx, type.file, constructor);
  final substitution = Substitution.of({
    if (!generic)
      for (var i = 0; i < owner.typeParameters.length; i++)
        owner.typeParameters[i]: interfaceArgumentsOf(type)[i],
  });
  return CallSignature(
    typeParameters: generic ? owner.typeParameters : const [],
    positional: [
      for (final parameter in declared.positional)
        parameter.substitute(substitution),
    ],
    requiredPositional: declared.requiredPositional,
    named: [
      for (final parameter in declared.named)
        parameter.substitute(substitution),
    ],
    returnType: result,
  );
}

/// Constructors have a hidden type argument or factory type environment.
/// A shared wrapper supplies it while retaining the constructor's native ABI.
Variable materializeConstructorTearOff(
  CompilerContext ctx,
  TypeRef type,
  String key,
  ConstructorDeclaration? constructor, {
  TypeRef? boundContext,
}) {
  final signature = constructorTearOffSignature(ctx, type, constructor);
  final functionType = signature.toFunctionType(ctx);
  final declared = constructor == null
      ? signature
      : CallSignature.forDeclaration(ctx, type.file, constructor);
  final parameters = [...signature.positional, ...signature.named];
  final declaredParameters = [...declared.positional, ...declared.named];
  final extensionType = nominalDeclOf(type)?.kind == TypeDeclKind.extensionType;
  final abi = constructor == null
      ? CallableAbi.fromParameterTypes(
          [for (final parameter in declaredParameters) parameter.type],
          signature.returnType,
          extensionType ? CallableKind.function : CallableKind.constructor,
        )
      : CallableAbi.ofConstructor(ctx, constructor, [
          for (final parameter in declaredParameters) parameter.type,
        ], hiddenTypeId: false);
  (Object?, int) parameterDefault(ParameterSpec parameter) {
    final (value, thunk) = compileParameterDefault(
      ctx,
      type.file,
      parameter.node!,
      bound: parameter.type,
    );
    return (
      value is int && parameter.type.isSpec(CoreTypes.double)
          ? value.toDouble()
          : value,
      thunk,
    );
  }

  final defaults = parameters.map(parameterDefault).toList();
  final adapterKey =
      'constructor:${type.file}:$key:${ctx.runtimeTypes.idOf(functionType)}';
  var functionId = ctx.instantiatedAdapterIds[adapterKey];
  if (functionId == null) {
    final outer = NestedFunctionState(ctx);
    try {
      ctx.finishMethod();
      outer.resumeAfterFlush();
      ctx.labels.clear();
      ctx.caughtExceptionTargets.clear();
      functionId = ctx.beginFunction('<constructor tear-off $key>');
      ctx.instantiatedAdapterIds[adapterKey] = functionId;
      ctx.locals = [];
      ctx.exceptionDepth = 0;
      ctx.beginScope();
      ctx.functionSignatures[functionId] = abi.machine;
      ctx.functionParameterTypes[functionId] = [
        for (final parameter in parameters) parameter.type,
      ];
      ctx.functionTypeParameters[functionId] = signature.typeParameters;
      ctx.functionRuntimeTypes[functionId] = functionType;
      final arguments = <Variable>[];
      for (var i = 0; i < parameters.length; i++) {
        final argument = SSA('arg_$i');
        ctx.pushOp(ir.Parameter(argument, i));
        arguments.add(
          Variable.of(
            ctx,
            argument,
            parameters[i].type,
            rep: abi.parameters[i],
          ),
        );
      }
      final result = extensionType
          ? arguments.single.toRep(ctx, abi.result!).copyWith(type: type)
          : ConstructorCall(
              staticType: type,
              instantiatedType: signature.returnType,
              offset: DeferredOrOffset(file: type.file, name: key),
              constructor: constructor,
              implicitDefault: constructor == null,
            ).emit(
              ctx,
              BoundCall(
                positional: arguments
                    .take(signature.positional.length)
                    .toList(),
                named: [
                  for (var i = 0; i < signature.named.length; i++)
                    (
                      signature.named[i].name,
                      arguments[signature.positional.length + i],
                    ),
                ],
                returnType: signature.returnType,
              ),
            );
      ctx.pushOp(Return(result.ssa));
      ctx.endScope();
      ctx.finishMethod();
    } finally {
      outer.restore();
    }
  }
  final created = Variable.ssa(
    ctx,
    CreateClosure(
      ctx.svar('constructor_tearoff'),
      DeferredOrOffset(offset: functionId),
      const [],
      hasEnvironment: false,
      requiredPositional: signature.requiredPositional,
      positionalCount: signature.positional.length,
      namedNames: [for (final parameter in signature.named) parameter.name],
      positionalDefaults: [
        for (final value in defaults.take(signature.positional.length))
          value.$1,
      ],
      namedDefaults: [
        for (final value in defaults.skip(signature.positional.length))
          value.$1,
      ],
      defaultThunks: [for (final value in defaults) value.$2],
      requiredNamed: [
        for (final parameter in signature.named)
          if (parameter.isRequired) parameter.name,
      ],
      positionalUnboxed: [
        for (final representation in abi.parameters.take(
          signature.positional.length,
        ))
          !representation.isBoxed,
      ],
      namedUnboxed: [
        for (final representation in abi.parameters.skip(
          signature.positional.length,
        ))
          !representation.isBoxed,
      ],
      runtimeTypeId: ctx.runtimeTypes.idOf(functionType),
    ),
    functionType,
    facts: ValueFacts(callableSignature: signature),
  );
  return instantiateRuntimeCallable(
    ctx,
    internConst(ctx, created, functionType),
    boundContext: boundContext,
    positionalDefaults: defaults.take(signature.positional.length).toList(),
    namedDefaults: {
      for (var i = 0; i < signature.named.length; i++)
        signature.named[i].name: defaults[signature.positional.length + i],
    },
  );
}
