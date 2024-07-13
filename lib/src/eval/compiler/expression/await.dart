import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/async.dart';

Variable compileAwaitExpression(AwaitExpression e, CompilerContext ctx) {
  AstNode? _e = e;
  while (_e != null) {
    if (_e is FunctionBody) {
      if (!_e.isAsynchronous) {
        throw CompileError('Cannot use await in a non-async context');
      } else {
        break;
      }
    }
    _e = _e.parent;
  }

  final subject = compileExpression(e.expression, ctx);
  final type = subject.type.resolveTypeChain(ctx);

  if (!type.isAssignableTo(ctx, CoreTypes.future.ref(ctx))) {
    throw CompileError("Cannot await something that isn't a Future");
  }

  var _completer = ctx.lookupLocal('#completer');

  return Variable.ssa(
      ctx,
      Await(ctx.svar('async_result'), _completer!.ssa, subject.ssa),
      type.specifiedTypeArgs.isNotEmpty
          ? type.specifiedTypeArgs[0]
          : CoreTypes.dynamic.ref(ctx));
}
