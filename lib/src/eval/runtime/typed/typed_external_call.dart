/// A bridge function invoked with canonical object arguments in R/S/C.
final class TypedExternalCall {
  const TypedExternalCall(this.externalFunctionId, this.argumentCount);

  final int externalFunctionId;
  final int argumentCount;

  /// With more than three arguments, C holds arguments two onward in a list.
  int get overflowCount => argumentCount > 3 ? argumentCount - 2 : 0;
}
