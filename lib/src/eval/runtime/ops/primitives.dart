part of '../runtime.dart';

class PushConstantInt implements DbcOp {
  PushConstantInt(Runtime exec) : _value = exec._readInt32();

  PushConstantInt.make(this._value);

  final int _value;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I32_LEN;

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec._vStack[exec._stackOffset++] = _value;
  }

  @override
  String toString() => 'PushConstantInt ($_value)';
}

class PushNull implements DbcOp {
  PushNull(Runtime exec);

  PushNull.make();

  static const int LEN = Dbc.BASE_OPLEN;

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec._vStack[exec._stackOffset++] = null;
  }

  @override
  String toString() => 'PushNull ()';
}

class PushConstantString implements DbcOp {
  PushConstantString(Runtime exec) : _value = exec._readString();

  PushConstantString.make(this._value);

  final String _value;

  static int len(PushConstantString s) {
    return Dbc.BASE_OPLEN + Dbc.istr_len(s._value);
  }

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec._vStack[exec._stackOffset++] = _value;
  }

  @override
  String toString() => "PushConstantString ('$_value')";
}

class NumAdd implements DbcOp {
  NumAdd(Runtime exec)
      : _location1 = exec._readInt16(),
        _location2 = exec._readInt16();

  NumAdd.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  // Add value A + B
  @override
  void run(Runtime exec) {
    final scopeStackOffset = exec.scopeStackOffset;
    exec._vStack[exec._stackOffset++] =
        (exec._vStack[scopeStackOffset + _location1] as num) + (exec._vStack[scopeStackOffset + _location2] as num);
  }

  @override
  String toString() => 'NumAdd (L$_location1 + L$_location2)';
}

class NumLt implements DbcOp {
  NumLt(Runtime exec)
      : _location1 = exec._readInt16(),
        _location2 = exec._readInt16();

  NumLt.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  @override
  void run(Runtime exec) {
    final scopeStackOffset = exec.scopeStackOffset;
    exec._vStack[exec._stackOffset++] =
        (exec._vStack[scopeStackOffset + _location1] as num) < (exec._vStack[scopeStackOffset + _location2] as num);
  }

  @override
  String toString() => 'NumLt (L$_location1 < L$_location2)';
}

class NumGt implements DbcOp {
  NumGt(Runtime exec)
      : _location1 = exec._readInt16(),
        _location2 = exec._readInt16();

  NumGt.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  @override
  void run(Runtime exec) {
    final scopeStackOffset = exec.scopeStackOffset;
    exec._vStack[exec._stackOffset++] =
        (exec._vStack[scopeStackOffset + _location1] as num) > (exec._vStack[scopeStackOffset + _location2] as num);
  }

  @override
  String toString() => 'NumGt (L$_location1 > L$_location2)';
}

class BoxInt implements DbcOp {
  BoxInt(Runtime exec) : _position = exec._readInt16();

  BoxInt.make(this._position);

  final int _position;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime exec) {
    final _p = exec.scopeStackOffset + _position;
    exec._vStack[_p] = EvalInt(exec._vStack[_p] as int);
  }

  @override
  String toString() => 'BoxInt (L$_position)';
}

class Unbox implements DbcOp {
  Unbox(Runtime exec) : _position = exec._readInt16();

  Unbox.make(this._position);

  final int _position;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime exec) {
    final _p = exec.scopeStackOffset + _position;
    exec._vStack[_p] = (exec._vStack[_p] as EvalValue).$value;
  }

  @override
  String toString() => 'Unbox (L$_position)';
}