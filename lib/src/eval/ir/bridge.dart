import 'package:control_flow_graph/control_flow_graph.dart';
import 'operands.dart';

final class ParentBridgeSuperShim extends Operation {
  final SSA shim;
  final SSA parent;

  ParentBridgeSuperShim(this.shim, this.parent);

  @override
  Set<SSA> get readsFrom => {shim, parent};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      ParentBridgeSuperShim(
        readsFrom?.first ?? shim,
        readsFrom?.last ?? parent,
      );
}

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return NewBridgeSuperShim(writesTo ?? target);
  }
}

final class BridgeInstantiate extends Operation {
  final SSA target;
  final SSA subclass;
  final List<SSA> args;
  final int externalFunctionId;

  BridgeInstantiate(
    this.target,
    this.externalFunctionId,
    this.subclass,
    this.args,
  );

  @override
  SSA? get writesTo => target;

  @override
  Set<SSA> get readsFrom => {subclass, ...args};

  @override
  String toString() =>
      '$target = newbridge $externalFunctionId, $subclass $args';

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [subclass, ...args],
      this.readsFrom,
      readsFrom,
    );
    return BridgeInstantiate(
      writesTo ?? target,
      externalFunctionId,
      newReadsFrom[0],
      newReadsFrom.sublist(1),
    );
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
  String toString() => '$target = invokeexternal $externalFunctionId $args';

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(args, this.readsFrom, readsFrom);
    return InvokeExternal(writesTo ?? target, externalFunctionId, newReadsFrom);
  }
}
