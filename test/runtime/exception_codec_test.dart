import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/typed/typed.dart';
import 'package:test/test.dart';

void main() {
  TypedProgram make({
    List<TypedExceptionRegion> regions = const [
      TypedExceptionRegion(0, catchTarget: 6, finallyTarget: 8),
    ],
    List<TypedCompletionJump> jumps = const [TypedCompletionJump(0, 8, 0)],
  }) => TypedProgram(
    Uint8List.fromList([
      TypedOp.enterTry,
      0,
      0,
      TypedOp.completeJump,
      0,
      0,
      TypedOp.ext,
      TypedOp.rCaughtException - TypedOp.extendedBase,
      TypedOp.resumeCompletion,
      TypedOp.rReturn,
    ]),
    exceptionRegions: regions,
    completionJumps: jumps,
  );

  test(
    'exception destinations and completion depths survive serialization',
    () {
      final restored = TypedProgram.read(make().write().buffer);
      expect(restored.exceptionRegions.single.catchTarget, 6);
      expect(restored.exceptionRegions.single.finallyTarget, 8);
      expect(restored.completionJumps.single.target, 8);
      expect(restored.completionJumps.single.targetDepth, 0);
      expect(() => restored.exceptionRegions.clear(), throwsUnsupportedError);
      expect(() => restored.completionJumps.clear(), throwsUnsupportedError);
    },
  );

  test('exception metadata rejects missing, unaligned and foreign targets', () {
    for (final region in [
      const TypedExceptionRegion(0),
      const TypedExceptionRegion(0, catchTarget: -2),
      const TypedExceptionRegion(-1, catchTarget: 6),
      const TypedExceptionRegion(1, catchTarget: 6),
      const TypedExceptionRegion(0, catchTarget: 1),
      const TypedExceptionRegion(0, finallyTarget: 7),
    ]) {
      expect(() => make(regions: [region]), throwsFormatException);
    }
    for (final jump in [
      const TypedCompletionJump(0, 1, 0),
      const TypedCompletionJump(0, 8, -1),
      const TypedCompletionJump(0, 8, 65536),
      const TypedCompletionJump(1, 8, 0),
    ]) {
      expect(() => make(jumps: [jump]), throwsFormatException);
    }
    expect(() => make(regions: []), throwsFormatException);
    expect(() => make(jumps: []), throwsFormatException);
    for (final foreign in [false, true]) {
      expect(
        () => TypedProgram(
          Uint8List.fromList([
            TypedOp.enterTry,
            0,
            0,
            TypedOp.rReturn,
            TypedOp.rReturn,
          ]),
          functions: const [TypedFunction(0), TypedFunction(4)],
          exceptionRegions: [
            TypedExceptionRegion(foreign ? 1 : 0, catchTarget: 4),
          ],
        ),
        throwsFormatException,
      );
    }
  });

  test('codec rejects corrupt exception counts and descriptor fields', () {
    final bytes = make().write().buffer.asUint8List();
    const metadata = 76 + 29;
    for (final (offset, value) in [
      (68, 65537),
      (72, 65537),
      (metadata, 1),
      (metadata + 4, 2),
      (metadata + 8, 100),
      (metadata + 12, 1),
      (metadata + 16, 2),
      (metadata + 20, 65536),
    ]) {
      final bad = Uint8List.fromList(bytes);
      ByteData.sublistView(bad).setUint32(offset, value, Endian.little);
      expect(() => TypedProgram.read(bad.buffer), throwsFormatException);
    }
  });
}
