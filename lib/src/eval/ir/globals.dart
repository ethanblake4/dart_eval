import 'package:control_flow_graph/control_flow_graph.dart';

final class SetGlobal extends Operation {
  final int index;
  final SSA source;

  SetGlobal(this.index, this.source);

  @override
  Set<SSA> get readsFrom => {source};

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

final class LoadGlobal extends Operation {
  final SSA target;
  final int index;

  LoadGlobal(this.target, this.index);

  @override
  Set<SSA> get readsFrom => {};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => AssignmentOp.assign;

  @override
  String toString() => '$target = loadglobal $index';

  @override
  bool operator ==(Object other) =>
      other is LoadGlobal && target == other.target && index == other.index;

  @override
  int get hashCode => index.hashCode ^ target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadGlobal(writesTo ?? target, index);
  }
}
