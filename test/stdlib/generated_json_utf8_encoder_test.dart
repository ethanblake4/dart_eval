@TestOn('vm')
library;

import 'dart:convert';

import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

class _NativeJsonValue {
  const _NativeJsonValue(this.name);

  final String name;
}

void main() {
  test('native JsonUtf8Encoder callbacks and indentation use SDK behavior', () {
    final encoded = JsonUtf8Encoder(
      '  ',
      (object) => {'name': (object as _NativeJsonValue).name},
    ).convert(const _NativeJsonValue('é😀'));

    expect(utf8.decode(encoded), '{\n  "name": "é😀"\n}');
    expect(
      () => JsonUtf8Encoder().convert(const _NativeJsonValue('strict')),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    expect(
      () => JsonUtf8Encoder(
        null,
        (object) => throw StateError('callback failed'),
      ).convert(const _NativeJsonValue('error')),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
  });

  test(
    'generated encoder supports constructors, callbacks and UTF-8 output',
    () {
      const source = r'''
      import 'dart:convert';

      class GuestJsonValue {
        GuestJsonValue(this.name);
        final String name;
        Map<String, Object?> toJson() => {'default': name};
      }

      String main() {
        String encode(String Function() convert) {
          try {
            return convert();
          } catch (error) {
            return 'error:$error';
          }
        }

        return [
          encode(() => utf8.decode(JsonUtf8Encoder(null, (dynamic value) {
            final guest = value as GuestJsonValue;
            return {'callback': guest.name, 'mark': '🌊'};
          }).convert(GuestJsonValue('Ada')))),
          encode(() => utf8.decode(
            JsonUtf8Encoder().convert(GuestJsonValue('Lin')),
          )),
          encode(() => utf8.decode(
            JsonUtf8Encoder(null, null, null).convert({'mark': 'é😀'}),
          )),
          encode(() => utf8.decode(
            JsonUtf8Encoder('  ').convert({'mark': 'é😀', 'items': [1, 2]}),
          )),
        ].join('|');
      }
    ''';

      for (final (mode, result) in runDynamicFixture(source)) {
        expect(
          result,
          const DynamicFixtureResult.value(
            '{"callback":"Ada","mark":"🌊"}|'
            '{"default":"Lin"}|'
            '{"mark":"é😀"}|'
            '{\n  "mark": "é😀",\n  "items": [\n    1,\n    2\n  ]\n}',
          ),
          reason: mode,
        );
      }
    },
  );

  test('generated encoder reports unsupported objects and callback errors', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class Unsupported {}

      String main() => utf8.decode(JsonUtf8Encoder().convert(Unsupported()));
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.error(JsonUnsupportedObjectError),
        reason: mode,
      );
    }

    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class Unsupported {}

      String main() => utf8.decode(
        JsonUtf8Encoder(
          null,
          (dynamic value) => throw StateError('callback failed'),
        ).convert(Unsupported()),
      );
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.error(JsonUnsupportedObjectError),
        reason: mode,
      );
    }
  });

  test('generated chunked conversion keeps UTF-8 chunks and closes once', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class CollectingSink implements Sink<List<int>> {
        final bytes = <int>[];
        int chunks = 0;
        int closes = 0;

        void add(List<int> chunk) {
          chunks++;
          bytes.addAll(chunk);
        }

        void close() { closes++; }
      }

      bool main() {
        final output = CollectingSink();
        final sink = JsonUtf8Encoder(null, null, 4)
            .startChunkedConversion(output);
        sink.add({'text': 'é😀abcdefgh'});
        sink.close();
        return utf8.decode(output.bytes) == '{"text":"é😀abcdefgh"}' &&
            output.chunks > 1 && output.closes == 1;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('generated bind converts a synchronous stream to byte lists', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:async';
      import 'dart:convert';

      String main() {
        final encoded = <String>[];
        var completed = false;
        final source = StreamController<Object?>(sync: true);
        JsonUtf8Encoder().bind(source.stream).listen(
          (bytes) => encoded.add(utf8.decode(bytes)),
          onDone: () => completed = true,
        );
        source.add({'text': '🌊'});
        source.close();
        return '${encoded.join()}/$completed';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('{"text":"🌊"}/true'),
        reason: mode,
      );
    }
  });
}
