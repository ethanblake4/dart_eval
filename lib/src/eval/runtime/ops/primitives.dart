// ignore_for_file: constant_identifier_names

part of '../runtime.dart';

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

class NumAdd implements EvcOp {
  NumAdd(Runtime runtime)
      : _location1 = runtime._readInt16(),
        _location2 = runtime._readInt16();

  NumAdd.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  // Add value A + B
  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_location1] as num) + (runtime.frame[_location2] as num);
  }

  @override
  String toString() => 'NumAdd (L$_location1 + L$_location2)';
}

class NumSub implements EvcOp {
  NumSub(Runtime runtime)
      : _location1 = runtime._readInt16(),
        _location2 = runtime._readInt16();

  NumSub.make(this._location1, this._location2);

  final int _location1;
  final int _location2;

  static const int LEN = Evc.BASE_OPLEN + Evc.I16_LEN * 2;

  // Add value A + B
  @override
  void run(Runtime runtime) {
    runtime.frame[runtime.frameOffset++] =
        (runtime.frame[_location1] as num) - (runtime.frame[_location2] as num);
  }

  @override
  String toString() => 'NumSub (L$_location1 - L$_location2)';
}

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
  String toString() => 'PushRecord ()';
}
