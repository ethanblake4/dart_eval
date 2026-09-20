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
    this.kind = TypedMemberKind.method,
  }) : positionalCount = positionalCount ?? argumentCount;

  final String name;
  final int argumentCount;
  final int positionalCount;
  final List<String> namedNames;
  final String callerLibrary;
  final List<int> typeArguments;
  final TypedMemberKind kind;
}
