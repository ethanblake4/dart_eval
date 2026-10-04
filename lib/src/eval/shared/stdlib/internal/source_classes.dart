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

final sdkSourceClassesSource = DartSource('dart:_internal', r'''
/// Implementation of [NullableIterableExtensions.nonNulls].
///
/// A filtering iterable, so it doesn't have efficient length
/// and cannot forward most methods to the underlying [_source].
class NonNullsIterable<T extends Object> extends Iterable<T> {
  final Iterable<T?> _source;
  NonNullsIterable(this._source);

  T? get _firstNonNull {
    for (var element in _source) {
      if (element != null) return element;
    }
    return null;
  }

  bool get isEmpty => _firstNonNull == null;
  bool get isNotEmpty => _firstNonNull != null;
  T get first => _firstNonNull ?? (throw IterableElementError.noElement());

  Iterator<T> get iterator => NonNullsIterator<T>(_source.iterator);
}
class NonNullsIterator<T extends Object> implements Iterator<T> {
  final Iterator<T?> _source;
  T? _current;

  NonNullsIterator(this._source);

  bool moveNext() {
    _current = null;
    while (_source.moveNext()) {
      var next = _source.current;
      if (next != null) {
        _current = next;
        return true;
      }
    }
    return false;
  }

  T get current => _current ?? (throw IterableElementError.noElement());
}
/**
 * Creates errors throw by [Iterable] when the element count is wrong.
 */
abstract class IterableElementError {
  /** Error thrown by, e.g., [Iterable.first] when there is no result. */
  static StateError noElement() => StateError("No element");
  /** Error thrown by, e.g., [Iterable.single] if there are too many results. */
  static StateError tooMany() => StateError("Too many elements");
  /** Error thrown by, e.g., [List.setRange] if there are too few elements. */
  static StateError tooFew() => StateError("Too few elements");
}
''');
