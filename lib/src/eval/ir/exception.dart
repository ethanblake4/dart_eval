import 'package:control_flow_graph/control_flow_graph.dart';
import 'representation.dart';

/// A frame-local slot whose contents survive abrupt control transfers.
final class ExceptionSlot {
  ExceptionSlot(this.name, this.representation);
  final String name;
  final MachineRepresentation representation;
}

final class StoreExceptionSlot extends Operation {
  StoreExceptionSlot(this.slot, this.value);
  final ExceptionSlot slot;
  final SSA value;
  @override
  Set<SSA> get readsFrom => {value};
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      StoreExceptionSlot(slot, readsFrom?.single ?? value);
}

final class LoadExceptionSlot extends Operation {
  LoadExceptionSlot(this.result, this.slot);
  final SSA result;
  final ExceptionSlot slot;
  @override
  bool get isPure => true;
  @override
  SSA get writesTo => result;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) =>
      LoadExceptionSlot(writesTo ?? result, slot);
}

/// Transfers control after unwinding protected regions down to [targetDepth].
final class CompleteJump extends Operation {
  CompleteJump(this.target, this.targetDepth);
  final String target;
  final int targetDepth;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => this;
}

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
  ResumeCompletion({this.terminal = false});
  final bool terminal;
  @override
  bool get isTerminator => terminal;
  @override
  Operation copyWith({Set<SSA>? readsFrom, SSA? writesTo}) => this;
}
