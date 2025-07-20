// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import '../runtime.dart';

class Evc {
  static const BASE_OPLEN = 1;

  /// [JumpConstant] Jump to constant position
  static const OP_JMPC = 0;

  /// [Exit] Exit program with value exit code
  static const OP_EXIT = 1;

  /// [Unbox] Compare value with value -> return register
  static const OP_UNBOX = 2;

  /// [PushReturnValue] Set value to return register
  static const OP_SETVR = 3;

  /// [NumAdd] Add value to value -> return register
  static const OP_ADDVV = 4;

  /// [JumpIfNonNull] Jump to constant position if return register != 0
  static const OP_JNZ = 5;

  /// [PushConstantInt] Set value to constant
  static const OP_SETVC = 6;

  /// [BoxInt] Add constant to value and re-store
  static const OP_BOXINT = 7;

  /// [PushArg]
  static const OP_PUSH_ARG = 8;

  /// [JumpIfFalse]
  static const OP_JUMP_IF_FALSE = 9;

  /// [PushScope] Push stack frame
  static const OP_PUSHSCOPE = 10;

  /// [CopyValue] Set value to other value
  static const OP_SETVV = 11;

  /// [Pop] Push constant string
  static const OP_POP = 12;

  /// [SetObjectProperty] Set object property
  static const OP_SET_OBJECT_PROP = 13;

  /// [SetReturnValue]
  static const OP_SETRV = 14;

  /// [Return]
  static const OP_RETURN = 15;

  /// [PopScope]
  static const OP_POPSCOPE = 16;

  /// [Call]
  static const OP_CALL = 17;

  /// [PushObjectProperty]
  static const OP_PUSH_OBJECT_PROP = 18;

  /// [InvokeDynamic]
  static const OP_INVOKE_DYNAMIC = 19;

  /// [PushNull]
  static const OP_PUSH_NULL = 20;

  /// [CreateClass]
  static const OP_CREATE_CLASS = 21;

  /// [PushObjectPropertyImpl]
  static const OP_PUSH_OBJECT_PROP_IMPL = 22;

  /// [PushObjectPropertyImpl]
  static const OP_SET_OBJECT_PROP_IMPL = 23;

  /// [NumLt]
  static const OP_NUM_LT = 24;

  /// [NumLtEq]
  static const OP_NUM_LT_EQ = 25;

  /// [PushSuper]
  static const OP_PUSH_SUPER = 26;

  /// [BridgeInstantiate]
  static const OP_BRIDGE_INSTANTIATE = 27;

  /// [PushBridgeSuperShim]
  static const OP_PUSH_SUPER_SHIM = 28;

  /// [ParentBridgeSuperShim]
  static const OP_PARENT_SUPER_SHIM = 29;

  /// [NumSub]
  static const OP_NUM_SUB = 30;

  /// [PushList]
  static const OP_PUSH_LIST = 31;

  /// [ListAppend]
  static const OP_LIST_APPEND = 32;

  /// [IndexList]
  static const OP_INDEX_LIST = 33;

  /// [PushIterableLength]
  static const OP_ITER_LENGTH = 34;

  /// [ListSetIndexed]
  static const OP_LIST_SETINDEXED = 35;

  /// [BoxString]
  static const OP_BOXSTRING = 36;

  /// [BoxList]
  static const OP_BOXLIST = 37;

  /// [PushCaptureScope]
  static const OP_CAPTURE_SCOPE = 38;

  /// [PushConstant]
  static const OP_PUSH_CONST = 39;

  /// [PushFunctionPtr]
  static const OP_PUSH_FUNCTION_PTR = 40;

  /// [BoxNum]
  static const OP_BOXNUM = 41;

  /// [BoxDouble]
  static const OP_BOXDOUBLE = 42;

  /// [InvokeExternal]
  static const OP_INVOKE_EXTERNAL = 43;

  /// [Await]
  static const OP_AWAIT = 44;

  /// [PushMap]
  static const OP_PUSH_MAP = 45;

  /// [MapSet]
  static const OP_MAP_SET = 46;

  /// [IndexMap]
  static const OP_INDEX_MAP = 47;

  /// [PushConstantDouble]
  static const OP_PUSH_DOUBLE = 48;

  /// [SetGlobal]
  static const OP_SET_GLOBAL = 49;

  /// [LoadGlobal]
  static const OP_LOAD_GLOBAL = 50;

  /// [BoxMap]
  static const OP_BOXMAP = 51;

  /// [PushTrue]
  static const OP_PUSH_TRUE = 52;

  /// [LogicalNot]
  static const OP_LOGICAL_NOT = 53;

  /// [BoxBool]
  static const OP_BOXBOOL = 54;

  /// [Return]
  static const OP_RETURN_ASYNC = 55;

  /// [BoxNull]
  static const OP_BOX_NULL = 56;

  /// [CheckEq]
  static const OP_CHECK_EQ = 57;

  /// [Try]
  static const OP_TRY = 58;

  /// [Throw]
  static const OP_THROW = 59;

  /// [PopCatch]
  static const OP_POP_CATCH = 60;

  /// [IsType]
  static const OP_IS_TYPE = 61;

  /// [CheckNotEq]
  static const OP_CHECK_NOT_EQ = 62;

  /// [Assert]
  static const OP_ASSERT = 63;

  /// [PushFinally]
  static const OP_PUSH_FINALLY = 64;

  /// [PushReturnFromCatch]
  static const OP_PUSH_RETURN_FROM_CATCH = 65;

  /// [MaybeBoxNull]
  static const OP_MAYBE_BOX_NULL = 66;

  /// [PushRuntimeType]
  static const OP_PUSH_RUNTIME_TYPE = 67;

  /// [PushConstantType]
  static const OP_PUSH_CONSTANT_TYPE = 68;

  /// [PushRecord]
  static const OP_PUSH_RECORD = 69;

  /// [PushSet]
  static const OP_PUSH_SET = 70;

  /// [SetAdd]
  static const OP_SET_ADD = 71;

  /// [BoxSet]
  static const OP_BOXSET = 72;

  static List<int> i16b(int i16) {
    final x = ByteData(2);
    x.setInt16(0, i16);
    return [x.getUint8(0), x.getUint8(1)];
  }

  static List<int> i32b(int i32) {
    final x = ByteData(4);
    x.setInt32(0, i32);
    return [x.getUint8(0), x.getUint8(1), x.getUint8(2), x.getUint8(3)];
  }

  static List<int> f32b(double f32) {
    final x = ByteData(4);
    x.setFloat32(0, f32);
    return [x.getUint8(0), x.getUint8(1), x.getUint8(2), x.getUint8(3)];
  }

  static List<int> istr(String str) {
    final u = utf8.encode(str);
    final x = ByteData(4);
    x.setInt32(0, u.length);
    return [...i32b(u.length), ...u];
  }

  static const int I8_LEN = 1;
  static const int I16_LEN = 2;
  static const int I32_LEN = 4;
  static const int F32_LEN = 4;
  static const int I64_LEN = 8;

  static int istrLen(String str) {
    return I32_LEN + utf8.encode(str).length;
  }
}

abstract class EvcOp {
  void run(Runtime exec);
}

typedef OpLoader = EvcOp Function(Runtime);

final List<OpLoader> ops = [
  (Runtime rt) => JumpConstant(rt), // 0
  (Runtime rt) => Exit(rt), // 1
  (Runtime rt) => Unbox(rt), // 2
  (Runtime rt) => PushReturnValue(rt), // 3
  (Runtime rt) => NumAdd(rt), // 4
  (Runtime rt) => JumpIfNonNull(rt), // 5
  (Runtime rt) => PushConstantInt(rt), // 6
  (Runtime rt) => BoxInt(rt), // 7
  (Runtime rt) => PushArg(rt), // 8
  (Runtime rt) => JumpIfFalse(rt), // 9
  (Runtime rt) => PushScope(rt), // 10
  (Runtime rt) => CopyValue(rt), // 11
  (Runtime rt) => Pop(rt), // 12
  (Runtime rt) => SetObjectProperty(rt), // 13
  (Runtime rt) => SetReturnValue(rt), // 14
  (Runtime rt) => Return(rt), // 15
  (Runtime rt) => PopScope(rt), // 16
  (Runtime rt) => Call(rt), // 17
  (Runtime rt) => PushObjectProperty(rt), // 18
  (Runtime rt) => InvokeDynamic(rt), // 19
  (Runtime rt) => PushNull(rt), // 20
  (Runtime rt) => CreateClass(rt), // 21
  (Runtime rt) => PushObjectPropertyImpl(rt), // 22
  (Runtime rt) => SetObjectPropertyImpl(rt), // 23
  (Runtime rt) => NumLt(rt), // 24
  (Runtime rt) => NumLtEq(rt), // 25
  (Runtime rt) => PushSuper(rt), // 26
  (Runtime rt) => BridgeInstantiate(rt), // 27
  (Runtime rt) => PushBridgeSuperShim(rt), // 28
  (Runtime rt) => ParentBridgeSuperShim(rt), // 29
  (Runtime rt) => NumSub(rt), // 30
  (Runtime rt) => PushList(rt), // 31
  (Runtime rt) => ListAppend(rt), // 32
  (Runtime rt) => IndexList(rt), // 33
  (Runtime rt) => PushIterableLength(rt), // 34
  (Runtime rt) => ListSetIndexed(rt), // 35
  (Runtime rt) => BoxString(rt), // 36
  (Runtime rt) => BoxList(rt), // 37
  (Runtime rt) => PushCaptureScope(rt), // 38
  (Runtime rt) => PushConstant(rt), // 39
  (Runtime rt) => PushFunctionPtr(rt), // 40
  (Runtime rt) => BoxNum(rt), // 41
  (Runtime rt) => BoxDouble(rt), // 42
  (Runtime rt) => InvokeExternal(rt), // 43
  (Runtime rt) => Await(rt), // 44
  (Runtime rt) => PushMap(rt), // 45
  (Runtime rt) => MapSet(rt), // 46
  (Runtime rt) => IndexMap(rt), // 47
  (Runtime rt) => PushConstantDouble(rt), // 48
  (Runtime rt) => SetGlobal(rt), // 49
  (Runtime rt) => LoadGlobal(rt), // 50
  (Runtime rt) => BoxMap(rt), // 51
  (Runtime rt) => PushTrue(rt), // 52
  (Runtime rt) => LogicalNot(rt), // 53
  (Runtime rt) => BoxBool(rt), // 54
  (Runtime rt) => ReturnAsync(rt), // 55
  (Runtime rt) => BoxNull(rt), // 56
  (Runtime rt) => CheckEq(rt), // 57
  (Runtime rt) => Try(rt), // 58
  (Runtime rt) => Throw(rt), // 59
  (Runtime rt) => PopCatch(rt), // 60
  (Runtime rt) => IsType(rt), // 61
  (Runtime rt) => throw UnimplementedError(), // 62
  (Runtime rt) => Assert(rt), // 63
  (Runtime rt) => PushFinally(rt), // 64
  (Runtime rt) => PushReturnFromCatch(rt), // 65
  (Runtime rt) => MaybeBoxNull(rt), // 66
  (Runtime rt) => PushRuntimeType(rt), // 67
  (Runtime rt) => PushConstantType(rt), // 68
  (Runtime rt) => PushRecord(rt), // 69
  (Runtime rt) => PushSet(rt), // 70
  (Runtime rt) => SetAdd(rt), // 71
  (Runtime rt) => BoxSet(rt), // 72
];
