part of '../runtime.dart';

class InvokeDynamic implements DbcOp {
  InvokeDynamic(Runtime exec)
      : _location = exec._readInt16(),
        _method = exec._readString();

  InvokeDynamic.make(this._location, this._method);

  final int _location;
  final String _method;

  static int len(InvokeDynamic s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._method);
  }

  @override
  void run(Runtime exec) {
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
  CreateClass(Runtime exec) : _library = exec._readInt32(), _super = exec._readInt16(), _name = exec._readString();

  CreateClass.make(this._library, this._super, this._name);

  final int _library;
  final String _name;
  final int _super;

  static int len(CreateClass s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN + Dbc.istr_len(s._name);
  }

  @override
  void run(Runtime exec) {
    final $super = exec._vStack[exec.scopeStackOffset + _super] as DbcInstanceImpl?;
    final $cls = exec.declaredClasses[_library]![_name]!;

    final instance = DbcInstanceImpl($cls, $super);
    exec._vStack[exec._stackOffset++] = instance;
  }

  @override
  String toString() => 'CreateClass (F$_library:"$_name", super L$_super)';
}


class PushObjectProperty implements DbcOp {
  PushObjectProperty(Runtime exec)
      : _location = exec._readInt16(),
        _property = exec._readString();

  PushObjectProperty.make(this._location, this._property);

  final int _location;
  final String _property;

  static int len(PushObjectProperty s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._property);
  }

  @override
  void run(Runtime exec) {
    final object = exec._vStack[exec.scopeStackOffset + _location];
    exec._vStack[exec._stackOffset++] = (object as DbcInstance).evalGetProperty(_property);
  }

  @override
  String toString() => 'PushObjectProperty (L$_location.$_property)';
}