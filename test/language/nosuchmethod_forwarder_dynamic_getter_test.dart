import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('restricted private forwarders bind slots and core helpers', () {
    final packages = {
      'dynamic_fixtures': {
        'api.dart': '''
          // @dart=3.7
          import 'dart:core' hide Invocation, Symbol, NoSuchMethodError;
          import 'dart:core' as core;
          class Invocation {}
          class Symbol {}
          class NoSuchMethodError {}
          abstract class Contract {
            void _wild(int _, int Invocation, int Symbol, int NoSuchMethodError);
            void _generic<_>(int _);
            int get _getter;
            set _setter(int Symbol);
            int _field = 0;
          }
          bool rejected(Contract receiver) {
            var count = 0;
            try { receiver._wild(1, 2, 3, 4); }
            on core.NoSuchMethodError { count++; }
            try { receiver._generic<num>(1); }
            on core.NoSuchMethodError { count++; }
            try { receiver._getter; }
            on core.NoSuchMethodError { count++; }
            try { receiver._setter = 2; }
            on core.NoSuchMethodError { count++; }
            try { receiver._field; }
            on core.NoSuchMethodError { count++; }
            try { receiver._field = 3; }
            on core.NoSuchMethodError { count++; }
            return count == 6;
          }
        ''',
        'main.dart': '''
          import 'api.dart';
          class Proxy implements Contract {
            int calls = 0;
            dynamic noSuchMethod(dynamic invocation) => ++calls;
          }
          bool main() {
            final receiver = Proxy();
            return rejected(receiver) && receiver.calls == 0;
          }
        ''',
      },
    };
    for (final (mode, result) in runDynamicPackages(
      packages,
      entrypoint: dynamicFixtureLibrary,
    )) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test(
    'forwarder signatures preserve colliding names and language versions',
    () {
      const source = '''
      // @dart=3.4
      abstract class Interface {
        int f([int f]);
        int xx([int xx, int x]);
        Type type<_>(_ value);
      }
      class Proxy implements Interface {
        dynamic noSuchMethod(Invocation invocation) {
          if (invocation.memberName == #type) return invocation.typeArguments[0];
          return 7;
        }
      }
      bool main() {
        dynamic receiver = Proxy();
        final f = receiver.f;
        final xx = receiver.xx;
        return f is int Function([int?]) &&
            xx is int Function([int?, int?]) &&
            f() == 7 && f(null) == 7 && xx(null, null) == 7 &&
            receiver.type<int>(2) == int;
      }
    ''';
      for (final (mode, result) in runDynamicFixture(source)) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    },
  );

  test('dynamic noSuchMethod forwarder tear-offs remain callable', () {
    const source = '''
      abstract class Interface {
        int method(String value);
      }
      class Proxy implements Interface {
        dynamic noSuchMethod(Invocation invocation) => 5;
      }
      bool main() {
        Interface value = Proxy();
        dynamic receiver = value;
        final tearOff = receiver.method;
        return tearOff('hello') == 5;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('forwarder tear-offs preserve named invocation arguments', () {
    const source = '''
      abstract class Interface {
        int transform(int value, {int scale = 2, int bias = 0});
      }
      class Handler {
        dynamic noSuchMethod(Invocation invocation) {
          if (invocation.memberName != #transform || !invocation.isMethod ||
              invocation.positionalArguments.length != 1 ||
              invocation.namedArguments.length != 2) {
            return -1000;
          }
          return invocation.positionalArguments[0] *
              invocation.namedArguments[#scale] +
              invocation.namedArguments[#bias];
        }
      }
      class Proxy extends Handler implements Interface {}
      int main() {
        dynamic receiver = Proxy();
        final tearOff = receiver.transform;
        return tearOff(3, bias: 5, scale: 7) +
            Function.apply(tearOff, [4], {#scale: 11, #bias: 13}) +
            tearOff.call(5, bias: 19, scale: 17);
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(187), reason: mode);
    }
  });
}
