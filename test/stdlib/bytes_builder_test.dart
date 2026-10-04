import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('BytesBuilder uses SDK copy and take semantics', () {
    for (final (mode, result) in runDynamicFixture(r'''
      import 'dart:typed_data';

      int main() {
        final copying = BytesBuilder();
        if (copying.length != 0 || !copying.isEmpty || copying.isNotEmpty) {
          return 1;
        }

        final copiedInput = Uint8List.fromList([1, 2]);
        copying.add(copiedInput);
        copiedInput[0] = 9;
        copying.addByte(258);
        if (copying.length != 3 || copying.isEmpty || !copying.isNotEmpty) {
          return 2;
        }
        final snapshot = copying.toBytes();
        if (snapshot.join(',') != '1,2,2') return 3;
        snapshot[0] = 7;
        if (copying.takeBytes().join(',') != '1,2,2') return 4;
        if (copying.length != 0 || !copying.isEmpty || copying.isNotEmpty) {
          return 5;
        }

        copying.add([4]);
        copying.clear();
        if (copying.length != 0 || !copying.isEmpty) return 6;

        final source = Uint8List.fromList([5, 6]);
        final nonCopying = BytesBuilder(copy: false)..add(source);
        source[0] = 8;
        if (source[0] != 8) return 50 + source[0];
        final nonCopyingSnapshot = nonCopying.toBytes();
        if (nonCopyingSnapshot.length != 2) return 60;
        if (nonCopyingSnapshot[0] != 8) return 70 + nonCopyingSnapshot[0];
        if (nonCopyingSnapshot[1] != 6) return 80 + nonCopyingSnapshot[1];
        nonCopyingSnapshot[0] = 7;
        if (source[0] != 8 || nonCopying.length != 2) return 8;

        final taken = nonCopying.takeBytes();
        if (taken.join(',') != '8,6') return 9;
        taken[0] = 3;
        return source[0] == 3 &&
            nonCopying.length == 0 &&
            nonCopying.isEmpty &&
            !nonCopying.isNotEmpty
            ? 0
            : 10;
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });
}
