import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:test/test.dart';

void main() {
  test('const buckets distinguish types with colliding hashes', () {
    // Find a real collision so this test follows the host's hash algorithm.
    final typeIdsByHash = <int, int>{};
    late int firstTypeId;
    var secondTypeId = 0;
    while (true) {
      final hash = Object.hashAll([secondTypeId]);
      final previousTypeId = typeIdsByHash[hash];
      if (previousTypeId != null) {
        firstTypeId = previousTypeId;
        break;
      }
      typeIdsByHash[hash] = secondTypeId;
      secondTypeId += 0x9e3779b9;
    }

    final runtime = Runtime(ByteData(0).buffer);
    final first = runtime.internConst(<Object?>[], firstTypeId);
    final second = runtime.internConst(<Object?>[], secondTypeId);

    expect(identical(first, second), isFalse);
    expect(
      identical(first, runtime.internConst(<Object?>[], firstTypeId)),
      isTrue,
    );
    expect(
      identical(second, runtime.internConst(<Object?>[], secondTypeId)),
      isTrue,
    );
  });
}
