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

final sdkExtensionsSource = DartSource('dart:collection', r'''
extension IterableExtensions<T> on Iterable<T> {
  /// Pairs of elements of the indices and elements of this iterable.
  ///
  /// The elements are `(0, this.first)` through
  /// `(this.length - 1, this.last)`, in index/iteration order.
  @pragma('vm:prefer-inline')
  Iterable<(int, T)> get indexed => IndexedIterable<T>(this, 0);

  /// The first element of this iterator, or `null` if the iterable is empty.
  T? get firstOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }

  /// The last element of this iterable, or `null` if the iterable is empty.
  ///
  /// This computation may not be efficient.
  /// The last value is potentially found by iterating the entire iterable
  /// and temporarily storing every value.
  /// The process only iterates the iterable once.
  /// If iterating more than once is not a problem, it may be more efficient
  /// for some iterables to do:
  /// ```dart
  /// var lastOrNull = iterable.isEmpty ? null : iterable.last;
  /// ```
  T? get lastOrNull {
    if (this is EfficientLengthIterable) {
      if (isEmpty) return null;
      return last;
    }
    var iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    T result;
    do {
      result = iterator.current;
    } while (iterator.moveNext());
    return result;
  }

  /// The single element of this iterator, or `null`.
  ///
  /// If the iterator has precisely one element, this is that element.
  /// Otherwise, if the iterator has zero elements, or it has two or more,
  /// the value is `null`.
  T? get singleOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) {
      var result = iterator.current;
      if (!iterator.moveNext()) return result;
    }
    return null;
  }

  /// The element at position [index] of this iterable, or `null`.
  ///
  /// The [index] is zero based, and must be non-negative.
  ///
  /// Returns the result of `elementAt(index)` if the iterable has
  /// at least `index + 1` elements, and `null` otherwise.
  T? elementAtOrNull(int index) {
    RangeError.checkNotNegative(index, "index");
    if (this is EfficientLengthIterable) {
      if (index >= length) return null;
      return elementAt(index);
    }
    var iterator = this.iterator;
    do {
      if (!iterator.moveNext()) return null;
    } while (--index >= 0);
    return iterator.current;
  }
}
''');
