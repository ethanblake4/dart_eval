import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/argument_list.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

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
    if (param is DefaultFormalParameter) {
      if (param.defaultValue != null && !ignoreDefaults) {
        ctx.beginAllocScope();
        final reserve = JumpIfNonNull.make(paramIndex, -1);
        final reserveOffset = ctx.pushOp(reserve, JumpIfNonNull.LEN);
        var V = compileExpression(param.defaultValue!, ctx);
        if (!allowUnboxed || !V.type.isUnboxedAcrossFunctionBoundaries) {
          V = V.boxIfNeeded(ctx);
        } else if (allowUnboxed && V.type.isUnboxedAcrossFunctionBoundaries) {
          V = V.unboxIfNeeded(ctx);
        }
        ctx.pushOp(
          CopyValue.make(paramIndex, V.scopeFrameOffset),
          CopyValue.LEN,
        );
        ctx.endAllocScope();
        ctx.rewriteOp(
          reserveOffset,
          JumpIfNonNull.make(paramIndex, ctx.out.length),
          0,
        );
        normalized.add(PossiblyValuedParameter(param.parameter, V));
      } else {
        if (param.defaultValue == null /* todo && param.type.nullable */ ) {
          ctx.pushOp(MaybeBoxNull.make(paramIndex), MaybeBoxNull.LEN);
        }
        normalized.add(PossiblyValuedParameter(param.parameter, null));
      }
    } else {
      param as NormalFormalParameter;
      normalized.add(PossiblyValuedParameter(param, null));
    }

    paramIndex++;
  }
  return normalized;
}

(TypeRef?, TypeAnnotation?) getFormalParameterType(CompilerContext ctx,
    FormalParameter param, int decLibrary, Declaration? parameterHost) {
  if (param is SimpleFormalParameter) {
    final type = param.type;
    return type == null
        ? (null, null)
        : (TypeRef.fromAnnotation(ctx, decLibrary, type), type);
  } else if (param is FieldFormalParameter) {
    return (
      resolveFieldFormalType(ctx, decLibrary, param, parameterHost!),
      null
    );
  } else if (param is SuperFormalParameter) {
    return (
      resolveSuperFormalType(ctx, decLibrary, param, parameterHost!),
      null
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
