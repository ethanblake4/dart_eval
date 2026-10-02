import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('String.split uses guest Pattern matches and checks their ranges', () {
    const source = '''
      class SliceMatch implements Match {
        int get start => 1;
        int get end => 2;
        dynamic noSuchMethod(Invocation invocation) => null;
      }

      class SlicePattern implements Pattern {
        Iterable<Match> allMatches(String input, [int start = 0]) =>
            [SliceMatch()];
        Match? matchAsPrefix(String input, [int start = 0]) => null;
      }

      class BadMatch implements Match {
        int get start => 100000000;
        int get end => 3;
        dynamic noSuchMethod(Invocation invocation) => null;
      }

      class BadPattern implements Pattern {
        Iterable<Match> allMatches(String input, [int start = 0]) =>
            [BadMatch()];
        Match? matchAsPrefix(String input, [int start = 0]) => null;
      }

      bool main() {
        final parts = 'abcd'.split(SlicePattern());
        if (parts.length != 2 || parts[0] != 'a' || parts[1] != 'cd') {
          return false;
        }
        try {
          'foo'.split(BadPattern());
        } on RangeError {
          return 'a,b'.split(',').length == 2;
        }
        return false;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
