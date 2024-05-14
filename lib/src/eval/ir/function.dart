import 'package:control_flow_graph/control_flow_graph.dart';

final class LoadFunctionPointer extends Operation {
  final SSA result;
  final String target;

  LoadFunctionPointer(this.result, this.target);

  @override
  String toString() => '$result = functionptr ${target}';

  @override
  bool operator ==(Object other) =>
      other is LoadFunctionPointer && target == other.target;

  @override
  int get hashCode => result.hashCode ^ target.hashCode;

  @override
  Operation copyWith({SSA? writesTo}) {
    return LoadFunctionPointer(writesTo ?? result, target);
  }
}
