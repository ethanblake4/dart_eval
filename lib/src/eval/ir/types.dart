import 'package:control_flow_graph/control_flow_graph.dart';

final class AssertType extends Operation {
  final SSA object;
  final int typeId;

  AssertType(this.object, this.typeId);

  @override
  Set<SSA> get readsFrom => {object};

  @override
  String toString() => 'asserttype $object is $typeId';

  @override
  bool operator ==(Object other) =>
      other is AssertType && object == other.object && typeId == other.typeId;

  @override
  int get hashCode => object.hashCode ^ typeId.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return AssertType(writesTo ?? object, typeId);
  }
}

/// TODO fix add result object
final class IsType extends Operation {
  final SSA object;
  final int typeId;
  final bool not;

  IsType(this.object, this.typeId, this.not);

  @override
  Set<SSA> get readsFrom => {object};

  @override
  String toString() => 'istype $object is${not ? "!" : ""} $typeId';

  @override
  bool operator ==(Object other) =>
      other is IsType && object == other.object && typeId == other.typeId;

  @override
  int get hashCode => object.hashCode ^ typeId.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return IsType(writesTo ?? object, typeId, not);
  }
}

final class LoadConstantType extends Operation {
  final SSA result;
  final int typeId;

  LoadConstantType(this.result, this.typeId);

  @override
  SSA? get writesTo => result;

  @override
  String toString() => '$result = loadconstanttype $typeId';

  @override
  bool operator ==(Object other) =>
      other is LoadConstantType &&
      result == other.result &&
      typeId == other.typeId;

  @override
  int get hashCode => result.hashCode ^ typeId.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadConstantType(writesTo ?? result, typeId);
  }
}

final class LoadRuntimeType extends Operation {
  final SSA result;
  final SSA object;

  LoadRuntimeType(this.result, this.object);

  @override
  SSA? get writesTo => result;

  @override
  Set<SSA> get readsFrom => {object};

  @override
  String toString() => '$result = loadruntimetype $object';

  @override
  bool operator ==(Object other) =>
      other is LoadRuntimeType &&
      result == other.result &&
      object == other.object;

  @override
  int get hashCode => result.hashCode ^ object.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadRuntimeType(writesTo ?? result, object);
  }
}
