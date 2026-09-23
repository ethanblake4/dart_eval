import 'package:analyzer/dart/ast/ast.dart' show TypeParameter;
import 'package:control_flow_graph/control_flow_graph.dart' show SSA;
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/variable.dart';

/// How the binder treats arguments the caller did not supply.
enum BindingPolicy {
  /// Full typed vector; omitted parameters get compiled defaults.
  callerFillsDefaults,

  /// Supplied arguments only; the runtime binds names and defaults.
  calleeBinds,

  /// Flattened positional vector; named arguments in declaration order
  /// with shared null placeholders.
  bridgeVector,
}

/// Whether a member *value* call evaluates the read or the arguments first.
enum EvalOrder { argumentsFirst, readFirst }


/// A matched, compiled, and coerced argument.
final class BoundArgument {
  const BoundArgument(this.value, {this.supplied = true});

  final Variable value;

  /// False for defaults filled by the binder.
  final bool supplied;
}

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
    this.genericReturnBoxed,
    this.classTypeParameters,
  });

  /// The receiver after coercion — compound assignments and indexed
  /// references read the post-coercion values from here.
  final Variable? receiver;

  /// [ClosureCall]: the callee materialized into a fresh slot before the
  /// arguments compiled — an argument may redefine the slot the callee
  /// expression read (`f(f = g())` invokes the old `f`).
  final Variable? callee;
  final List<BoundArgument> positional;
  final List<(String, BoundArgument)> named;
  final Map<String, TypeRef> typeArguments;
  final List<int> runtimeTypeArguments;
  final TypeRef returnType;

  /// ClosureCall: every supplied argument proven against the static
  /// signature, so the runtime skips per-argument checks.
  final bool trusted;

  /// A precomputed call vector for legacy arg machinery whose ordering
  /// doesn't decompose into positional-then-named (dynamic source order,
  /// bridge padded ABI).
  final List<SSA>? vectorOverride;

  /// The callee's declared return type with call-site generics applied
  /// (declaration-vector paths only — null when the annotation wasn't
  /// generic-dependent or the target has no declaration).
  final TypeRef? declaredReturn;

  /// Whether generic substitution narrowed the language return type without
  /// changing the callee's compiled ABI, forcing the result to stay boxed.
  final bool? genericReturnBoxed;

  /// The declaring class's type parameters, in order, when the bound call
  /// targets a constructor declaration.
  final List<TypeParameter>? classTypeParameters;

  /// The provided positional arguments as plain variables.
  List<Variable> get positionalValues => [
    for (final arg in positional) arg.value,
  ];

  /// The named arguments as a name-to-variable map.
  Map<String, Variable> get namedValues => {
    for (final e in named) e.$1: e.$2.value,
  };

  /// The flattened call vector: positionals then named values in
  /// declaration order.
  List<SSA> vector() =>
      vectorOverride ??
      [
        for (final arg in positional) arg.value.ssa,
        for (final entry in named) entry.$2.value.ssa,
      ];
}
