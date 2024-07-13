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
  Operation copyWith({SSA? writesTo}) {
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
  Operation copyWith({SSA? writesTo}) {
    return IndexList(writesTo ?? target, list, index);
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
  Operation copyWith({SSA? writesTo}) {
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
  Operation copyWith({SSA? writesTo}) {
    return IndexMap(writesTo ?? target, map, key);
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
  Operation copyWith({SSA? writesTo}) {
    return ListSet(list, index, writesTo ?? value);
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
  Operation copyWith({SSA? writesTo}) {
    return MapSet(map, key, writesTo ?? value);
  }
}
