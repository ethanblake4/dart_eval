import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import 'package:dart_eval/src/eval/ir/generators.dart';
import '../values/value_rep.dart';

/// Marks a synchronous generator's entry. The result slot is metadata for
/// the iterable's type; execution resumes after this operation.
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
  ctx.setLocal(
    '#syncGenerator',
    Variable.ssa(ctx, begin, runtimeType, rep: ValueRep.boxed),
  );
  return begin;
}
