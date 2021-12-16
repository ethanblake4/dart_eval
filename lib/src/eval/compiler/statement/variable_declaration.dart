import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';

import '../errors.dart';
import '../type.dart';
import '../variable.dart';
import 'statement.dart';

StatementInfo compileVariableDeclarationStatement(VariableDeclarationStatement s, CompilerContext ctx) {
  compileVariableDeclarationList(s.variables, ctx);
  return StatementInfo(-1);
}

void compileVariableDeclarationList(VariableDeclarationList l, CompilerContext ctx) {
  TypeRef? type;
  if (l.type != null) {
    type = TypeRef.fromAnnotation(ctx, ctx.library, l.type!);
  }

  for (final li in l.variables) {
    final init = li.initializer;
    if (init != null) {
      final res = compileExpression(init, ctx);
      if (ctx.locals.last.containsKey(li.name.name)) {
        throw CompileError('Cannot declare variable ${li.name.name} multiple times in the same scope');
      }
      ctx.setLocal(li.name.name, Variable(res.scopeFrameOffset, type ?? res.type, boxed: res.boxed));
    }
  }
}