import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectResult(String source) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, const DynamicFixtureResult.value(true), reason: mode);
  }
}

void main() {
  test('inherited implementation checks widened positional calls', () {
    _expectResult('''
      class Base {
        int calls = 0;
        void accept(covariant int value) { calls++; }
      }
      class Leaf extends Base {
        void accept(covariant num value);
      }
      bool main() {
        final leaf = Leaf();
        leaf.accept(3);
        try {
          leaf.accept(1.5);
        } on TypeError {
          return leaf.calls == 1;
        }
        return false;
      }
    ''');
  });

  test(
    'inherited implementation checks named calls after argument evaluation',
    () {
      _expectResult('''
      class Base {
        int calls = 0;
        int accept({covariant int value = 7, String label = 'base'}) {
          calls++;
          return value;
        }
      }
      class Leaf extends Base {
        int accept({covariant num value = 1.5, String label = 'leaf'});
      }
      bool main() {
        final leaf = Leaf();
        if (leaf.accept() != 7) return false;
        var evaluated = false;
        String later() { evaluated = true; return 'later'; }
        try {
          leaf.accept(value: 1.5, label: later());
        } on TypeError {
          return evaluated && leaf.calls == 1;
        }
        return false;
      }
    ''');
    },
  );
}
