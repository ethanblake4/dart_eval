import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';
import 'package:test/test.dart';

void main() {
  test(
    '\$Type does not implement dart:core Type (dart2wasm compatibility)',
    () {
      final Object wrapped = $Type(int);
      expect(wrapped is Type, isFalse);
      expect(($Type(int)).$value, int);
    },
  );
}
