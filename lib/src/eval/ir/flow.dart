import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:collection/collection.dart';
import '../compiler/invocation/deferred.dart';

final class Return extends Operation {
  final SSA? value;

  Return(this.value);

  @override
  Set<SSA> get readsFrom => {?value};

  @override
  String toString() => 'return $value';

  @override
  bool operator ==(Object other) => other is Return && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return Return(readsFrom?.firstOrNull ?? value);
  }
}

final class ReturnAsync extends Operation {
  final SSA? value;
  final SSA completer;

  ReturnAsync(this.value, this.completer);

  @override
  Set<SSA> get readsFrom => {?value, completer};

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [?value, completer],
      this.readsFrom,
      readsFrom,
    );
    return ReturnAsync(
      newReadsFrom.length > 1 ? newReadsFrom[0] : null,
      newReadsFrom.last,
    );
  }
}

final class Jump extends Operation {
  final String target;

  Jump(this.target);

  @override
  String toString() => 'jump @$target';

  @override
  bool operator ==(Object other) => other is Jump && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return this;
  }
}

final class JumpIfFalse extends Operation {
  final SSA condition;
  final String target;

  JumpIfFalse(this.condition, this.target);

  @override
  Set<SSA> get readsFrom => {condition};

  @override
  SSA? get writesTo => ControlFlowGraph.branch;

  @override
  String toString() => 'jumpiffalse $condition @$target';

  @override
  bool operator ==(Object other) =>
      other is JumpIfFalse &&
      condition == other.condition &&
      target == other.target;

  @override
  int get hashCode => condition.hashCode ^ target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return JumpIfFalse(readsFrom?.single ?? condition, target);
  }
}

final class JumpIfNonNull extends Operation {
  final SSA condition;
  final String target;

  JumpIfNonNull(this.condition, this.target);

  @override
  Set<SSA> get readsFrom => {condition};

  @override
  SSA? get writesTo => ControlFlowGraph.branch;

  @override
  String toString() => 'jumpifnonnull $condition @$target';

  @override
  bool operator ==(Object other) =>
      other is JumpIfNonNull &&
      condition == other.condition &&
      target == other.target;

  @override
  int get hashCode => condition.hashCode ^ target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return JumpIfNonNull(readsFrom?.single ?? condition, target);
  }
}

final class JumpIfNull extends Operation {
  final SSA condition;
  final String target;

  JumpIfNull(this.condition, this.target);

  @override
  Set<SSA> get readsFrom => {condition};

  @override
  SSA? get writesTo => ControlFlowGraph.branch;

  @override
  String toString() => 'jumpifnull $condition @$target';

  @override
  bool operator ==(Object other) =>
      other is JumpIfNull &&
      condition == other.condition &&
      target == other.target;

  @override
  int get hashCode => condition.hashCode ^ target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return JumpIfNull(readsFrom?.single ?? condition, target);
  }
}

final class Call extends Operation {
  final DeferredOrOffset target;
  final List<SSA> arguments;
  final SSA? typeEnvironmentReceiver;
  final List<int> typeArguments;

  final SSA? result;

  Call(
    this.target,
    this.arguments, {
    this.result,
    this.typeEnvironmentReceiver,
    this.typeArguments = const [],
  });

  @override
  SSA? get writesTo => result;

  @override
  Set<SSA> get readsFrom => {...arguments, ?typeEnvironmentReceiver};

  @override
  String toString() => 'call $target(${arguments.join(', ')})';

  @override
  bool operator ==(Object other) =>
      other is Call &&
      target == other.target &&
      result == other.result &&
      typeEnvironmentReceiver == other.typeEnvironmentReceiver &&
      const ListEquality<int>().equals(typeArguments, other.typeArguments) &&
      const ListEquality<SSA>().equals(arguments, other.arguments);

  @override
  int get hashCode => Object.hash(
    target,
    result,
    typeEnvironmentReceiver,
    Object.hashAll(typeArguments),
    Object.hashAll(arguments),
  );

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final operands = [...arguments, ?typeEnvironmentReceiver];
    final renamed = renameOperands(operands, this.readsFrom, readsFrom);
    return Call(
      target,
      renamed.take(arguments.length).toList(),
      result: writesTo ?? result,
      typeEnvironmentReceiver: typeEnvironmentReceiver == null
          ? null
          : renamed.last,
      typeArguments: typeArguments,
    );
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [condition, errorMessage],
      this.readsFrom,
      readsFrom,
    );
    return Assert(newReadsFrom[0], newReadsFrom[1]);
  }
}

/// Raises a value through the active exception handlers.
final class Throw extends Operation {
  final SSA value;
  Throw(this.value);
  @override
  Set<SSA> get readsFrom => {value};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      Throw(readsFrom?.single ?? value);
}

/// Rethrows the exception from its lexical catch, preserving its stack trace.
final class Rethrow extends Operation {
  final String catchTarget;
  Rethrow(this.catchTarget);
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => this;
}
