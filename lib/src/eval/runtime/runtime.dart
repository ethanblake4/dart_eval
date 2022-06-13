import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/continuation.dart';
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
  final EvalCallableFunc func;
}

class Runtime {
  Runtime(this._evc)
      : id = _id++,
        _fromEvc = true;

  static $Value? _fn(Runtime rt, $Value? target, List<$Value?> args) {
    throw UnimplementedError(
        'Tried to invoke a nonexistent external function; did you forget to add it with registerBridgeFunc()?');
  }

  static const _defaultFunction = $Function(_fn);

  Runtime.ofProgram(Program program)
      : id = _id++,
        _fromEvc = false,
        typeTypes = program.typeTypes,
        typeNames = program.typeNames,
        runtimeTypes = program.runtimeTypes,
        _bridgeLibraryMappings = program.bridgeLibraryMappings,
        bridgeFuncMappings = program.bridgeFunctionMappings,
        globalInitializers = program.globalInitializers {
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

  void _load() {
    final encodedToplevelDecs = _readString();
    final encodedInstanceDecs = _readString();
    final encodedTypeNames = _readString();
    final encodedTypeTypes = _readString();
    final encodedBridgeLibraryMappings = _readString();
    final encodedBridgeFuncMappings = _readString();
    final encodedConstantPool = _readString();
    final encodedRuntimeTypes = _readString();
    final encodedGlobalInitializers = _readString();

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

    bridgeFuncMappings = (json.decode(encodedBridgeFuncMappings) as Map)
        .cast<String, Map>()
        .map((key, value) => MapEntry(int.parse(key), value.cast<String, int>()));

    constantPool.addAll((json.decode(encodedConstantPool) as List).cast());

    runtimeTypes = [for (final s in (json.decode(encodedRuntimeTypes) as List)) RuntimeTypeSet.fromJson(s as List)];

    globalInitializers = [for (final i in json.decode(encodedGlobalInitializers) as List) i as int];

    _setupBridging();

    while (_offset < _evc.lengthInBytes) {
      final opId = _evc.getUint8(_offset);
      _offset++;
      pr.add(ops[opId](this));
    }
  }

  void _setupBridging() {
    for (final ulb in _unloadedBrFunc) {
      final libIndex = _bridgeLibraryMappings[ulb.library]!;
      _bridgeFunctions[bridgeFuncMappings[libIndex]![ulb.name] ?? (throw ArgumentError('Could not find ${ulb.name}'))] =
          ulb.func;
    }
  }

  void registerBridgeClass(String library, String name, $Bridge cls) {
    _unloadedBrClass.add(_UnloadedBridgeClass(library, name, cls));
  }

  void registerBridgeFunc(String library, String name, EvalCallableFunc fn, {bool isBridge = false}) {
    _unloadedBrFunc.add(_UnloadedBridgeFunction(library, isBridge ? '#$name' : name, fn));
  }

  void setup() {
    configureCoreForRuntime(this);
    configureAsyncForRuntime(this);
    if (_fromEvc) {
      _load();
    } else {
      _setupBridging();
    }
  }

  var _bridgeLibraryMappings = <String, int>{};
  final _bridgeFunctions = List<EvalCallableFunc>.filled(1000, _defaultFunction);
  final _unloadedBrClass = <_UnloadedBridgeClass>[];
  final _unloadedBrFunc = <_UnloadedBridgeFunction>[];
  final constantPool = <Object>[];
  final globals = List<Object?>.filled(4000, null);
  var globalInitializers = <int>[];

  static List<int> opcodeFrom(EvcOp op) {
    switch (op.runtimeType) {
      case JumpConstant:
        op as JumpConstant;
        return [Evc.OP_JMPC, ...Evc.i32b(op._offset)];
      case Exit:
        op as Exit;
        return [Evc.OP_EXIT, ...Evc.i16b(op._location)];
      case Unbox:
        op as Unbox;
        return [Evc.OP_UNBOX, ...Evc.i16b(op._reg)];
      case PushReturnValue:
        op as PushReturnValue;
        return [Evc.OP_SETVR];
      case NumAdd:
        op as NumAdd;
        return [Evc.OP_ADDVV, ...Evc.i16b(op._location1), ...Evc.i16b(op._location2)];
      case NumSub:
        op as NumSub;
        return [Evc.OP_NUM_SUB, ...Evc.i16b(op._location1), ...Evc.i16b(op._location2)];
      case BoxInt:
        op as BoxInt;
        return [Evc.OP_BOXINT, ...Evc.i16b(op._reg)];
      case BoxDouble:
        op as BoxDouble;
        return [Evc.OP_BOXDOUBLE, ...Evc.i16b(op._reg)];
      case BoxNum:
        op as BoxNum;
        return [Evc.OP_BOXNUM, ...Evc.i16b(op._reg)];
      case PushArg:
        op as PushArg;
        return [Evc.OP_PUSH_ARG, ...Evc.i16b(op._location)];
      case JumpIfNonNull:
        op as JumpIfNonNull;
        return [Evc.OP_JNZ, ...Evc.i16b(op._location), ...Evc.i32b(op._offset)];
      case JumpIfFalse:
        op as JumpIfFalse;
        return [Evc.OP_JUMP_IF_FALSE, ...Evc.i16b(op._location), ...Evc.i32b(op._offset)];
      case PushConstantInt:
        op as PushConstantInt;
        return [Evc.OP_SETVC, ...Evc.i32b(op._value)];
      case PushScope:
        op as PushScope;
        return [Evc.OP_PUSHSCOPE, ...Evc.i32b(op.sourceFile), ...Evc.i32b(op.sourceOffset), ...Evc.istr(op.frName)];
      case PopScope:
        op as PopScope;
        return [Evc.OP_POPSCOPE];
      case CopyValue:
        op as CopyValue;
        return [Evc.OP_SETVV, ...Evc.i16b(op._to), ...Evc.i16b(op._from)];
      case SetReturnValue:
        op as SetReturnValue;
        return [Evc.OP_SETRV, ...Evc.i16b(op._location)];
      case Return:
        op as Return;
        return [Evc.OP_RETURN, ...Evc.i16b(op._location)];
      case Pop:
        op as Pop;
        return [Evc.OP_POP, op._amount];
      case Call:
        op as Call;
        return [Evc.OP_CALL, ...Evc.i32b(op._offset)];
      case InvokeDynamic:
        op as InvokeDynamic;
        return [Evc.OP_INVOKE_DYNAMIC, ...Evc.i16b(op._location), ...Evc.istr(op._method)];
      case SetObjectProperty:
        op as SetObjectProperty;
        return [
          Evc.OP_SET_OBJECT_PROP,
          ...Evc.i16b(op._location),
          ...Evc.istr(op._property),
          ...Evc.i16b(op._valueOffset)
        ];
      case PushObjectProperty:
        op as PushObjectProperty;
        return [Evc.OP_PUSH_OBJECT_PROP, ...Evc.i16b(op._location), ...Evc.istr(op._property)];
      case PushObjectPropertyImpl:
        op as PushObjectPropertyImpl;
        return [Evc.OP_PUSH_OBJECT_PROP_IMPL, ...Evc.i16b(op._objectOffset), ...Evc.i16b(op._propertyIndex)];
      case SetObjectPropertyImpl:
        op as SetObjectPropertyImpl;
        return [
          Evc.OP_SET_OBJECT_PROP_IMPL,
          ...Evc.i16b(op._objectOffset),
          ...Evc.i16b(op._propertyIndex),
          ...Evc.i16b(op._valueOffset)
        ];
      case PushNull:
        op as PushNull;
        return [Evc.OP_PUSH_NULL];
      case CreateClass:
        op as CreateClass;
        return [
          Evc.OP_CREATE_CLASS,
          ...Evc.i32b(op._library),
          ...Evc.i16b(op._super),
          ...Evc.istr(op._name),
          ...Evc.i16b(op._valuesLen)
        ];
      case NumLt:
        op as NumLt;
        return [Evc.OP_NUM_LT, ...Evc.i16b(op._location1), ...Evc.i16b(op._location2)];
      case NumLtEq:
        op as NumLtEq;
        return [Evc.OP_NUM_LT_EQ, ...Evc.i16b(op._location1), ...Evc.i16b(op._location2)];
      case PushSuper:
        op as PushSuper;
        return [Evc.OP_PUSH_SUPER, ...Evc.i16b(op._objectOffset)];
      case BridgeInstantiate:
        op as BridgeInstantiate;
        return [Evc.OP_BRIDGE_INSTANTIATE, ...Evc.i16b(op._subclass), ...Evc.i32b(op._constructor)];
      case PushBridgeSuperShim:
        op as PushBridgeSuperShim;
        return [Evc.OP_PUSH_SUPER_SHIM];
      case ParentBridgeSuperShim:
        op as ParentBridgeSuperShim;
        return [Evc.OP_PARENT_SUPER_SHIM, ...Evc.i16b(op._shimOffset), ...Evc.i16b(op._bridgeOffset)];
      case PushList:
        op as PushList;
        return [Evc.OP_PUSH_LIST];
      case ListAppend:
        op as ListAppend;
        return [Evc.OP_LIST_APPEND, ...Evc.i16b(op._reg), ...Evc.i16b(op._value)];
      case IndexList:
        op as IndexList;
        return [Evc.OP_INDEX_LIST, ...Evc.i16b(op._position), ...Evc.i32b(op._index)];
      case PushIterableLength:
        op as PushIterableLength;
        return [Evc.OP_ITER_LENGTH, ...Evc.i16b(op._position)];
      case ListSetIndexed:
        op as ListSetIndexed;
        return [Evc.OP_LIST_SETINDEXED, ...Evc.i16b(op._position), ...Evc.i32b(op._index), ...Evc.i16b(op._value)];
      case BoxString:
        op as BoxString;
        return [Evc.OP_BOXSTRING, ...Evc.i16b(op._reg)];
      case BoxList:
        op as BoxList;
        return [Evc.OP_BOXLIST, ...Evc.i16b(op._reg)];
      case BoxMap:
        op as BoxMap;
        return [Evc.OP_BOXMAP, ...Evc.i16b(op._reg)];
      case BoxBool:
        op as BoxBool;
        return [Evc.OP_BOXBOOL, ...Evc.i16b(op._reg)];
      case PushCaptureScope:
        op as PushCaptureScope;
        return [Evc.OP_CAPTURE_SCOPE];
      case PushConstant:
        op as PushConstant;
        return [Evc.OP_PUSH_CONST, ...Evc.i32b(op._const)];
      case PushFunctionPtr:
        op as PushFunctionPtr;
        return [Evc.OP_PUSH_FUNCTION_PTR, ...Evc.i32b(op._offset)];
      case InvokeExternal:
        op as InvokeExternal;
        return [Evc.OP_INVOKE_EXTERNAL, ...Evc.i32b(op._function)];
      case Await:
        op as Await;
        return [Evc.OP_AWAIT, ...Evc.i16b(op._completerOffset), ...Evc.i16b(op._futureOffset)];
      case PushMap:
        op as PushMap;
        return [Evc.OP_PUSH_MAP];
      case MapSet:
        op as MapSet;
        return [Evc.OP_MAP_SET, ...Evc.i16b(op._map), ...Evc.i16b(op._index), ...Evc.i16b(op._value)];
      case IndexMap:
        op as IndexMap;
        return [Evc.OP_INDEX_MAP, ...Evc.i16b(op._map), ...Evc.i16b(op._index)];
      case PushConstantDouble:
        op as PushConstantDouble;
        return [Evc.OP_PUSH_DOUBLE, ...Evc.f32b(op._value)];
      case SetGlobal:
        op as SetGlobal;
        return [Evc.OP_SET_GLOBAL, ...Evc.i32b(op._index), ...Evc.i16b(op._value)];
      case LoadGlobal:
        op as LoadGlobal;
        return [Evc.OP_LOAD_GLOBAL, ...Evc.i32b(op._index)];
      case PushTrue:
        op as PushTrue;
        return [Evc.OP_PUSH_TRUE];
      case LogicalNot:
        op as LogicalNot;
        return [Evc.OP_LOGICAL_NOT, ...Evc.i16b(op._index)];
      default:
        throw ArgumentError('Not a valid op $op');
    }
  }

  static int _id = 0;
  final int id;

  static final bridgeData = Expando<BridgeData>();
  late ByteData _evc;
  final bool _fromEvc;
  final stack = <List<Object?>>[];
  List<Object?> frame = [];
  var args = <Object?>[];
  final pr = <EvcOp>[];
  Object? returnValue;
  final frameOffsetStack = <int>[0];
  final callStack = <int>[0];
  var declarations = <int, Map<String, int>>{};
  final declaredClasses = <int, Map<String, EvalClass>>{};
  late final List<String> typeNames;
  late final List<Set<int>> typeTypes;
  late final List<RuntimeTypeSet> runtimeTypes;
  late final Map<int, Map<String, int>> bridgeFuncMappings;

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

  dynamic executeLib(String library, String name, [List? args]) {
    if (args != null) {
      this.args = args;
    }
    // ignore: deprecated_member_use_from_same_package
    return executeNamed(_bridgeLibraryMappings[library]!, name);
  }

  @Deprecated('Use executeLib() instead')
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
    } on RuntimeException catch (_) {
      rethrow;
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
    } on RuntimeException catch (_) {
      rethrow;
    } catch (e, stk) {
      throw RuntimeException(this, e, stk);
    }
  }

  @pragma('vm:always-inline')
  int _readInt32() {
    final i = _evc.getInt32(_offset);
    _offset += 4;
    return i;
  }

  @pragma('vm:always-inline')
  double _readFloat32() {
    final i = _evc.getFloat32(_offset);
    _offset += 4;
    return i;
  }

  @pragma('vm:always-inline')
  int _readUint8() {
    final i = _evc.getUint8(_offset);
    _offset += 1;
    return i;
  }

  @pragma('vm:always-inline')
  int _readInt16() {
    final i = _evc.getInt16(_offset);
    _offset += 2;
    return i;
  }

  @pragma('vm:always-inline')
  String _readString() {
    final len = _evc.getInt32(_offset);
    _offset += 4;
    final codeUnits = List.filled(len, 0);
    for (var i = 0; i < len; i++) {
      codeUnits[i] = _evc.getUint8(_offset + i);
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
        '${stackTrace.toString().split("\n").take(3).join('\n')}\n\n'
        'RUNTIME STATE\n'
        '=============\n'
        'Program offset: ${runtime._prOffset - 1}\n'
        'Stack sample: ${runtime.stack.last.take(10).toList()}\n'
        'Call stack: ${runtime.callStack}\n'
        'TRACE:\n$prStr';
  }
}
