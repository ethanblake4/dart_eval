/// Tags used after the nominal type and nullability entries in a runtime type
/// descriptor. Non-negative entries in that position remain generic arguments.
abstract final class RuntimeTypeDescriptorTag {
  static const function = -1;
  static const record = -2;
  static const typeParameter = -3;
  static const futureOr = -4;

  /// The owner slot of a type-parameter descriptor is negative for any
  /// callable parameter: -(4 + seq) identifies the declaring callable's
  /// parameter space (function, method, closure, or signature binder), so
  /// nested signatures do not alias an enclosing scope's parameters. Class
  /// parameters store their nominal type (a non-negative id).
}
