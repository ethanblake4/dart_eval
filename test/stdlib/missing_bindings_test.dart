import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Set.identity keeps distinct guest-equal objects', () {
    final results = runDynamicFixture('''
      class Key {
        final int value;
        Key(this.value);

        @override
        bool operator ==(Object other) => other is Key && other.value == value;

        @override
        int get hashCode => value;
      }

      int main() {
        final first = Key(1);
        final second = Key(1);
        final values = Set<Key>.identity()
          ..add(first)
          ..add(second)
          ..add(first);
        return values.length * 10 +
            (values.contains(first) ? 1 : 0) +
            (values.contains(second) ? 2 : 0);
      }
    ''');

    for (final (kind, result) in results) {
      expect(result.value, 23, reason: kind);
      expect(result.errorType, isNull, reason: kind);
    }
  });

  test('String.replaceFirstMapped passes a guest Match to the callback', () {
    final results = runDynamicFixture(r'''
      int main() {
        final result = 'cat cat'.replaceFirstMapped(
          RegExp('cat'),
          (match) => '${match.start}:${match[0]}',
          4,
        );
        return result == 'cat 4:cat' ? 0 : 1;
      }
    ''');

    for (final (kind, result) in results) {
      expect(result.value, 0, reason: kind);
      expect(result.errorType, isNull, reason: kind);
    }
  });

  test('dart:developer.log forwards named parameters', () {
    final results = runDynamicFixture('''
      import 'dart:developer' as developer;

      int main() {
        developer.log(
          'stdlib bridge smoke test',
          time: DateTime.fromMillisecondsSinceEpoch(123),
          sequenceNumber: 17,
          level: 900,
          name: 'dart_eval.test',
        );
        return 0;
      }
    ''');

    for (final (kind, result) in results) {
      expect(result.value, 0, reason: kind);
      expect(result.errorType, isNull, reason: kind);
    }
  });
}
