import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';
import '../invocation/resolver.dart';

extension Invoke on Variable {
  /// Operators, indexers, `==`/`!=`, and legacy dynamic member dispatch —
  /// delegates to [CallResolver.invokeOperator].
  InvokeResult invoke(
    CompilerContext ctx,
    String? method,
    List<Variable> args, {
    Map<String, Variable>? namedArgs,
  }) => CallResolver(ctx).invokeOperator(
    this,
    method,
    args,
    namedArgs: namedArgs,
  );
}
