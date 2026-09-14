/// Layout of a function's private typed storage. Registers are clobbered
/// by calls, so values live across a call belong in the caller's spill banks.
class TypedFunction {
  const TypedFunction(
    this.entry, {
    this.intSpillCount = 0,
    this.doubleSpillCount = 0,
    this.boolSpillCount = 0,
    this.objectSpillCount = 0,
    this.intArgumentCount = 0,
    this.doubleArgumentCount = 0,
    this.boolArgumentCount = 0,
    this.objectArgumentCount = 0,
    this.intOutgoingCount = 0,
    this.doubleOutgoingCount = 0,
    this.boolOutgoingCount = 0,
    this.objectOutgoingCount = 0,
  });

  final int entry;
  final int intSpillCount, doubleSpillCount, boolSpillCount, objectSpillCount;
  final int intArgumentCount,
      doubleArgumentCount,
      boolArgumentCount,
      objectArgumentCount;
  final int intOutgoingCount,
      doubleOutgoingCount,
      boolOutgoingCount,
      objectOutgoingCount;

  List<int> get layout => [
    entry,
    intSpillCount,
    doubleSpillCount,
    boolSpillCount,
    objectSpillCount,
    intArgumentCount,
    doubleArgumentCount,
    boolArgumentCount,
    objectArgumentCount,
    intOutgoingCount,
    doubleOutgoingCount,
    boolOutgoingCount,
    objectOutgoingCount,
  ];
}
