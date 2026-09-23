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
    this.superDispatch = false,
  }) : positionalCount = positionalCount ?? argumentCount;

  final String name;
  final int argumentCount;
  final int positionalCount;
  final List<String> namedNames;
  final String callerLibrary;
  final List<int> typeArguments;
  final TypedMemberKind kind;

  /// `super.m(...)` (and super property access): member resolution starts
  /// at the receiver's own chain link instead of the dispatch root.
  final bool superDispatch;
}
