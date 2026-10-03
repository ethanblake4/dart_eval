import 'package:control_flow_graph/control_flow_graph.dart';

final class CreateLateLocal extends Operation {
  CreateLateLocal(this.result, this.name, this.isFinal);
  final SSA result;
  final String name;
  final bool isFinal;
  @override
  SSA get writesTo => result;
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) =>
      CreateLateLocal(writesTo ?? result, name, isFinal);
}

final class SetLateLocalInitializer extends Operation {
  SetLateLocalInitializer(this.cell, this.initializer);
  final SSA cell, initializer;
  @override
  Set<SSA> get readsFrom => {cell, initializer};
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) {
    final replacements = readsFrom == null
        ? <SSA, SSA>{}
        : Map<SSA, SSA>.fromIterables(this.readsFrom, readsFrom);
    return SetLateLocalInitializer(
      replacements[cell] ?? cell,
      replacements[initializer] ?? initializer,
    );
  }
}

final class ReadLateLocal extends Operation {
  ReadLateLocal(this.result, this.cell);
  final SSA result, cell;
  @override
  SSA get writesTo => result;
  @override
  Set<SSA> get readsFrom => {cell};
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) =>
      ReadLateLocal(writesTo ?? result, readsFrom?.single ?? cell);
}

final class WriteLateLocal extends Operation {
  WriteLateLocal(this.cell, this.value);
  final SSA cell, value;
  @override
  Set<SSA> get readsFrom => {cell, value};
  @override
  Operation copyWith({SSA? writesTo, Set<SSA>? readsFrom}) {
    final replacements = readsFrom == null
        ? <SSA, SSA>{}
        : Map<SSA, SSA>.fromIterables(this.readsFrom, readsFrom);
    return WriteLateLocal(
      replacements[cell] ?? cell,
      replacements[value] ?? value,
    );
  }
}
