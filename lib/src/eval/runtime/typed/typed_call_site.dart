/// Member dispatch metadata. Argument count excludes the receiver.
enum TypedMemberKind { method, getter, setter }

final class TypedCallSite {
  const TypedCallSite(
    this.name, {
    required this.argumentCount,
    this.kind = TypedMemberKind.method,
  });

  final String name;
  final int argumentCount;
  final TypedMemberKind kind;
}
