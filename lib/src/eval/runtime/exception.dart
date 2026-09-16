class EvalUnknownPropertyException implements Exception {
  const EvalUnknownPropertyException(this.name);

  final String name;

  @override
  String toString() => 'EvalUnknownPropertyException ($name)';
}

class InvalidUnboxedValueException implements Exception {
  const InvalidUnboxedValueException(this.message, this.value);

  final String message;
  final Object? value;

  @override
  String toString() =>
      'InvalidUnboxedValueException: $message (${value?.runtimeType})';
}
