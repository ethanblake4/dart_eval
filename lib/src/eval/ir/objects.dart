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

final class LoadPropertyDynamic extends Operation {
  final SSA target;
  final SSA object;
  final String name;

  LoadPropertyDynamic(this.target, this.object, this.name);

  @override
  Set<SSA> get readsFrom => {object};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = getpropdynamic $object:"$name"';

  @override
  bool operator ==(Object other) =>
      other is LoadPropertyDynamic &&
      target == other.target &&
      object == other.object &&
      name == other.name;

  @override
  int get hashCode => target.hashCode ^ object.hashCode ^ name.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadPropertyDynamic(writesTo ?? target, object, name);
  }
}

final class SetPropertyDynamic extends Operation {
  final SSA object;
  final String name;
  final SSA variable;

  SetPropertyDynamic(this.object, this.name, this.variable);

  @override
  Set<SSA> get readsFrom => {object, variable};

  @override
  SSA? get writesTo => null;

  @override
  String toString() => 'setpropdynamic $object:"$name" = $variable';

  @override
  bool operator ==(Object other) =>
      other is SetPropertyDynamic &&
      variable == other.variable &&
      object == other.object &&
      name == other.name;

  @override
  int get hashCode => variable.hashCode ^ object.hashCode ^ name.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return SetPropertyDynamic(object, name, variable);
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

final class DynamicEquals extends Operation {
  final SSA target;
  final SSA left;
  final SSA right;

  DynamicEquals(this.target, this.left, this.right);

  @override
  Set<SSA> get readsFrom => {left, right};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = $left dyneq $right';

  @override
  bool operator ==(Object other) =>
      other is DynamicEquals &&
      target == other.target &&
      left == other.left &&
      right == other.right;

  @override
  int get hashCode => target.hashCode ^ left.hashCode ^ right.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return DynamicEquals(writesTo ?? target, left, right);
  }
}

final class InvokeDynamic extends Operation {
  final SSA target;
  final SSA object;
  final String name;
  final List<SSA> args;

  InvokeDynamic(this.target, this.object, this.name, this.args);

  @override
  Set<SSA> get readsFrom => {...args, object};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = invokedynamic $object.$name $args';

  @override
  bool operator ==(Object other) =>
      other is InvokeDynamic &&
      target == other.target &&
      object == other.object &&
      name == other.name &&
      args == other.args;

  @override
  int get hashCode =>
      target.hashCode ^
      object.hashCode ^
      name.hashCode ^
      object.hashCode ^
      args.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return InvokeDynamic(writesTo ?? target, object, name, args);
  }
}
