/// Version 101 instruction encoding, in signed 32-bit words:
/// [opcode, resultRegister (-1 for none), inputCount, ...inputRegisters,
///  dataCount, ...data]. Jump/call destinations are absolute word offsets.
/// Each function starts with an entry instruction whose data is [registers, spills].
enum RegisterOp {
  entry,
  constant, // data: constant-pool index; null uses -1
  move,
  swap,
  spill, // input: value; data: slot
  reload, // data: slot
  parameter, // data: argument index
  intAdd,
  intSub,
  intMul,
  intDiv,
  intLt,
  intLte,
  intGt,
  intGte,
  intEq,
  intNe,
  lessThan,
  increment,
  logicalNot,
  logicalAnd,
  logicalOr,
  dynamicEquals,
  isNull,
  boxInt,
  boxDouble,
  boxNum,
  boxBool,
  boxString,
  boxList,
  boxMap,
  boxSet,
  boxNull,
  maybeBoxNull,
  unbox,
  jump, // data: destination
  jumpIfFalse, // input: condition; data: false destination, true destination
  jumpIfNull, // input: value; data: null destination, nonnull destination
  jumpIfNonNull, // input: value; data: nonnull destination, null destination
  stageArgument, // input: value; appends to frame's pending arguments
  call, // consumes pending arguments; data: function destination
  invokeExternal, // consumes pending arguments; data: external function index
  invokeDynamic, // pending arguments start with receiver; data: name constant
  invokeClosure, // pending args start with closure; data: positional count, named-names constant
  returnValue, // zero or one input
  returnAsync, // inputs: optional value then completer
  createClosure, // pending args are captures; data: destination, signature constant
  loadCapture, // data: capture index
  loadFunctionPointer, // data: destination
  createClass, // input: superclass; data: library, class-name constant, field count
  loadPropertyStatic, // input: object; data: field index
  setPropertyStatic, // inputs: object, value; data: field index
  loadPropertyDynamic, // input: object; data: name constant
  setPropertyDynamic, // inputs: object, value; data: name constant
  loadSuper,
  newBridgeSuperShim,
  parentBridgeSuperShim, // inputs: shim, parent
  bridgeInstantiate, // pending args start with subclass; data: external function index
  loadGlobal, // data: global index
  setGlobal, // input: value; data: global index
  newList,
  indexList, // inputs: list, index
  listSet, // inputs: list, index, value
  listAppend, // inputs: list, value
  newMap,
  mapIndex, // inputs: map, key
  mapSet, // inputs: map, key, value
  newSet,
  setAdd,
  iterableLength,
  newRecord, // input: fields list; data: field-indices constant, type ID
  assertType, // input: object; data: type ID
  isType, // input: object; data: type ID, negated 0/1
  loadConstantType, // data: type ID
  loadRuntimeType,
  assertValue, // inputs: condition, message
  throwValue,
  rethrowValue,
  enterTry, // data: catch destination (-1 absent), finally destination (-1 absent)
  leaveTry,
  caughtException,
  caughtStackTrace,
  resumeCompletion,
  awaitValue, // inputs: completer, subject
}
