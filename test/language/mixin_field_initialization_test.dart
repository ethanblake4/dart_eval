import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('shadowed mixin fields retain their own initializer values', () {
    const source = '''
      String log = '';
      int record(String name, int value) { log += name; return value; }
      base mixin BaseMixin {
        int foo = record('mixin;', 0);
      }
      typedef BaseMixinTypeDef = BaseMixin;
      base class A with BaseMixinTypeDef {
        int foo = record('class;', 1);
      }
      mixin First {
        int foo = record('first;', 2);
      }
      mixin Last {
        int foo = record('last;', 3);
      }
      class Alias = Object with First, Last;
      bool main() {
        if (A().foo != 1 || log != 'class;mixin;') return false;
        log = '';
        return Alias().foo == 3 && log == 'last;first;';
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test(
    'mixin field initializers follow constructor layers in source order',
    () {
      const source = '''
      String log = '';
      int record(String name, int value) { log += name; return value; }
      class Base {
        int base = record('base;', 1);
        Base() { log += 'body;'; }
      }
      mixin First on Base {
        int first = record('first;', 2);
        int second = record('second;', 3);
      }
      mixin Last on Base {
        int third = record('third;', 4), fourth = record('fourth;', 5);
        int fifth = record('fifth;', 6);
      }
      class Implicit extends Base with First, Last {
        int own = record('own;', 7);
      }
      class Explicit extends Base with First, Last {
        int own = record('own;', 7);
        Explicit() { log += 'derived;'; }
      }
      class Alias = Base with First, Last;
      bool main() {
        final implicit = Implicit();
        if (log != 'own;third;fourth;fifth;first;second;base;body;') return false;
        if (implicit.first != 2 || implicit.second != 3 ||
            implicit.third != 4 || implicit.fourth != 5 ||
            implicit.fifth != 6 || implicit.own != 7 || implicit.base != 1) {
          return false;
        }
        log = '';
        Explicit();
        if (log != 'own;third;fourth;fifth;first;second;base;body;derived;') {
          return false;
        }
        log = '';
        Alias();
        return log == 'third;fourth;fifth;first;second;base;body;';
      }
    ''';
      for (final (mode, result) in runDynamicFixture(source)) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    },
  );
}
