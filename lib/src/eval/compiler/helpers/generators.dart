import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/generators.dart';
import '../variable.dart';
import '../values/value_rep.dart';

/// Emits the initial suspension before parameter capture cells are allocated.
BeginGenerator setupGenerator(
  CompilerContext ctx, {
  TypeRef? returnType,
  bool asynchronous = false,
}) {
  final iterable = (asynchronous ? CoreTypes.stream : CoreTypes.iterable).ref(
    ctx,
  );
  final runtimeType =
      returnType != null && sameDeclaration(returnType, iterable)
      ? returnType
      : iterable.copyWith(arguments: [CoreTypes.dynamic.ref(ctx)]);
  final begin = BeginGenerator(
    ctx.svar('#generator'),
    asynchronous: asynchronous,
    runtimeTypeId: ctx.runtimeTypes.idOf(runtimeType),
  );
  ctx.pushOp(begin);
  if (asynchronous) {
    ctx.setLocal(
      '#completer',
      Variable.of(ctx, begin.result, runtimeType, rep: ValueRep.boxed),
    );
  }
  return begin;
}
