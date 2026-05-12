import 'package:control_flow_graph/control_flow_graph.dart';

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
      completer == other.completer &&
      subject == other.subject;

  @override
  int get hashCode => completer.hashCode ^ subject.hashCode;

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    return Await(
      writesTo ?? result,
      readsFrom?.firstWhere((s) => s == completer) ?? completer,
      readsFrom?.firstWhere((s) => s == subject) ?? subject,
    );
  }
}