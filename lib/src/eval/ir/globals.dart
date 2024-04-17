import 'package:control_flow_graph/control_flow_graph.dart';

final class SetGlobal extends Operation {
  final int index;
  final SSA source;

  SetGlobal(this.index, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  OpType get type => AssignmentOp.assign;

  @override
  String toString() => 'setglobal $index = $source';

  @override
  bool operator ==(Object other) =>
      other is SetGlobal && index == other.index && source == other.source;

  @override
  int get hashCode => index.hashCode ^ source.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}
