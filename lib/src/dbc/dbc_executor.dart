import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';

class ProgramExit implements Exception {
  final int exitCode;

  ProgramExit(this.exitCode);
}

class Dbc {
  static const BASE_OPLEN = 1;

  /// [Jmpc] Jump to constant position
  static const OP_JMPC = 0;

  /// [Exit] Exit program with value exit code
  static const OP_EXIT = 1;

  /// [Cmpddi] Compare value with value -> return register
  static const OP_CMPDDI = 2;

  /// [Setvr] Set value to return register
  static const OP_SETVR = 3;

  /// [Addvv] Add value to value -> return register
  static const OP_ADDVV = 4;

  /// [Jnz] Jump to constant position if return register != 0
  static const OP_JNZ = 5;

  /// [Setvc] Set value to constant
  static const OP_SETVC = 6;

  /// [Addvcs] Add constant to value and re-store
  static const OP_ADDVCS = 7;

  /// [Subvcs] Subtract constant from value and re-store
  static const OP_SUBVCS = 8;

  /// [Modvcs] Modulo value with constant and re-store
  static const OP_MODVCS = 9;

  /// [PushScope] Push stack frame
  static const OP_PUSHSCOPE = 10;

  /// Set value to other value
  static const OP_SETVV = 11;

  /// Set value to constant string
  static const OP_SETVCSTR = 12;

  /// [PopScope] Pop scope frame
  static const OP_POPSCOPE = 13;

  /// [Setrv]
  static const OP_SETRV = 14;

  static List<int> opcodeFrom(DbcOp op) {
    switch (op.runtimeType) {
      case Jmpc:
        op as Jmpc;
        return [OP_JMPC, ...i32b(op._offset)];
      case Exit:
        op as Exit;
        return [OP_EXIT, ...i16b(op._location)];
      case Cmpddi:
        op as Cmpddi;
        return [OP_CMPDDI, ...i16b(op._location1), ...i16b(op._location2)];
      case Setvr:
        op as Setvr;
        return [OP_SETVR, ...i16b(op._location)];
      case Addvv:
        op as Addvv;
        return [OP_ADDVV, ...i16b(op._location1), ...i16b(op._location2)];
      case Jnz:
        op as Jnz;
        return [OP_JNZ, ...i32b(op._offset)];
      case Setvc:
        op as Setvc;
        return [OP_SETVC, ...i16b(op._location), ...i32b(op._value)];
      case Addvcs:
        op as Addvcs;
        return [OP_ADDVCS, ...i16b(op._location), ...i32b(op._value)];
      case Subvcs:
        op as Subvcs;
        return [OP_ADDVCS, ...i16b(op._location), ...i32b(op._value)];
      case Modvcs:
        op as Modvcs;
        return [OP_MODVCS, ...i16b(op._location), ...i32b(op._value)];
      case PushScope:
        op as PushScope;
        return [OP_PUSHSCOPE, ...i32b(op.sourceFile), ...i32b(op.sourceOffset), ...istr(op.frName)];
      case PopScope:
        return [OP_POPSCOPE];
      case Setvv:
        op as Setvv;
        return [OP_SETVV, ...i16b(op._position1), ...i16b(op._position2)];
      case Setvcstr:
        op as Setvcstr;
        return [OP_SETVCSTR, ...i16b(op._location), ...istr(op._value)];
      case Setrv:
        op as Setrv;
        return [OP_SETRV, ...i16b(op._location)];
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

List<Opmake> ops = [
  (DbcExecutor ex) => Jmpc(ex), // 0
  (DbcExecutor ex) => Exit(ex), // 1
  (DbcExecutor ex) => Cmpddi(ex), // 2
  (DbcExecutor ex) => Setvr(ex), // 3
  (DbcExecutor ex) => Addvv(ex), // 4
  (DbcExecutor ex) => Jnz(ex), // 5
  (DbcExecutor ex) => Setvc(ex), // 6
  (DbcExecutor ex) => Addvcs(ex), // 7
  (DbcExecutor ex) => Subvcs(ex), // 8
  (DbcExecutor ex) => Modvcs(ex), // 9
  (DbcExecutor ex) => PushScope(ex), // 10
  (DbcExecutor ex) => Setvv(ex), // 11
  (DbcExecutor ex) => Setvcstr(ex), // 12
  (DbcExecutor ex) => PopScope(ex), // 13
  (DbcExecutor ex) => Setrv(ex), // 14
];

class ScopeFrame {
  final _vStack = ByteData(65535);
}

class DbcExecutor {
  DbcExecutor(this._dbc);

  final ByteData _dbc;
  final _vStack = List<Object>.filled(65535, 0);
  var valueStack = <EvalValue>[];
  var scopeStack = <ScopeFrame>[];
  int _returnValue = 0;
  int _offset = 0;
  int _prOffset = 0;

  static const VTYPE_INT = 0;
  static const VTYPE_OBJECT = 1;

  void execute() {

    final pr = <DbcOp>[];
    while (_offset < _dbc.lengthInBytes) {
      final opId = _dbc.getUint8(_offset);
      _offset++;
      pr.add(ops[opId](this));
    }
    var i = 0;
    for (final oo in pr) {
      print('$i: $oo');
      i++;
    }
    print('');
    print('< exec >');
    try {
      while (true) {
        pr[_prOffset++].run(this);
      }
    } on ProgramExit catch (e) {
      print('Program exit: ${e.exitCode}');
    }
  }

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

  @pragma('vm:always-inline')
  void _setString(int location, String str) {
    _vStack[location] = str;
  }
}

abstract class DbcOp {
  void run(DbcExecutor exec);
}

// Move to constant position
class Jmpc implements DbcOp {
  Jmpc(DbcExecutor exec) : _offset = exec._readInt32();

  Jmpc.make(this._offset);

  final int _offset;

  @override
  void run(DbcExecutor exec) {
    exec._prOffset = _offset;
  }

  @override
  String toString() => 'Jmpc (L$_offset)';
}

// Exit program
class Exit implements DbcOp {
  Exit(DbcExecutor exec) : _location = exec._readInt16();

  Exit.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(DbcExecutor exec) {
    throw ProgramExit(exec._vStack[_location] as int);
  }

  @override
  String toString() => 'Exit (L$_location)';
}

class Setvr implements DbcOp {
  Setvr(DbcExecutor exec) : _location = exec._readInt16();

  Setvr.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;


  @override
  void run(DbcExecutor exec) {
    exec._vStack[_location] =  exec._returnValue;
  }

  @override
  String toString() => 'Setvr (L$_location = \$)';
}

class Setrv implements DbcOp {
  Setrv(DbcExecutor exec) : _location = exec._readInt16();

  Setrv.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(DbcExecutor exec) {
    exec._returnValue = exec._vStack[_location] as int;
  }

  @override
  String toString() => 'Setrv (\$ = L$_location)';
}

class Setvc implements DbcOp {
  Setvc(DbcExecutor exec)
      : _location = exec._readInt16(),
        _value = exec._readInt32();

  Setvc.make(this._location, this._value);

  final int _location;
  final int _value;

  static const int LEN = 6;

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._vStack[_location] = _value;
  }

  @override
  String toString() => 'Setvc (L$_location = $_value)';
}

class Setvcstr implements DbcOp {
  Setvcstr(DbcExecutor exec)
      : _location = exec._readInt16(),
        _value = exec._readString();

  Setvcstr.make(this._location, this._value);

  final int _location;
  final String _value;

  static int len(Setvcstr s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.istr_len(s._value);
  }

  static int lenX(String s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.istr_len(s);
  }

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._setString(_location, _value);
  }

  @override
  String toString() => "Setvcstr (L$_location = '$_value')";
}

class Addvv implements DbcOp {
  Addvv(DbcExecutor exec)
      : _location1 = exec._readInt16(),
        _location2 = exec._readInt16();

  Addvv.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  // Add value A + B
  @override
  void run(DbcExecutor exec) {
    exec._returnValue = (exec._vStack[_location1] as int) + (exec._vStack[_location2] as int);
  }

  @override
  String toString() => 'Addvv (L$_location1 + L$_location2 --> \$)';
}

class Addvcs implements DbcOp {
  Addvcs(DbcExecutor exec)
      : _location = exec._readInt16(),
        _value = exec._readInt32();

  Addvcs.make(this._location, this._value);

  final int _location;
  final int _value;

  // Add value A + @1, store
  @override
  void run(DbcExecutor exec) {
    exec._vStack[_location] = (exec._vStack[_location] as int) + _value;
  }

  @override
  String toString() => 'Addvcs (L$_location += $_value)';
}

class Modvcs implements DbcOp {
  Modvcs(DbcExecutor exec)
      : _location = exec._readInt16(),
        _value = exec._readInt32();

  Modvcs.make(this._location, this._value);

  final int _location;
  final int _value;

  // Add value A + @1, store
  @override
  void run(DbcExecutor exec) {
    exec._vStack[_location] = (exec._vStack[_location] as int) % _value;
  }

  @override
  String toString() => 'Modvcs (L$_location %= $_value)';
}

class Subvcs implements DbcOp {
  Subvcs(DbcExecutor exec)
      : _location = exec._readInt16(),
        _value = exec._readInt32();

  Subvcs.make(this._location, this._value);

  final int _location;
  final int _value;

  // Subtract value A - @1, store
  @override
  void run(DbcExecutor exec) {
    exec._vStack[_location] = (exec._vStack[_location] as int) - _value;
  }

  @override
  String toString() => 'Subvcs (L$_location -= $_value)';
}

class Cmpddi implements DbcOp {
  Cmpddi(DbcExecutor exec)
      : _location1 = exec._readInt16(),
        _location2 = exec._readInt16();

  Cmpddi.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  // Compare 4-byte
  @override
  void run(DbcExecutor exec) {
    final a = exec._vStack[_location1] as int;
    final b = exec._vStack[_location2] as int;
    exec._returnValue = a - b;
  }

  @override
  String toString() => 'Cmpddi (L$_location1 <> L$_location2 --> \$)';
}

class Jnz implements DbcOp {
  Jnz(DbcExecutor exec) : _offset = exec._readInt32();

  Jnz.make(this._offset);

  final int _offset;

  // Conditional move
  @override
  void run(DbcExecutor exec) {
    if (exec._returnValue != 0) {
      exec._prOffset = _offset;
    }
  }

  @override
  String toString() => 'Jnz (@$_offset if \$ != 0)';
}

class Setvv implements DbcOp {
  Setvv(DbcExecutor exec)
      : _position1 = exec._readInt16(),
        _position2 = exec._readInt16();

  Setvv.make(this._position1, this._position2);

  final int _position1;
  final int _position2;

  static const LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  // Conditional move
  @override
  void run(DbcExecutor exec) {
    exec._vStack[_position1] = exec._vStack[_position2];
  }

  @override
  String toString() => 'Setvv (L$_position1 <-- L$_position2)';
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
    exec.scopeStack.add(ScopeFrame());
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
    exec.scopeStack.removeLast();
  }

  @override
  String toString() => 'PopScope ()';
}