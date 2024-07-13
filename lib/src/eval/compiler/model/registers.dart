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

// parameter layout:
// 1st int: regALUAcc, 2nd int: regALU2
// 1st double: regFPUAcc, 2nd float: regFPU2
// 1st string: regStringAcc, 2nd string: regString2
// 1st bool: regBoolFlag, 2nd bool: regBool2
// 1st collection: regGPR3
// next: regGPR1, regGPR2, regGPR3
// remaining: pushed in order to stack
List<String> mapParameterLayout(CompilerContext ctx, List<TypeRef> types) {
  var intc = 0,
      floatc = 0,
      stringc = 0,
      boolc = 0,
      collc = 0,
      gpc = 0,
      gp3 = 0,
      sc = 0;

  final result = <String>[];

  for (final type in types) {
    if (intc < 2 && type.isAssignableTo(ctx, CoreTypes.int.ref(ctx))) {
      result.add(intc == 0 ? regALUAcc : regALU2);
      intc++;
    } else if (floatc < 2 &&
        type.isAssignableTo(ctx, CoreTypes.double.ref(ctx))) {
      result.add(floatc == 0 ? regFPUAcc : regFPU2);
      floatc++;
    } else if (stringc < 2 &&
        type.isAssignableTo(ctx, CoreTypes.string.ref(ctx))) {
      result.add(stringc == 0 ? regStringAcc : regString2);
      stringc++;
    } else if (boolc < 2 && type.isAssignableTo(ctx, CoreTypes.bool.ref(ctx))) {
      result.add(boolc == 0 ? regBoolFlag : regBool2);
      boolc++;
    } else if (collc == 0 &&
        gp3 == 0 &&
        (type.isAssignableTo(ctx, CoreTypes.list.ref(ctx)) ||
            type.isAssignableTo(ctx, CoreTypes.map.ref(ctx)))) {
      result.add(regGPR3);
      gp3 = 1;
    } else if (gpc < 2) {
      result.add(gpc == 0 ? regGPR1 : regGPR2);
      gpc++;
    } else if (gp3 == 0) {
      result.add(regGPR3);
      gpc++;
    } else {
      result.add('%$sc');
      sc++;
    }
  }

  return result;
}
