import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('Map lookup accepts Object keys and preserves a nullable result', () {
    final program = Compiler().compile({
      'map_lookup_signature': {
        'main.dart': r'''
          extension LookupExtension on Object? {
            String operator [](Object? key) => 'extension';
          }
          String? lookup(Map<int, String> map, Object? key) => map[key];
          String? nullableLookup(Map<int?, String> map, Object? key) => map[key];
          int main() {
            final values = <int, String>{1: 'one'};
            if (lookup(values, 1) != 'one') return -1;
            if (lookup(values, 2) != null) return -2;
            if (lookup(values, '1') != null) return -3;
            final nullable = <int?, String>{null: 'null key', 1: 'one'};
            if (nullableLookup(nullable, null) != 'null key') return -4;
            if (nullableLookup(nullable, 2) != null) return -5;
            if (nullableLookup(nullable, '1') != null) return -6;
            if (nullableLookup(<int?, String>{}, null) != null) return -7;
            return 0;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:map_lookup_signature/main.dart', 'main'),
        0,
      );
    }
  });
}
