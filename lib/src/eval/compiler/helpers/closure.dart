import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/expression/expression.dart';
import 'package:dart_eval/src/eval/compiler/reference.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/closures.dart';
import 'package:dart_eval/src/eval/ir/flow.dart';
import 'package:dart_eval/src/eval/shared/types.dart';

InvokeResult invokeClosure(
  CompilerContext ctx,
  Reference? closureRef,
  Variable? closureVar,
  ArgumentList? argumentList, {
  List<Variable>? positional,
  Map<String, Variable>? named,
}) {
  final positionalArgs = [...?positional];
  final namedArgs = {...?named};
  for (final arg in argumentList?.arguments ?? <Expression>[]) {
    if (arg is NamedExpression) {
      namedArgs[arg.name.label.name] = compileExpression(arg.expression, ctx);
    } else {
      positionalArgs.add(compileExpression(arg, ctx));
    }
  }
  for (var i = 0; i < positionalArgs.length; i++) {
    positionalArgs[i] = positionalArgs[i].boxIfNeeded(ctx);
  }
  for (final name in namedArgs.keys.toList()) {
    namedArgs[name] = namedArgs[name]!.boxIfNeeded(ctx);
  }
  final dispatch = closureRef?.getStaticDispatch(ctx);
  final target = ctx.svar('closure_result');
  final positionalSsa = positionalArgs.map((arg) => arg.ssa).toList();
  final namedSsa = namedArgs.map((key, arg) => MapEntry(key, arg.ssa));
  if (dispatch != null) {
    ctx.pushOp(
      Call(dispatch.offset, [
        ...positionalSsa,
        ...namedSsa.values,
      ], result: target),
    );
  } else {
    final closure = closureRef?.getValue(ctx) ?? closureVar!;
    ctx.pushOp(InvokeClosure(target, closure.ssa, positionalSsa, namedSsa));
  }
  return InvokeResult(
    null,
    Variable.of(ctx, target, CoreTypes.dynamic.ref(ctx).copyWith(boxed: true)),
    positionalArgs,
    namedArgs: namedArgs,
  );
}
