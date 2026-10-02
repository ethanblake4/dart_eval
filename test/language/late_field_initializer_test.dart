import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('late field initializers bind this and run once after construction', () {
    const source = '''
      int calls = 0;
      class Parent {
        late var self = this;
        late final Object finalSelf = this;
        late int value = initialize();
        int initialize() { calls++; return 7; }
      }
      class Child extends Parent {
        Child() { value = 9; }
      }
      mixin SelfMixin {
        late final Object mixinSelf = this;
      }
      class Applied = Parent with SelfMixin;

      bool main() {
        final parent = Parent();
        final child = Child();
        final applied = Applied();
        if (calls != 0) return false;
        if (!identical(parent.self, parent) ||
            !identical(child.self, child) ||
            !identical(child.finalSelf, child) ||
            !identical(applied.mixinSelf, applied)) return false;
        if (child.value != 9 || calls != 0) return false;
        return parent.value == 7 && parent.value == 7 && calls == 1;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('late field initializers retry errors and cache assigned null', () {
    const source = '''
      int calls = 0;
      class Fields {
        late final int? value = initialize();
        int? initialize() {
          calls++;
          if (calls == 1) throw 'retry';
          return null;
        }
      }
      bool main() {
        final fields = Fields();
        if (calls != 0) return false;
        try { fields.value; } catch (error) {}
        if (calls != 1) return false;
        return fields.value == null && fields.value == null && calls == 2;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
