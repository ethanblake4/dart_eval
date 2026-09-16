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
    this.hasEnvironment = true,
    this.boundReceiver = false,
  }) : namedNames = List.unmodifiable(namedNames),
       requiredNamed = List.unmodifiable(requiredNamed),
       positionalDefaults = List.unmodifiable(positionalDefaults),
       namedDefaults = List.unmodifiable(namedDefaults);

  final int functionId, captureCount, positionalCount, requiredPositional;
  final List<String> namedNames, requiredNamed;
  final List<Object?> positionalDefaults, namedDefaults;
  final bool hasEnvironment, boundReceiver;
  int get argumentCount => positionalCount + namedNames.length;
}

/// Source-order arguments at a closure call, followed by named argument values.
final class TypedClosureCall {
  TypedClosureCall(this.positionalCount, {List<String> namedNames = const []})
    : namedNames = List.unmodifiable(namedNames);
  final int positionalCount;
  final List<String> namedNames;
  int get argumentCount => positionalCount + namedNames.length;
  int get overflowCount => argumentCount > 2 ? argumentCount - 1 : 0;
}
