/// Tags used after the nominal type and nullability entries in a runtime type
/// descriptor. Non-negative entries in that position remain generic arguments.
abstract final class RuntimeTypeDescriptorTag {
  static const function = -1;
  static const record = -2;
  static const typeParameter = -3;

  /// The owner slot of a type-parameter descriptor uses this value for a
  /// function or method parameter. Class parameters store their nominal type.
  static const callableTypeParameterOwner = -1;
}
