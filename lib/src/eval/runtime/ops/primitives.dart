// ignore_for_file: constant_identifier_names

part of '../runtime.dart';

/// Appends an unboxed value from [Runtime.constantPool] at the given index
/// to the runtime frame. Those constants are collected at compile time
/// with [ConstantPool] in [CompilerContext.constantPool] and stored as a list
/// in the compiled program.
class PushConstant implements EvcOp {
  PushConstant(Runtime runtime) : _const = runtime._readInt32();

  PushConstant.make(this._const);

  final int _const;

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  // Set value at position to constant
  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = runtime.constantPool[_const];
  }

  @override
  String toString() => 'PushConstant (C$_const)';
}

/// Appends an unboxed int32 value to the runtime frame.
/// See [BoxInt] for boxing it.
class PushConstantInt implements EvcOp {
  PushConstantInt(Runtime exec) : _value = exec._readInt32();

  PushConstantInt.make(this._value);

  final int _value;

  static const int LEN = Evc.BASE_OPLEN + Evc.I32_LEN;

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec.frame[exec.frameOffset++] = _value;
  }

  @override
  String toString() => 'PushConstantInt ($_value)';
}

/// Appends an unboxed float32 (as Dart double) value to the runtime frame.
/// See [BoxDouble] for boxing it.
class PushConstantDouble implements EvcOp {
  PushConstantDouble(Runtime exec) : _value = exec._readFloat32();

  PushConstantDouble.make(this._value);

  final double _value;

  static const int LEN = Evc.BASE_OPLEN + Evc.F32_LEN;

  // Set value at position to constant
  @override
  void run(Runtime exec) {
    exec.frame[exec.frameOffset++] = _value;
  }

  @override
  String toString() => 'PushConstantDouble ($_value)';
}

/// Appends an unboxed null value to the runtime frame.
/// See [BoxNull] for boxing it.
class PushNull implements EvcOp {
  PushNull(Runtime exec);

  PushNull.make();

  static const int LEN = Evc.BASE_OPLEN;

  // Set value at position to constant
  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = null;
  }

  @override
  String toString() => 'PushNull ()';
}

/// Takes two unboxed numbers (integer or double) from the given locations
/// on the runtime frame, and appends their sum to the frame.
class NumAdd implements EvcOp {
  NumAdd(Runtime runtime)
      : _location1 = runtime._readInt16(),
        _location2 = runtime._readInt16();

  NumAdd.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_location1] as num) + (runtime.frame[_location2] as num);
  }

  @override
  String toString() => 'NumAdd (L$_location1 + L$_location2)';
}

/// Takes two unboxed numbers (integer or double) from the given locations
/// on the runtime frame, and appends their difference (A-B) to the frame.
class NumSub implements EvcOp {
  NumSub(Runtime runtime)
      : _location1 = runtime._readInt16(),
        _location2 = runtime._readInt16();

  NumSub.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_location1] as num) - (runtime.frame[_location2] as num);
  }

  @override
  String toString() => 'NumSub (L$_location1 - L$_location2)';
}

/// Takes two unboxed numbers (integer or double) from the given locations
/// on the runtime frame, and appends an unboxed boolean value marking
/// whether the first number is smaller than the second.
class NumLt implements EvcOp {
  NumLt(Runtime runtime)
      : _location1 = runtime._readInt16(),
        _location2 = runtime._readInt16();

  NumLt.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_location1] as num) < (runtime.frame[_location2] as num);
  }

  @override
  String toString() => 'NumLt (L$_location1 < L$_location2)';
}

/// Takes two unboxed numbers (integer or double) from the given locations
/// on the runtime frame, and appends an unboxed boolean value marking
/// whether the first number is smaller or equal to the second.
class NumLtEq implements EvcOp {
  NumLtEq(Runtime runtime)
      : _location1 = runtime._readInt16(),
        _location2 = runtime._readInt16();

  NumLtEq.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = (runtime.frame[_location1] as num) <=
        (runtime.frame[_location2] as num);
  }

  @override
  String toString() => 'NumLtEq (L$_location1 <= L$_location2)';
}

/// Boxes an integer number at the given location on the runtime frame.
class BoxInt implements EvcOp {
  BoxInt(Runtime runtime) : _reg = runtime._readInt16();

  BoxInt.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $int(runtime.frame[reg] as int);
  }

  @override
  String toString() => 'BoxInt (L$_reg)';
}

/// Boxes a double number at the given location on the runtime frame.
class BoxDouble implements EvcOp {
  BoxDouble(Runtime runtime) : _reg = runtime._readInt16();

  BoxDouble.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $double(runtime.frame[reg] as double);
  }

  @override
  String toString() => 'BoxDouble (L$_reg)';
}

/// Boxes a [num] instance (integer or double) at the given location
/// on the runtime frame. Replaces it with a [$num] instance.
class BoxNum implements EvcOp {
  BoxNum(Runtime runtime) : _reg = runtime._readInt16();

  BoxNum.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $num(runtime.frame[reg] as num);
  }

  @override
  String toString() => 'BoxNum (L$_reg)';
}

/// Boxes a string at the given location on the runtime frame.
class BoxString implements EvcOp {
  BoxString(Runtime runtime) : _reg = runtime._readInt16();

  BoxString.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $String(runtime.frame[reg] as String);
  }

  @override
  String toString() => 'BoxString (L$_reg)';
}

/// Boxes a list at the given location on the runtime frame.
/// Expects all elements of the list already boxed, inheriting
/// from [$Value].
class BoxList implements EvcOp {
  BoxList(Runtime runtime) : _reg = runtime._readInt16();

  BoxList.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $List.wrap(<$Value>[...(runtime.frame[reg] as List)]);
  }

  @override
  String toString() => 'BoxList (L$_reg)';
}

/// Boxes a null values at the given location on the runtime frame.
/// Does not actually check for the existing value, just overwrites it
/// with a [$null] instance.
class BoxNull implements EvcOp {
  BoxNull(Runtime runtime) : _reg = runtime._readInt16();

  BoxNull.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $null();
  }

  @override
  String toString() => 'BoxNull (L$_reg)';
}

/// Boxes a map at the given location on the runtime frame.
/// Expects all keys and values of the map already boxed, inheriting
/// from [$Value].
class BoxMap implements EvcOp {
  BoxMap(Runtime runtime) : _reg = runtime._readInt16();

  BoxMap.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] =
        $Map.wrap(<$Value, $Value>{...(runtime.frame[reg] as Map)});
  }

  @override
  String toString() => 'BoxMap (L$_reg)';
}

/// Boxes a set at the given location on the runtime frame.
/// Expects all elements of the set already boxed, inheriting
/// from [$Value].
class BoxSet implements EvcOp {
  BoxSet(Runtime runtime) : _reg = runtime._readInt16();

  BoxSet.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $Set.wrap(<$Value>{...(runtime.frame[reg] as Set)});
  }

  @override
  String toString() => 'BoxSet (L$_reg)';
}

/// Boxes a value at the given location on the runtime frame,
/// but only if it's a null. Used for nullable properties.
class MaybeBoxNull implements EvcOp {
  MaybeBoxNull(Runtime runtime) : _reg = runtime._readInt16();

  MaybeBoxNull.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  // Set value at position to constant
  @override
  void run(Runtime runtime) {
    final reg = _reg;
    final value = runtime.frame[reg];
    if (value == null) {
      runtime.frame[reg] = const $null();
    }
  }

  @override
  String toString() => 'MaybeBoxNull (L$_reg)';
}

/// Unboxes a [$Value] at the given location on the runtime frame.
/// Does not check whether it's been unboxed already.
class Unbox implements EvcOp {
  Unbox(Runtime runtime) : _reg = runtime._readInt16();

  Unbox.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[_reg] = (runtime.frame[_reg] as $Value).$value;
  }

  @override
  String toString() => 'Unbox (L$_reg)';
}

/// Appends an empty unboxed untyped list to the runtime frame.
class PushList extends EvcOp {
  PushList(Runtime runtime);

  PushList.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = [];
  }

  @override
  String toString() => 'PushList ()';
}

/// Takes a value from the runtime frame, and appends it to a list
/// (boxed or unboxed) in a different location on the frame. Does not care
/// whether the value is boxed or not.
class ListAppend extends EvcOp {
  ListAppend(Runtime runtime)
      : _reg = runtime._readInt16(),
        _value = runtime._readInt16();

  ListAppend.make(this._reg, this._value);

  final int _reg;
  final int _value;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    (runtime.frame[_reg] as List).add(runtime.frame[_value]);
  }

  @override
  String toString() => 'ListAppend (L$_reg[] = L$_value)';
}

/// Gets an unboxed integer value from the runtime frame, and uses it
/// as an index for a list (boxed or unboxed) on the frame. Appends the received
/// value to the runtime frame.
class IndexList extends EvcOp {
  IndexList(Runtime runtime)
      : _position = runtime._readInt16(),
        _index = runtime._readInt32();

  IndexList.make(this._position, this._index);

  final int _position;
  final int _index;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_position] as List)[runtime.frame[_index] as int];
  }

  @override
  String toString() => 'IndexList (L$_position[L$_index])';
}

/// Gets an unboxed integer value from the runtime frame ([_index]), and uses it
/// as an index for a list (boxed or unboxed, [_position]) on the frame.
/// Finds another value on the frame of whatever type ([_value]) and assigns
/// it to the list in the given position.
class ListSetIndexed extends EvcOp {
  ListSetIndexed(Runtime runtime)
      : _position = runtime._readInt16(),
        _index = runtime._readInt32(),
        _value = runtime._readInt16();

  ListSetIndexed.make(this._position, this._index, this._value);

  final int _position;
  final int _index;
  final int _value;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2 + Evc.I32_LEN;

  @override
  void run(Runtime runtime) {
    final frame = runtime.frame;
    (frame[_position] as List)[frame[_index] as int] = frame[_value];
  }

  @override
  String toString() => 'ListSetIndexed (L$_position[L$_index] = L$_value)';
}

/// Gets a length of an iterable and appends it unboxed to the runtime frame.
class PushIterableLength extends EvcOp {
  PushIterableLength(Runtime runtime) : _position = runtime._readInt16();

  PushIterableLength.make(this._position);

  final int _position;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_position] as Iterable).length;
  }

  @override
  String toString() => 'PushIterableLength (L$_position)';
}

/// Appends an empty unboxed untyped map to the runtime frame.
class PushMap extends EvcOp {
  PushMap(Runtime runtime);

  PushMap.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = <Object?, Object?>{};
  }

  @override
  String toString() => 'PushMap ()';
}

/// Takes a key and a value from the runtime frame, and adds those to a map
/// in a different location on the frame. Does not care whether any of those
/// are boxed.
class MapSet extends EvcOp {
  MapSet(Runtime runtime)
      : _map = runtime._readInt16(),
        _index = runtime._readInt16(),
        _value = runtime._readInt16();

  MapSet.make(this._map, this._index, this._value);

  final int _map;
  final int _index;
  final int _value;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 3;

  @override
  void run(Runtime runtime) {
    final frame = runtime.frame;
    (frame[_map] as Map)[frame[_index]] = frame[_value];
  }

  @override
  String toString() => 'MapSet (L$_map[L$_index] = L$_value)';
}

/// Gets a  value from the runtime frame, and uses it
/// as an index for a map (boxed or unboxed) on the frame. Appends the received
/// value to the runtime frame.
class IndexMap extends EvcOp {
  IndexMap(Runtime runtime)
      : _map = runtime._readInt16(),
        _index = runtime._readInt16();

  IndexMap.make(this._map, this._index);

  final int _map;
  final int _index;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    final frame = runtime.frame;
    frame[runtime.frameOffset++] = (frame[_map] as Map)[frame[_index]];
  }

  @override
  String toString() => 'IndexMap (L$_map[L$_index])';
}

/// Appends an empty unboxed untyped set to the runtime frame.
class PushSet extends EvcOp {
  PushSet(Runtime runtime);

  PushSet.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = <Object?>{};
  }

  @override
  String toString() => 'PushSet ()';
}

/// Takes a value from the runtime frame, and adds it to a set
/// (boxed or unboxed) in a different location on the frame. Does not care
/// whether the value is boxed or not.
class SetAdd extends EvcOp {
  SetAdd(Runtime runtime)
      : _set = runtime._readInt16(),
        _value = runtime._readInt16();

  SetAdd.make(this._set, this._value);

  final int _set;
  final int _value;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  @override
  void run(Runtime runtime) {
    (runtime.frame[_set] as Set).add(runtime.frame[_value]);
  }

  @override
  String toString() => 'SetAdd (L$_set, L$_value)';
}

/// Pushes an unboxed `true` boolean value to the frame,
/// increasing the frame offset. For pushing `false`, call
/// [LogicalNot] right after this op.
class PushTrue extends EvcOp {
  PushTrue(Runtime runtime);

  PushTrue.make();

  static const int LEN = Evc.BASE_OPLEN;

  @override
  void run(Runtime runtime) {
    final frame = runtime.frame;
    frame[runtime.frameOffset++] = true;
  }

  @override
  String toString() => 'PushTrue ()';
}

/// Inverts the boolean value at the given [_index] on the frame.
/// Works regardless of whether the value is boxed or not.
class LogicalNot extends EvcOp {
  LogicalNot(Runtime runtime) : _index = runtime._readInt16();

  LogicalNot.make(this._index);

  final int _index;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final frame = runtime.frame;
    frame[runtime.frameOffset++] = !(frame[_index] as bool);
  }

  @override
  String toString() => 'LogicalNot (L$_index)';
}

/// Boxes a boolean value at the [_reg] location on the frame into [$bool].
/// Expects an unboxed bool at that location.
class BoxBool implements EvcOp {
  BoxBool(Runtime runtime) : _reg = runtime._readInt16();

  BoxBool.make(this._reg);

  final int _reg;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN;

  @override
  void run(Runtime runtime) {
    final reg = _reg;
    runtime.frame[reg] = $bool(runtime.frame[reg] as bool);
  }

  @override
  String toString() => 'BoxBool (L$_reg)';
}

/// Appends a boxed [$Record] to the runtime frame.
/// For field values, expects a list in the given location on the frame,
/// and for the field mapping (strings to list indices), a map on the
/// constant pool.
class PushRecord implements EvcOp {
  PushRecord(Runtime runtime)
      : _fields = runtime._readInt16(),
        _const = runtime._readInt32(),
        _type = runtime._readInt32();

  PushRecord.make(this._fields, this._const, this._type);

  final int _fields;
  final int _const;
  final int _type;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN + Evc.I32_LEN * 2;

  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] = $Record(
      (runtime.frame[_fields] as List).cast(),
      (runtime.constantPool[_const] as Map).cast(),
      _type,
    );
  }

  @override
  String toString() => 'PushRecord (L$_fields, C$_const)';
}
