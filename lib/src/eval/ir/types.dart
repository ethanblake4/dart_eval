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
    return IsType(writesTo ?? object, typeId);
  }
}
