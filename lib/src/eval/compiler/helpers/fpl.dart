// Formal-parameter-list helpers: normalizing positional/named parameter
// ordering, assigning argument slots, and resolving declared types.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/helpers/default_value.dart';
import 'package:dart_eval/src/eval/compiler/member/member.dart';
import 'package:dart_eval/src/eval/compiler/member/member_name.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import '../values/abi.dart';

/// Normalizes a formal parameter list into dart_eval's calling convention —
/// positional parameters first (sorted named parameters last when [sortNamed]),
/// records the parameters and their declared types on [ctx], emits a
/// [Parameter] op for each, and returns the parameters in call order.
List<FormalParameter> resolveFPLDefaults(
  CompilerContext ctx,
  FormalParameterList? fpl,
  bool isInstanceMethod, {
  bool allowUnboxed = true,
  bool sortNamed = false,
  bool ignoreDefaults = false,
  bool isEnum = false,
  int parameterOffset = 0,
  Declaration? parameterHost,
  int? decLibrary,
  Map<String, TypeRef> typeParameters = const {},
}) {
  final normalized = <FormalParameter>[];
  var hasEncounteredOptionalPositionalParam = false;
  var hasEncounteredNamedParam = false;
  var paramIndex = parameterOffset + (isEnum ? 2 : (isInstanceMethod ? 1 : 0));

  final named = <FormalParameter>[];
  final positional = <FormalParameter>[];

  for (final param in fpl?.parameters ?? <FormalParameter>[]) {
    if (param.isNamed) {
      if (hasEncounteredOptionalPositionalParam) {
        throw CompileError(
          'Cannot mix named and optional positional parameters',
        );
      }
      hasEncounteredNamedParam = true;
      named.add(param);
    } else {
      if (param.isOptionalPositional) {
        if (hasEncounteredNamedParam) {
          throw CompileError(
            'Cannot mix named and optional positional parameters',
          );
        }
        hasEncounteredOptionalPositionalParam = true;
      }
      positional.add(param);
    }
  }

  if (sortNamed) {
    named.sort((a, b) => (a.name!.lexeme).compareTo(b.name!.lexeme));
  }

  ctx.functionParameters[ctx.currentFunctionId!] = [...positional, ...named];
  // Non-scalar defaults need hidden thunk functions, which must be emitted
  // while this function is still being compiled — closures, call sites, and
  // exports all share the cached indices afterwards.
  for (final param in [...positional, ...named]) {
    // The declared parameter type is the default value's context type.
    var bound = param.type == null
        ? null
        : ctx.typeFactory.formalParameterAnnotationType(
            decLibrary ?? ctx.library,
            param,
            typeParameters: typeParameters,
          );
    if (bound == null && parameterHost != null) {
      bound = getFormalParameterType(
        ctx,
        param,
        decLibrary ?? ctx.library,
        parameterHost,
        typeParameters: typeParameters,
      ).$1;
    }
    compileParameterDefault(ctx, ctx.library, param, bound: bound);
  }
  final declaredTypes = <TypeRef>[];

  for (final param in [...positional, ...named]) {
    final argument = SSA('arg_$paramIndex');
    final annotation = param.type;
    var declaredType = annotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : ctx.typeFactory.formalParameterAnnotationType(
            decLibrary ?? ctx.library,
            param,
            typeParameters: typeParameters,
          );
    if (annotation == null && parameterHost != null) {
      // Field and super formal parameters may omit their type, which then
      // comes from the target field or super-parameter.
      declaredType =
          getFormalParameterType(
            ctx,
            param,
            decLibrary ?? ctx.library,
            parameterHost,
            typeParameters: typeParameters,
          ).$1 ??
          declaredType;
    }
    declaredTypes.add(declaredType);
    final paramRep = Abi.parameter(
      declaredType,
      allowUnboxed ? CallableKind.function : CallableKind.method,
    );
    ctx.pushOp(Parameter(argument, paramIndex, representation: paramRep.bank));
    // Callers bind omitted arguments before entering typed registers. Null is
    // an actual argument value and must never act as a missing-value sentinel.
    normalized.add(param);
    paramIndex++;
  }
  ctx.functionParameterTypes[ctx.currentFunctionId!] = declaredTypes;
  return normalized;
}

(TypeRef?, TypeAnnotation?) getFormalParameterType(
  CompilerContext ctx,
  FormalParameter param,
  int decLibrary,
  Declaration? parameterHost, {
  Map<String, TypeRef> typeParameters = const {},
}) {
  if (param is RegularFormalParameter) {
    final type = param.type;
    if (type != null) {
      return (
        ctx.typeFactory.formalParameterAnnotationType(
          decLibrary,
          param,
          typeParameters: typeParameters,
        ),
        type,
      );
    }
    // An unwritten parameter type on an instance method is inherited from
    // the overridden member's signature (Dart's override inference).
    return (
      _inheritedParameterType(ctx, param, decLibrary, parameterHost),
      null,
    );
  } else if (param is FieldFormalParameter) {
    return (
      resolveFieldFormalType(ctx, decLibrary, param, parameterHost!),
      null,
    );
  } else if (param is SuperFormalParameter) {
    return (
      resolveSuperFormalType(ctx, decLibrary, param, parameterHost!),
      null,
    );
  } else {
    throw CompileError('Unknown formal type ${param.runtimeType}');
  }
}

/// The overridden member's type for [param] — Dart's override inference
/// binds an unannotated instance-method parameter to the type the combined
/// superinterface signature declares at the same position.
TypeRef? _inheritedParameterType(
  CompilerContext ctx,
  FormalParameter param,
  int decLibrary,
  Declaration? parameterHost,
) {
  final list = param.parent;
  final method = list?.parent;
  if (list is! FormalParameterList ||
      method is! MethodDeclaration ||
      method.isStatic ||
      parameterHost == null) {
    return null;
  }
  final kind = method.isGetter
      ? MemberKind.getter
      : method.isSetter
      ? MemberKind.setter
      : MemberKind.method;
  final decl = ctx.types.find(decLibrary, declarationName(parameterHost));
  if (decl == null) return null;
  final signature = inheritedMemberSignature(
    ctx,
    decl,
    MemberName(method.name.lexeme, kind),
  );
  if (signature == null) return null;
  if (param.isNamed) {
    for (final spec in signature.named) {
      if (spec.name == param.name?.lexeme) return spec.type;
    }
    return null;
  }
  var index = 0;
  for (final other in list.parameters) {
    if (identical(other, param)) {
      return index < signature.positional.length
          ? signature.positional[index].type
          : null;
    }
    if (other.isPositional) index++;
  }
  return null;
}
