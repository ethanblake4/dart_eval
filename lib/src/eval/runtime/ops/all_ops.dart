import 'dart:convert';
import 'dart:typed_data';

import '../runtime.dart';

class Dbc {
  static const BASE_OPLEN = 1;

  /// [JumpConstant] Jump to constant position
  static const OP_JMPC = 0;

  /// [Exit] Exit program with value exit code
  static const OP_EXIT = 1;

  /// [Unbox] Compare value with value -> return register
  static const OP_UNBOX = 2;

  /// [PushReturnValue] Set value to return register
  static const OP_SETVR = 3;

  /// [AddInts] Add value to value -> return register
  static const OP_ADDVV = 4;

  /// [JumpIfNonNull] Jump to constant position if return register != 0
  static const OP_JNZ = 5;

  /// [PushConstantInt] Set value to constant
  static const OP_SETVC = 6;

  /// [BoxInt] Add constant to value and re-store
  static const OP_BOXINT = 7;

  /// [PushArg]
  static const OP_PUSH_ARG = 8;

  /// [PushNamedArg]
  static const OP_PUSH_NAMED_ARG = 9;

  /// [PushScope] Push stack frame
  static const OP_PUSHSCOPE = 10;

  /// Set value to other value
  static const OP_SETVV = 11;

  /// Push constant string
  static const OP_PUSH_CONST_STR = 12;

  /// [PopScope] Pop scope frame
  static const OP_POPSCOPE = 13;

  /// [SetReturnValue]
  static const OP_SETRV = 14;

  /// [Return]
  static const OP_RETURN = 15;

  /// [Pop]
  static const OP_POP = 16;

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

  static List<int> istr(String str) {
    final u = utf8.encode(str);
    final x = ByteData(4);
    x.setInt32(0, u.length);
    return [...i32b(u.length), ...u];
  }

  static const int I8_LEN = 1;
  static const int I16_LEN = 2;
  static const int I32_LEN = 4;
  static const int I64_LEN = 8;

  static int istr_len(String str) {
    return I32_LEN + utf8.encode(str).length;
  }
}

abstract class DbcOp {
  void run(Runtime exec);
}

typedef OpLoader = DbcOp Function(Runtime);

final List<OpLoader> ops = [
      (Runtime ex) => JumpConstant(ex), // 0
      (Runtime ex) => Exit(ex), // 1
      (Runtime ex) => Unbox(ex), // 2
      (Runtime ex) => PushReturnValue(ex), // 3
      (Runtime ex) => AddInts(ex), // 4
      (Runtime ex) => JumpIfNonNull(ex), // 5
      (Runtime ex) => PushConstantInt(ex), // 6
      (Runtime ex) => BoxInt(ex), // 7
      (Runtime ex) => PushArg(ex), // 8
      (Runtime ex) => PushNamedArg(ex), // 9
      (Runtime ex) => PushScope(ex), // 10
      (Runtime ex) => CopyValue(ex), // 11
      (Runtime ex) => PushConstantString(ex), // 12
      (Runtime ex) => PopScope(ex), // 13
      (Runtime ex) => SetReturnValue(ex), // 14
      (Runtime ex) => Return(ex), // 15
      (Runtime ex) => Pop(ex), // 16
      (Runtime ex) => Call(ex), // 17
      (Runtime ex) => PushObjectProperty(ex), // 18
      (Runtime ex) => InvokeDynamic(ex), // 19
      (Runtime ex) => PushNull(ex), // 20
      (Runtime ex) => CreateClass(ex), // 21
      (Runtime ex) => PushObjectPropertyImpl(ex), // 22
      (Runtime ex) => SetObjectPropertyImpl(ex) // 23
];