import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/ir/generators.dart';

/// Emits the initial suspension before parameter capture cells are allocated.
BeginSyncGenerator setupSyncGenerator(
  CompilerContext ctx, {
  TypeRef? returnType,
}) {
  final iterable = CoreTypes.iterable.ref(ctx);
  final runtimeType =
      returnType != null && sameDeclaration(returnType, iterable)
      ? returnType
      : iterable.copyWith(arguments: [CoreTypes.dynamic.ref(ctx)]);
  final begin = BeginSyncGenerator(
    ctx.svar('#syncGenerator'),
    runtimeTypeId: ctx.runtimeTypes.idOf(runtimeType),
  );
  ctx.pushOp(begin);
  return begin;
}
