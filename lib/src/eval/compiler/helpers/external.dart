import 'package:dart_eval/dart_eval_bridge.dart';
import '../../ir/bridge.dart' show InvocationKind;
import '../builtins.dart';
import '../context.dart';
import '../invocation/bound_call.dart';
import '../invocation/targets.dart';
import '../type.dart';
import '../variable.dart';

export '../../ir/bridge.dart' show InvocationKind;

/// A source external declaration has no linked implementation. Throw directly,
/// even if the receiver overrides noSuchMethod.
Variable emitMissingExternal(
  CompilerContext ctx,
  String name, {
  InvocationKind kind = InvocationKind.method,
  Variable? receiver,
  List<Variable> positional = const [],
  List<(String, Variable)> named = const [],
}) {
  final target = NoSuchMethodCall(
    name: name,
    restricted: true,
    receiver: receiver ?? BuiltinValue().push(ctx),
  );
  if (kind == InvocationKind.getter) return target.emitGetterValue(ctx);
  if (kind == InvocationKind.setter) {
    target.emitSetter(ctx, positional.single);
    return Variable.never(ctx);
  }
  return target.emit(
    ctx,
    BoundCall(
      positional: positional,
      named: named,
      returnType: CoreTypes.never.ref(ctx),
    ),
  );
}
