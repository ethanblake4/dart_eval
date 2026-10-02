import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  for (final generic in [false, true]) {
    for (final leafFirst in [false, true]) {
      test('${generic ? "generic" : "explicit"} forwarding tearoffs, '
          '${leafFirst ? "leaf" : "base"} allocated first', () {
        final source =
            """
            class A {}
            class B extends A {}
            class C {
              int calls = 0;
              void f(B value) { calls++; }
              void named({required B value}) { calls++; }
            }
            ${generic ? 'abstract class I<T> { void f(T value); void named({required T value}); }' : 'abstract class I { void f(covariant A value); void named({required covariant A value}); }'}
            class D extends C implements ${generic ? 'I<B>' : 'I'} {
              bool superSignature() => super.f is void Function(B) &&
                  super.f is! void Function(Object?);
            }
            class E extends C {}
            bool check(dynamic f, dynamic named) {
              if (f is! void Function(Object?) ||
                  named is! void Function({required Object? value})) return false;
              f(B());
              named(value: B());
              var errors = 0;
              try { f(A()); } on TypeError { errors++; }
              try { f(null); } on TypeError { errors++; }
              try { named(value: A()); } on TypeError { errors++; }
              return errors == 3;
            }
            bool main() {
              ${leafFirst ? 'final d = D(); final c = C();' : 'final c = C(); final d = D();'}
              final e = E();
              C base = d;
              I interface = d;
              dynamic dynamicD = d;
              if (!check(d.f, d.named) || !check(base.f, base.named) ||
                  !check(interface.f, interface.named) ||
                  !check(dynamicD.f, dynamicD.named)) return false;
              if (c.f is void Function(Object?) ||
                  e.f is void Function(Object?)) return false;
              return d.superSignature() && d.calls == 8 && c.calls == 0 && e.calls == 0 &&
                  d.f == base.f && base.f == interface.f;
            }
          """;
        for (final (mode, result) in runDynamicFixture(source)) {
          expect(result, const DynamicFixtureResult.value(true), reason: mode);
        }
      });
    }
  }
}
