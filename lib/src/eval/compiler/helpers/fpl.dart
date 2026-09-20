// Formal-parameter-list helpers: normalizing positional/named parameter
// ordering, assigning argument slots, and resolving declared types.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart'
    show representationForType;
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

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
  final declaredTypes = <TypeRef>[];

  for (final param in [...positional, ...named]) {
    final argument = SSA('arg_$paramIndex');
    final annotation = param.type;
    final declaredType = annotation == null
        ? CoreTypes.dynamic.ref(ctx)
        : TypeRef.fromAnnotation(ctx, ctx.library, annotation);
    declaredTypes.add(declaredType);
    final type = !allowUnboxed
        ? declaredType.copyWith(boxed: true)
        : declaredType;
    ctx.pushOp(
      Parameter(
        argument,
        paramIndex,
        representation: representationForType(
          type.copyWith(
            boxed: !allowUnboxed || !type.isUnboxedAcrossFunctionBoundaries,
          ),
        ),
      ),
    );
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
    return type == null
        ? (null, null)
        : (
            TypeRef.fromAnnotation(
              ctx,
              decLibrary,
              type,
              typeParameters: typeParameters,
            ),
            type,
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
