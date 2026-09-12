import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/ir/function.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/ir/primitives.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/helpers/invoke.dart';
import 'package:dart_eval/src/eval/compiler/macros/branch.dart';
import 'package:dart_eval/src/eval/compiler/statement/statement.dart';

List<PossiblyValuedParameter> resolveFPLDefaults(
  CompilerContext ctx,
  FormalParameterList? fpl,
  bool isInstanceMethod, {
  bool allowUnboxed = true,
  bool sortNamed = false,
  bool ignoreDefaults = false,
  bool isEnum = false,
}) {
  final normalized = <PossiblyValuedParameter>[];
  var hasEncounteredOptionalPositionalParam = false;
  var hasEncounteredNamedParam = false;
  var paramIndex = isEnum ? 2 : (isInstanceMethod || sortNamed ? 1 : 0);

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

  for (final param in [...positional, ...named]) {
    final argument = SSA('arg_$paramIndex');
    ctx.pushOp(Parameter(argument, paramIndex));
    if (param is DefaultFormalParameter) {
      Variable? defaultValue;
      if (param.defaultValue != null && !ignoreDefaults) {
        macroBranch(
          ctx,
          null,
          condition: (ctx) => Variable.of(
            ctx,
            argument,
            CoreTypes.dynamic.ref(ctx),
          ).invoke(ctx, '==', [BuiltinValue().push(ctx)]).result,
          thenBranch: (ctx, _) {
            var value = compileExpression(param.defaultValue!, ctx);
            value =
                !allowUnboxed || !value.type.isUnboxedAcrossFunctionBoundaries
                ? value.boxIfNeeded(ctx)
                : value.unboxIfNeeded(ctx);
            ctx.pushOp(Assign(argument, value.ssa));
            defaultValue = value;
            return StatementInfo(-1);
          },
        );
      } else if (param.defaultValue == null) {
        ctx.pushOp(MaybeBoxNull(argument, argument));
      }
      normalized.add(PossiblyValuedParameter(param.parameter, defaultValue));
    } else {
      normalized.add(
        PossiblyValuedParameter(param as NormalFormalParameter, null),
      );
    }
    paramIndex++;
  }
  return normalized;
}

(TypeRef?, TypeAnnotation?) getFormalParameterType(
  CompilerContext ctx,
  FormalParameter param,
  int decLibrary,
  Declaration? parameterHost,
) {
  if (param is SimpleFormalParameter) {
    final type = param.type;
    return type == null
        ? (null, null)
        : (TypeRef.fromAnnotation(ctx, decLibrary, type), type);
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
  } else if (param is DefaultFormalParameter) {
    final p = param.parameter;
    if (p is! SimpleFormalParameter) {
      return (null, null);
    }
    final type = p.type;
    return type == null
        ? (null, null)
        : (TypeRef.fromAnnotation(ctx, decLibrary, type), type);
  } else {
    throw CompileError('Unknown formal type ${param.runtimeType}');
  }
}
