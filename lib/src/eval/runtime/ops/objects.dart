// ignore_for_file: constant_identifier_names

part of '../runtime.dart';

class InvokeDynamic implements EvcOp {
  InvokeDynamic(Runtime runtime)
      : _location = runtime._readInt16(),
        _methodIdx = runtime._readInt32();

  InvokeDynamic.make(this._location, this._methodIdx);

  final int _location;
  final int _methodIdx;

  static int len(InvokeDynamic s) {
    return Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN;
  }

  @override
  void run(Runtime runtime) {
    final method0 = runtime.constantPool[_methodIdx] as String;
    var object = runtime.frame[_location];

    while (true) {
      if (object is $InstanceImpl) {
        final methods = object.evalClass.methods;
        final offset = methods[method0];
        if (offset == null) {
          object = object.evalSuperclass;
          continue;
        }
        runtime.callStack.add(runtime._prOffset);
        runtime.catchStack.add([]);
        runtime._prOffset = offset;
        return;
      }

      if (method0 == 'call' && object is EvalFunctionPtr) {
        final cpat = runtime.args[0] as List;
        final cnat = runtime.args[2] as List;

        final csPosArgTypes = [for (final a in cpat) runtime.runtimeTypes[a]];
        final csNamedArgs = runtime.args[1] as List;
        final csNamedArgTypes = [for (final a in cnat) runtime.runtimeTypes[a]];

        final totalPositionalArgCount = object.positionalArgTypes.length;
        final totalNamedArgCount = object.sortedNamedArgs.length;

        if (csPosArgTypes.length < object.requiredPositionalArgCount ||
            csPosArgTypes.length > totalPositionalArgCount) {
          throw ArgumentError(
              'FunctionPtr: Cannot invoke function with the given arguments (unacceptable # of positional arguments). '
              '$totalPositionalArgCount >= ${csPosArgTypes.length} >= ${object.requiredPositionalArgCount}');
        }

        var i = 0, j = 0;
        while (i < csPosArgTypes.length) {
          if (!csPosArgTypes[i].isAssignableTo(object.positionalArgTypes[i])) {
            throw ArgumentError(
                'FunctionPtr: Cannot invoke function with the given arguments');
          }
          i++;
        }

        // Very efficient algorithm for checking that named args match
        // Requires that the named arg arrays be sorted
        i = 0;
        final cl = csNamedArgs.length, cp = csPosArgTypes.length;
        final tl = totalNamedArgCount - 1;
        while (j < cl) {
          if (i > tl) {
            throw ArgumentError(
                'FunctionPtr: Cannot invoke function with the given arguments');
          }
          final t = csNamedArgTypes[j];
          final ti = object.sortedNamedArgTypes[i];
          if (object.sortedNamedArgs[i] == csNamedArgs[j] &&
              t.isAssignableTo(ti)) {
            j++;
          }
          i++;
        }

        runtime.args = [
          if (object.$prev != null) object.$prev,
          for (i = 0; i < object.requiredPositionalArgCount; i++)
            runtime.args[i + 3],
          for (i = object.requiredPositionalArgCount;
              i < totalPositionalArgCount;
              i++)
            if (cp > i) runtime.args[i + 3] else null,
          for (i = 0; i < object.sortedNamedArgs.length; i++)
            if (cl > i) runtime.args[i + 3 + totalPositionalArgCount] else null
        ];
        runtime.callStack.add(runtime._prOffset);
        runtime.catchStack.add([]);
        runtime._prOffset = object.offset;
        return;
      }
      final method = ((object as $Instance).$getProperty(runtime, method0)
          as EvalFunction);
      try {
        runtime.returnValue = method.call(runtime, object, runtime.args.cast());
      } catch (e) {
        runtime.$throw(e);
      }
      runtime.args = [];
      return;
    }
  }

  @override
  String toString() => 'InvokeDynamic (L$_location.C$_methodIdx)';
}

class CheckEq implements EvcOp {
  CheckEq(Runtime runtime)
      : _value1 = runtime._readInt16(),
        _value2 = runtime._readInt16();

  CheckEq.make(this._value1, this._value2);

  final int _value1;
  final int _value2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    final v1 = runtime.frame[_value1];
    final v2 = runtime.frame[_value2];

    var vx = v1;

    while (true) {
      if (vx is $InstanceImpl) {
        final methods = vx.evalClass.methods;
        final offset = methods['=='];
        if (offset == null) {
          vx = vx.evalSuperclass;
          continue;
        }
        runtime.args = [v2];
        runtime.callStack.add(runtime._prOffset);
        runtime.catchStack.add([]);
        runtime._prOffset = offset;

        return;
      }

      if (vx is $Instance) {
        final method = vx.$getProperty(runtime, '==') as EvalFunction;

        runtime.returnValue = method
            .call(runtime, vx, [v2 == null ? null : v2 as $Value])!.$value;
        runtime.args = [];

        return;
      }

      runtime.returnValue = v1 == v2;
      return;
    }
  }

  @override
  String toString() => 'CheckEq (L$_value1 == L$_value2)';
}

// Create a class
class CreateClass implements EvcOp {
  CreateClass(Runtime runtime)
      : _library = runtime._readInt32(),
        _super = runtime._readInt16(),
        _name = runtime._readString(),
        _valuesLen = runtime._readInt16();

  CreateClass.make(this._library, this._super, this._name, this._valuesLen);

  final int _library;
  final String _name;
  final int _super;
  final int _valuesLen;

  static int len(CreateClass s) {
    return Evc.BASE_OPLEN +
        Evc.I32_LEN +
        Evc.I16_LEN * 2 +
        Evc.istrLen(s._name);
  }

  @override
  void run(Runtime runtime) {
    final $super = runtime.frame[_super] as $Instance?;
    final $cls = runtime.declaredClasses[_library]![_name]!;

    final instance = $InstanceImpl($cls, $super, List.filled(_valuesLen, null));
    runtime.frame[runtime.frameOffset++] = instance;
  }

  @override
  String toString() =>
      'CreateClass (F$_library:"$_name", super L$_super, vLen=$_valuesLen))';
}

class SetObjectProperty implements EvcOp {
  SetObjectProperty(Runtime runtime)
      : _location = runtime._readInt16(),
        _property = runtime._readString(),
        _valueOffset = runtime._readInt16();

  SetObjectProperty.make(this._location, this._property, this._valueOffset);

  final int _location;
  final String _property;
  final int _valueOffset;

  static int len(SetObjectProperty s) {
    return Evc.BASE_OPLEN +
        Evc.I16_LEN +
        Evc.istrLen(s._property) +
        Evc.I16_LEN;
  }

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_location];
    (object as $Instance).$setProperty(
        runtime, _property, runtime.frame[_valueOffset] as $Value);
  }

  @override
  String toString() =>
      'SetObjectProperty (L$_location.$_property = L$_valueOffset)';
}

class PushObjectProperty implements EvcOp {
  PushObjectProperty(Runtime runtime)
      : _location = runtime._readInt16(),
        _propertyIdx = runtime._readInt32();

  PushObjectProperty.make(this._location, this._propertyIdx);

  final int _location;
  final int _propertyIdx;

  static int len(PushObjectProperty s) {
    return Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN;
  }

  @override
  void run(Runtime runtime) {
    final property = runtime.constantPool[_propertyIdx] as String;
    var base = runtime.frame[_location];
    var object = base;

    while (true) {
      if (object is $InstanceImpl) {
        base = object;
        final evalClass = object.evalClass;
        final offset = evalClass.getters[property];
        if (offset == null) {
          final method = evalClass.methods[property];
          if (method == null) {
            object = object.evalSuperclass;
            if (object == null) {
              runtime.returnValue =
                  (base as $InstanceImpl).getCoreObjectProperty(property);
              return;
            }
            continue;
          }
          runtime.returnValue = EvalStaticFunctionPtr(object, method);
          runtime.args = [];
          return;
        }
        runtime.args.add(object);
        runtime.callStack.add(runtime._prOffset);
        runtime.catchStack.add([]);
        runtime._prOffset = offset;
        return;
      }

      final result = ((object as $Instance).$getProperty(runtime, property));
      runtime.returnValue = result;
      runtime.args = [];
      return;
    }
  }

  @override
  String toString() => 'PushObjectProperty (L$_location.C$_propertyIdx)';
}

class PushObjectPropertyImpl implements EvcOp {
  PushObjectPropertyImpl(Runtime runtime)
      : objectOffset = runtime._readInt16(),
        _propertyIndex = runtime._readInt16();

  final int objectOffset;
  final int _propertyIndex;

  PushObjectPropertyImpl.make(this.objectOffset, this._propertyIndex);

  static int length = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[objectOffset] as $InstanceImpl;
    runtime.frame[runtime.frameOffset++] = object.values[_propertyIndex];
  }

  @override
  String toString() =>
      'PushObjectPropertyImpl (L$objectOffset[$_propertyIndex])';
}

class SetObjectPropertyImpl implements EvcOp {
  SetObjectPropertyImpl(Runtime runtime)
      : _objectOffset = runtime._readInt16(),
        _propertyIndex = runtime._readInt16(),
        _valueOffset = runtime._readInt16();

  final int _objectOffset;
  final int _propertyIndex;
  final int _valueOffset;

  SetObjectPropertyImpl.make(
      this._objectOffset, this._propertyIndex, this._valueOffset);

  static int length = Evc.BASE_OPLEN + Evc.I16_LEN * 3;

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_objectOffset] as $InstanceImpl;
    final value = runtime.frame[_valueOffset]!;
    object.values[_propertyIndex] = value;
  }

  @override
  String toString() =>
      'SetObjectPropertyImpl (L$_objectOffset[$_propertyIndex] = L$_valueOffset)';
}

class PushSuper implements EvcOp {
  PushSuper(Runtime runtime) : _objectOffset = runtime._readInt16();

  final int _objectOffset;

  PushSuper.make(this._objectOffset);

  static int length = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final object = runtime.frame[_objectOffset] as $Instance;
    if (object is $InstanceImpl) {
      runtime.frame[runtime.frameOffset++] = object.evalSuperclass;
    } else if (object is $Bridge) {
      runtime.frame[runtime.frameOffset++] =
          (Runtime.bridgeData[object]!.subclass as $InstanceImpl)
              .evalSuperclass!;
    } else {
      throw UnimplementedError();
    }
  }

  @override
  String toString() => 'PushSuper (L$_objectOffset.super)';
}

class IsType implements EvcOp {
  IsType(Runtime runtime)
      : _objectOffset = runtime._readInt16(),
        _type = runtime._readInt32(),
        _not = runtime._readUint8() > 0;

  final int _objectOffset;
  final int _type;
  final bool _not;

  IsType.make(this._objectOffset, this._type, this._not);

  static int length = Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN + Evc.I8_LEN;

  @override
  void run(Runtime runtime) {
    final value = runtime.frame[_objectOffset] as $Value;
    final type = value.$getRuntimeType(runtime);
    if (type < 0) {
      final result = type == _type;
      runtime.frame[runtime.frameOffset++] = _not ? !result : result;
      return;
    }
    final typeSet = runtime.typeTypes[type];
    final result = typeSet.contains(_type);
    runtime.frame[runtime.frameOffset++] = _not ? !result : result;
  }

  @override
  String toString() => 'IsType (L$_objectOffset is${_not ? '!' : ''} $_type)';
}

class PushRuntimeType implements EvcOp {
  PushRuntimeType(Runtime runtime) : _value = runtime._readInt16();

  final int _value;

  PushRuntimeType.make(this._value);

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final value = runtime.frame[_value] as $Value;
    runtime.frame[runtime.frameOffset++] =
        $TypeImpl(value.$getRuntimeType(runtime));
  }

  @override
  String toString() => 'PushRuntimeType (L$_value)';
}

class PushConstantType implements EvcOp {
  PushConstantType(Runtime runtime) : _typeId = runtime._readInt32();

  final int _typeId;

  PushConstantType.make(this._typeId);

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = $TypeImpl(_typeId);
  }

  @override
  String toString() => 'PushConstantType (ID $_typeId)';
}
