import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';
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
    if (ctx.locals.last.containsKey(li.name.lexeme)) {
      throw CompileError('Cannot declare variable ${li.name.lexeme}'
          ' multiple times in the same scope');
    }
    final init = li.initializer;

    if (init != null) {
      var res = compileExpression(init, ctx, type);
      if (type != null &&
          !res.type.resolveTypeChain(ctx).isAssignableTo(ctx, type)) {
        throw CompileError(
            'Type mismatch: variable "${li.name.lexeme} is specified'
            ' as type $type, but is initialized to an incompatible value of type ${res.type}');
      }
      if (!((type ?? res.type).isUnboxedAcrossFunctionBoundaries)) {
        res = res.boxIfNeeded(ctx);
      }
      if (res.name != null) {
        final _type = type ?? res.type;
        var _v = Variable.alloc(
          ctx,
          _type.isUnboxedAcrossFunctionBoundaries
              ? _type.copyWith(boxed: false)
              : _type,
        )..name = ctx.svar(li.name.lexeme).name;
        ctx.pushOp(Assign(_v.ssa, res.ssa));
        ctx.setLocal(li.name.lexeme, _v);
      } else {
        ctx.setLocal(
            li.name.lexeme,
            Variable(res.scopeFrameOffset,
                (type ?? res.type).copyWith(boxed: res.boxed),
                isFinal: l.isFinal || l.isConst,
                methodOffset: res.methodOffset,
                methodReturnType: res.methodReturnType,
                callingConvention: res.callingConvention)
              ..name = ctx.svar(li.name.lexeme).name);
      }
    } else {
      ctx.setLocal(
          li.name.lexeme,
          BuiltinValue()
              .push(ctx)
              .boxIfNeeded(ctx)
              .copyWith(type: type ?? CoreTypes.dynamic.ref(ctx)));
    }
  }
}
