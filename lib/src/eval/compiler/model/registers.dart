import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/shared/registers.dart';

String returnTypeToRegister(CompilerContext ctx, TypeRef type) {
  if (type == CoreTypes.int.ref(ctx)) {
    return regALUAcc;
  } else if (type == CoreTypes.double.ref(ctx)) {
    return regFPUAcc;
  } else if (type == CoreTypes.bool.ref(ctx)) {
    return regBoolFlag;
  } else if (type == CoreTypes.string.ref(ctx)) {
    return regStringAcc;
  } else if (type == CoreTypes.num.ref(ctx)) {
    return regALUAcc;
  }
  return regGPR1;
}
