@TestOn('vm')
library;

import 'dart:convert';

import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  for (final expression in [
    'JsonEncoder().convert(value)',
    'utf8.decode(JsonUtf8Encoder().convert(value))',
    'jsonEncode(value)',
    'JsonCodec().encode(value)',
    'json.encode(value)',
    'JsonCodec.withReviver((key, value) => value).encode(value)',
    "JsonEncoder.withIndent('').convert(value)",
  ]) {
    test('default guest toJson through $expression', () {
      for (final (mode, result) in runDynamicFixture('''
        import 'dart:convert';
        class Value {
          Map<String, Object?> toJson() => {'value': 42};
        }
        String main() {
          final value = Value();
          return $expression;
        }
      ''')) {
        expect(
          result,
          DynamicFixtureResult.value(
            expression.contains('withIndent')
                ? '{\n"value": 42\n}'
                : '{"value":42}',
          ),
          reason: mode,
        );
      }
    });
  }

  for (final encoder in [
    'JsonEncoder().convert(value)',
    'utf8.decode(JsonUtf8Encoder().convert(value))',
    'jsonEncode(value)',
  ]) {
    for (final (declaration, expected) in [
      ('class Value { int toJson() => 42; }', '42'),
      ('class Value { Object? toJson() => null; }', 'null'),
      (
        'class Value { Object? Function() get toJson => () => {"getter": true}; }',
        '{"getter":true}',
      ),
    ]) {
      test(
        'guest callable toJson semantics through $encoder: $declaration',
        () {
          for (final (mode, result) in runDynamicFixture('''
          import 'dart:convert';
          $declaration
          String main() {
            final value = Value();
            return $encoder;
          }
        ''')) {
            expect(result, DynamicFixtureResult.value(expected), reason: mode);
          }
        },
      );
    }
    test('nested and inherited guest toJson through $encoder', () {
      for (final (mode, result) in runDynamicFixture('''
        import 'dart:convert';
        class Base {
          final int id;
          Base(this.id);
          Map<String, Object?> toJson() => {'id': id};
        }
        class Child extends Base { Child(int id) : super(id); }
        class Outer {
          Map<String, Object?> toJson() => {'child': Child(2)};
        }
        String main() {
          final value = {'items': [Child(1), Outer()]};
          return $encoder;
        }
      ''')) {
        expect(
          result,
          const DynamicFixtureResult.value(
            '{"items":[{"id":1},{"child":{"id":2}}]}',
          ),
          reason: mode,
        );
      }
    });

    for (final (declaration, value, error) in [
      ('class Value {}', 'Value()', JsonUnsupportedObjectError),
      (
        'class Value { Object toJson() => Value(); }',
        'Value()',
        JsonUnsupportedObjectError,
      ),
      (
        "class Value { Object toJson() => throw StateError('failed'); }",
        'Value()',
        JsonUnsupportedObjectError,
      ),
      (
        'class Value { Object toJson() => {1: 2}; }',
        'Value()',
        JsonUnsupportedObjectError,
      ),
      (
        'class Value { Object toJson() => double.nan; }',
        'Value()',
        JsonUnsupportedObjectError,
      ),
      (
        'class Value { Object toJson() => [this]; }',
        'Value()',
        JsonUnsupportedObjectError,
      ),
      ('', '<Object?>[]', JsonCyclicError),
    ]) {
      test('SDK rejection through $encoder: $declaration / $value', () {
        for (final (mode, result) in runDynamicFixture('''
          import 'dart:convert';
          $declaration
          String main() {
            final value = $value;
            ${declaration.isEmpty ? 'value.add(value);' : ''}
            return $encoder;
          }
        ''')) {
          expect(result, DynamicFixtureResult.error(error), reason: mode);
        }
      });
    }
  }

  for (final encoder in [
    'JsonEncoder(callback).convert(value)',
    'utf8.decode(JsonUtf8Encoder(null, callback).convert(value))',
    'jsonEncode(value, toEncodable: callback)',
    'JsonCodec(toEncodable: callback).encode(value)',
    'json.encode(value, toEncodable: callback)',
  ]) {
    test('explicit callback takes precedence through $encoder', () {
      for (final (mode, result) in runDynamicFixture('''
        import 'dart:convert';
        class Value {
          Object toJson() => throw StateError('default must not run');
          final int id = 42;
        }
        String main() {
          final value = Value();
          Object? callback(dynamic object) => {'explicit': (object as Value).id};
          return $encoder;
        }
      ''')) {
        expect(
          result,
          const DynamicFixtureResult.value('{"explicit":42}'),
          reason: mode,
        );
      }
    });
  }

  test('guest fallback survives UTF-8 chunking and bind', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:async';
      import 'dart:convert';
      class Value { Object toJson() => {'id': 42}; }
      class Output implements Sink<List<int>> {
        final bytes = <int>[];
        int closes = 0;
        void add(List<int> value) { bytes.addAll(value); }
        void close() { closes++; }
      }
      String main() {
        final output = Output();
        final chunks = JsonUtf8Encoder(null, null, 4)
            .startChunkedConversion(output);
        chunks.add(Value());
        chunks.close();
        final strings = <String>[];
        final stream = StreamController<Object?>(sync: true);
        JsonUtf8Encoder().bind(stream.stream).listen(
          (bytes) => strings.add(utf8.decode(bytes)));
        stream.add(Value());
        stream.close();
        return '${utf8.decode(output.bytes)}|${output.closes}|'
            '${strings.join()}';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('{"id":42}|1|{"id":42}'),
        reason: mode,
      );
    }
  });
}
