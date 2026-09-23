import 'package:dart_eval/src/eval/ir/async.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../values/value_rep.dart';

Variable compileAwaitExpression(AwaitExpression e, CompilerContext ctx) {
  AstNode? e0 = e;
  while (e0 != null) {
    if (e0 is FunctionBody) {
      if (!e0.isAsynchronous) {
        throw CompileError('Cannot use await in a non-async context');
      } else {
        break;
      }
    }
    e0 = e0.parent;
  }

  final subject = compileExpression(e.expression, ctx).boxIfNeeded(ctx);
  final type = subject.type;

  final completer = ctx.lookupLocal('#completer')!;
  final isFuture = type
      .copyWith(nullable: false)
      .isAssignableTo(ctx, CoreTypes.future.ref(ctx));
  final resultType = isFuture ? ctx.typeSystem.flatten(type) : type;

  return Variable.ssa(
    ctx,
    Await(ctx.svar('await_result'), completer.ssa, subject.ssa),
    resultType.copyWith(
      nullable: resultType.nullable || isFuture && type.nullable,
    ),
    rep: ValueRep.boxed,
  );
}
