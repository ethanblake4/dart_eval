import 'package:control_flow_graph/control_flow_graph.dart';

/// Starts an async invocation without going through the bridge call ABI.
final class BeginAsync extends Operation {
  BeginAsync(this.result, {required this.runtimeTypeId});
  final SSA result;
  int runtimeTypeId;
  @override
  SSA get writesTo => result;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      BeginAsync(writesTo ?? result, runtimeTypeId: runtimeTypeId);
}

final class Await extends Operation {
  final SSA result;
  final SSA completer;
  final SSA subject;

  /// Runtime descriptor id of `Future<flatten(T)>` where `T` is the
  /// subject's static type — `await` only suspends on a value matching it
  /// (a `Future<C1>` under static type `X extends A` returns unawaited).
  final int awaitTypeId;

  Await(this.result, this.completer, this.subject, this.awaitTypeId);

  @override
  Set<SSA> get readsFrom => {completer, subject};

  @override
  SSA? get writesTo => result;

  @override
  String toString() =>
      '$result = await $subject, completer: $completer, type: $awaitTypeId';

  @override
  bool operator ==(Object other) =>
      other is Await &&
      result == other.result &&
      completer == other.completer &&
      subject == other.subject &&
      awaitTypeId == other.awaitTypeId;

  @override
  int get hashCode => Object.hash(result, completer, subject, awaitTypeId);

  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) {
    final inputs = renameOperands(
      [completer, subject],
      this.readsFrom,
      readsFrom,
    );
    return Await(writesTo ?? result, inputs[0], inputs[1], awaitTypeId);
  }
}
