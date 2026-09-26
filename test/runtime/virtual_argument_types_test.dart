import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void _expectResult(String source, Object expected) {
  for (final (mode, result) in runDynamicFixture(source)) {
    expect(result, DynamicFixtureResult.value(expected), reason: mode);
  }
}

void main() {
  test('polymorphic calls accept mixed nominal parameters', () {
    _expectResult(r'''
      class Formatter {
        String format(int id, String label, bool active) =>
            'base';
      }
      class Detailed extends Formatter {
        String format(int id, String label, bool active) =>
            '$id:$label:$active';
      }
      String apply(Formatter formatter, int id, String label, bool active) =>
          formatter.format(id, label, active);
      bool main() =>
          apply(Formatter(), 1, 'a', false) == 'base' &&
          apply(Detailed(), 2, 'b', true) == '2:b:true';
    ''', true);
  });

  test('covariant override checks a widened num argument', () {
    _expectResult('''
      class Receiver {
        int accept(num value) => 1;
      }
      class Narrow extends Receiver {
        int accept(covariant int value) => value + 1;
      }
      bool check(Receiver receiver) {
        num good = 3;
        num bad = 2.5;
        if (receiver.accept(good) != 4) return false;
        try {
          receiver.accept(bad);
        } on TypeError {
          return true;
        }
        return false;
      }
      bool main() => check(Narrow());
    ''', true);
  });

  test('dynamic and null arguments still receive runtime checks', () {
    _expectResult('''
      class Receiver {
        int calls = 0;
        int accept(int value) { calls++; return value; }
      }
      int invoke(dynamic receiver, dynamic value) => receiver.accept(value);
      bool main() {
        final receiver = Receiver();
        dynamic bad = 'wrong';
        dynamic missing = null;
        var rejected = 0;
        try { invoke(receiver, bad); } on TypeError { rejected++; }
        try { invoke(receiver, missing); } on TypeError { rejected++; }
        return rejected == 2 && receiver.calls == 0 &&
            receiver.accept(7) == 7;
      }
    ''', true);
  });

  test('class and method type parameters retain their runtime checks', () {
    _expectResult('''
      class Box<T> {
        int calls = 0;
        int accept(T value) { calls++; return calls; }
        int acceptMethod<U>(U value) { calls++; return calls; }
      }
      bool check(Box<Object> box) {
        if (box.accept('ok') != 1) return false;
        var rejected = false;
        try {
          box.accept(42);
        } on TypeError {
          rejected = true;
        }
        if (!rejected || box.calls != 1) return false;
        dynamic bad = 'wrong';
        try {
          box.acceptMethod<int>(bad);
        } on TypeError {
          return box.calls == 1;
        }
        return false;
      }
      bool main() => check(Box<String>());
    ''', true);
  });
}
