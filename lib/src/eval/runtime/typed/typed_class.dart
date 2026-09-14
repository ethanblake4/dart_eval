/// Class members refer to entries in the owning program's function table.
/// Field storage contains the representations selected by the compiler.
final class TypedClass {
  TypedClass(
    this.name, {
    required this.library,
    required this.valueCount,
    Map<String, int> methods = const {},
    Map<String, int> getters = const {},
    Map<String, int> setters = const {},
  }) : methods = Map.unmodifiable(methods),
       getters = Map.unmodifiable(getters),
       setters = Map.unmodifiable(setters);

  final String name;
  final String library;
  final int valueCount;
  final Map<String, int> methods;
  final Map<String, int> getters;
  final Map<String, int> setters;
}
