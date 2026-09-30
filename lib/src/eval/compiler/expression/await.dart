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

  // `await e` gives its operand a `FutureOr<K>` context — `FutureOr<_>`
  // when no context imposes one (dart-lang/language#3648). `FutureOr`
  // can't be represented and any plain `K`-typed operand is legal, so
  // the closest permissive context is `dynamic`.
  final subject = compileExpression(
    e.expression,
    ctx,
    CoreTypes.dynamic.ref(ctx),
  ).boxIfNeeded(ctx);
  final type = subject.type;

  final completer = ctx.lookupLocal('#completer')!;
  final resultType = ctx.typeSystem.flatten(type);

  // `await v` suspends on `v` only when `v is Future<flatten(T)>`
  // (spec 16.34) — a `Future` implementation whose type argument doesn't
  // match `flatten(T)` (e.g. under a type-variable static type) is returned
  // unawaited. The descriptor is resolved against the frame's type
  // environment at runtime when it mentions type parameters.
  final awaitTypeId = ctx.runtimeTypes.idOf(
    ctx.types.bySpec(CoreTypes.future).instantiate([resultType]),
  );

  return Variable.ssa(
    ctx,
    Await(ctx.svar('await_result'), completer.ssa, subject.ssa, awaitTypeId),
    resultType,
    rep: ValueRep.boxed,
  );
}
