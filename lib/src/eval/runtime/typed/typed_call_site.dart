/// Member dispatch metadata. Argument count excludes the receiver.
enum TypedMemberKind { method, getter, setter }

final class TypedCallSite {
  const TypedCallSite(
    this.name, {
    required this.argumentCount,
    int? positionalCount,
    this.namedNames = const [],
    this.callerLibrary = '',
    this.typeArguments = const [],
    this.argumentTypes = const [],
    this.kind = TypedMemberKind.method,
  }) : positionalCount = positionalCount ?? argumentCount;

  final String name;
  final int argumentCount;
  final int positionalCount;
  final List<String> namedNames;
  final String callerLibrary;
  final List<int> typeArguments;

  /// Compiler-proven concrete argument types, or -1 where no proof exists.
  /// An empty list supplies no proof for calls with arguments.
  final List<int> argumentTypes;
  final TypedMemberKind kind;

  /// The fixed shape required by the checked native append instruction.
  bool get isListAppend =>
      kind == TypedMemberKind.method &&
      name == 'add' &&
      argumentCount == 1 &&
      positionalCount == 1 &&
      namedNames.isEmpty &&
      typeArguments.isEmpty;

  /// The fixed shape required by the native indexed-read instruction.
  bool get isIndexRead =>
      kind == TypedMemberKind.method &&
      name == '[]' &&
      argumentCount == 1 &&
      positionalCount == 1 &&
      namedNames.isEmpty &&
      typeArguments.isEmpty;
}
