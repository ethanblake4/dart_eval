/// Layout of a function's private typed storage. Scalar registers are clobbered
/// by calls, so values live across a call belong in the caller's spill banks.
class TypedFunction {
  const TypedFunction(
    this.entry, {
    this.intSpillCount = 0,
    this.doubleSpillCount = 0,
    this.boolSpillCount = 0,
    this.intArgumentCount = 0,
    this.doubleArgumentCount = 0,
    this.boolArgumentCount = 0,
    this.intOutgoingCount = 0,
    this.doubleOutgoingCount = 0,
    this.boolOutgoingCount = 0,
  });

  final int entry;
  final int intSpillCount, doubleSpillCount, boolSpillCount;
  final int intArgumentCount, doubleArgumentCount, boolArgumentCount;
  final int intOutgoingCount, doubleOutgoingCount, boolOutgoingCount;

  List<int> get layout => [
    entry,
    intSpillCount,
    doubleSpillCount,
    boolSpillCount,
    intArgumentCount,
    doubleArgumentCount,
    boolArgumentCount,
    intOutgoingCount,
    doubleOutgoingCount,
    boolOutgoingCount,
  ];
}
