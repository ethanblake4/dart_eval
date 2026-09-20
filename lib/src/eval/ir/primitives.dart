import 'package:control_flow_graph/control_flow_graph.dart';

import 'representation.dart';

final class BoxSet extends Operation {
  final SSA target;
  final SSA source;
  final int runtimeTypeId;

  BoxSet(this.target, this.source, {required this.runtimeTypeId});
  @override
  SSA get writesTo => target;
  @override
  Set<SSA> get readsFrom => {source};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => BoxSet(
    writesTo ?? target,
    readsFrom?.single ?? source,
    runtimeTypeId: runtimeTypeId,
  );
}

final class BoxInt extends Operation {
  final SSA target;
  final SSA source;

  BoxInt(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxint $source';

  @override
  bool operator ==(Object other) =>
      other is BoxInt && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxInt(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class BoxNum extends Operation {
  final SSA target;
  final SSA source;

  BoxNum(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxnum $source';

  @override
  bool operator ==(Object other) =>
      other is BoxNum && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxNum(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class BoxString extends Operation {
  final SSA target;
  final SSA source;

  BoxString(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxstring $source';

  @override
  bool operator ==(Object other) =>
      other is BoxString && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxString(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class BoxDouble extends Operation {
  final SSA target;
  final SSA source;

  BoxDouble(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxdouble $source';

  @override
  bool operator ==(Object other) =>
      other is BoxDouble && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxDouble(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class BoxBool extends Operation {
  final SSA target;
  final SSA source;

  BoxBool(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxbool $source';

  @override
  bool operator ==(Object other) =>
      other is BoxBool && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxBool(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class BoxNull extends Operation {
  final SSA target;

  BoxNull(this.target);

  @override
  Set<SSA> get readsFrom => {};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxnull';

  @override
  bool operator ==(Object other) => other is BoxNull && target == other.target;

  @override
  int get hashCode => target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxNull(writesTo ?? target);
  }
}

final class MaybeBoxNull extends Operation {
  final SSA target;
  final SSA source;

  MaybeBoxNull(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxnullq $source';

  @override
  bool operator ==(Object other) =>
      other is MaybeBoxNull && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return MaybeBoxNull(writesTo ?? target, readsFrom?.first ?? source);
  }
}

final class BoxList extends Operation {
  final SSA target;
  final SSA source;
  final int? runtimeTypeId;

  BoxList(this.target, this.source, {this.runtimeTypeId});

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxlist $source';

  @override
  bool operator ==(Object other) =>
      other is BoxList &&
      target == other.target &&
      source == other.source &&
      runtimeTypeId == other.runtimeTypeId;

  @override
  int get hashCode => Object.hash(target, source, runtimeTypeId);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxList(
      writesTo ?? target,
      readsFrom?.first ?? source,
      runtimeTypeId: runtimeTypeId,
    );
  }
}

final class BoxMap extends Operation {
  final SSA target;
  final SSA source;
  final int runtimeTypeId;

  BoxMap(this.target, this.source, {required this.runtimeTypeId});

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxmap $source';

  @override
  bool operator ==(Object other) =>
      other is BoxMap &&
      target == other.target &&
      source == other.source &&
      runtimeTypeId == other.runtimeTypeId;

  @override
  int get hashCode => Object.hash(target, source, runtimeTypeId);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return BoxMap(
      writesTo ?? target,
      readsFrom?.first ?? source,
      runtimeTypeId: runtimeTypeId,
    );
  }
}

final class Unbox extends Operation {
  final SSA target;
  final SSA source;
  final MachineRepresentation representation;

  Unbox(this.target, this.source, this.representation);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = unbox $source';

  @override
  bool operator ==(Object other) =>
      other is Unbox &&
      target == other.target &&
      source == other.source &&
      representation == other.representation;

  @override
  int get hashCode => Object.hash(target, source, representation);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return Unbox(
      writesTo ?? target,
      readsFrom?.first ?? source,
      representation,
    );
  }
}
