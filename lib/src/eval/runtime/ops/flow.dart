part of '../runtime.dart';

// Move to constant position
class Call implements DbcOp {
  Call(Runtime exec) : _offset = exec._readInt32();

  Call.make(this._offset);

  final int _offset;

  static final int LEN = Dbc.BASE_OPLEN + Dbc.I32_LEN;

  @override
  void run(Runtime exec) {
    exec.callStack.add(exec._prOffset);
    exec._prOffset = _offset;
  }

  @override
  String toString() => 'Call (@$_offset)';
}

class PushScope implements DbcOp {
  PushScope(Runtime exec)
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
  void run(Runtime exec) {
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
  PopScope(Runtime exec);

  PopScope.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime exec) {
    final lastStack = exec.scopeStack.removeLast();
    final offset = lastStack.stackOffset;
    exec._stackOffset = offset;
    exec.scopeStackOffset = offset;
  }

  @override
  String toString() => 'PopScope ()';
}

class JumpIfNonNull implements DbcOp {
  JumpIfNonNull(Runtime exec) : _location = exec._readInt16(), _offset = exec._readInt32();

  JumpIfNonNull.make(this._location, this._offset);

  final int _location;
  final int _offset;

  static const int LEN = Dbc.I16_LEN + Dbc.I32_LEN;

  // Conditional move
  @override
  void run(Runtime exec) {
    if (exec._vStack[exec.scopeStackOffset + _location] != null) {
      exec._prOffset = _offset;
    }
  }

  @override
  String toString() => 'JumpIfNonNull (@$_offset if L$_location != null)';
}

// Exit program
class Exit implements DbcOp {
  Exit(Runtime exec) : _location = exec._readInt16();

  Exit.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime exec) {
    throw ProgramExit(exec._vStack[exec.scopeStackOffset + _location] as int);
  }

  @override
  String toString() => 'Exit (L$_location)';
}

class Return implements DbcOp {
  Return(Runtime exec) : _location = exec._readInt16();

  Return.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime exec) {
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

// Move to constant position
class JumpConstant implements DbcOp {
  JumpConstant(Runtime exec) : _offset = exec._readInt32();

  JumpConstant.make(this._offset);

  final int _offset;

  @override
  void run(Runtime exec) {
    exec._prOffset = _offset;
  }

  @override
  String toString() => 'JumpConstant (@$_offset)';
}
