import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

List<PossiblyValuedParameter> resolveFPLDefaults(
    CompilerContext ctx, FormalParameterList fpl, bool isInstanceMethod,
    {bool allowUnboxed = true,
    bool sortNamed = false,
    bool ignoreDefaults = false,
    bool isEnum = false}) {
  final normalized = <PossiblyValuedParameter>[];
  var hasEncounteredOptionalPositionalParam = false;
  var hasEncounteredNamedParam = false;
  var _paramIndex = isEnum ? 2 : (isInstanceMethod || sortNamed ? 1 : 0);

  final named = <FormalParameter>[];
  final positional = <FormalParameter>[];

  for (final param in fpl.parameters) {
    if (param.isNamed) {
      if (hasEncounteredOptionalPositionalParam) {
        throw CompileError(
            'Cannot mix named and optional positional parameters');
      }
      hasEncounteredNamedParam = true;
      named.add(param);
    } else {
      if (param.isOptionalPositional) {
        if (hasEncounteredNamedParam) {
          throw CompileError(
              'Cannot mix named and optional positional parameters');
        }
        hasEncounteredOptionalPositionalParam = true;
      }
      positional.add(param);
    }
  }

  if (sortNamed) {
    named.sort((a, b) =>
        (a.name!.value() as String).compareTo(b.name!.value() as String));
  }

  for (final param in [...positional, ...named]) {
    if (param is DefaultFormalParameter) {
      if (param.defaultValue != null && !ignoreDefaults) {
        ctx.beginAllocScope();
        final _reserve = JumpIfNonNull.make(_paramIndex, -1);
        final _reserveOffset = ctx.pushOp(_reserve, JumpIfNonNull.LEN);
        var V = compileExpression(param.defaultValue!, ctx);
        if (!allowUnboxed) {
          V = V.boxIfNeeded(ctx);
        }
        ctx.pushOp(
            CopyValue.make(_paramIndex, V.scopeFrameOffset), CopyValue.LEN);
        ctx.endAllocScope();
        ctx.rewriteOp(
            _reserveOffset, JumpIfNonNull.make(_paramIndex, ctx.out.length), 0);
        normalized.add(PossiblyValuedParameter(param.parameter, V));
      } else {
        if (param.defaultValue == null /* TODO && param.type.nullable */) {
          ctx.pushOp(MaybeBoxNull.make(_paramIndex), MaybeBoxNull.LEN);
        }
        normalized.add(PossiblyValuedParameter(param.parameter, null));
      }
    } else {
      param as NormalFormalParameter;
      normalized.add(PossiblyValuedParameter(param, null));
    }

    _paramIndex++;
  }
  return normalized;
}
