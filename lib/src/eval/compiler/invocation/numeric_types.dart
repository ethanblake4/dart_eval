import 'package:dart_eval/dart_eval_bridge.dart';

import '../context.dart';
import '../type.dart';

bool _isNumericSubtype(
  CompilerContext ctx,
  TypeRef type,
  BridgeTypeSpec target,
) =>
    !type.nullable &&
    !type.isSpec(CoreTypes.never) &&
    type.isAssignableTo(ctx, target.ref(ctx), forceAllowDynamic: false);

/// The operand-dependent static result type of `num.remainder`.
TypeRef? numericRemainderResultType(
  CompilerContext ctx,
  TypeRef receiver,
  TypeRef argument,
) {
  if (!_isNumericSubtype(ctx, receiver, CoreTypes.num)) return null;
  if (_isNumericSubtype(ctx, receiver, CoreTypes.double) ||
      _isNumericSubtype(ctx, argument, CoreTypes.double)) {
    return CoreTypes.double.ref(ctx);
  }
  if (_isNumericSubtype(ctx, receiver, CoreTypes.int) &&
      _isNumericSubtype(ctx, argument, CoreTypes.int)) {
    return CoreTypes.int.ref(ctx);
  }
  return CoreTypes.num.ref(ctx);
}

/// A numeric operator's right operand can inherit a more specific context.
TypeRef? numericArgumentContext(
  CompilerContext ctx,
  TypeRef receiver,
  TypeRef? context,
) {
  if (!_isNumericSubtype(ctx, receiver, CoreTypes.num)) return null;
  if (context != null &&
      _isNumericSubtype(ctx, receiver, CoreTypes.int) &&
      _isNumericSubtype(ctx, context, CoreTypes.int)) {
    return CoreTypes.int.ref(ctx);
  }
  if (context != null &&
      !_isNumericSubtype(ctx, receiver, CoreTypes.double) &&
      _isNumericSubtype(ctx, context, CoreTypes.double)) {
    return CoreTypes.double.ref(ctx);
  }
  return CoreTypes.num.ref(ctx);
}

TypeRef? numericClampResultType(
  CompilerContext ctx,
  TypeRef receiver,
  TypeRef lower,
  TypeRef upper,
) {
  if (!_isNumericSubtype(ctx, receiver, CoreTypes.num)) return null;
  if (_isNumericSubtype(ctx, receiver, CoreTypes.int) &&
      _isNumericSubtype(ctx, lower, CoreTypes.int) &&
      _isNumericSubtype(ctx, upper, CoreTypes.int)) {
    return CoreTypes.int.ref(ctx);
  }
  if (_isNumericSubtype(ctx, receiver, CoreTypes.double) &&
      _isNumericSubtype(ctx, lower, CoreTypes.double) &&
      _isNumericSubtype(ctx, upper, CoreTypes.double)) {
    return CoreTypes.double.ref(ctx);
  }
  return CoreTypes.num.ref(ctx);
}

TypeRef numericClampArgumentContext(
  CompilerContext ctx,
  TypeRef receiver,
  TypeRef? context,
) =>
    context != null &&
        _isNumericSubtype(ctx, receiver, CoreTypes.num) &&
        _isNumericSubtype(ctx, context, CoreTypes.num)
    ? context
    : CoreTypes.num.ref(ctx);
