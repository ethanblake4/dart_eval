import 'package:control_flow_graph/control_flow_graph.dart';
import 'operands.dart';

/// A private field-slot marker, distinct from an initialized nullable value.
final class LoadUninitializedField extends Operation {
  LoadUninitializedField(this.target);
  final SSA target;
  @override
  SSA get writesTo => target;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      LoadUninitializedField(writesTo ?? target);
}

final class CreateClass extends Operation {
  final SSA target;
  final int library;
  final String name;
  final SSA $super;
  final int valuesLength;

  CreateClass(
    this.target,
    this.library,
    this.name,
    this.$super,
    this.valuesLength,
  );

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
      $super == other.$super &&
      valuesLength == other.valuesLength;

  @override
  int get hashCode =>
      target.hashCode ^
      library.hashCode ^
      name.hashCode ^
      $super.hashCode ^
      valuesLength.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return CreateClass(
      writesTo ?? target,
      library,
      name,
      readsFrom?.first ?? $super,
      valuesLength,
    );
  }
}

final class SetPropertyStatic extends Operation {
  final SSA object;
  final int index;
  final SSA value;
  final bool isLateFinal;

  SetPropertyStatic(
    this.object,
    this.index,
    this.value, {
    this.isLateFinal = false,
  });

  @override
  Set<SSA> get readsFrom => {value, object};

  @override
  String toString() => 'setpropstatic $object:$index = $value';

  @override
  bool operator ==(Object other) =>
      other is SetPropertyStatic &&
      object == other.object &&
      index == other.index &&
      isLateFinal == other.isLateFinal &&
      value == other.value;

  @override
  int get hashCode =>
      object.hashCode ^ index.hashCode ^ value.hashCode ^ isLateFinal.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final inputs = renameOperands([object, value], this.readsFrom, readsFrom);
    return SetPropertyStatic(
      inputs[0],
      index,
      inputs[1],
      isLateFinal: isLateFinal,
    );
  }
}

final class LoadPropertyStatic extends Operation {
  final SSA target;
  final SSA object;
  final int index;
  final bool isLate;

  LoadPropertyStatic(
    this.target,
    this.object,
    this.index, {
    this.isLate = false,
  });

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
      index == other.index &&
      isLate == other.isLate;

  @override
  int get hashCode =>
      target.hashCode ^ object.hashCode ^ index.hashCode ^ isLate.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadPropertyStatic(
      writesTo ?? target,
      readsFrom?.first ?? object,
      index,
      isLate: isLate,
    );
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadPropertyDynamic(
      writesTo ?? target,
      readsFrom?.first ?? object,
      name,
    );
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return SetPropertyDynamic(
      readsFrom?.first ?? object,
      name,
      readsFrom?.last ?? variable,
    );
  }
}

/// The source-level receiver, distinct from its lexical superclass field view.
final class LoadThis extends Operation {
  LoadThis(this.target, this.object);
  final SSA target;
  final SSA object;
  @override
  Set<SSA> get readsFrom => {object};
  @override
  SSA get writesTo => target;
  @override
  String toString() => '$target = loadthis $object';
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      LoadThis(writesTo ?? target, readsFrom?.first ?? object);
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadSuper(writesTo ?? target, readsFrom?.first ?? object);
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return DynamicEquals(
      writesTo ?? target,
      readsFrom?.first ?? left,
      readsFrom?.last ?? right,
    );
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
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final inputs = renameOperands([object, ...args], this.readsFrom, readsFrom);
    return InvokeDynamic(
      writesTo ?? target,
      inputs[0],
      name,
      inputs.sublist(1),
    );
  }
}
