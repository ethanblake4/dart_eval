import 'typed_instance.dart';
import 'typed_late_local.dart' show TypedLateInitializationError;
import 'typed_program.dart';

/// Late slots use a private marker so an assigned null is still initialized.
abstract final class TypedLateField {
  static const uninitialized = Object();

  @pragma('vm:never-inline')
  static Object? readNamed(
    Object? receiver,
    TypedProgram program,
    int descriptor,
  ) {
    final index = program.objectAt(descriptor) as int;
    final value = (receiver as TypedInstance).values[index];
    if (identical(value, uninitialized)) {
      throw TypedLateInitializationError(
        "Field '${program.objectAt(descriptor + 1)}' has not been initialized.",
      );
    }
    return TypedInstance.boxField(value);
  }

  @pragma('vm:never-inline')
  static void writeNamedFinal(
    Object? receiver,
    Object? value,
    TypedProgram program,
    int descriptor,
  ) {
    final fields = (receiver as TypedInstance).values;
    final index = program.objectAt(descriptor) as int;
    if (!identical(fields[index], uninitialized)) {
      final reason = program.objectAt(descriptor + 2) as bool
          ? 'been assigned during initialization'
          : 'already been initialized';
      throw TypedLateInitializationError(
        "Field '${program.objectAt(descriptor + 1)}' has $reason.",
      );
    }
    fields[index] = value;
  }

  @pragma('vm:never-inline')
  static bool isUninitialized(Object? receiver, int index) =>
      identical((receiver as TypedInstance).values[index], uninitialized);

  @pragma('vm:never-inline')
  static Object? read(Object? receiver, int index) {
    final value = (receiver as TypedInstance).values[index];
    if (identical(value, uninitialized)) {
      throw StateError('Late field has not been initialized');
    }
    return TypedInstance.boxField(value);
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
