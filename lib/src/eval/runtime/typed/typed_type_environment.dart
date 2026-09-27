/// Immutable bindings captured by a generic callable and its nested closures.
final class TypedTypeEnvironment {
  TypedTypeEnvironment(this.owners, List<int> arguments, this.parent)
    : arguments = List.unmodifiable(arguments);

  final List<int> owners;
  final List<int> arguments;
  final TypedTypeEnvironment? parent;

  int? lookup(int owner, int index) {
    for (
      TypedTypeEnvironment? scope = this;
      scope != null;
      scope = scope.parent
    ) {
      var parameterIndex = 0;
      for (var slot = 0; slot < scope.owners.length; slot++) {
        if (scope.owners[slot] == owner && parameterIndex++ == index) {
          return slot < scope.arguments.length ? scope.arguments[slot] : null;
        }
      }
    }
    return null;
  }
}
