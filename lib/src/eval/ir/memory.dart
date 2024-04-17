import 'package:control_flow_graph/control_flow_graph.dart';

final class LoadInt extends Operation {
  final SSA target;
  final int value;

  LoadInt(this.target, this.value);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = int $value';

  @override
  bool operator ==(Object other) =>
      other is LoadInt && target == other.target && value == other.value;

  @override
  int get hashCode => target.hashCode ^ value.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadInt(writesTo ?? target, value);
  }
}

final class LoadDouble extends Operation {
  final SSA target;
  final double value;

  LoadDouble(this.target, this.value);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = double $value';

  @override
  bool operator ==(Object other) =>
      other is LoadDouble && target == other.target && value == other.value;

  @override
  int get hashCode => target.hashCode ^ value.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadDouble(writesTo ?? target, value);
  }
}

final class LoadString extends Operation {
  final SSA target;
  final String value;

  LoadString(this.target, this.value);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = string "$value"';

  @override
  bool operator ==(Object other) =>
      other is LoadString && target == other.target && value == other.value;

  @override
  int get hashCode => target.hashCode ^ value.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadString(writesTo ?? target, value);
  }
}

final class LoadBool extends Operation {
  final SSA target;
  final bool value;

  LoadBool(this.target, this.value);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = bool $value';

  @override
  bool operator ==(Object other) =>
      other is LoadBool && target == other.target && value == other.value;

  @override
  int get hashCode => target.hashCode ^ value.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadBool(writesTo ?? target, value);
  }
}

final class LoadNull extends Operation {
  final SSA target;

  LoadNull(this.target);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = #null';

  @override
  bool operator ==(Object other) => other is LoadNull && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadNull(writesTo ?? target);
  }
}

final class Assign extends Operation {
  final SSA target;
  final SSA source;

  Assign(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => AssignmentOp.assign;

  @override
  String toString() => '$target = $source';

  @override
  bool operator ==(Object other) =>
      other is Assign && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return Assign(writesTo ?? target, source);
  }
}

final class AssignRegister extends Operation {
  final SSA target;
  final String reg;

  AssignRegister(
    this.target,
    this.reg,
  );

  @override
  Set<SSA> get readsFrom => {};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = $reg';

  @override
  bool operator ==(Object other) =>
      other is AssignRegister && target == other.target && reg == other.reg;

  @override
  int get hashCode => target.hashCode ^ reg.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return AssignRegister(writesTo ?? target, reg);
  }
}
