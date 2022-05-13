part of '../runtime.dart';

class PushArg implements DbcOp {
  PushArg(Runtime runtime) : _location = runtime._readInt16();

  PushArg.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  // Set value at position to constant
  @override
  void run(Runtime runtime) {
    runtime.args.add(runtime.frame[_location]);
  }

  @override
  String toString() => 'PushArg (L$_location)';
}

class Pop implements DbcOp {
  Pop(Runtime runtime) : _amount = runtime._readUint8();

  Pop.make(this._amount);

  final int _amount;

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frameOffset -= _amount;
  }

  @override
  String toString() => 'Pop ($_amount)';
}

class PushReturnValue implements DbcOp {
  PushReturnValue(Runtime runtime);

  PushReturnValue.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = runtime.returnValue;
  }

  @override
  String toString() => 'PushReturnValue ()';
}

class SetReturnValue implements DbcOp {
  SetReturnValue(Runtime runtime) : _location = runtime._readInt16();

  SetReturnValue.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  @override
  void run(Runtime runtime) {
    runtime.returnValue = runtime.frame[_location] as int;
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
  void run(Runtime runtime) {
    runtime.frame[_to] = runtime.frame[_from];
  }

  @override
  String toString() => 'CopyValue (L$_to <-- L$_from)';
}

class LoadGlobal implements DbcOp {
  LoadGlobal(Runtime runtime): _index = runtime._readInt32();

  final int _index;

  LoadGlobal.make(this._index);

  static const LEN = Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN;

  @override
  void run(Runtime runtime) {
    var value = runtime.globals[_index];
    if (value == null) {
      runtime.callStack.add(runtime._prOffset);
      runtime._prOffset = runtime.globalInitializers[_index];
    } else {
      runtime.returnValue = value;
    }
  }

  @override
  String toString() => 'LoadGlobal (G$_index)';
}

class SetGlobal implements DbcOp {
  SetGlobal(Runtime runtime): _index = runtime._readInt32(), _value = runtime._readInt16();

  final int _index;
  final int _value;

  SetGlobal.make(this._index, this._value);

  static const LEN = Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN;

  @override
  void run(Runtime runtime) {
    runtime.globals[_index] = runtime.frame[_value];
  }

  @override
  String toString() => 'SetGlobal (G$_index = L$_value)';
}
