part of '../runtime.dart';

class PushArg implements DbcOp {
  PushArg(Runtime exec) : _location = exec._readInt16();

  PushArg.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec.args.add(exec._vStack[exec.scopeStackOffset + _location]);
  }

  @override
  String toString() => 'PushArg (L$_location)';
}

class Pop implements DbcOp {
  Pop(Runtime exec) : _amount = exec._readUint8();

  Pop.make(this._amount);

  final int _amount;

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime exec) {
    exec._stackOffset -= _amount;
  }

  @override
  String toString() => 'Pop ($_amount)';
}

class PushReturnValue implements DbcOp {
  PushReturnValue(Runtime exec);

  PushReturnValue.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime exec) {
    exec._vStack[exec._stackOffset++] = exec.returnValue;
  }

  @override
  String toString() => 'PushReturnValue ()';
}

class SetReturnValue implements DbcOp {
  SetReturnValue(Runtime exec) : _location = exec._readInt16();

  SetReturnValue.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime exec) {
    exec.returnValue = exec._vStack[exec.scopeStackOffset + _location] as int;
  }

  @override
  String toString() => 'SetReturnValue (\$ = L$_location)';
}

class CopyValue implements DbcOp {
  CopyValue(Runtime exec)
      : _to = exec._readInt16(),
        _from = exec._readInt16();

  CopyValue.make(this._to, this._from);

  final int _to;
  final int _from;

  static const LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  // Conditional move
  @override
  void run(Runtime exec) {

    exec._vStack[exec.scopeStackOffset + _to] = exec._vStack[exec.scopeStackOffset + _from];
  }

  @override
  String toString() => 'CopyValue (L$_to <-- L$_from)';
}