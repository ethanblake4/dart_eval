// ignore_for_file: experimental_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:control_flow_graph/control_flow_graph.dart';

class CompilerLabel {
  final void Function(CompilerContext ctx) cleanup;
  final BasicBlock? breakTarget;
  final BasicBlock? continueTarget;
  final int exceptionDepth;

  /// Names this label answers to in `break`/`continue` statements — the
  /// identifiers of a wrapping `LabeledStatement` (`outer:` in
  /// `outer: while (...)`).
  final Set<String> names;

  const CompilerLabel(
    this.cleanup, {
    this.breakTarget,
    this.continueTarget,
    this.names = const {},
    required this.exceptionDepth,
  });
}

/// Where a `return` inside an anonymous-method block lands: the value is
/// stored into [resultName] (a compiler-generated local) and control jumps
/// to [exit]. Tracked on `CompilerContext.anonymousMethodReturns`, keyed by
/// the invocation node.
class AnonymousMethodReturn {
  AnonymousMethodReturn({
    required this.node,
    required this.exit,
    required this.resultName,
    this.boundType,
    required this.initialState,
    required this.exceptionDepth,
  });

  final AnonymousMethodInvocation node;
  final BasicBlock exit;
  final String resultName;

  /// The invocation's context type — `return` expressions inside the body
  /// are compiled against it.
  final TypeRef? boundType;

  /// Static types of every `return` value compiled against this return —
  /// joined into the invocation's result type when the body finishes.
  final Set<TypeRef> types = {};

  final ContextSaveState initialState;
  final int exceptionDepth;
}
