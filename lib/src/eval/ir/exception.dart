import 'package:control_flow_graph/control_flow_graph.dart';

/// Installs the exception and finally destinations for a protected region.
final class EnterTry extends Operation {
  final String? catchTarget;
  final String? finallyTarget;
  EnterTry({this.catchTarget, this.finallyTarget});
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => this;
}

final class LeaveTry extends Operation {
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => this;
}

/// The exception supplied on entry to a handler.
final class CaughtException extends Operation {
  final SSA result;
  CaughtException(this.result);
  @override
  SSA get writesTo => result;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      CaughtException(writesTo ?? result);
}

final class CaughtStackTrace extends Operation {
  final SSA result;
  CaughtStackTrace(this.result);
  @override
  SSA get writesTo => result;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      CaughtStackTrace(writesTo ?? result);
}

/// Resumes a pending return/throw after finally, or continues normally.
final class ResumeCompletion extends Operation {
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => this;
}
