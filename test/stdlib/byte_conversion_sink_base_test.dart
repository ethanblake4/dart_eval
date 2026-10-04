import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('ByteConversionSinkBase preserves the ByteConversionSink alias', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:convert';

      class CollectingSink extends ByteConversionSinkBase {
        final List<int> bytes = [];
        int closes = 0;

        void add(List<int> chunk) => bytes.addAll(chunk);
        void close() => closes++;
      }

      String main() {
        final guest = CollectingSink();
        ByteConversionSinkBase base = guest;
        ByteConversionSink interface = base;
        interface.add([1]);
        interface.addSlice([0, 2, 3, 0], 1, 3, true);

        final nativeWrapped = CollectingSink();
        ByteConversionSinkBase.from(nativeWrapped)
          ..addSlice([0, 4, 5, 0], 1, 3, true);

        final callbackBytes = <int>[];
        final callbackSink = ByteConversionSinkBase.withCallback(
          callbackBytes.addAll,
        );
        callbackSink.add([6]);
        callbackSink.addSlice([0, 7, 8, 0], 1, 3, true);

        final rejectsUnrelatedObject = Object() is! ByteConversionSinkBase;
        return '${guest.bytes.join(',')}/${guest.closes}|'
            '${nativeWrapped.bytes.join(',')}/${nativeWrapped.closes}|'
            '${callbackBytes.join(',')}|$rejectsUnrelatedObject';
      }
    ''')) {
      expect(
        result,
        const DynamicFixtureResult.value('1,2,3/1|4,5/1|6,7,8|true'),
        reason: mode,
      );
    }
  });
}
