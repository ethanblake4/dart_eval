import 'package:control_flow_graph/control_flow_graph.dart';
import 'operands.dart';

final class Await extends Operation {
  final SSA result;
  final SSA completer;
  final SSA subject;

  Await(this.result, this.completer, this.subject);

  @override
  Set<SSA> get readsFrom => {completer, subject};

  @override
  SSA? get writesTo => result;

  @override
  String toString() => '$result = await $subject, completer: $completer';

  @override
  bool operator ==(Object other) =>
      other is Await &&
      result == other.result &&
      completer == other.completer &&
      subject == other.subject;

  @override
  int get hashCode => Object.hash(result, completer, subject);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final inputs = renameOperands(
      [completer, subject],
      this.readsFrom,
      readsFrom,
    );
    return Await(writesTo ?? result, inputs[0], inputs[1]);
  }
}
