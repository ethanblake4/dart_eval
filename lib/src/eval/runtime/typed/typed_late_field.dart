import 'typed_instance.dart';

/// Late slots use a private marker so an assigned null is still initialized.
abstract final class TypedLateField {
  static const uninitialized = Object();

  @pragma('vm:never-inline')
  static Object? read(Object? receiver, int index) {
    final value = (receiver as TypedInstance).values[index];
    if (identical(value, uninitialized)) {
      throw StateError('Late field has not been initialized');
    }
    return value;
  }

  @pragma('vm:never-inline')
  static void writeFinal(Object? receiver, int index, Object? value) {
    final fields = (receiver as TypedInstance).values;
    if (!identical(fields[index], uninitialized)) {
      throw StateError('Late final field has already been initialized');
    }
    fields[index] = value;
  }
}
