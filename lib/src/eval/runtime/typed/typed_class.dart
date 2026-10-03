/// Class members refer to entries in the owning program's function table.
/// Field storage contains the representations selected by the compiler.
final class TypedClass {
  TypedClass(
    this.name, {
    required this.library,
    required this.valueCount,
    this.hasBridgeCallMethod = false,
    Set<String> noSuchMethodForwarders = const {},
    Map<int, int> methodRuntimeTypes = const {},
    Map<String, int> methods = const {},
    Map<String, int> getters = const {},
    Map<String, int> setters = const {},
  }) : noSuchMethodForwarders = Set.unmodifiable(noSuchMethodForwarders),
       methodRuntimeTypes = Map.unmodifiable(methodRuntimeTypes),
       methods = Map.unmodifiable(methods),
       getters = Map.unmodifiable(getters),
       setters = Map.unmodifiable(setters);

  final String name;
  final String library;
  final int valueCount;

  /// Only an inherited bridge method makes an implicit bridge call eligible.
  final bool hasBridgeCallMethod;

  /// Missing interface methods that have implicit noSuchMethod tear-offs.
  final Set<String> noSuchMethodForwarders;

  /// Receiver-specific signatures for inherited methods with forwarding checks.
  final Map<int, int> methodRuntimeTypes;
  final Map<String, int> methods;
  final Map<String, int> getters;
  final Map<String, int> setters;
}
