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
  void run(Runtime runtime) {
    var object = runtime._vStack[runtime.scopeStackOffset + _location];

    while (true) {
      if (object is DbcInstanceImpl) {
        final methods = object.evalClass.methods;
        if (!methods.containsKey(_method)) {
          object = object.evalSuperclass;
          continue;
        }
        final _offset = methods[_method]!;
        runtime.callStack.add(runtime._prOffset);
        runtime._prOffset = _offset;
        return;
      }

      if (object is DbcBridgeInstance) {

      }

      final method = ((object as DbcInstance).$getProperty(runtime, _method) as DbcFunction);
      if (method is DbcFunctionImpl) {
        runtime._returnValue = method.call(runtime, object, runtime._args.cast());
        runtime._args = [];
        return;
      } else {
        throw UnimplementedError();
      }
    }

  }

  @override
  String toString() => 'InvokeDynamic (L$_location.$_method)';
}

// Create a class
class CreateClass implements DbcOp {
  CreateClass(Runtime exec)
      : _library = exec._readInt32(),
        _super = exec._readInt16(),
        _name = exec._readString(),
        _valuesLen = exec._readInt16();

  CreateClass.make(this._library, this._super, this._name, this._valuesLen);

  final int _library;
  final String _name;
  final int _super;
  final int _valuesLen;

  static int len(CreateClass s) {
    return Dbc.BASE_OPLEN + Dbc.I32_LEN + Dbc.I16_LEN * 2 + Dbc.istr_len(s._name);
  }

  @override
  void run(Runtime exec) {
    final $super = exec._vStack[exec.scopeStackOffset + _super] as DbcInstance?;
    final $cls = exec.declaredClasses[_library]![_name]!;

    final instance = DbcInstanceImpl($cls, $super, List.filled(_valuesLen, null));
    exec._vStack[exec._stackOffset++] = instance;
  }

  @override
  String toString() => 'CreateClass (F$_library:"$_name", super L$_super, vLen=$_valuesLen))';
}

class SetObjectProperty implements DbcOp {
  SetObjectProperty(Runtime exec)
      : _location = exec._readInt16(),
        _property = exec._readString(),
        _valueOffset = exec._readInt16();

  SetObjectProperty.make(this._location, this._property, this._valueOffset);

  final int _location;
  final String _property;
  final int _valueOffset;

  static int len(SetObjectProperty s) {
    return Dbc.BASE_OPLEN + Dbc.I16_LEN + Dbc.istr_len(s._property) + Dbc.I16_LEN;
  }

  @override
  void run(Runtime runtime) {
    final object = runtime._vStack[runtime.scopeStackOffset + _location];
    (object as DbcInstance)
        .$setProperty(runtime, _property, runtime._vStack[runtime.scopeStackOffset + _valueOffset] as IDbcValue);
  }

  @override
  String toString() => 'SetObjectProperty (L$_location.$_property = L$_valueOffset)';
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
  void run(Runtime runtime) {
    final object = runtime._vStack[runtime.scopeStackOffset + _location];
    final _r = (object as DbcInstance).$getProperty(runtime, _property);;
    runtime._vStack[runtime._stackOffset++] = _r;
  }

  @override
  String toString() => 'PushObjectProperty (L$_location.$_property)';
}

class PushObjectPropertyImpl implements DbcOp {
  PushObjectPropertyImpl(Runtime exec)
      : _objectOffset = exec._readInt16(),
        _propertyIndex = exec._readInt16();

  final int _objectOffset;
  final int _propertyIndex;

  PushObjectPropertyImpl.make(this._objectOffset, this._propertyIndex);

  static int LEN = Dbc.I16_LEN * 2;

  @override
  void run(Runtime exec) {
    final object = exec._vStack[exec.scopeStackOffset + _objectOffset] as DbcInstanceImpl;
    exec._vStack[exec._stackOffset++] = object.values[_propertyIndex];
  }

  @override
  String toString() => 'PushObjectPropertyImpl (L$_objectOffset[$_propertyIndex])';
}

class SetObjectPropertyImpl implements DbcOp {
  SetObjectPropertyImpl(Runtime exec)
      : _objectOffset = exec._readInt16(),
        _propertyIndex = exec._readInt16(),
        _valueOffset = exec._readInt16();

  final int _objectOffset;
  final int _propertyIndex;
  final int _valueOffset;

  SetObjectPropertyImpl.make(this._objectOffset, this._propertyIndex, this._valueOffset);

  static int LEN = Dbc.I16_LEN * 3;

  @override
  void run(Runtime exec) {
    final object = exec._vStack[exec.scopeStackOffset + _objectOffset] as DbcInstanceImpl;
    final value = exec._vStack[exec.scopeStackOffset + _valueOffset]!;
    object.values[_propertyIndex] = value;
  }

  @override
  String toString() => 'SetObjectPropertyImpl (L$_objectOffset[$_propertyIndex] = L$_valueOffset)';
}

class PushSuper implements DbcOp {
  PushSuper(Runtime exec)
      : _objectOffset = exec._readInt16();

  final int _objectOffset;

  PushSuper.make(this._objectOffset);

  static int LEN = Dbc.I16_LEN;

  @override
  void run(Runtime exec) {
    final object = exec._vStack[exec.scopeStackOffset + _objectOffset] as DbcInstanceImpl;
    exec._vStack[exec._stackOffset++] = object.evalSuperclass;
  }

  @override
  String toString() => 'PushSuper (L$_objectOffset)';
}
