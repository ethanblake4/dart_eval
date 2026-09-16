import 'typed_function.dart';

/// Storage representation and optional lazy initializer for one global slot.
final class TypedGlobal {
  const TypedGlobal({
    this.initializerFunction = -1,
    this.kind = TypedArgumentKind.object,
    this.isLate = false,
    this.isFinal = false,
    this.name = '',
  });

  final int initializerFunction;
  final TypedArgumentKind kind;
  final bool isLate, isFinal;
  final String name;
}
