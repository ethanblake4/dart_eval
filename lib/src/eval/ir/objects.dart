import 'package:control_flow_graph/control_flow_graph.dart';

final class CreateClass extends Operation {
  final SSA target;
  final int library;
  final String name;
  final SSA $super;
  final int valuesLength;

  CreateClass(
      this.target, this.library, this.name, this.$super, this.valuesLength);

  @override
  Set<SSA> get readsFrom => {$super};

  @override
  SSA? get writesTo => target;

  @override
  String toString() =>
      '$target = createclass $library:$name $valuesLength super=${$super}';

  @override
  bool operator ==(Object other) =>
      other is CreateClass &&
      target == other.target &&
      library == other.library &&
      name == other.name &&
      valuesLength == other.valuesLength;

  @override
  int get hashCode =>
      target.hashCode ^
      library.hashCode ^
      name.hashCode ^
      valuesLength.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return CreateClass(writesTo ?? target, library, name, $super, valuesLength);
  }
}

final class SetPropertyStatic extends Operation {
  final SSA object;
  final int index;
  final SSA value;

  SetPropertyStatic(this.object, this.index, this.value);

  @override
  Set<SSA> get readsFrom => {value, object};

  @override
  String toString() => 'setpropstatic $object:$index = $value';

  @override
  bool operator ==(Object other) =>
      other is SetPropertyStatic &&
      object == other.object &&
      index == other.index &&
      value == other.value;

  @override
  int get hashCode => object.hashCode ^ index.hashCode ^ value.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return this;
  }
}

final class LoadPropertyStatic extends Operation {
  final SSA target;
  final SSA object;
  final int index;

  LoadPropertyStatic(this.target, this.object, this.index);

  @override
  Set<SSA> get readsFrom => {object};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = getpropstatic $object:$index';

  @override
  bool operator ==(Object other) =>
      other is LoadPropertyStatic &&
      target == other.target &&
      object == other.object &&
      index == other.index;

  @override
  int get hashCode => target.hashCode ^ object.hashCode ^ index.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadPropertyStatic(writesTo ?? target, object, index);
  }
}

final class LoadSuper extends Operation {
  final SSA target;
  final SSA object;

  LoadSuper(this.target, this.object);

  @override
  Set<SSA> get readsFrom => {object};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = loadsuper $object';

  @override
  bool operator ==(Object other) =>
      other is LoadSuper && target == other.target && object == other.object;

  @override
  int get hashCode => target.hashCode ^ object.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadSuper(writesTo ?? target, object);
  }
}
