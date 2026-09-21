import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conversion.dart';
import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/src/eval/ir/memory.dart';

import '../errors.dart';
import '../type.dart';
import 'statement.dart';

StatementInfo compileVariableDeclarationStatement(
  VariableDeclarationStatement s,
  CompilerContext ctx,
) {
  compileVariableDeclarationList(s.variables, ctx);
  return StatementInfo();
}

void compileVariableDeclarationList(
  VariableDeclarationList l,
  CompilerContext ctx,
) {
  TypeRef? type;
  if (l.type != null) {
    type = TypeRef.fromAnnotation(ctx, ctx.library, l.type!);
  }

  for (final li in l.variables) {
    // A local `_` is a wildcard: non-binding and repeatable in one scope.
    // (Top-level and member `_` declarations are still binding.)
    final isWildcard = li.name.lexeme == '_';
    if (ctx.locals.last.containsKey(li.name.lexeme) && !isWildcard) {
      throw CompileError(
        'Cannot declare variable ${li.name.lexeme}'
        ' multiple times in the same scope',
      );
    }
    final init = li.initializer;

    if (init != null) {
      var res = compileExpression(init, ctx, type);
      if (type != null) {
        res = convertForAssignment(
          ctx,
          res,
          type,
          representation: type.isUnboxedAcrossFunctionBoundaries
              ? representationForType(type.copyWith(boxed: false))
              : MachineRepresentation.object,
          source: li,
          description:
              'Type mismatch: variable "${li.name.lexeme}" is specified as '
              'type $type, but is initialized to ${res.type}',
        );
      }
      if (!((type ?? res.type).isUnboxedAcrossFunctionBoundaries)) {
        res = res.boxIfNeeded(ctx);
      }
      if (isWildcard) {
        // Evaluate for side effects only; the wildcard binds nothing.
        continue;
      }
      final local = res.copyWith(
        name: ctx.svar(li.name.lexeme).name,
        type: (type ?? res.type).copyWith(boxed: res.boxed),
        declaredType: type ?? res.type,
        isFinal: l.isFinal || l.isConst,
      );
      ctx.pushOp(Assign(local.ssa, res.ssa));
      ctx.setLocal(li.name.lexeme, local.captureBinding(ctx, li));
    } else {
      if (isWildcard) continue;
      ctx.setLocal(
        li.name.lexeme,
        BuiltinValue()
            .push(ctx)
            .boxIfNeeded(ctx)
            .copyWith(
              type: type ?? CoreTypes.dynamic.ref(ctx),
              declaredType: type ?? CoreTypes.dynamic.ref(ctx),
              representation: MachineRepresentation.object,
            )
            .captureBinding(ctx, li),
      );
    }
  }
}
