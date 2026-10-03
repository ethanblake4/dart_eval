// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

final sdkExtensionsSource = DartSource('dart:core', r'''
extension EnumName on Enum {
  /// The name of the enum value.
  ///
  /// The name is a string containing the source identifier used
  /// to declare the enum value.
  ///
  /// For example, given a declaration like:
  /// ```dart
  /// enum MyEnum {
  ///   value1,
  ///   value2
  /// }
  /// ```
  /// the result of `MyEnum.value1.name` is the string `"value1"`.
  String get name => _name;
}
extension EnumByName<T extends Enum> on Iterable<T> {
  /// Finds the enum value in this list with name [name].
  ///
  /// Goes through this collection looking for an enum with
  /// name [name], as reported by [EnumName.name].
  /// Returns the first value with the given name. Such a value must be found.
  T byName(String name) {
    for (var value in this) {
      if (value._name == name) return value;
    }
    throw ArgumentError.value(name, "name", "No enum value with that name");
  }

  /// Creates a map from the names of enum values to the values.
  ///
  /// The collection that this method is called on is expected to have
  /// enums with distinct names, like the `values` list of an enum class.
  /// Only one value for each name can occur in the created map,
  /// so if two or more enum values have the same name (either being the
  /// same value, or being values of different enum type), at most one of
  /// them will be represented in the returned map.
  Map<String, T> asNameMap() => <String, T>{
    for (var value in this) value._name: value,
  };
}
''');
