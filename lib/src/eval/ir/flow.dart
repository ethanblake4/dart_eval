import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/src/eval/compiler/offset_tracker.dart';

final class Return extends Operation {
  final SSA? value;

  Return(this.value);

  @override
  Set<SSA> get readsFrom => {if (value != null) value!};

  @override
  String toString() => 'return $value';

  @override
  bool operator ==(Object other) => other is Return && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}

final class Jump extends Operation {
  final String target;

  Jump(this.target);

  @override
  String toString() => 'jump ${target}';

  @override
  bool operator ==(Object other) => other is Jump && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}

final class JumpIfFalse extends Operation {
  final SSA condition;
  final String target;

  JumpIfFalse(this.condition, this.target);

  @override
  Set<SSA> get readsFrom => {condition};

  SSA? get writesTo => ControlFlowGraph.branch;

  @override
  String toString() => 'jumpiffalse $condition ${target}';

  @override
  bool operator ==(Object other) =>
      other is JumpIfFalse &&
      condition == other.condition &&
      target == other.target;

  @override
  int get hashCode => condition.hashCode ^ target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}

final class JumpIfNonNull extends Operation {
  final SSA condition;
  final String target;

  JumpIfNonNull(this.condition, this.target);

  @override
  Set<SSA> get readsFrom => {condition};

  SSA? get writesTo => ControlFlowGraph.branch;

  @override
  String toString() => 'jumpifnonnull $condition ${target}';

  @override
  bool operator ==(Object other) =>
      other is JumpIfNonNull &&
      condition == other.condition &&
      target == other.target;

  @override
  int get hashCode => condition.hashCode ^ target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}

final class Call extends Operation {
  final DeferredOrOffset target;
  final List<SSA> arguments;

  Call(this.target, this.arguments);

  @override
  Set<SSA> get readsFrom => Set.from(arguments);

  @override
  String toString() => 'call ${target}(${arguments.join(', ')})';

  @override
  bool operator ==(Object other) =>
      other is Call &&
      target == other.target &&
      arguments.length == other.arguments.length &&
      arguments.every((e) => other.arguments.contains(e));

  @override
  int get hashCode => target.hashCode ^ arguments.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}
