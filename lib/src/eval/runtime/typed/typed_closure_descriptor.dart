/// Callable signature and captured storage for a closure or function tear-off.
final class TypedClosureDescriptor {
  TypedClosureDescriptor(
    this.functionId, {
    required this.captureCount,
    required this.positionalCount,
    required this.requiredPositional,
    List<String> namedNames = const [],
    List<String> requiredNamed = const [],
    List<Object?> positionalDefaults = const [],
    List<Object?> namedDefaults = const [],
    List<int> defaultThunks = const [],
    List<int> parameterTypeIds = const [],
    List<int> parameterTypeParameterIndices = const [],
    List<bool> parameterNullable = const [],
    List<int> typeParameterBounds = const [],
    this.runtimeTypeId = -1,
    this.hasEnvironment = true,
    this.boundReceiver = false,
    this.isInstantiationAdapter = false,
  }) : namedNames = List.unmodifiable(namedNames),
       requiredNamed = List.unmodifiable(requiredNamed),
       positionalDefaults = List.unmodifiable(positionalDefaults),
       namedDefaults = List.unmodifiable(namedDefaults),
       defaultThunks = List.unmodifiable(defaultThunks),
       parameterTypeIds = List.unmodifiable(parameterTypeIds),
       parameterTypeParameterIndices = List.unmodifiable(
         parameterTypeParameterIndices.isEmpty
             ? List.filled(parameterTypeIds.length, -1)
             : parameterTypeParameterIndices,
       ),
       parameterNullable = List.unmodifiable(parameterNullable),
       typeParameterBounds = List.unmodifiable(typeParameterBounds),
       needsCovariantParameterChecks =
           boundReceiver && parameterTypeIds.any((id) => id >= 0);

  final int functionId, captureCount, positionalCount, requiredPositional;
  final List<String> namedNames, requiredNamed;
  final List<Object?> positionalDefaults, namedDefaults;

  /// Function indices of hidden zero-arg default thunks, parallel to
  /// `[...positionalDefaults, ...namedDefaults]`; `-1` uses the scalar.
  final List<int> defaultThunks;
  final List<int> parameterTypeIds;
  final List<int> parameterTypeParameterIndices;
  final List<bool> parameterNullable;
  final List<int> typeParameterBounds;
  final bool hasEnvironment, boundReceiver;

  /// Whether this descriptor is a `<generic function adapter>`: a closure that
  /// forwards a captured callable with resolved type arguments. Instantiated
  /// tear-offs created at different sites get distinct function ids, so
  /// equality compares the captured callable and resolved signature instead.
  final bool isInstantiationAdapter;
  final int runtimeTypeId;

  /// Whether this is a bound-method tear-off with runtime-checked
  /// parameters. Method parameters are covariant — a tear-off may be invoked
  /// through a static signature wider than the callee's own — so a trusted
  /// call site cannot see the real contract and such closures must run their
  /// per-argument checks even on trusted calls.
  final bool needsCovariantParameterChecks;

  int get argumentCount => positionalCount + namedNames.length;

  bool accepts(int positionalArguments, Iterable<String> namedArguments) {
    if (positionalArguments < requiredPositional ||
        positionalArguments > positionalCount) {
      return false;
    }
    // Skip the Set allocation for the common positional-only call.
    if (namedArguments.isEmpty) return requiredNamed.isEmpty;
    final supplied = namedArguments.toSet();
    if (supplied.length != namedArguments.length ||
        supplied.any((name) => !namedNames.contains(name)) ||
        requiredNamed.any((name) => !supplied.contains(name))) {
      return false;
    }
    return true;
  }
}

/// Source-order arguments at a closure call, followed by named argument values.
final class TypedClosureCall {
  TypedClosureCall(
    this.positionalCount, {
    List<String> namedNames = const [],
    List<int> typeArguments = const [],
    this.trusted = false,
  }) : namedNames = List.unmodifiable(namedNames),
       typeArguments = List.unmodifiable(typeArguments);
  final int positionalCount;
  final List<String> namedNames;
  final List<int> typeArguments;
  final bool trusted;
  int get argumentCount => positionalCount + namedNames.length;
  int get overflowCount => argumentCount > 2 ? argumentCount - 1 : 0;
}
