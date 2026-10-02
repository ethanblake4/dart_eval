import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Type objects report the runtime type of Type', () {
    const source = '''
      class A {}
      class B {}
      bool main() {
        final a = A();
        final classA = A;
        final classB = B;
        final functionType = (() => null).runtimeType;
        return classA.runtimeType is Type &&
            classA.runtimeType == classB.runtimeType &&
            classA.runtimeType == functionType.runtimeType &&
            classA.runtimeType != a.runtimeType;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
