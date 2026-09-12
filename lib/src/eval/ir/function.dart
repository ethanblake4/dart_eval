import 'package:control_flow_graph/control_flow_graph.dart';

final class LoadFunctionPointer extends Operation {
  final SSA result;
  final String target;

  LoadFunctionPointer(this.result, this.target);

  @override
  SSA get writesTo => result;

  @override
  String toString() => '$result = functionptr $target';

  @override
  bool operator ==(Object other) =>
      other is LoadFunctionPointer &&
      result == other.result &&
      target == other.target;

  @override
  int get hashCode => result.hashCode ^ target.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return LoadFunctionPointer(writesTo ?? result, target);
  }
}

/// A value supplied by the caller, before register allocation chooses its slot.
final class Parameter extends Operation {
  final SSA target;
  final int index;

  Parameter(this.target, this.index);

  @override
  SSA get writesTo => target;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      Parameter(writesTo ?? target, index);

  @override
  String toString() => '$target = parameter $index';
}
