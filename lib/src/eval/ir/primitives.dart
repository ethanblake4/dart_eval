import 'package:control_flow_graph/control_flow_graph.dart';

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
  Operation copyWith({SSA? writesTo}) {
    return BoxInt(writesTo ?? target, source);
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
  Operation copyWith({SSA? writesTo}) {
    return BoxNum(writesTo ?? target, source);
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
  Operation copyWith({SSA? writesTo}) {
    return BoxString(writesTo ?? target, source);
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
  Operation copyWith({SSA? writesTo}) {
    return BoxDouble(writesTo ?? target, source);
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
  Operation copyWith({SSA? writesTo}) {
    return BoxBool(writesTo ?? target, source);
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
  Operation copyWith({SSA? writesTo}) {
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
  Operation copyWith({SSA? writesTo}) {
    return MaybeBoxNull(writesTo ?? target, source);
  }
}

final class BoxList extends Operation {
  final SSA target;
  final SSA source;

  BoxList(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxlist $source';

  @override
  bool operator ==(Object other) =>
      other is BoxList && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return BoxList(writesTo ?? target, source);
  }
}

final class BoxMap extends Operation {
  final SSA target;
  final SSA source;

  BoxMap(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = boxmap $source';

  @override
  bool operator ==(Object other) =>
      other is BoxMap && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return BoxMap(writesTo ?? target, source);
  }
}

final class Unbox extends Operation {
  final SSA target;
  final SSA source;

  Unbox(this.target, this.source);

  @override
  Set<SSA> get readsFrom => {source};

  @override
  SSA? get writesTo => target;

  @override
  String toString() => '$target = unbox $source';

  @override
  bool operator ==(Object other) =>
      other is Unbox && target == other.target && source == other.source;

  @override
  int get hashCode => target.hashCode ^ source.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return Unbox(writesTo ?? target, source);
  }
}
