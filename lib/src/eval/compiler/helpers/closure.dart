import '../../ir/memory.dart' show Assign;
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
  final dispatch = closureRef?.getStaticDispatch(ctx);
  final callable = dispatch == null
      ? (closureRef?.getValue(ctx) ?? closureVar!)
      : null;
  final closure = callable == null
      ? null
      : Variable.ssa(
          ctx,
          Assign(ctx.svar('closure_target'), callable.ssa),
          callable.type,
        );
  Variable snapshot(Variable argument) => Variable.ssa(
    ctx,
    Assign(ctx.svar('closure_argument'), argument.ssa),
    argument.type,
  ).boxIfNeeded(ctx);
  final positionalArgs = [
    for (final argument in positional ?? <Variable>[]) snapshot(argument),
  ];
  final namedArgs = {
    for (final entry in (named ?? <String, Variable>{}).entries)
      entry.key: snapshot(entry.value),
  };
  for (final arg in argumentList?.arguments ?? <Expression>[]) {
    if (arg is NamedExpression) {
      namedArgs[arg.name.label.name] = snapshot(
        compileExpression(arg.expression, ctx),
      );
    } else {
      positionalArgs.add(snapshot(compileExpression(arg, ctx)));
    }
  }
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
    ctx.pushOp(InvokeClosure(target, closure!.ssa, positionalSsa, namedSsa));
  }
  return InvokeResult(
    null,
    Variable.of(ctx, target, CoreTypes.dynamic.ref(ctx).copyWith(boxed: true)),
    positionalArgs,
    namedArgs: namedArgs,
  );
}
