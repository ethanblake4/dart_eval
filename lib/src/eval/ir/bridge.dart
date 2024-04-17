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
