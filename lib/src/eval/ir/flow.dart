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

final class ReturnAsync extends Operation {
  final SSA? value;
  final SSA completer;

  ReturnAsync(this.value, this.completer);

  @override
  Set<SSA> get readsFrom => {if (value != null) value!, completer};

  @override
  String toString() => 'returnasync $value, $completer';

  @override
  bool operator ==(Object other) =>
      other is ReturnAsync &&
      value == other.value &&
      completer == other.completer;

  @override
  int get hashCode => value.hashCode ^ completer.hashCode;

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
  String toString() => 'jumpiffalse $condition @${target}';

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
  String toString() => 'jumpifnonnull $condition @${target}';

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

final class JumpIfNull extends Operation {
  final SSA condition;
  final String target;

  JumpIfNull(this.condition, this.target);

  @override
  Set<SSA> get readsFrom => {condition};

  SSA? get writesTo => ControlFlowGraph.branch;

  @override
  String toString() => 'jumpifnull $condition @${target}';

  @override
  bool operator ==(Object other) =>
      other is JumpIfNull &&
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

final class Assert extends Operation {
  final SSA condition;
  final SSA errorMessage;

  Assert(this.condition, this.errorMessage);

  @override
  Set<SSA> get readsFrom => {condition, errorMessage};

  @override
  String toString() => 'assert $condition, $errorMessage';

  @override
  bool operator ==(Object other) =>
      other is Assert &&
      condition == other.condition &&
      errorMessage == other.errorMessage;

  @override
  int get hashCode => condition.hashCode ^ errorMessage.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}
