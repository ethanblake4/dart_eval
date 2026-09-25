import 'package:control_flow_graph/control_flow_graph.dart';

final class NewList extends Operation {
  final SSA target;

  NewList(this.target);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = []';

  @override
  bool operator ==(Object other) => other is NewList && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return NewList(writesTo ?? target);
  }
}

final class IndexList extends Operation {
  final SSA target;
  final SSA list;
  final SSA index;

  IndexList(this.target, this.list, this.index);

  @override
  Set<SSA> get readsFrom => {list, index};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => CollectionOp.indexInto;

  @override
  String toString() => '$target = indexlist $list[$index]';

  @override
  bool operator ==(Object other) =>
      other is IndexList &&
      target == other.target &&
      list == other.list &&
      index == other.index;

  @override
  int get hashCode => target.hashCode ^ list.hashCode ^ index.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [list, index],
      this.readsFrom,
      readsFrom,
    );
    return IndexList(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class NewMap extends Operation {
  final SSA target;

  NewMap(this.target);

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = {}';

  @override
  bool operator ==(Object other) => other is NewMap && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return NewMap(writesTo ?? target);
  }
}

final class IndexMap extends Operation {
  final SSA target;
  final SSA map;
  final SSA key;

  IndexMap(this.target, this.map, this.key);

  @override
  Set<SSA> get readsFrom => {map, key};

  @override
  SSA? get writesTo => target;

  @override
  OpType get type => CollectionOp.indexInto;

  @override
  String toString() => '$target = indexmap $map[$key]';

  @override
  bool operator ==(Object other) =>
      other is IndexMap &&
      target == other.target &&
      map == other.map &&
      key == other.key;

  @override
  int get hashCode => target.hashCode ^ map.hashCode ^ key.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands([map, key], this.readsFrom, readsFrom);
    return IndexMap(writesTo ?? target, newReadsFrom[0], newReadsFrom[1]);
  }
}

final class ListSet extends Operation {
  final SSA list;
  final SSA index;
  final SSA value;

  ListSet(this.list, this.index, this.value);

  @override
  Set<SSA> get readsFrom => {list, index, value};

  @override
  OpType get type => CollectionOp.indexInto;

  @override
  String toString() => 'listset $list[$index] = $value';

  @override
  bool operator ==(Object other) =>
      other is ListSet &&
      list == other.list &&
      index == other.index &&
      value == other.value;

  @override
  int get hashCode => list.hashCode ^ index.hashCode ^ value.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [list, index, value],
      this.readsFrom,
      readsFrom,
    );
    return ListSet(newReadsFrom[0], newReadsFrom[1], newReadsFrom[2]);
  }
}

final class MapSet extends Operation {
  final SSA map;
  final SSA key;
  final SSA value;

  MapSet(this.map, this.key, this.value);

  @override
  Set<SSA> get readsFrom => {map, key, value};

  @override
  OpType get type => CollectionOp.indexInto;

  @override
  String toString() => 'mapset $map[$key] = $value';

  @override
  bool operator ==(Object other) =>
      other is MapSet &&
      map == other.map &&
      key == other.key &&
      value == other.value;

  @override
  int get hashCode => map.hashCode ^ key.hashCode ^ value.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final newReadsFrom = renameOperands(
      [map, key, value],
      this.readsFrom,
      readsFrom,
    );
    return MapSet(newReadsFrom[0], newReadsFrom[1], newReadsFrom[2]);
  }
}

/// Appends a value to an existing list; the list identity does not change.
final class ListAppend extends Operation {
  final SSA list;
  final SSA value;

  ListAppend(this.list, this.value);

  @override
  Set<SSA> get readsFrom => {list, value};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final inputs = renameOperands([list, value], this.readsFrom, readsFrom);
    return ListAppend(inputs[0], inputs[1]);
  }

  @override
  String toString() => 'append $list, $value';
}

final class NewRecord extends Operation {
  final SSA target;
  final SSA fields;
  final int fieldIndices;
  final int typeId;

  /// Whether the runtime type must be reified from the field values. Skipped
  /// when every field has a fixed runtime type ([TypeRef.hasFixedRuntimeType]).
  final bool reify;

  NewRecord(
    this.target,
    this.fields,
    this.fieldIndices,
    this.typeId, {
    this.reify = true,
  });

  @override
  SSA get writesTo => target;

  @override
  Set<SSA> get readsFrom => {fields};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => NewRecord(
    writesTo ?? target,
    readsFrom?.single ?? fields,
    fieldIndices,
    typeId,
    reify: reify,
  );

  @override
  String toString() => '$target = record $fields, $fieldIndices, $typeId';
}

final class NewSet extends Operation {
  final SSA target;

  NewSet(this.target);

  @override
  SSA get writesTo => target;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      NewSet(writesTo ?? target);

  @override
  String toString() => '$target = set {}';
}

final class SetAdd extends Operation {
  final SSA set;
  final SSA value;

  SetAdd(this.set, this.value);

  @override
  Set<SSA> get readsFrom => {set, value};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final inputs = renameOperands([set, value], this.readsFrom, readsFrom);
    return SetAdd(inputs[0], inputs[1]);
  }

  @override
  String toString() => 'setadd $set, $value';
}

final class IterableLength extends Operation {
  final SSA target;
  final SSA iterable;

  IterableLength(this.target, this.iterable);

  @override
  SSA get writesTo => target;

  @override
  Set<SSA> get readsFrom => {iterable};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      IterableLength(writesTo ?? target, readsFrom?.single ?? iterable);

  @override
  String toString() => '$target = length $iterable';
}

final class ListLength extends Operation {
  final SSA target;
  final SSA list;

  ListLength(this.target, this.list);

  @override
  SSA get writesTo => target;

  @override
  Set<SSA> get readsFrom => {list};

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      ListLength(writesTo ?? target, readsFrom?.single ?? list);

  @override
  String toString() => '$target = length $list';
}
