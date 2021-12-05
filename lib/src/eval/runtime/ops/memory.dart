part of '../runtime.dart';

class PushArg implements DbcOp {
  PushArg(Runtime exec) : _location = exec._readInt16();

  PushArg.make(this._location);

  final int _location;

  static const int LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN;

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec._args.add(exec._vStack[exec.scopeStackOffset + _location]);
    exec._argsOffset++;
  }

  @override
  String toString() => 'PushArg (L$_location)';
}

class PushNamedArg implements DbcOp {
  PushNamedArg(Runtime exec)
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
  void run(Runtime exec) {
    exec._namedArgs[_name] = exec._vStack[exec.scopeStackOffset + _location];
  }

  @override
  String toString() => 'PushNamedArg ($_name: L$_location)';
}

class Pop implements DbcOp {
  Pop(Runtime exec);

  Pop.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime exec) {
    exec._stackOffset--;
  }

  @override
  String toString() => 'Pop ()';
}

class PushReturnValue implements DbcOp {
  PushReturnValue(Runtime exec);

  PushReturnValue.make();

  static const int LEN = Dbc.BASE_OPLEN;

  @override
  void run(Runtime exec) {
    exec._vStack[exec._stackOffset++] = exec._returnValue;
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
    exec._returnValue = exec._vStack[exec.scopeStackOffset + _location] as int;
  }

  @override
  String toString() => 'SetReturnValue (\$ = L$_location)';
}

class CopyValue implements DbcOp {
  CopyValue(Runtime exec)
      : _position1 = exec._readInt16(),
        _position2 = exec._readInt16();

  CopyValue.make(this._position1, this._position2);

  final int _position1;
  final int _position2;

  static const LEN = Dbc.BASE_OPLEN + Dbc.I16_LEN * 2;

  // Conditional move
  @override
  void run(Runtime exec) {

    exec._vStack[exec.scopeStackOffset + _position1] = exec._vStack[exec.scopeStackOffset + _position2];
  }

  @override
  String toString() => 'CopyValue (L$_position1 <-- L$_position2)';
}