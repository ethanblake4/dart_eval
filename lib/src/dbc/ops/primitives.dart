part of '../dbc_executor.dart';

class PushConstantInt implements DbcOp {
  PushConstantInt(DbcExecutor exec) : _value = exec._readInt32();

  PushConstantInt.make(this._value);

  final int _value;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I32_LEN;

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._vStack[exec._stackOffset++] = _value;
  }

  @override
  String toString() => 'PushConstantInt ($_value)';
}

class PushNull implements DbcOp {
  PushNull(DbcExecutor exec);

  PushNull.make();

  static const int LEN = Dbc.BASE_OPLEN;

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._vStack[exec._stackOffset++] = null;
  }

  @override
  String toString() => 'PushNull ()';
}

class AddInts implements DbcOp {
  AddInts(DbcExecutor exec)
      : _location1 = exec._readInt16(),
        _location2 = exec._readInt16();

  AddInts.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  // Add value A + B
  @override
  void run(DbcExecutor exec) {
    final scopeStackOffset = exec.scopeStackOffset;
    exec._vStack[exec._stackOffset++] =
        (exec._vStack[scopeStackOffset + _location1] as int) + (exec._vStack[scopeStackOffset + _location2] as int);
  }

  @override
  String toString() => 'AddInts (L$_location1 + L$_location2)';
}

class BoxInt implements DbcOp {
  BoxInt(DbcExecutor exec) : _position = exec._readInt16();

  BoxInt.make(this._position);

  final int _position;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._vStack[exec._stackOffset++] = DbcInt(exec._vStack[exec.scopeStackOffset + _position] as int);
  }

  @override
  String toString() => 'BoxInt (L$_position)';
}

class Unbox implements DbcOp {
  Unbox(DbcExecutor exec) : _position = exec._readInt16();

  Unbox.make(this._position);

  final int _position;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  // Set value at position to constant
  @override
  void run(DbcExecutor exec) {
    exec._vStack[exec._stackOffset++] =
        (exec._vStack[exec.scopeStackOffset + _position] as DbcValueInterface).evalValue;
  }

  @override
  String toString() => 'Unbox (L$_position)';
}
