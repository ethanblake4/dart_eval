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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return AssertType(readsFrom?.first ?? object, typeId);
  }
}

final class IsType extends Operation {
  final SSA result;
  final SSA object;
  final int typeId;
  final bool not;

  IsType(this.result, this.object, this.typeId, this.not);

  @override
  SSA get writesTo => result;

  @override
  Set<SSA> get readsFrom => {object};

  @override
  String toString() => 'istype $object is${not ? "!" : ""} $typeId';

  @override
  bool operator ==(Object other) =>
      other is IsType &&
      result == other.result &&
      object == other.object &&
      typeId == other.typeId &&
      not == other.not;

  @override
  int get hashCode => Object.hash(result, object, typeId, not);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return IsType(writesTo ?? result, readsFrom?.first ?? object, typeId, not);
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadConstantType(writesTo ?? result, typeId);
  }
}

/// Adopts an integer runtime type id (a constructor's trailing type argument)
/// as the frame's type environment, so type parameters of the constructed
/// class resolve against the instantiated type.
final class SetTypeEnvironment extends Operation {
  final SSA typeId;

  SetTypeEnvironment(this.typeId);

  @override
  Set<SSA> get readsFrom => {typeId};

  @override
  String toString() => 'settypeenvironment $typeId';

  @override
  bool operator ==(Object other) =>
      other is SetTypeEnvironment && typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return SetTypeEnvironment(readsFrom?.single ?? typeId);
  }
}

/// Resolves a runtime type descriptor index against the frame's type
/// environment, producing the concrete runtime type id as an integer.
/// Constructor calls use it to deliver the instantiated type to the callee.
final class ResolveTypeId extends Operation {
  final SSA result;
  final int typeId;

  ResolveTypeId(this.result, this.typeId);

  @override
  SSA? get writesTo => result;

  @override
  String toString() => '$result = resolvetypeid $typeId';

  @override
  bool operator ==(Object other) =>
      other is ResolveTypeId && result == other.result && typeId == other.typeId;

  @override
  int get hashCode => result.hashCode ^ typeId.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return ResolveTypeId(writesTo ?? result, typeId);
  }
}

/// Loads a `Type` object for a type parameter, resolved against the frame's
/// type environment at runtime. [typeId] is the runtime descriptor index of
/// the type parameter reference.
final class LoadTypeParameter extends Operation {
  final SSA result;
  final int typeId;

  LoadTypeParameter(this.result, this.typeId);

  @override
  SSA? get writesTo => result;

  @override
  String toString() => '$result = loadtypeparameter $typeId';

  @override
  bool operator ==(Object other) =>
      other is LoadTypeParameter &&
      result == other.result &&
      typeId == other.typeId;

  @override
  int get hashCode => result.hashCode ^ typeId.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadTypeParameter(writesTo ?? result, typeId);
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadRuntimeType(writesTo ?? result, readsFrom?.first ?? object);
  }
}
