import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// The binder's output: callee-order arguments, resolved type arguments,
/// the post-coercion receiver, and the call's return type.
final class BoundCall {
  const BoundCall({
    this.receiver,
    this.callee,
    required this.positional,
    required this.named,
    this.typeArguments = const {},
    this.runtimeTypeArguments = const [],
    required this.returnType,
    this.trusted = false,
    this.vectorOverride,
    this.declaredReturn,
  });

  /// The receiver after coercion — compound assignments and indexed
  /// references read the post-coercion values from here.
  final Variable? receiver;

  /// [ClosureCall]: the callee materialized into a fresh slot before the
  /// arguments compiled — an argument may redefine the slot the callee
  /// expression read (`f(f = g())` invokes the old `f`).
  final Variable? callee;
  final List<Variable> positional;
  final List<(String, Variable)> named;
  final Map<String, TypeRef> typeArguments;
  final List<int> runtimeTypeArguments;
  final TypeRef returnType;

  /// ClosureCall: every supplied argument proven against the static
  /// signature, so the runtime skips per-argument checks.
  final bool trusted;

  /// A precomputed call vector for bridge ABI padding or a leading receiver.
  final List<SSA>? vectorOverride;

  /// The callee's declared return type with call-site generics applied
  /// (declaration-vector paths only — null when the annotation wasn't
  /// generic-dependent or the target has no declaration).
  final TypeRef? declaredReturn;

  /// The named arguments as a name-to-variable map.
  Map<String, Variable> get namedValues => {for (final e in named) e.$1: e.$2};

  /// The flattened call vector: positionals then named values in
  /// declaration order.
  List<SSA> vector() =>
      vectorOverride ??
      [
        for (final arg in positional) arg.ssa,
        for (final entry in named) entry.$2.ssa,
      ];
}
