import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/declaration.dart';

import 'function.dart';
import 'stdlib_base.dart';
import 'class.dart';
import 'exception.dart';
import 'ops/all_ops.dart';

part 'ops/primitives.dart';

part 'ops/memory.dart';

part 'ops/flow.dart';

part 'ops/objects.dart';

class ScopeFrame {
  ScopeFrame(this.stackOffset, this.scopeStackOffset, [this.entrypoint = false]);

  final int stackOffset;
  final int scopeStackOffset;
  final bool entrypoint;
}

class Runtime {
  Runtime(this._dbc) : id = _id++;

  static List<int> opcodeFrom(DbcOp op) {
    switch (op.runtimeType) {
      case JumpConstant:
        op as JumpConstant;
        return [Dbc.OP_JMPC, ...Dbc.i32b(op._offset)];
      case Exit:
        op as Exit;
        return [Dbc.OP_EXIT, ...Dbc.i16b(op._location)];
      case Unbox:
        op as Unbox;
        return [Dbc.OP_UNBOX, ...Dbc.i16b(op._position)];
      case PushReturnValue:
        op as PushReturnValue;
        return [Dbc.OP_SETVR];
      case AddInts:
        op as AddInts;
        return [Dbc.OP_ADDVV, ...Dbc.i16b(op._location1), ...Dbc.i16b(op._location2)];
      case BoxInt:
        op as BoxInt;
        return [Dbc.OP_BOXINT, ...Dbc.i16b(op._position)];
      case PushArg:
        op as PushArg;
        return [Dbc.OP_PUSH_ARG, ...Dbc.i16b(op._location)];
      case PushNamedArg:
        op as PushNamedArg;
        return [Dbc.OP_PUSH_NAMED_ARG, ...Dbc.i16b(op._location), ...Dbc.istr(op._name)];
      case JumpIfNonNull:
        op as JumpIfNonNull;
        return [Dbc.OP_JNZ, ...Dbc.i16b(op._location), ...Dbc.i32b(op._offset)];
      case PushConstantInt:
        op as PushConstantInt;
        return [Dbc.OP_SETVC, ...Dbc.i32b(op._value)];
      case PushScope:
        op as PushScope;
        return [Dbc.OP_PUSHSCOPE, ...Dbc.i32b(op.sourceFile), ...Dbc.i32b(op.sourceOffset), ...Dbc.istr(op.frName)];
      case CopyValue:
        op as CopyValue;
        return [Dbc.OP_SETVV, ...Dbc.i16b(op._position1), ...Dbc.i16b(op._position2)];
      case PushConstantString:
        op as PushConstantString;
        return [Dbc.OP_PUSH_CONST_STR, ...Dbc.istr(op._value)];
      case SetReturnValue:
        op as SetReturnValue;
        return [Dbc.OP_SETRV, ...Dbc.i16b(op._location)];
      case Return:
        op as Return;
        return [Dbc.OP_RETURN, ...Dbc.i16b(op._location)];
      case Pop:
        return [Dbc.OP_POP];
      case Call:
        op as Call;
        return [Dbc.OP_CALL, ...Dbc.i32b(op._offset)];
      case InvokeDynamic:
        op as InvokeDynamic;
        return [Dbc.OP_INVOKE_DYNAMIC, ...Dbc.i16b(op._location), ...Dbc.istr(op._method)];
      case SetObjectProperty:
        op as SetObjectProperty;
        return [
          Dbc.OP_SET_OBJECT_PROP,
          ...Dbc.i16b(op._location),
          ...Dbc.istr(op._property),
          ...Dbc.i16b(op._valueOffset)
        ];
      case PushObjectProperty:
        op as PushObjectProperty;
        return [Dbc.OP_PUSH_OBJECT_PROP, ...Dbc.i16b(op._location), ...Dbc.istr(op._property)];
      case PushObjectPropertyImpl:
        op as PushObjectPropertyImpl;
        return [Dbc.OP_PUSH_OBJECT_PROP_IMPL, ...Dbc.i16b(op._objectOffset), ...Dbc.i16b(op._propertyIndex)];
      case SetObjectPropertyImpl:
        op as SetObjectPropertyImpl;
        return [
          Dbc.OP_SET_OBJECT_PROP_IMPL,
          ...Dbc.i16b(op._objectOffset),
          ...Dbc.i16b(op._propertyIndex),
          ...Dbc.i16b(op._valueOffset)
        ];
      case PushNull:
        op as PushNull;
        return [Dbc.OP_PUSH_NULL];
      case CreateClass:
        op as CreateClass;
        return [
          Dbc.OP_CREATE_CLASS,
          ...Dbc.i32b(op._library),
          ...Dbc.i16b(op._super),
          ...Dbc.istr(op._name),
          ...Dbc.i16b(op._valuesLen)
        ];
      default:
        throw ArgumentError('Not a valid op $op');
    }
  }

  static int _id = 0;
  final int id;

  static const MIN_DYNAMIC_REGISTER = 32;

  final ByteData _dbc;
  final _vStack = List<Object?>.filled(65535, null);
  var _args = <Object?>[];
  var _namedArgs = <String, Object?>{};
  final pr = <DbcOp>[];
  Object? _returnValue = null;
  var scopeStack = <ScopeFrame>[ScopeFrame(0, 0)];
  var scopeStackOffset = 0;
  final callStack = <int>[0];
  var declarations = <int, Map<String, int>>{};
  final declaredClasses = <int, Map<String, DbcClass>>{};
  int _stackOffset = 0;
  int _argsOffset = 0;
  int _offset = 0;
  int _prOffset = 0;

  static const VTYPE_INT = 0;
  static const VTYPE_OBJECT = 1;

  void loadProgram() {
    final metaLength = _dbc.getInt32(0);
    final metaStr = <int>[];
    _offset = 4;
    while (_offset < metaLength + 4) {
      metaStr.add(_dbc.getUint8(_offset));
      _offset++;
    }

    final classesLength = _dbc.getInt32(_offset);
    final classStr = <int>[];

    _offset += 4;

    final _startOffset = _offset;
    while (_offset < classesLength + _startOffset) {
      classStr.add(_dbc.getUint8(_offset));
      _offset++;
    }

    declarations =
        (json.decode(utf8.decode(metaStr)).map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, int>())) as Map)
            .cast<int, Map<String, int>>();

    final classes = (json
            .decode(utf8.decode(classStr))
            .map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, List>())) as Map)
        .cast<int, Map<String, List>>();

    final _vm = DbcVmInterface(this);

    classes.forEach((file, classs) {
      final decls = <String, DbcClass>{};

      classs.forEach((name, declarations) {
        final dc = declarations.cast<Map>();

        final getters = (dc[0]).cast<String, int>();
        final setters = (dc[1]).cast<String, int>();
        final methods = (dc[2]).cast<String, int>();

        final cls = DbcClass(_vm, null, [], getters, setters, methods);
        decls[name] = cls;
      });

      declaredClasses[file] = decls;
    });

    while (_offset < _dbc.lengthInBytes) {
      final opId = _dbc.getUint8(_offset);
      _offset++;
      pr.add(ops[opId](this));
    }
  }

  void printOpcodes() {
    var i = 0;
    for (final oo in pr) {
      print('$i: $oo');
      i++;
    }
  }

  dynamic executeNamed(int file, String name) {
    return execute(declarations[file]![name]!);
  }

  dynamic execute(int entrypoint) {
    _prOffset = entrypoint;
    try {
      callStack.add(-1);
      while (true) {
        final op = pr[_prOffset++];
        op.run(this);
      }
    } on ProgramExit catch (_) {
      return _returnValue;
    }
  }

  void bridgeCall(int $offset) {
    final _savedOffset = _prOffset;
    _prOffset = $offset;
    callStack.add(-1);

    try {
      while (true) {
        final op = pr[_prOffset++];
        op.run(this);
      }
    } on ProgramExit catch (_) {
      _prOffset = _savedOffset;
      return;
    }
  }

  void pushArg(Object? _value) {
    _args.add(_value);
    _argsOffset++;
  }

  void popScope() {
    final offset = scopeStack.removeLast().stackOffset;
    _stackOffset = offset;
    scopeStackOffset = offset;
  }

  Object? get returnValue => _returnValue;

  @pragma('vm:always-inline')
  int _readInt32() {
    final i = _dbc.getInt32(_offset);
    _offset += 4;
    return i;
  }

  @pragma('vm:always-inline')
  int _readInt16() {
    final i = _dbc.getInt16(_offset);
    _offset += 2;
    return i;
  }

  @pragma('vm:always-inline')
  String _readString() {
    final len = _dbc.getInt32(_offset);
    _offset += 4;
    final codeUnits = List.filled(len, 0);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = _dbc.getUint8(_offset + i);
    }
    _offset += len;
    return utf8.decode(codeUnits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Runtime && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
