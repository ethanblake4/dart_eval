import 'package:control_flow_graph/control_flow_graph.dart';

final class LoadInt extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadInt(writesTo ?? target, value);
  }
}

final class LoadDouble extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadDouble(writesTo ?? target, value);
  }
}

final class LoadString extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadString(writesTo ?? target, value);
  }
}

final class LoadBool extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadBool(writesTo ?? target, value);
  }
}

final class LoadNull extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadNull(writesTo ?? target);
  }
}

final class Assign extends Operation {
  @override
  bool get isPure => true;

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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return Assign(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class IsNull extends Operation {
  @override
  bool get isPure => true;

  final SSA result;
  final SSA object;

  IsNull(this.result, this.object);

  @override
  Set<SSA> get readsFrom => {object};

  @override
  SSA? get writesTo => result;

  @override
  String toString() => '$result = $object is null';

  @override
  bool operator ==(Object other) =>
      other is IsNull && result == other.result && object == other.object;

  @override
  int get hashCode => object.hashCode ^ result.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return IsNull(writesTo ?? result, readsFrom?.first ?? object);
  }
}
