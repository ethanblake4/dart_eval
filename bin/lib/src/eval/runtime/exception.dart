import 'dart:math';

import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';

/// Format a dart_eval stack sample for printing.
String formatStackSample(List st, int size, [int? frameOffset]) {
  final sb = StringBuffer('[');
  final _size = min(size, st.length);
  for (var i = 0; i < _size; i++) {
    final s = st[i];
    if (i == frameOffset) {
      sb.write('*');
    }
    sb.write('L$i: ');
    if (s is List) {
      sb.write(formatStackSample(s, 3));
    } else if (s is String) {
      sb.write('"$s"');
    } else if (s is $num) {
      sb.write('\$$s');
    } else {
      sb.write('$s');
    }
    if (i < _size - 1) {
      sb.write(', ');
    }
  }
  sb.write(']');
  return sb.toString();
}

class EvalUnknownPropertyException implements Exception {
  const EvalUnknownPropertyException(this.name);

  final String name;

  @override
  String toString() => 'EvalUnknownPropertyException ($name)';
}

class ProgramExit implements Exception {
  final int exitCode;

  ProgramExit(this.exitCode);
}
