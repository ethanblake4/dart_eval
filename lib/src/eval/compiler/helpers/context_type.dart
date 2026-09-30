import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../type.dart';

/// Selects the branch of a FutureOr context matching the value being inferred.
/// An unknown return parameter retains the union until its argument is inferred.
TypeRef inferContextType(
  CompilerContext ctx,
  TypeRef valueType,
  TypeRef context,
) {
  if (valueType.isTypeParameter) return context;
  var result = context;
  while (result is InterfaceTypeRef &&
      result.decl.isSpec(AsyncTypes.futureOr)) {
    final arguments = interfaceArgumentsOf(result);
    final value = arguments.isEmpty
        ? CoreTypes.dynamic.ref(ctx)
        : arguments.first;
    if (ctx.typeSystem.asInstanceOf(
          valueType,
          ctx.types.bySpec(CoreTypes.future),
        ) !=
        null) {
      return ctx.types.bySpec(CoreTypes.future).instantiate([
        value,
      ], nullable: result.nullable);
    }
    result = value.withNullable(result.nullable || value.nullable);
  }
  return result;
}
