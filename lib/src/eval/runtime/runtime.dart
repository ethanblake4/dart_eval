import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/type.dart';

import 'exception.dart';
import 'ops/all_ops.dart';

part 'ops/primitives.dart';

part 'ops/memory.dart';

part 'ops/flow.dart';

part 'ops/objects.dart';

part 'ops/bridge.dart';

class ScopeFrame {
  const ScopeFrame(this.stackOffset, this.scopeStackOffset, [this.entrypoint = false]);

  final int stackOffset;
  final int scopeStackOffset;
  final bool entrypoint;

  @override
  String toString() {
    return '$stackOffset (scope $scopeStackOffset)';
  }
}

class _UnloadedBridgeClass {
  const _UnloadedBridgeClass(this.library, this.name, this.cls);

  final String library;
  final String name;
  final $Bridge cls;
}

class _UnloadedBridgeFunction {
  const _UnloadedBridgeFunction(this.library, this.name, this.func);

  final String library;
  final String name;
  final $Function func;
}

class Runtime {
  Runtime(this._dbc) : id = _id++ {
    loadProgram();
  }

  Runtime.ofProgram(Program program)
      : id = _id++,
        typeTypes = program.typeTypes,
        typeNames = program.typeNames,
        runtimeTypes = program.runtimeTypes {
    declarations = program.topLevelDeclarations;
    constantPool.addAll(program.constantPool);
    program.instanceDeclarations.forEach((file, $class) {
      final decls = <String, EvalClass>{};

      $class.forEach((name, declarations) {
        final getters = (declarations[0] as Map).cast<String, int>();
        final setters = (declarations[1] as Map).cast<String, int>();
        final methods = (declarations[2] as Map).cast<String, int>();
        final type = (declarations[3] as int);

        final cls = EvalClass(type, null, [], {...getters}, {...setters}, {...methods});
        decls[name] = cls;
      });

      declaredClasses[file] = decls;
    });

    pr.addAll(program.ops);
  }

  void loadProgram() {
    final encodedToplevelDecs = _readString();
    final encodedInstanceDecs = _readString();
    final encodedTypeNames = _readString();
    final encodedTypeTypes = _readString();
    final encodedBridgeLibraryMappings = _readString();
    final encodedBridgeFuncMappings = _readString();
    final encodedConstantPool = _readString();
    final encodedRuntimeTypes = _readString();

    declarations =
        (json.decode(encodedToplevelDecs).map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, int>())) as Map)
            .cast<int, Map<String, int>>();

    final classes =
        (json.decode(encodedInstanceDecs).map((k, v) => MapEntry(int.parse(k), (v as Map).cast<String, List>())) as Map)
            .cast<int, Map<String, List>>();

    classes.forEach((file, $class) {
      declaredClasses[file] = {for (final decl in $class.entries) decl.key: EvalClass.fromJson(decl.value)};
    });

    typeNames = (json.decode(encodedTypeNames) as List).cast();
    typeTypes = [for (final s in (json.decode(encodedTypeTypes) as List)) (s as List).cast<int>().toSet()];

    _bridgeLibraryMappings = (json.decode(encodedBridgeLibraryMappings) as Map).cast();

    final bridgeFuncMappings = (json.decode(encodedBridgeFuncMappings) as Map).cast<String, Map>().map((key, value) =>
        MapEntry(int.parse(key), value.cast<String, int>()));

    constantPool.addAll((json.decode(encodedConstantPool) as List).cast());

    runtimeTypes = [for (final s in (json.decode(encodedRuntimeTypes) as List)) RuntimeTypeSet.fromJson(s as List)];

    for (final ulb in _unloadedBrFunc) {
      final libIndex = _bridgeLibraryMappings[ulb.library]!;
      _bridgeFunctions[bridgeFuncMappings[libIndex]![ulb.name]!] = ulb.func;
    }

    while (_offset < _dbc.lengthInBytes) {
      final opId = _dbc.getUint8(_offset);
      _offset++;
      pr.add(ops[opId](this));
    }
  }

  void registerBridgeClass(String library, String name, $Bridge cls) {
    _unloadedBrClass.add(_UnloadedBridgeClass(library, name, cls));
  }

  var _bridgeLibraryIdx = -2;
  var _bridgeLibraryMappings = <String, int>{};
  var _bridgeFunctions = <$Function>[];
  var _bridgeGlobals = <int, Map<String, $BridgeField>>{};
  final _unloadedBrClass = <_UnloadedBridgeClass>[];
  final _unloadedBrFunc = <_UnloadedBridgeFunction>[];
  final constantPool = <Object>[];

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
        return [Dbc.OP_UNBOX, ...Dbc.i16b(op._reg)];
      case PushReturnValue:
        op as PushReturnValue;
        return [Dbc.OP_SETVR];
      case NumAdd:
        op as NumAdd;
        return [Dbc.OP_ADDVV, ...Dbc.i16b(op._location1), ...Dbc.i16b(op._location2)];
      case NumSub:
        op as NumSub;
        return [Dbc.OP_NUM_SUB, ...Dbc.i16b(op._location1), ...Dbc.i16b(op._location2)];
      case BoxInt:
        op as BoxInt;
        return [Dbc.OP_BOXINT, ...Dbc.i16b(op._reg)];
      case BoxDouble:
        op as BoxDouble;
        return [Dbc.OP_BOXDOUBLE, ...Dbc.i16b(op._reg)];
      case BoxNum:
        op as BoxNum;
        return [Dbc.OP_BOXNUM, ...Dbc.i16b(op._reg)];
      case PushArg:
        op as PushArg;
        return [Dbc.OP_PUSH_ARG, ...Dbc.i16b(op._location)];
      case JumpIfNonNull:
        op as JumpIfNonNull;
        return [Dbc.OP_JNZ, ...Dbc.i16b(op._location), ...Dbc.i32b(op._offset)];
      case JumpIfFalse:
        op as JumpIfFalse;
        return [Dbc.OP_JUMP_IF_FALSE, ...Dbc.i16b(op._location), ...Dbc.i32b(op._offset)];
      case PushConstantInt:
        op as PushConstantInt;
        return [Dbc.OP_SETVC, ...Dbc.i32b(op._value)];
      case PushScope:
        op as PushScope;
        return [Dbc.OP_PUSHSCOPE, ...Dbc.i32b(op.sourceFile), ...Dbc.i32b(op.sourceOffset), ...Dbc.istr(op.frName)];
      case PopScope:
        op as PopScope;
        return [Dbc.OP_POPSCOPE];
      case CopyValue:
        op as CopyValue;
        return [Dbc.OP_SETVV, ...Dbc.i16b(op._to), ...Dbc.i16b(op._from)];
      case SetReturnValue:
        op as SetReturnValue;
        return [Dbc.OP_SETRV, ...Dbc.i16b(op._location)];
      case Return:
        op as Return;
        return [Dbc.OP_RETURN, ...Dbc.i16b(op._location)];
      case Pop:
        op as Pop;
        return [Dbc.OP_POP, op._amount];
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
      case NumLt:
        op as NumLt;
        return [Dbc.OP_NUM_LT, ...Dbc.i16b(op._location1), ...Dbc.i16b(op._location2)];
      case NumLtEq:
        op as NumLtEq;
        return [Dbc.OP_NUM_LT_EQ, ...Dbc.i16b(op._location1), ...Dbc.i16b(op._location2)];
      case PushSuper:
        op as PushSuper;
        return [Dbc.OP_PUSH_SUPER, ...Dbc.i16b(op._objectOffset)];
      case BridgeInstantiate:
        op as BridgeInstantiate;
        return [
          Dbc.OP_BRIDGE_INSTANTIATE,
          ...Dbc.i16b(op._subclass),
          ...Dbc.i32b(op._constructor)
        ];
      case PushBridgeSuperShim:
        op as PushBridgeSuperShim;
        return [Dbc.OP_PUSH_SUPER_SHIM];
      case ParentBridgeSuperShim:
        op as ParentBridgeSuperShim;
        return [Dbc.OP_PARENT_SUPER_SHIM, ...Dbc.i16b(op._shimOffset), ...Dbc.i16b(op._bridgeOffset)];
      case PushList:
        op as PushList;
        return [Dbc.OP_PUSH_LIST];
      case ListAppend:
        op as ListAppend;
        return [Dbc.OP_LIST_APPEND, ...Dbc.i16b(op._reg), ...Dbc.i16b(op._value)];
      case IndexList:
        op as IndexList;
        return [Dbc.OP_INDEX_LIST, ...Dbc.i16b(op._position), ...Dbc.i32b(op._index)];
      case PushIterableLength:
        op as PushIterableLength;
        return [Dbc.OP_ITER_LENGTH, ...Dbc.i16b(op._position)];
      case ListSetIndexed:
        op as ListSetIndexed;
        return [Dbc.OP_LIST_SETINDEXED, ...Dbc.i16b(op._position), ...Dbc.i32b(op._index), ...Dbc.i16b(op._value)];
      case BoxString:
        op as BoxString;
        return [Dbc.OP_BOXSTRING, ...Dbc.i16b(op._reg)];
      case BoxList:
        op as BoxList;
        return [Dbc.OP_BOXLIST, ...Dbc.i16b(op._reg)];
      case PushCaptureScope:
        op as PushCaptureScope;
        return [Dbc.OP_CAPTURE_SCOPE];
      case PushConstant:
        op as PushConstant;
        return [Dbc.OP_PUSH_CONST, ...Dbc.i32b(op._const)];
      case PushFunctionPtr:
        op as PushFunctionPtr;
        return [Dbc.OP_PUSH_FUNCTION_PTR, ...Dbc.i32b(op._offset)];
      default:
        throw ArgumentError('Not a valid op $op');
    }
  }

  static int _id = 0;
  final int id;

  static final bridgeData = Expando<BridgeData>();
  late ByteData _dbc;
  final stack = <List<Object?>>[];
  List<Object?> frame = [];
  var args = <Object?>[];
  final pr = <DbcOp>[];
  Object? returnValue;
  final frameOffsetStack = <int>[0];
  final callStack = <int>[0];
  var declarations = <int, Map<String, int>>{};
  final declaredClasses = <int, Map<String, EvalClass>>{};
  late final List<String> typeNames;
  late final List<Set<int>> typeTypes;
  late final List<RuntimeTypeSet> runtimeTypes;

  int frameOffset = 0;
  int _offset = 0;
  int _prOffset = 0;

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
      return returnValue;
    } catch (e, stk) {
      throw RuntimeException(this, e, stk);
    }
  }

  /// Run the VM in a 'sub-state' of a parent invocation of the VM. Used for bridge calls.
  /// For performance reasons, avoid making excessive use of this pattern, despite its convenience
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

  @pragma('vm:always-inline')
  int _readInt32() {
    final i = _dbc.getInt32(_offset);
    _offset += 4;
    return i;
  }

  @pragma('vm:always-inline')
  int _readUint8() {
    final i = _dbc.getUint8(_offset);
    _offset += 1;
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

class RuntimeException implements Exception {
  const RuntimeException(this.runtime, this.caughtException, this.stackTrace);

  final Runtime runtime;
  final Object caughtException;
  final StackTrace stackTrace;

  @override
  String toString() {
    var prStr = '';
    final maxIdx = min(runtime.pr.length - 1, runtime._prOffset + 3);

    for (var i = max(0, runtime._prOffset - 7); i < maxIdx; i++) {
      prStr += '$i: ${runtime.pr[i]}';
      if (i == runtime._prOffset - 1) {
        prStr += '  <<< EXCEPTION';
      }
      prStr += '\n';
    }

    return 'dart_eval runtime exception: $caughtException\n'
        '${stackTrace.toString().split("\n").take(2).join('\n')}\n\n'
        'RUNTIME STATE\n'
        '=============\n'
        'Program offset: ${runtime._prOffset - 1}\n'
        'Stack sample: ${runtime.stack.last.take(10).toList()}\n'
        'Call stack: ${runtime.callStack}\n'
        'TRACE:\n$prStr';
  }
}
