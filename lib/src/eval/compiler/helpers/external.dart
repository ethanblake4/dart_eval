import 'package:analyzer/dart/ast/ast.dart';
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/dart_eval_bridge.dart';
import '../../ir/bridge.dart' show InvocationKind;
import '../builtins.dart';
import '../context.dart';
import '../invocation/bound_call.dart';
import '../invocation/targets.dart';
import '../type.dart';
import '../variable.dart';
import '../values/abi.dart';

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

/// Reconstructs the declaration's argument slots for its missing external body.
Variable emitMissingExternalBody(
  CompilerContext ctx,
  String name,
  List<FormalParameter> parameters,
  List<TypeRef> types,
  CallableAbi abi, {
  InvocationKind kind = InvocationKind.method,
  Variable? receiver,
  int argumentOffset = 0,
}) {
  Variable argument(int index) => Variable.of(
    ctx,
    SSA('arg_${index + argumentOffset}'),
    types[index],
    rep: abi.parameters[index + argumentOffset],
  );
  return emitMissingExternal(
    ctx,
    name,
    kind: kind,
    receiver: receiver,
    positional: [
      for (var i = 0; i < parameters.length; i++)
        if (!parameters[i].isNamed) argument(i),
    ],
    named: [
      for (var i = 0; i < parameters.length; i++)
        if (parameters[i].isNamed) (parameters[i].name!.lexeme, argument(i)),
    ],
  );
}
