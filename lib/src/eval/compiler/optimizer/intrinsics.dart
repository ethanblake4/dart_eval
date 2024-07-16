import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/ir/alu.dart';
import 'package:dart_eval/src/eval/ir/logic.dart';

final intrinsicNames = {
  '+': 'add',
  '-': 'sub',
  '<': 'lt',
  '>': 'gt',
  '<=': 'lte',
  '>=': 'gte',
  '==': 'eq',
  '!=': 'neq',
};

final intIntrinsics = <String,
    (BridgeTypeSpec type, Operation Function(SSA result, SSA l, SSA r) fn)>{
  '+': (CoreTypes.int, (SSA result, SSA l, SSA r) => IntAdd(result, l, r)),
  '-': (CoreTypes.int, (SSA result, SSA l, SSA r) => IntSub(result, l, r)),
  '<': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA r) => IntLessThan(result, l, r)
  ),
  '>': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA r) => IntGreaterThan(result, l, r)
  ),
  '<=': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA r) => IntLessThanOrEqual(result, l, r)
  ),
  '>=': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA r) => IntGreaterThanOrEqual(result, l, r)
  ),
  '==': (CoreTypes.bool, (SSA result, SSA l, SSA r) => IntEqual(result, l, r)),
  '!=': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA r) => IntNotEqual(result, l, r)
  ),
};

final boolIntrinsics = <String,
    (BridgeTypeSpec type, Operation Function(SSA result, SSA l, SSA? r) fn)>{
  '!': (CoreTypes.bool, (SSA result, SSA l, SSA? r) => LogicalNot(result, l)),
  '&&': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA? r) => LogicalAnd(result, l, r!)
  ),
  '||': (
    CoreTypes.bool,
    (SSA result, SSA l, SSA? r) => LogicalOr(result, l, r!)
  ),
};
/*
final stringIntrinsics = <String,
    (BridgeTypeSpec type, Operation Function(SSA result, SSA l, SSA r) fn)>{
  '+': (
    CoreTypes.string,
    (SSA result, SSA l, SSA r) => StringConcat(result, l, r)
  ),
};*/
