import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('ByteConversionSink.from exports guest Sink implementations', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';
      class Collecting implements Sink<List<int>> {
        List<int> bytes = [];
        int closes = 0;
        void add(List<int> value) { bytes.addAll(value); }
        void close() { closes++; }
      }
      String main() {
        final guest = Collecting();
        final sink = ByteConversionSink.from(guest);
        sink.add([1, 2]);
        sink.add([3]);
        sink.close();
        return '${guest.bytes.join(',')}/${guest.closes}';
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value('1,2,3/1'), reason: mode);
    }
  });

  test(
    'chunked callback keeps nested payload witnesses after later factory calls',
    () {
      for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';
      import 'dart:io';
      bool main() {
        final decoded = <int>[];
        bool witnesses = false;
        final output = ChunkedConversionSink<List<int>>.withCallback((chunks) {
          witnesses = chunks is List<List<int>> && chunks.first is List<int>;
          for (final chunk in chunks) { decoded.addAll(chunk); }
        });
        final other = ChunkedConversionSink<String>.withCallback((chunks) {});
        other.add('other');
        other.close();
        final bytes = <int>[1, 2, 3, 4];
        final encoder = ZLibEncoder();
        final encoded = encoder.convert(bytes);
        final sink = ZLibDecoder().startChunkedConversion(output);
        sink.add(encoded);
        sink.close();
        return witnesses && decoded.join(',') == bytes.join(',');
      }
    ''')) {
        expect(result, const DynamicFixtureResult.value(true), reason: mode);
      }
    },
  );

  test('Uint64List retains 64-bit values and native buffer views', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:typed_data';

      int main() {
        final values = Uint64List(1);
        values[0] = 0x100000001;
        final view = Uint64List.view(values.buffer);
        if (values is! TypedData) return 1;
        if (view[0] != 0x100000001) return 2;
        view[0] = 7;
        if (values[0] != 7) return 3;
        return 0;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });

  test('ConcurrentModificationError preserves its SDK type and value', () {
    for (final (mode, result) in runDynamicFixture(r'''
      bool main() {
        try {
          throw ConcurrentModificationError('modified collection');
        } on ConcurrentModificationError catch (error) {
          return error.modifiedObject == 'modified collection';
        }
        return false;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test('base64Encode and base64Decode are native SDK functions', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      String main() =>
          '${base64Encode([1, 2, 3])}/${base64Decode('AQID').join(',')}';
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('AQID/1,2,3'),
        reason: mode,
      );
    }
  });

  test('ZLibCodec decodes chunked input into a ByteConversionSink', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';
      import 'dart:io';

      String main() {
        const original = [1, 2, 3, 4, 5, 6];
        final codec = ZLibCodec();
        final encoded = codec.encode(original);
        final decoded = <int>[];
        final output = ByteConversionSink.withCallback(decoded.addAll);
        final sink = codec.decoder.startChunkedConversion(output);
        sink.add(encoded.sublist(0, 2));
        sink.add(encoded.sublist(2));
        sink.close();
        return '${codec.decode(encoded).join(',')}/${decoded.join(',')}';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('1,2,3,4,5,6/1,2,3,4,5,6'),
        reason: mode,
      );
    }
  });

  test(
    'guest Codec subclasses preserve SDK virtual encoder and decoder calls',
    () {
      for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class StringCodec extends Codec<String, String> {
        const StringCodec();
        Converter<String, String> get encoder => const AddPrefix();
        Converter<String, String> get decoder => const RemovePrefix();
      }

      class AddPrefix extends Converter<String, String> {
        const AddPrefix();
        String convert(String input) => 'x$input';
        Sink<String> startChunkedConversion(Sink<String> sink) => sink;
      }

      class RemovePrefix extends Converter<String, String> {
        const RemovePrefix();
        String convert(String input) => input.substring(1);
        Sink<String> startChunkedConversion(Sink<String> sink) => sink;
      }

      String apply(Codec<String, String> codec) =>
          codec.decode(codec.encode('value'));

      String main() => apply(const StringCodec());
    ''')) {
        expect(result, const DynamicFixtureResult.value('value'), reason: mode);
      }
    },
  );

  test(
    'guest ByteConversionSink subclasses receive inherited addSlice calls',
    () {
      for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class CollectingSink extends ByteConversionSink {
        final List<int> bytes = [];
        void add(List<int> chunk) => bytes.addAll(chunk);
        void close() {}
      }

      String apply(ByteConversionSink sink) {
        sink.addSlice([65, 66, 67], 1, 3, true);
        return (sink as CollectingSink).bytes.join(',');
      }

      String main() => apply(CollectingSink());
    ''')) {
        expect(result, const DynamicFixtureResult.value('66,67'), reason: mode);
      }
    },
  );

  test('GZipCodec uses SDK compression and decoder implementations', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:io';

      String main() {
        final codec = GZipCodec();
        final input = [1, 2, 3, 4];
        final encoded = codec.encode(input);
        return '${codec.gzip}/${codec.decode(encoded).join(',')}';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('true/1,2,3,4'),
        reason: mode,
      );
    }
  });

  test('identityHashCode accepts guest and native objects', () {
    for (final (mode, result) in runDynamicFixture(r'''
      class Marker {}

      bool main() {
        final marker = Marker();
        final values = <int>[1, 2];
        return identityHashCode(marker) == identityHashCode(marker) &&
            identityHashCode(values) == identityHashCode(values);
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });

  test(
    'guest StringConversionSink implementations receive native sink calls',
    () {
      for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class CollectingSink extends StringConversionSink {
        final StringBuffer buffer = StringBuffer();
        void addSlice(String chunk, int start, int end, bool isLast) {
          buffer.write(chunk.substring(start, end));
          if (isLast) close();
        }
        void close() {}
      }

      String main() {
        final guest = CollectingSink();
        StringConversionSink sink = guest;
        sink.addSlice('abcd', 1, 3, true);
        return guest.buffer.toString();
      }
    ''')) {
        expect(result, const DynamicFixtureResult.value('bc'), reason: mode);
      }
    },
  );
}
