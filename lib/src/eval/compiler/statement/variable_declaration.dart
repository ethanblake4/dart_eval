import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../errors.dart';
import '../type.dart';
import '../variable.dart';
import 'statement.dart';

StatementInfo compileVariableDeclarationStatement(
    VariableDeclarationStatement s, CompilerContext ctx) {
  compileVariableDeclarationList(s.variables, ctx);
  return StatementInfo(-1);
}

void compileVariableDeclarationList(
    VariableDeclarationList l, CompilerContext ctx) {
  TypeRef? type;
  if (l.type != null) {
    type = TypeRef.fromAnnotation(ctx, ctx.library, l.type!);
  }

  for (final li in l.variables) {
    if (ctx.locals.last.containsKey(li.name.value() as String)) {
      throw CompileError('Cannot declare variable ${li.name.value() as String}'
          ' multiple times in the same scope');
    }
    final init = li.initializer;
    if (init != null) {
      var res = compileExpression(init, ctx, type);
      if (type != null &&
          !res.type.resolveTypeChain(ctx).isAssignableTo(ctx, type)) {
        throw CompileError(
            'Type mismatch: variable "${li.name.value() as String} is specified'
            ' as type $type, but is initialized to an incompatible value of type ${res.type}');
      }
      if (!(type?.isUnboxedAcrossFunctionBoundaries ?? true)) {
        res = res.boxIfNeeded(ctx);
      }
      if (res.name != null) {
        var _v = Variable.alloc(ctx, type ?? res.type);
        ctx.pushOp(PushNull.make(), PushNull.LEN);
        ctx.pushOp(CopyValue.make(_v.scopeFrameOffset, res.scopeFrameOffset),
            CopyValue.LEN);
        ctx.setLocal(li.name.value() as String, _v);
      } else {
        ctx.setLocal(
            li.name.value() as String,
            Variable(res.scopeFrameOffset,
                (type ?? res.type).copyWith(boxed: res.boxed),
                isFinal: l.isFinal || l.isConst,
                methodOffset: res.methodOffset,
                methodReturnType: res.methodReturnType,
                callingConvention: res.callingConvention));
      }
    } else {
      ctx.setLocal(li.name.value() as String, BuiltinValue().push(ctx));
    }
  }
}
