import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('Object super.toString retains the receiver across mixin layers', () {
    const source = '''
      mixin class B {
        String toString() => 'B(' + super.toString() + ')';
      }
      class R {
        String toString() => 'R[' + super.toString() + ']';
      }
      class D extends R with B {
        String toString() => 'D<' + super.toString() + '>';
      }
      class E extends D with B {
        String toString() => 'E{' + super.toString() + '}';
      }
      class F = R with B, B;
      class G extends F with B {
        String toString() => 'G{' + super.toString() + '}';
      }
      class Generic<T> {
        Type get runtimeType => String;
        String toString() => super.toString();
      }
      bool main() => B().toString() == "B(Instance of 'B')" &&
          R().toString() == "R[Instance of 'R']" &&
          D().toString() == "D<B(R[Instance of 'D'])>" &&
          E().toString() == "E{B(D<B(R[Instance of 'E'])>)}" &&
          G().toString() == "G{B(B(B(R[Instance of 'G'])))}" &&
          Generic<int>().toString() == "Instance of 'Generic<int>'";
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
