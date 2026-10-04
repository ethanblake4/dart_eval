@TestOn('vm')
library;

import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('ASCII codec encodes and decodes valid and malformed bytes', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      String main() {
        final encoded = ascii.encode('Dart').join(',');
        final replacement = ascii.decode([65, 128], allowInvalid: true);
        var rejectsMalformed = false;
        try {
          ascii.decode([128]);
        } on FormatException {
          rejectsMalformed = true;
        }
        return '$encoded/$replacement/$rejectsMalformed';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('68,97,114,116/A\uFFFD/true'),
        reason: mode,
      );
    }
  });

  test('HtmlEscape and HtmlEscapeMode are generated native wrappers', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      String main() => const HtmlEscape(HtmlEscapeMode.element).convert('<&>');
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('&lt;&amp;&gt;'),
        reason: mode,
      );
    }
  });

  test(
    'LineSplitter static and instance conversion work after serialization',
    () {
      for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      String main() {
        final staticLines = LineSplitter.split('alpha\r\nbeta\rgamma\n')
            .join('|');
        final instanceLines = const LineSplitter()
            .convert('one\ntwo\r\nthree\r')
            .join('|');
        return '$staticLines/$instanceLines';
      }
    ''')) {
        expect(
          result,
          const DynamicFixtureResult.value('alpha|beta|gamma/one|two|three'),
          reason: mode,
        );
      }
    },
  );

  test('dart:async controller callback typedefs resolve in guest source', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:async';

      int main() {
        var calls = 0;
        ControllerCallback callback = () { calls++; };
        ControllerCancelCallback cancelCallback = () { calls++; };
        callback();
        cancelCallback();
        return calls;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(2), reason: mode);
    }
  });

  test('pragma constructors and properties round-trip after serialization', () {
    for (final (mode, result) in runDynamicFixture(r'''
      String main() {
        final withoutOptions = pragma('guest:keep');
        final withOptions = pragma('guest:option', 42);
        return '${withoutOptions.name}/${withoutOptions.options == null}/'
            '${withOptions.name}/${withOptions.options.toString()}';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('guest:keep/true/guest:option/42'),
        reason: mode,
      );
    }
  });

  test('Object hashAll functions preserve primitive and guest hash codes', () {
    for (final (mode, result) in runDynamicFixture(r'''
      class Key {
        const Key(this.hashCode);
        @override
        final int hashCode;
      }

      bool main() {
        final orderedA = Object.hashAll([1, 'value', const Key(17)]);
        final orderedB = Object.hashAll([1, 'value', const Key(17)]);
        final unorderedA = Object.hashAllUnordered([
          const Key(17),
          const Key(23),
        ]);
        final unorderedB = Object.hashAllUnordered([
          const Key(23),
          const Key(17),
        ]);
        return orderedA == orderedB && unorderedA == unorderedB;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('num-returning SDK functions preserve runtime numeric types', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:math';

      bool main() {
        final integer = pow(3, 2);
        final fraction = pow(4, 0.5);
        return integer is int && fraction is double;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('double.abs keeps its double result type and runtime wrapper', () {
    for (final (mode, result) in runDynamicFixture(r'''
      bool main() {
        final positive = (-1.5).abs();
        dynamic dynamicPositive = (-2.25).abs();
        return positive is double && dynamicPositive is double &&
            positive == 1.5 && dynamicPositive == 2.25;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('IterableExtensions.firstOrNull is available through core imports', () {
    for (final (mode, result) in runDynamicFixture(r'''
      String main() {
        final first = <int>[4, 5].firstOrNull;
        final empty = <int>[].firstOrNull;
        return '$first/${empty == null}';
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value('4/true'), reason: mode);
    }
  });

  test('IterableExtensions.firstOrNull supports guest Iterable subclasses', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:collection';

      class Values extends IterableBase<int> {
        Values(this.values);
        final List<int> values;
        @override
        Iterator<int> get iterator => values.iterator;
      }

      int? main() => Values([8, 9]).firstOrNull;
    ''')) {
      expect(result, const DynamicFixtureResult.value(8), reason: mode);
    }
  });

  test('SplayTreeSet is available with its SDK comparator behavior', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:collection';

      String main() {
        final values = SplayTreeSet<int>((left, right) => right.compareTo(left));
        values.addAll([1, 3, 2]);
        return values.join(',');
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value('3,2,1'), reason: mode);
    }
  });

  test('guest Converter subclasses cross the generated SDK bridge', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class Increment extends Converter<int, int> {
        int convert(int input) => input + 1;
        Sink<int> startChunkedConversion(Sink<int> sink) => sink;
      }

      int apply(Converter<int, int> converter) => converter.convert(4);

      int main() => apply(Increment());
    ''')) {
      expect(result, const DynamicFixtureResult.value(5), reason: mode);
    }
  });
}
