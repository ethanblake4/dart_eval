import 'package:control_flow_graph/control_flow_graph.dart';

final class NewBridgeSuperShim extends Operation {
  final SSA target;

  NewBridgeSuperShim(this.target);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = #shim';

  @override
  bool operator ==(Object other) =>
      other is NewBridgeSuperShim && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return NewBridgeSuperShim(writesTo ?? target);
  }
}

final class BridgeInstantiate extends Operation {
  final SSA target;
  final SSA subclass;
  final List<SSA> args;
  final int externalFunctionId;

  BridgeInstantiate(
      this.target, this.externalFunctionId, this.subclass, this.args);

  @override
  SSA? get writesTo => target;

  @override
  Set<SSA> get readsFrom => {subclass, ...args};

  @override
  String toString() =>
      '$target = newbridge $externalFunctionId, $subclass ($args)';

  @override
  bool operator ==(Object other) =>
      other is BridgeInstantiate &&
      target == other.target &&
      externalFunctionId == other.externalFunctionId &&
      subclass == other.subclass &&
      args == other.args;

  @override
  int get hashCode =>
      target.hashCode ^
      externalFunctionId.hashCode ^
      subclass.hashCode ^
      args.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return BridgeInstantiate(
        writesTo ?? target, externalFunctionId, subclass, args);
  }
}

final class InvokeExternal extends Operation {
  final SSA target;
  final int externalFunctionId;

  final List<SSA> args;

  InvokeExternal(this.target, this.externalFunctionId, this.args);

  @override
  SSA? get writesTo => target;

  @override
  Set<SSA> get readsFrom => {...args};

  @override
  String toString() => '$target = invokeexternal $externalFunctionId ($args)';

  @override
  bool operator ==(Object other) =>
      other is InvokeExternal &&
      target == other.target &&
      externalFunctionId == other.externalFunctionId &&
      args == other.args;

  @override
  int get hashCode =>
      target.hashCode ^ externalFunctionId.hashCode ^ args.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return InvokeExternal(writesTo ?? target, externalFunctionId, args);
  }
}
