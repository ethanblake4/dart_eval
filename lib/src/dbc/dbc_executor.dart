import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/src/dbc/dbc_declaration.dart';

import 'dbc_function.dart';
import 'dbc_stdlib_base.dart';
import 'dbc_class.dart';

part 'ops/primitives.dart';

class ProgramExit implements Exception {
  final int exitCode;

  ProgramExit(this.exitCode);
}

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

  /// [JumpIfNonZero] Jump to constant position if return register != 0
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

  static List<int> opcodeFrom(DbcOp op) {
    switch (op.runtimeType) {
      case JumpConstant:
        op as JumpConstant;
        return [OP_JMPC, ...i32b(op._offset)];
      case Exit:
        op as Exit;
        return [OP_EXIT, ...i16b(op._location)];
      case Unbox:
        op as Unbox;
        return [OP_UNBOX, ...i16b(op._position)];
      case PushReturnValue:
        op as PushReturnValue;
        return [OP_SETVR];
      case AddInts:
        op as AddInts;
        return [OP_ADDVV, ...i16b(op._location1), ...i16b(op._location2)];
      case BoxInt:
        op as BoxInt;
        return [OP_BOXINT, ...i16b(op._position)];
      case PushArg:
        op as PushArg;
        return [OP_PUSH_ARG, ...i16b(op._location)];
      case PushNamedArg:
        op as PushNamedArg;
        return [OP_PUSH_NAMED_ARG, ...i16b(op._location), ...istr(op._name)];
      case JumpIfNonZero:
        op as JumpIfNonZero;
        return [OP_JNZ, ...i32b(op._offset)];
      case PushConstantInt:
        op as PushConstantInt;
        return [OP_SETVC, ...i32b(op._value)];
      case PushScope:
        op as PushScope;
        return [OP_PUSHSCOPE, ...i32b(op.sourceFile), ...i32b(op.sourceOffset), ...istr(op.frName)];
      case PopScope:
        return [OP_POPSCOPE];
      case CopyValue:
        op as CopyValue;
        return [OP_SETVV, ...i16b(op._position1), ...i16b(op._position2)];
      case PushConstantString:
        op as PushConstantString;
        return [OP_PUSH_CONST_STR, ...istr(op._value)];
      case SetReturnValue:
        op as SetReturnValue;
        return [OP_SETRV, ...i16b(op._location)];
      case Return:
        op as Return;
        return [OP_RETURN, ...i16b(op._location)];
      case Pop:
        return [OP_POP];
      case Call:
        op as Call;
        return [OP_CALL, ...i32b(op._offset)];
      case InvokeDynamic:
        op as InvokeDynamic;
        return [OP_INVOKE_DYNAMIC, ...i16b(op._location), ...istr(op._method)];
      case PushObjectProperty:
        op as PushObjectProperty;
        return [OP_PUSH_OBJECT_PROP, ...i16b(op._location), ...istr(op._property)];
      case PushNull:
        op as PushNull;
        return [OP_PUSH_NULL];
      case CreateClass:
        op as CreateClass;
        return [OP_CREATE_CLASS, ...i32b(op._library), ...i16b(op._super), ...istr(op._name)];
      default:
        throw ArgumentError('Not a valid op $op');
    }
  }

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

typedef Opmake = DbcOp Function(DbcExecutor);

final List<Opmake> ops = [
  (DbcExecutor ex) => JumpConstant(ex), // 0
  (DbcExecutor ex) => Exit(ex), // 1
  (DbcExecutor ex) => Unbox(ex), // 2
  (DbcExecutor ex) => PushReturnValue(ex), // 3
  (DbcExecutor ex) => AddInts(ex), // 4
  (DbcExecutor ex) => JumpIfNonZero(ex), // 5
  (DbcExecutor ex) => PushConstantInt(ex), // 6
  (DbcExecutor ex) => BoxInt(ex), // 7
  (DbcExecutor ex) => PushArg(ex), // 8
  (DbcExecutor ex) => PushNamedArg(ex), // 9
  (DbcExecutor ex) => PushScope(ex), // 10
  (DbcExecutor ex) => CopyValue(ex), // 11
  (DbcExecutor ex) => PushConstantString(ex), // 12
  (DbcExecutor ex) => PopScope(ex), // 13
  (DbcExecutor ex) => SetReturnValue(ex), // 14
  (DbcExecutor ex) => Return(ex), // 15
  (DbcExecutor ex) => Pop(ex), // 16
  (DbcExecutor ex) => Call(ex), // 17
  (DbcExecutor ex) => PushObjectProperty(ex), // 18
  (DbcExecutor ex) => InvokeDynamic(ex), // 19
  (DbcExecutor ex) => PushNull(ex), // 20
  (DbcExecutor ex) => CreateClass(ex) // 21
];

class ScopeFrame {
  ScopeFrame(this.stackOffset, this.scopeStackOffset, [this.entrypoint = false]);

  final int stackOffset;
  final int scopeStackOffset;
  final bool entrypoint;
}

class BridgeScopeFrame extends ScopeFrame {
  BridgeScopeFrame(int stackOffset) : super(stackOffset,stackOffset);
}

class DbcExecutor {
  DbcExecutor(this._dbc) : id = _id++;

  static int _id = 0;
  final int id;

  static const MIN_DYNAMIC_REGISTER = 32;

  final ByteData _dbc;
  final _vStack = List<Object?>.filled(65535, null);
  var _args = <Object?>[];
  var _namedArgs = <String, Object?>{};
  final pr = <DbcOp>[];
  Object? _returnValue = null;
  var scopeStack = <ScopeFrame>[ScopeFrame(0, 0)];
  var scopeStackOffset = 0;
  final callStack = <int>[0];
  var declarations = <int, Map<String, int>>{};
  final declaredClasses = <int, Map<String, DbcClass>>{};
  int _stackOffset = 0;
  int _argsOffset = 0;
  int _offset = 0;
  int _prOffset = 0;

  static const VTYPE_INT = 0;
  static const VTYPE_OBJECT = 1;

  void loadProgram() {
    final metaLength = _dbc.getInt32(0);
    final metaStr = <int>[];
    _offset = 4;
    while (_offset < metaLength + 4) {
      metaStr.add(_dbc.getUint8(_offset));
      _offset++;
    }

    final classesLength = _dbc.getInt32(_offset);
    final classStr = <int>[];

    _offset += 4;

    final _startOffset = _offset;
    while (_offset < classesLength + _startOffset) {
      classStr.add(_dbc.getUint8(_offset));
      _offset++;
    }

    declarations =
        (json.decode(utf8.decode(metaStr)).map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, int>())) as Map)
            .cast<int, Map<String, int>>();

    final classes =
        (json.decode(utf8.decode(classStr)).map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, List>())) as Map)
            .cast<int, Map<String, List>>();

    final _vm = DbcVmInterface(this);

    classes.forEach((file, classs) {
      final decls = <String, DbcClass>{};

      classs.forEach((name, declarations) {
        final dc = declarations.cast<Map>();

        final getters = (dc[0]).cast<String, int>();
        final setters = (dc[1]).cast<String, int>();
        final methods = (dc[2]).cast<String, int>();

        final cls = DbcClass(_vm, null, [], getters, setters, methods);
        decls[name] = cls;
      });

      declaredClasses[file] = decls;
    });

    while (_offset < _dbc.lengthInBytes) {
      final opId = _dbc.getUint8(_offset);
      _offset++;
      pr.add(ops[opId](this));
    }
  }

  void printOpcodes() {
    var i = 0;
    for (final oo in pr) {
      print('$i: $oo');
      i++;
    }
  }

  dynamic executeNamed(int file, String name) {
    return execute(declarations[file]![name]!);
  }

  dynamic execute(int entrypoint) {
    _prOffset = entrypoint;
    final _pr = pr;
    try {
      callStack.add(-1);
      while (true) {
        final op = _pr[_prOffset++];
        op.run(this);
      }
    } on ProgramExit catch (_) {
      return _returnValue;
    }
  }

  void beginBridgedScope() {
    throw UnimplementedError();
    scopeStack.add(BridgeScopeFrame(_stackOffset));
    scopeStackOffset = _stackOffset;
  }

  void push(Object? _value) {
    throw UnimplementedError();
    _vStack[_stackOffset++] = _value;
  }

  void popScope() {
    final offset = scopeStack.removeLast().stackOffset;
    _stackOffset = offset;
    scopeStackOffset = offset;
  }

  Object? get returnValue => _returnValue;

  @pragma('vm:always-inline')
  int _readInt32() {
    final i = _dbc.getInt32(_offset);
    _offset += 4;
    return i;
  }

  @pragma('vm:always-inline')
  int _readInt16() {
    final i = _dbc.getInt16(_offset);
    _offset += 2;
    return i;
  }

  @pragma('vm:always-inline')
  String _readString() {
    final len = _dbc.getInt32(_offset);
    _offset += 4;
    final codeUnits = List.filled(len, 0);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = _dbc.getUint8(_offset + i);
    }
    _offset += len;
    return utf8.decode(codeUnits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DbcExecutor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

abstract class DbcOp {
  void run(DbcExecutor exec);
}

class PushArg implements DbcOp {
  PushArg(DbcExecutor exec) : _location = exec._readInt16();

  PushArg.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._args.add(exec._vStack[exec.scopeStackOffset + _location]);
    exec._argsOffset++;
  }

  @override
  String toString() => 'PushArg (L$_location)';
}

class PushNamedArg implements DbcOp {
  PushNamedArg(DbcExecutor exec)
      : _location = exec._readInt16(),
        _name = exec._readString();

  PushNamedArg.make(this._location, this._name);

  final int _location;
  final String _name;

  static int len(PushNamedArg s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._name);
  }

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._namedArgs[_name] = exec._vStack[exec.scopeStackOffset + _location];
  }

  @override
  String toString() => 'PushNamedArg ($_name: L$_location)';
}

// Move to constant position
class Call implements DbcOp {
  Call(DbcExecutor exec) : _offset = exec._readInt32();

  Call.make(this._offset);

  final int _offset;

  static final int LEN = Dbc.BASE_OPLEN + Dbc.I32_LEN;

  @override
  void run(DbcExecutor exec) {
    exec.callStack.add(exec._prOffset);
    exec._prOffset = _offset;
  }

  @override
  String toString() => 'Call (@$_offset)';
}

class InvokeDynamic implements DbcOp {
  InvokeDynamic(DbcExecutor exec)
      : _location = exec._readInt16(),
        _method = exec._readString();

  InvokeDynamic.make(this._location, this._method);

  final int _location;
  final String _method;

  static int len(InvokeDynamic s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._method);
  }

  @override
  void run(DbcExecutor exec) {
    final object = exec._vStack[exec.scopeStackOffset + _location];
    if (object is DbcInstanceImpl) {
      final _offset = object.evalClass.methods[_method]!;
      exec.callStack.add(exec._prOffset);
      exec._prOffset = _offset;
      return;
    }
    final method = ((object as DbcInstance).evalGetProperty(_method) as DbcFunction);
    if (method is DbcFunctionImpl) {

      exec._vStack[exec._stackOffset++] =
          method.call(DbcVmInterface(exec), object, exec._args.cast(), exec._namedArgs.cast());
    } else {
      throw UnimplementedError();
    }
  }

  @override
  String toString() => 'InvokeDynamic (L$_location.$_method)';
}

// Create a class
class CreateClass implements DbcOp {
  CreateClass(DbcExecutor exec) : _library = exec._readInt32(), _super = exec._readInt16(), _name = exec._readString();

  CreateClass.make(this._library, this._super, this._name);

  final int _library;
  final String _name;
  final int _super;

  static int len(CreateClass s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN + Dbc.istr_len(s._name);
  }

  @override
  void run(DbcExecutor exec) {
    final $super = exec._vStack[exec.scopeStackOffset + _super] as DbcInstanceImpl?;
    final $cls = exec.declaredClasses[_library]![_name]!;

    final instance = DbcInstanceImpl($cls, $super);
    exec._vStack[exec._stackOffset++] = instance;
  }

  @override
  String toString() => 'CreateClass (F$_library:"$_name", super L$_super)';
}

// Move to constant position
class JumpConstant implements DbcOp {
  JumpConstant(DbcExecutor exec) : _offset = exec._readInt32();

  JumpConstant.make(this._offset);

  final int _offset;

  @override
  void run(DbcExecutor exec) {
    exec._prOffset = _offset;
  }

  @override
  String toString() => 'JumpConstant (@$_offset)';
}

// Exit program
class Exit implements DbcOp {
  Exit(DbcExecutor exec) : _location = exec._readInt16();

  Exit.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(DbcExecutor exec) {
    throw ProgramExit(exec._vStack[exec.scopeStackOffset + _location] as int);
  }

  @override
  String toString() => 'Exit (L$_location)';
}

class PushReturnValue implements DbcOp {
  PushReturnValue(DbcExecutor exec);

  PushReturnValue.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(DbcExecutor exec) {
    exec._vStack[exec._stackOffset++] = exec._returnValue;
  }

  @override
  String toString() => 'PushReturnValue ()';
}

class SetReturnValue implements DbcOp {
  SetReturnValue(DbcExecutor exec) : _location = exec._readInt16();

  SetReturnValue.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(DbcExecutor exec) {
    exec._returnValue = exec._vStack[exec.scopeStackOffset + _location] as int;
  }

  @override
  String toString() => 'SetReturnValue (\$ = L$_location)';
}

class Return implements DbcOp {
  Return(DbcExecutor exec) : _location = exec._readInt16();

  Return.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(DbcExecutor exec) {
    if (_location == -1) {
      exec._returnValue = null;
    } else {
      exec._returnValue = exec._vStack[exec.scopeStackOffset + _location];
    }

    final lastStack = exec.scopeStack.removeLast();
    exec._stackOffset = lastStack.stackOffset;
    exec.scopeStackOffset = lastStack.scopeStackOffset;

    final prOffset = exec.callStack.removeLast();
    if (prOffset == -1) {
      throw ProgramExit(0);
    }
    exec._prOffset = prOffset;
  }

  @override
  String toString() => 'Return (L$_location)';
}

class PushObjectProperty implements DbcOp {
  PushObjectProperty(DbcExecutor exec)
      : _location = exec._readInt16(),
        _property = exec._readString();

  PushObjectProperty.make(this._location, this._property);

  final int _location;
  final String _property;

  static int len(PushObjectProperty s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._property);
  }

  @override
  void run(DbcExecutor exec) {
    final object = exec._vStack[exec.scopeStackOffset + _location];
    exec._vStack[exec._stackOffset++] = (object as DbcInstance).evalGetProperty(_property);
  }

  @override
  String toString() => 'PushObjectProperty (L$_location.$_property)';
}

class Pop implements DbcOp {
  Pop(DbcExecutor exec);

  Pop.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(DbcExecutor exec) {
    exec._stackOffset--;
  }

  @override
  String toString() => 'Pop ()';
}

class PushConstantString implements DbcOp {
  PushConstantString(DbcExecutor exec) : _value = exec._readString();

  PushConstantString.make(this._value);

  final String _value;

  static int len(PushConstantString s) {
    return Dbc.BASE_OPLEN + Dbc.istr_len(s._value);
  }

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._vStack[exec._stackOffset++] = _value;
  }

  @override
  String toString() => "PushConstantString ('$_value')";
}

class JumpIfNonZero implements DbcOp {
  JumpIfNonZero(DbcExecutor exec) : _offset = exec._readInt32();

  JumpIfNonZero.make(this._offset);

  final int _offset;

  // Conditional move
  @override
  void run(DbcExecutor exec) {
    if (exec._returnValue != 0) {
      exec._prOffset = _offset;
    }
  }

  @override
  String toString() => 'JumpNonZero (@$_offset if \$ != 0)';
}

class CopyValue implements DbcOp {
  CopyValue(DbcExecutor exec)
      : _position1 = exec._readInt16(),
        _position2 = exec._readInt16();

  CopyValue.make(this._position1, this._position2);

  final int _position1;
  final int _position2;

  static const LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  // Conditional move
  @override
  void run(DbcExecutor exec) {

    exec._vStack[exec.scopeStackOffset + _position1] = exec._vStack[exec.scopeStackOffset + _position2];
  }

  @override
  String toString() => 'CopyValue (L$_position1 <-- L$_position2)';
}

class PushScope implements DbcOp {
  PushScope(DbcExecutor exec)
      : sourceFile = exec._readInt32(),
        sourceOffset = exec._readInt32(),
        frName = exec._readString();

  PushScope.make(this.sourceFile, this.sourceOffset, this.frName);

  final int sourceFile;
  final int sourceOffset;
  final String frName;

  static int len(PushScope s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN * 2 + Dbc.istr_len(s.frName);
  }

  @override
  void run(DbcExecutor exec) {
    exec.scopeStack.add(ScopeFrame(exec._stackOffset, exec.scopeStackOffset));
    exec.scopeStackOffset = exec._stackOffset;
    for (final arg in exec._args) {
      exec._vStack[exec._stackOffset++] = arg;
    }
    exec._args = [];
  }

  @override
  String toString() => "PushScope (F$sourceFile:$sourceOffset, '$frName')";
}

class PopScope implements DbcOp {
  PopScope(DbcExecutor exec);

  PopScope.make();

  static int LEN = Dbc.BASE_OPLEN;

  @override
  void run(DbcExecutor exec) {
    final lastStack = exec.scopeStack.removeLast();
    final offset = lastStack.stackOffset;
    exec._stackOffset = offset;
    exec.scopeStackOffset = offset;
  }

  @override
  String toString() => 'PopScope ()';
}
