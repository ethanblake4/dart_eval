import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('explicit substitutions recurse through parameter types', () {
    const source = '''
      int calls = 0;

      void accept<T>(List<T> values) {
        calls++;
      }

      bool main() {
        dynamic bad = <String>[];
        try {
          accept<int>(bad);
        } on TypeError {
          return calls == 0;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('known generic receivers substitute member signatures', () {
    const source = '''
      class Box<T> {
        int calls = 0;

        T echo(T value) {
          calls++;
          return value;
        }
      }

      bool main() {
        final box = Box<int>();
        final good = box.echo(7) + 1;
        dynamic bad = 'bad';
        try {
          box.echo(bad);
        } on TypeError {
          return good == 8 && box.calls == 1;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('dynamic member checks substitute nested class parameters', () {
    const source = '''
      class Box<T> {
        int calls = 0;

        void accept(List<T> values) {
          calls++;
        }
      }

      bool main() {
        dynamic box = Box<int>();
        box.accept(<int>[]);
        dynamic bad = <String>[];
        try {
          box.accept(bad);
        } on TypeError {
          return box.calls == 1;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('class substitutions recurse through records and functions', () {
    const source = '''
      String echo(String value) => value;

      class Box<T> {
        bool acceptsRecord(dynamic value) => value is (T,);
        bool acceptsFunction(dynamic value) => value is T Function(T);
      }

      bool main() {
        dynamic strings = Box<String>();
        dynamic integers = Box<int>();
        return strings.acceptsRecord(('ok',)) &&
            !strings.acceptsRecord((1,)) &&
            strings.acceptsFunction(echo) &&
            !integers.acceptsFunction(echo);
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('explicit generic return keeps the boxed callee ABI', () {
    for (final (mode, result) in runDynamicFixture('''
      T identity<T>(T value) => value;
      int main() => identity<int>(7) + 1;
    ''')) {
      expect(result, const DynamicFixtureResult.value(8), reason: mode);
    }
  });

  test('optional generic arguments retain explicit substitution', () {
    for (final (mode, result) in runDynamicFixture('''
      int calls = 0;
      void accept<T>([T? value]) { calls++; }
      int main() {
        dynamic bad = 'bad';
        try { accept<int>(bad); } on TypeError { return calls; }
        return -1;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });

  test('class type parameters accept null when their runtime type does', () {
    for (final (mode, result) in runDynamicFixture('''
      class Box<T> { int accept(T value) => 1; }
      class Receiver { int accept(dynamic value) => 2; }
      int main() {
        dynamic box = Box<dynamic>();
        dynamic receiver = Receiver();
        return box.accept(null) + receiver.accept(null);
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('explicit generic calls check dynamic arguments before entry', () {
    const source = '''
      int functionCalls = 0;

      T accept<T extends num>(T value) {
        functionCalls++;
        return value;
      }

      class Receiver {
        int methodCalls = 0;

        T accept<T extends num>(T value) {
          methodCalls++;
          return value;
        }
      }

      int main() {
        dynamic bad = 'bad';
        var result = 0;
        try {
          accept<int>(bad);
        } on TypeError {
          if (functionCalls == 0) result += 1;
        }

        final receiver = Receiver();
        try {
          receiver.accept<int>(bad);
        } on TypeError {
          if (receiver.methodCalls == 0) result += 2;
        }
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(3), reason: mode);
    }
  });

  test('method type parameters do not alias class type parameters', () {
    const source = '''
      class Box<T> {
        int calls = 0;

        U echo<U>(U value) {
          calls++;
          return value;
        }
      }

      bool main() {
        dynamic box = Box<int>();
        return box.echo('ok') == 'ok' && box.calls == 1;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('dynamic receivers apply explicit method type arguments', () {
    const source = '''
      class Receiver {
        int calls = 0;

        T first<T extends num>(List<T> values) {
          if (values is! List<T>) throw StateError('wrong type arguments');
          calls++;
          return values[0];
        }
      }

      bool main() {
        dynamic receiver = Receiver();
        if (receiver.first<int>(<int>[7]) != 7) return false;

        dynamic bad = <String>['bad'];
        try {
          receiver.first<int>(bad);
        } on TypeError {
          if (receiver.calls != 1) return false;
        }

        try {
          receiver.first<String>(<String>['bad']);
        } on TypeError {
          return receiver.calls == 1;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('dynamic generic closures check arguments before entry', () {
    const source = '''
      int calls = 0;

      T accept<T extends num>(T value) {
        if (value is! T) throw StateError('wrong type argument');
        calls++;
        return value;
      }

      bool main() {
        dynamic fn = accept;
        if (fn<int>(4) != 4) return false;
        dynamic bad = 'bad';
        try {
          fn<int>(bad);
        } on TypeError {
          return calls == 1;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('generic relays resolve call-site types in the caller environment', () {
    const source = '''
      int calls = 0;

      R accept<R extends num>(R value) {
        calls++;
        return value;
      }

      class Relay<T extends num> {
        T throughClass(dynamic fn, dynamic value) => fn<T>(value);
        R throughMethod<R extends T>(dynamic fn, dynamic value) => fn<R>(value);
      }

      bool main() {
        final relay = Relay<int>();
        dynamic fn = accept;
        if (relay.throughClass(fn, 3) != 3) return false;
        if (relay.throughMethod<int>(fn, 4) != 4) return false;
        dynamic bad = 'bad';
        try {
          relay.throughMethod<int>(fn, bad);
        } on TypeError {
          return calls == 2;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('direct generic calls retain class and callable environments', () {
    const source = '''
      class Box<T> {
        bool accepts(dynamic value) => value is T;
      }

      bool accepts<R>(dynamic value) => value is R;

      bool main() {
        final box = Box<int>();
        return box.accepts(2) &&
            !box.accepts('bad') &&
            accepts<String>('ok') &&
            !accepts<String>(3);
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('generic as checks use the active direct-call environment', () {
    const source = '''
      class Box<T> {
        int calls = 0;
        T cast(dynamic value) {
          calls++;
          return value as T;
        }
      }

      bool main() {
        final box = Box<int>();
        if (box.cast(7) != 7) return false;
        try {
          box.cast('bad');
        } on TypeError {
          return box.calls == 2;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('noSuchMethod receives explicit type arguments', () {
    const source = '''
      class Catcher {
        int noSuchMethod(Invocation invocation) =>
            invocation.typeArguments.length;
      }

      int main() {
        dynamic catcher = Catcher();
        return catcher.missing<int, String>();
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(2), reason: mode);
    }
  });

  test('class type parameters check dynamic method arguments', () {
    const source = '''
      class Box<T> {
        int calls = 0;
        void accept(T value) {
          calls++;
        }
      }

      int main() {
        dynamic box = Box<int>();
        dynamic bad = 'bad';
        try {
          box.accept(bad);
        } on TypeError {
          return box.calls;
        }
        return -1;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });

  test('inherited generic method signatures retain substitutions', () {
    const source = '''
      class Box<T> {
        int calls = 0;
        void accept(T value) {
          calls++;
        }
      }
      class IntBox extends Box<int> {}

      int main() {
        dynamic box = IntBox();
        dynamic bad = 'bad';
        try {
          box.accept(bad);
        } on TypeError {
          return box.calls;
        }
        return -1;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });

  test('constructor bodies see instantiated type arguments', () {
    const source = '''
      class A<T> {
        bool good = false;
        A() {
          good = this is A<int>;
        }
      }

      bool main() => A<int>().good;
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('guest instances retain constructed type arguments', () {
    const source = '''
      class Box<T> {
        Box();
      }

      int main() {
        dynamic value = Box<int>();
        dynamic explicit = new Box<String>();
        var result = 0;
        if (value is Box<int>) result += 2;
        if (value is Box<String>) result += 1;
        if (explicit is Box<String>) result += 8;
        if (explicit is Box<int>) result += 4;
        return result;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(10), reason: mode);
    }
  });

  test('generic allocations retain resolved type arguments', () {
    const source = '''
      List<T> make<T>() => <T>[];

      bool main() {
        dynamic values = make<int>();
        if (values is! List<int> || values is List<String>) return false;
        values.add(7);
        try {
          values.add('bad');
        } on TypeError {
          return values.length == 1 && values[0] == 7;
        }
        return false;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('escaping closures retain their defining generic environment', () {
    const source = '''
      bool Function(dynamic) make<T>() => (value) => value is T;

      bool main() {
        final acceptsInt = make<int>();
        return acceptsInt(7) && !acceptsInt('bad');
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('escaped closure signatures resolve their defining type arguments', () {
    const source = '''
      dynamic make<T>() {
        T Function(T) identity = (T value) => value;
        return identity;
      }

      bool main() {
        dynamic identity = make<int>();
        return identity is int Function(int) &&
            identity is! String Function(String) &&
            identity(7) == 7;
      }
    ''';

    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
