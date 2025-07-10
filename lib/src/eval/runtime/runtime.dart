import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/runtime/class.dart';
import 'package:dart_eval/src/eval/runtime/function.dart';
import 'package:dart_eval/src/eval/runtime/record.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io.dart';
import 'package:dart_eval/src/eval/shared/stdlib/math.dart';
import 'package:dart_eval/src/eval/shared/stdlib/typed_data.dart';
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

typedef TypeAutowrapper = $Value? Function(dynamic);

class ScopeFrame {
  const ScopeFrame(this.stackOffset, this.scopeStackOffset,
      [this.entrypoint = false]);

  final int stackOffset;
  final int scopeStackOffset;
  final bool entrypoint;

  @override
  String toString() {
    return '$stackOffset (scope $scopeStackOffset)';
  }
}

class _UnloadedBridgeFunction {
  const _UnloadedBridgeFunction(this.library, this.name, this.func);

  final String library;
  final String name;
  final EvalCallableFunc func;
}

class _UnloadedEnumValues {
  const _UnloadedEnumValues(this.library, this.name, this.values);
  final String library;
  final String name;
  final Map<String, $Value> values;
}

/// A [Runtime] is a virtual machine instance that executes EVC bytecode.
///
/// It can be created from a [Program] or from EVC bytecode, using the
/// [Runtime.ofProgram] constructor or the [Runtime] constructor respectively.
/// When possible, the [Runtime.ofProgram] constructor should be preferred as it
/// avoids overhead of loading bytecode.
///
/// After creating a Runtime, register bridge functions using
/// [registerBridgeFunc] or [addPlugin].
///
/// Once setup is complete, call [executeLib] to execute a function in the
/// program.
///
/// By default, a Runtime has no permissions to access resources like the file
/// system or network. Permissions can be granted using [grant] and revoked
/// using [revoke]. Clients of the permission system such as bridge classes
/// should check permissions using [checkPermission] or [assertPermission].
///
class Runtime {
  /// The current runtime version code
  static const int versionCode = 79;

  /// Construct a runtime from EVC bytecode. When possible, use the
  /// [Runtime.ofProgram] constructor instead to reduce loading time.
  Runtime(this._evc)
      : id = _id++,
        _fromEvc = true;

  static $Value? _fn(Runtime rt, $Value? target, List<$Value?> args) {
    throw UnimplementedError(
        'Tried to invoke a nonexistent external function; did you forget to add it with registerBridgeFunc()?');
  }

  static const _defaultFunction = $Function(_fn);

  /// Create a [Runtime] from a [Program]. This constructor should be preferred
  /// where possible as it avoids overhead of loading bytecode.
  Runtime.ofProgram(Program program)
      : id = _id++,
        _fromEvc = false,
        typeTypes = program.typeTypes,
        //typeNames = program.typeNames,
        typeIds = program.typeIds,
        runtimeTypes = program.runtimeTypes,
        _bridgeLibraryMappings = program.bridgeLibraryMappings,
        bridgeFuncMappings = program.bridgeFunctionMappings,
        bridgeEnumMappings = program.enumMappings,
        globalInitializers = program.globalInitializers,
        overrideMap = program.overrideMap {
    declarations = program.topLevelDeclarations;
    constantPool.addAll(program.constantPool);
    program.instanceDeclarations.forEach((file, $class) {
      final decls = <String, EvalClass>{};

      $class.forEach((name, declarations) {
        final getters = (declarations[0] as Map).cast<String, int>();
        final setters = (declarations[1] as Map).cast<String, int>();
        final methods = (declarations[2] as Map).cast<String, int>();
        final type = (declarations[3] as int);

        final cls =
            EvalClass(type, null, [], {...getters}, {...setters}, {...methods});
        decls[name] = cls;
      });

      declaredClasses[file] = decls;
    });

    pr.addAll(program.ops);
  }

  void _load() {
    final m1 = _readUint8(),
        m2 = _readUint8(),
        m3 = _readUint8(),
        m4 = _readUint8();
    final version = _readInt32();
    if (m1 != 0x45 || m2 != 0x56 || m3 != 0x43 || m4 != 0x00) {
      throw Exception(
          'dart_eval runtime error: Not an EVC file or bytecode version older than 064');
    }
    if (version != versionCode) {
      var vstr = version.toString();
      if (vstr.length < 3) {
        vstr = '0$vstr';
      }
      throw Exception(
          'dart_eval runtime error: EVC bytecode is version $vstr, but runtime supports version $versionCode.\n'
          'Try using the same version of dart_eval for compiling as the version in your application.');
    }
    final encodedToplevelDecs = _readString();
    final encodedInstanceDecs = _readString();
    //final encodedTypeNames = _readString();
    final encodedTypeTypes = _readString();
    final encodedTypeIds = _readString();
    final encodedBridgeLibraryMappings = _readString();
    final encodedBridgeFuncMappings = _readString();
    final encodedConstantPool = _readString();
    final encodedRuntimeTypes = _readString();
    final encodedGlobalInitializers = _readString();
    final encodedBridgeEnumMappings = _readString();
    final encodedOverrideMap = _readString();

    declarations = (json.decode(encodedToplevelDecs).map((k, v) =>
            MapEntry(int.parse(k), (v as Map).cast<String, int>())) as Map)
        .cast<int, Map<String, int>>();

    final classes = (json.decode(encodedInstanceDecs).map((k, v) =>
            MapEntry(int.parse(k), (v as Map).cast<String, List>())) as Map)
        .cast<int, Map<String, List>>();

    bridgeEnumMappings = (json.decode(encodedBridgeEnumMappings) as Map).map(
        (k, v) => MapEntry(
            int.parse(k),
            (v as Map)
                .map((key, value) =>
                    MapEntry(key, (value as Map).cast<String, int>()))
                .cast<String, Map<String, int>>()));

    classes.forEach((file, $class) {
      declaredClasses[file] = {
        for (final decl in $class.entries)
          decl.key: EvalClass.fromJson(decl.value)
      };
    });

    typeTypes = [
      for (final s in (json.decode(encodedTypeTypes) as List))
        (s as List).cast<int>().toSet()
    ];

    typeIds = (json.decode(encodedTypeIds) as Map).cast<String, Map>().map(
        (key, value) => MapEntry(int.parse(key), value.cast<String, int>()));

    _bridgeLibraryMappings =
        (json.decode(encodedBridgeLibraryMappings) as Map).cast();

    bridgeFuncMappings = (json.decode(encodedBridgeFuncMappings) as Map)
        .cast<String, Map>()
        .map((key, value) =>
            MapEntry(int.parse(key), value.cast<String, int>()));

    constantPool.addAll((json.decode(encodedConstantPool) as List).cast());

    runtimeTypes = [
      for (final s in (json.decode(encodedRuntimeTypes) as List))
        RuntimeTypeSet.fromJson(s as List)
    ];

    globalInitializers = [
      for (final i in json.decode(encodedGlobalInitializers) as List) i as int
    ];

    overrideMap = (json.decode(encodedOverrideMap) as Map)
        .cast<String, List>()
        .map((key, value) => MapEntry(key, OverrideSpec(value[0], value[1])));

    _setupBridging();

    while (_offset < _evc.lengthInBytes) {
      final opId = _evc.getUint8(_offset);
      _offset++;
      pr.add(ops[opId](this));
    }
  }

  void _setupBridging() {
    for (final ulb in _unloadedBrFunc) {
      final libIndex = _bridgeLibraryMappings[ulb.library];
      if (libIndex == null || bridgeFuncMappings[libIndex]?[ulb.name] == null) {
        continue;
      }
      _bridgeFunctions[bridgeFuncMappings[libIndex]![ulb.name]!] = ulb.func;
    }

    for (final ule in _unloadedEnumValues) {
      final libIndex = _bridgeLibraryMappings[ule.library]!;
      final mapping = bridgeEnumMappings[libIndex]![ule.name]!;
      for (final value in ule.values.entries) {
        globals[mapping[value.key]!] = value.value;
      }
    }
  }

  /// Add a plugin to the runtime, which can register bridge functions.
  void addPlugin(EvalPlugin plugin) {
    _plugins.add(plugin);
  }

  /// Register a bridged runtime top-level/static function or class constructor.
  void registerBridgeFunc(String library, String name, EvalCallableFunc fn,
      {bool isBridge = false}) {
    _unloadedBrFunc
        .add(_UnloadedBridgeFunction(library, isBridge ? '#$name' : name, fn));
  }

  /// Register bridged runtime enum values.
  void registerBridgeEnumValues(
      String library, String name, Map<String, $Value> values) {
    _unloadedEnumValues.add(_UnloadedEnumValues(library, name, values));
  }

  /// No longer needed, runtime is automatically setup by [executeLib]
  @Deprecated("setup() is no longer required")
  void setup() => _setup();

  void _setup() {
    if (_didSetup) {
      return;
    }
    for (final plugin in _plugins) {
      plugin.configureForRuntime(this);
    }
    if (_fromEvc) {
      _load();
    } else {
      _setupBridging();
    }
    _didSetup = true;
  }

  /// Sets this runtime as the global runtime, and loads its overrides globally.
  void loadGlobalOverrides() {
    _setup();
    globalRuntime = this;
    runtimeOverrides = overrideMap;
  }

  /// Grant a permission to the runtime.
  void grant(Permission permission) {
    for (final domain in permission.domains) {
      _permissions.putIfAbsent(domain, () => []).add(permission);
    }
  }

  /// Revoke a permission from the runtime.
  void revoke(Permission permission) {
    for (final domain in permission.domains) {
      _permissions[domain]?.remove(permission);
    }
  }

  /// Check if a permission is granted.
  bool checkPermission(String domain, [Object? data]) {
    return _permissions[domain]?.any((element) => element.match(data)) ?? false;
  }

  /// Check if a permission is granted, otherwise throw an exception.
  void assertPermission(String domain, [Object? data]) {
    if (!checkPermission(domain, data)) {
      throw Exception(
          "Permission '$domain' denied${data == null ? '' : " for '$data'"}.\n"
          "To grant permissions, use Runtime.grant() or add the permission "
          "to the permissions array of your HotSwapLoader, EvalWidget, "
          "or eval() function.");
    }
  }

  /// Attempt to wrap a Dart primitive value into a [$Value].
  /// This is needed because Dart primitives cannot be implemented or extended,
  /// so creating a [bimodal wrapper](https://github.com/ethanblake4/dart_eval/wiki/Wrappers#bimodal-wrappers)
  /// is impossible.
  $Value? wrapPrimitive(dynamic value) {
    if (value is int) {
      return $int(value);
    } else if (value is double) {
      return $double(value);
    } else if (value is String) {
      return $String(value);
    } else if (value is bool) {
      return $bool(value);
    } else if (value == null) {
      return $null();
    }
    return null;
  }

  /// Add a type autowrapper to the runtime. Type autowrappers are used to
  /// automatically wrap values of a certain type into a [$Value]. They should
  /// be used sparingly due to their high performance overhead.
  ///
  /// Type autowrappers should implement the code pattern:
  /// ```dart
  /// $Value? myTypeAutowrapper(dynamic value) {
  ///   if (value is MyType) {
  ///     return $MyType.wrap(value);
  ///   } else if (value is MyOtherType) {
  ///     return $MyOtherType.wrap(value);
  ///   }
  ///   return null;
  /// }
  /// ```
  void addTypeAutowrapper(TypeAutowrapper wrapper) {
    _typeAutowrappers.add(wrapper);
  }

  /// Attempt to wrap a Dart value into a [$Value], and throw if unsuccessful.
  $Value wrap(dynamic value, {bool recursive = false}) {
    if (value is $Value) {
      return value;
    }
    if (value is List) {
      return recursive
          ? $List.wrap(value.map((v) => wrap(v, recursive: true)).toList())
          : $List.wrap(value);
    } else if (value is Map) {
      return recursive
          ? $Map.wrap(value.map((key, value) => MapEntry(
              wrap(key, recursive: true), wrap(value, recursive: true))))
          : $Map.wrap(value);
    }
    for (final wrapper in _typeAutowrappers) {
      final wrapped = wrapper(value);
      if (wrapped != null) {
        return wrapped;
      }
    }
    return wrapPrimitive(value) ??
        (throw Exception('Cannot wrap $value (${value.runtimeType}).'
            'If the type is known explicitly, use \${TypeName}.wrap(value); '
            'otherwise, try adding a type autowrapper with '
            'runtime.addTypeAutowrapper().'));
  }

  @Deprecated("Use runtime.wrap() with recursive:true instead")
  $Value wrapRecursive(dynamic value) => wrap(value, recursive: true);

  /// Attempt to wrap a Dart value into a [$Value], falling back to wrapping
  /// in an [$Object]
  $Value wrapAlways(dynamic value, {bool recursive = false}) {
    try {
      return wrap(value, recursive: recursive);
    } catch (e) {
      return $Object(value);
    }
  }

  String valueToString($Value? value) {
    if (value is $Instance) {
      final toString = value.$getProperty(this, 'toString');
      if (toString != null) {
        final result = (toString as EvalCallable).call(this, value, [value]);
        return result?.$value;
      }
    }
    return (value?.$value).toString();
  }

  var _didSetup = false;
  var _bridgeLibraryMappings = <String, int>{};
  final _bridgeFunctions =
      List<EvalCallableFunc>.filled(1000, _defaultFunction.call);
  final _unloadedBrFunc = <_UnloadedBridgeFunction>[];
  final _unloadedEnumValues = <_UnloadedEnumValues>[];
  final _plugins = <EvalPlugin>[
    DartAsyncPlugin(),
    DartCollectionPlugin(),
    DartConvertPlugin(),
    DartCorePlugin(),
    DartIoPlugin(),
    DartMathPlugin(),
    DartTypedDataPlugin(),
  ];
  final constantPool = <Object>[];
  final globals = List<Object?>.filled(20000, null);
  var globalInitializers = <int>[];
  var overrideMap = <String, OverrideSpec>{};
  final _permissions = <String, List<Permission>>{};
  final _typeAutowrappers = <TypeAutowrapper>[];

  /// Virtual current working directory for filesystem operations
  String? _currentDir;

  /// Get the current virtual working directory
  String? get currentDir => _currentDir;

  /// Set the current virtual working directory
  set currentDir(String? path) {
    if (path == null) {
      _currentDir = null;
    } else if (path.startsWith('/')) {
      _currentDir = path;
    } else {
      // If relative, resolve against current directory
      _currentDir = _currentDir != null ? resolvePath(path, _currentDir) : path;
    }
  }

  /// Resolve a path against a given current working directory
  String resolvePath(String path, [String? workingDir]) {
    if (path.startsWith('/') || workingDir == null) {
      // Already absolute or no working directory
      return path;
    }
    // Relative path - resolve against workingDir
    return _normalizePath('$workingDir/$path');
  }

  /// Normalize a path by resolving . and .. components
  String _normalizePath(String path) {
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final normalizedParts = <String>[];

    for (final part in parts) {
      if (part == '.') {
        // Skip current directory references
        continue;
      } else if (part == '..') {
        // Go up one directory if possible
        if (normalizedParts.isNotEmpty) {
          normalizedParts.removeLast();
        }
      } else {
        normalizedParts.add(part);
      }
    }

    return '/${normalizedParts.join('/')}';
  }

  /// Write an [EvcOp] bytecode to a list of bytes.
  static List<int> opcodeFrom(EvcOp op) {
    switch (op) {
      case JumpConstant op:
        return [Evc.OP_JMPC, ...Evc.i32b(op._offset)];
      case Exit op:
        return [Evc.OP_EXIT, ...Evc.i16b(op._location)];
      case Unbox op:
        return [Evc.OP_UNBOX, ...Evc.i16b(op._reg)];
      case PushReturnValue _:
        return [Evc.OP_SETVR];
      case NumAdd op:
        return [
          Evc.OP_ADDVV,
          ...Evc.i16b(op._location1),
          ...Evc.i16b(op._location2)
        ];
      case NumSub op:
        return [
          Evc.OP_NUM_SUB,
          ...Evc.i16b(op._location1),
          ...Evc.i16b(op._location2)
        ];
      case BoxInt op:
        return [Evc.OP_BOXINT, ...Evc.i16b(op._reg)];
      case BoxDouble op:
        return [Evc.OP_BOXDOUBLE, ...Evc.i16b(op._reg)];
      case BoxNum op:
        return [Evc.OP_BOXNUM, ...Evc.i16b(op._reg)];
      case PushArg op:
        return [Evc.OP_PUSH_ARG, ...Evc.i16b(op._location)];
      case JumpIfNonNull op:
        return [Evc.OP_JNZ, ...Evc.i16b(op._location), ...Evc.i32b(op._offset)];
      case JumpIfFalse op:
        return [
          Evc.OP_JUMP_IF_FALSE,
          ...Evc.i16b(op._location),
          ...Evc.i32b(op._offset)
        ];
      case PushConstantInt op:
        return [Evc.OP_SETVC, ...Evc.i32b(op._value)];
      case PushScope op:
        return [
          Evc.OP_PUSHSCOPE,
          ...Evc.i32b(op.sourceFile),
          ...Evc.i32b(op.sourceOffset),
          ...Evc.istr(op.frName)
        ];
      case PopScope _:
        return [Evc.OP_POPSCOPE];
      case CopyValue op:
        return [Evc.OP_SETVV, ...Evc.i16b(op._to), ...Evc.i16b(op._from)];
      case SetReturnValue op:
        return [Evc.OP_SETRV, ...Evc.i16b(op._location)];
      case Return op:
        return [Evc.OP_RETURN, ...Evc.i16b(op._location)];
      case ReturnAsync op:
        return [
          Evc.OP_RETURN_ASYNC,
          ...Evc.i16b(op._location),
          ...Evc.i16b(op._completerOffset)
        ];
      case Pop op:
        return [Evc.OP_POP, op._amount];
      case Call op:
        return [Evc.OP_CALL, ...Evc.i32b(op._offset)];
      case InvokeDynamic op:
        return [
          Evc.OP_INVOKE_DYNAMIC,
          ...Evc.i16b(op._location),
          ...Evc.i32b(op._methodIdx)
        ];
      case SetObjectProperty op:
        return [
          Evc.OP_SET_OBJECT_PROP,
          ...Evc.i16b(op._location),
          ...Evc.istr(op._property),
          ...Evc.i16b(op._valueOffset)
        ];
      case PushObjectProperty op:
        return [
          Evc.OP_PUSH_OBJECT_PROP,
          ...Evc.i16b(op._location),
          ...Evc.i32b(op._propertyIdx)
        ];
      case PushObjectPropertyImpl op:
        return [
          Evc.OP_PUSH_OBJECT_PROP_IMPL,
          ...Evc.i16b(op.objectOffset),
          ...Evc.i16b(op._propertyIndex)
        ];
      case SetObjectPropertyImpl op:
        return [
          Evc.OP_SET_OBJECT_PROP_IMPL,
          ...Evc.i16b(op._objectOffset),
          ...Evc.i16b(op._propertyIndex),
          ...Evc.i16b(op._valueOffset)
        ];
      case PushNull _:
        return [Evc.OP_PUSH_NULL];
      case CreateClass op:
        return [
          Evc.OP_CREATE_CLASS,
          ...Evc.i32b(op._library),
          ...Evc.i16b(op._super),
          ...Evc.istr(op._name),
          ...Evc.i16b(op._valuesLen)
        ];

      case NumLt op:
        return [
          Evc.OP_NUM_LT,
          ...Evc.i16b(op._location1),
          ...Evc.i16b(op._location2)
        ];
      case NumLtEq op:
        return [
          Evc.OP_NUM_LT_EQ,
          ...Evc.i16b(op._location1),
          ...Evc.i16b(op._location2)
        ];
      case PushSuper op:
        return [Evc.OP_PUSH_SUPER, ...Evc.i16b(op._objectOffset)];
      case BridgeInstantiate op:
        return [
          Evc.OP_BRIDGE_INSTANTIATE,
          ...Evc.i16b(op._subclass),
          ...Evc.i32b(op._constructor)
        ];
      case PushBridgeSuperShim _:
        return [Evc.OP_PUSH_SUPER_SHIM];
      case ParentBridgeSuperShim op:
        return [
          Evc.OP_PARENT_SUPER_SHIM,
          ...Evc.i16b(op._shimOffset),
          ...Evc.i16b(op._bridgeOffset)
        ];
      case PushList _:
        return [Evc.OP_PUSH_LIST];
      case ListAppend op:
        return [
          Evc.OP_LIST_APPEND,
          ...Evc.i16b(op._reg),
          ...Evc.i16b(op._value)
        ];
      case IndexList op:
        return [
          Evc.OP_INDEX_LIST,
          ...Evc.i16b(op._position),
          ...Evc.i32b(op._index)
        ];
      case PushIterableLength op:
        return [Evc.OP_ITER_LENGTH, ...Evc.i16b(op._position)];
      case ListSetIndexed op:
        return [
          Evc.OP_LIST_SETINDEXED,
          ...Evc.i16b(op._position),
          ...Evc.i32b(op._index),
          ...Evc.i16b(op._value)
        ];
      case BoxString op:
        return [Evc.OP_BOXSTRING, ...Evc.i16b(op._reg)];
      case BoxList op:
        return [Evc.OP_BOXLIST, ...Evc.i16b(op._reg)];
      case BoxMap op:
        return [Evc.OP_BOXMAP, ...Evc.i16b(op._reg)];
      case BoxSet op:
        return [Evc.OP_BOXSET, ...Evc.i16b(op._reg)];
      case BoxBool op:
        return [Evc.OP_BOXBOOL, ...Evc.i16b(op._reg)];
      case BoxNull op:
        return [Evc.OP_BOX_NULL, ...Evc.i16b(op._reg)];
      case PushCaptureScope _:
        return [Evc.OP_CAPTURE_SCOPE];
      case PushConstant op:
        return [Evc.OP_PUSH_CONST, ...Evc.i32b(op._const)];
      case PushFunctionPtr op:
        return [Evc.OP_PUSH_FUNCTION_PTR, ...Evc.i32b(op._offset)];
      case InvokeExternal op:
        return [Evc.OP_INVOKE_EXTERNAL, ...Evc.i32b(op._function)];
      case Await op:
        return [
          Evc.OP_AWAIT,
          ...Evc.i16b(op._completerOffset),
          ...Evc.i16b(op._futureOffset)
        ];
      case PushMap _:
        return [Evc.OP_PUSH_MAP];
      case MapSet op:
        return [
          Evc.OP_MAP_SET,
          ...Evc.i16b(op._map),
          ...Evc.i16b(op._index),
          ...Evc.i16b(op._value)
        ];
      case IndexMap op:
        return [Evc.OP_INDEX_MAP, ...Evc.i16b(op._map), ...Evc.i16b(op._index)];
      case PushSet _:
        return [Evc.OP_PUSH_SET];
      case SetAdd op:
        return [Evc.OP_SET_ADD, ...Evc.i16b(op._set), ...Evc.i16b(op._value)];
      case PushConstantDouble op:
        return [Evc.OP_PUSH_DOUBLE, ...Evc.f32b(op._value)];
      case SetGlobal op:
        return [
          Evc.OP_SET_GLOBAL,
          ...Evc.i32b(op._index),
          ...Evc.i16b(op._value)
        ];
      case LoadGlobal op:
        return [Evc.OP_LOAD_GLOBAL, ...Evc.i32b(op._index)];
      case PushTrue _:
        return [Evc.OP_PUSH_TRUE];
      case LogicalNot op:
        return [Evc.OP_LOGICAL_NOT, ...Evc.i16b(op._index)];
      case CheckEq op:
        return [
          Evc.OP_CHECK_EQ,
          ...Evc.i16b(op._value1),
          ...Evc.i16b(op._value2)
        ];
      case Try op:
        return [Evc.OP_TRY, ...Evc.i32b(op._catchOffset)];
      case Throw op:
        return [Evc.OP_THROW, ...Evc.i16b(op._location)];
      case PopCatch _:
        return [Evc.OP_POP_CATCH];
      case IsType op:
        return [
          Evc.OP_IS_TYPE,
          ...Evc.i16b(op._objectOffset),
          ...Evc.i32b(op._type),
          op._not ? 1 : 0
        ];
      case Assert op:
        return [
          Evc.OP_ASSERT,
          ...Evc.i16b(op._valueOffset),
          ...Evc.i16b(op._exceptionOffset)
        ];
      case PushFinally op:
        return [Evc.OP_PUSH_FINALLY, ...Evc.i32b(op._tryOffset)];
      case PushReturnFromCatch _:
        return [Evc.OP_PUSH_RETURN_FROM_CATCH];
      case MaybeBoxNull op:
        return [Evc.OP_MAYBE_BOX_NULL, ...Evc.i16b(op._reg)];
      case PushRuntimeType op:
        return [Evc.OP_PUSH_RUNTIME_TYPE, ...Evc.i16b(op._value)];
      case PushConstantType op:
        return [Evc.OP_PUSH_CONSTANT_TYPE, ...Evc.i32b(op._typeId)];
      case PushRecord op:
        return [
          Evc.OP_PUSH_RECORD,
          ...Evc.i16b(op._fields),
          ...Evc.i32b(op._const),
          ...Evc.i32b(op._type)
        ];
      default:
        throw ArgumentError('Not a valid op $op');
    }
  }

  static int _id = 0;
  final int id;

  /// Stores the [BridgeData] for each bridge class in the program.
  static final bridgeData = Expando<BridgeData>();

  /// Binary EVC bytecode
  late ByteData _evc;

  /// Whether the program is loaded from binary EVC rather than from a
  /// [Program].
  final bool _fromEvc;

  /// The program's value stack
  final stack = <List<Object?>>[];

  /// Scope name stack
  final scopeNameStack = <String>[];

  /// The current frame (usually stack.last)
  List<Object?> frame = [];

  /// Arguments to the current function.
  var args = <Object?>[];

  /// The decoded program bytecode
  final pr = <EvcOp>[];

  /// The most recent return value
  Object? returnValue;

  bool inCatch = false;

  /// 0 = throw, 1 = return, 2 = break, 3 = continue
  int catchControlFlowOutcome = -1;

  /// The exception to be rethrown
  Object? rethrowException;

  /// Last return value from a catch block
  Object? returnFromCatch;

  /// [frameOffset]s for each stack frame
  final frameOffsetStack = <int>[0];

  /// The program's call stack. If a function returns it will pop the last
  /// element from this stack and set [_prOffset] to the popped value.
  final callStack = <int>[0];

  /// The program's catch stack. If a function throws it will pop the last
  /// element from this stack and set [_prOffset] to the popped value.
  final catchStack = <List<int>>[];

  var declarations = <int, Map<String, int>>{};
  final declaredClasses = <int, Map<String, EvalClass>>{};
  //late final List<String> typeNames;
  late final List<Set<int>> typeTypes;
  late final Map<int, Map<String, int>> typeIds;
  late final List<RuntimeTypeSet> runtimeTypes;
  late final Map<int, Map<String, int>> bridgeFuncMappings;
  late final Map<int, Map<String, Map<String, int>>> bridgeEnumMappings;

  /// Lookup a type ID from a [BridgeTypeSpec]
  int lookupType(BridgeTypeSpec spec) {
    final libIndex = _bridgeLibraryMappings[spec.library]!;
    return typeIds[libIndex]![spec.name]!;
  }

  /// Offset in the current stack frame
  int frameOffset = 0;

  /// Binary file read offset, only used when loading
  int _offset = 0;

  /// The current bytecode program offset
  int _prOffset = 0;

  /// Print the program's bytecode in a readable format
  void printOpcodes() {
    _setup();
    var i = 0;
    for (final oo in pr) {
      print('$i: $oo');
      i++;
    }
  }

  /// Execute a function in the current runtime, from a passed [library] URI
  /// and function [name], with optional [args].
  dynamic executeLib(String library, String name, [List? args]) {
    _setup();
    if (args != null) {
      this.args = args;
    }
    if (declarations[_bridgeLibraryMappings[library]] == null) {
      throw ArgumentError('Cannot find $library, maybe it wasn\'t declared as'
          ' an entrypoint?');
    }
    return execute(declarations[_bridgeLibraryMappings[library]!]![name]!);
  }

  /// Start program execution at a specific bytecode offset.
  /// Users should use [executeLib] instead.
  dynamic execute(int entrypoint) {
    _setup();
    _prOffset = entrypoint;
    try {
      callStack.add(-1);
      catchStack.add([]);
      while (true) {
        final op = pr[_prOffset++];
        op.run(this);
      }
    } on ProgramExit catch (_) {
      return returnValue;
    } on RuntimeException catch (_) {
      rethrow;
    } on WrappedException catch (e) {
      throw e.exception;
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
    catchStack.add([]);
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
    } on WrappedException catch (e) {
      throw e.exception;
    } catch (e, stk) {
      throw RuntimeException(this, e, stk);
    }
  }

  /// Throw an exception from the VM. This will unwind the stack until a
  /// catch block is found.
  void $throw(dynamic exception) {
    List<int> catchFrame;
    while (true) {
      catchFrame = catchStack.last;
      if (catchFrame.isNotEmpty) {
        break;
      }
      stack.removeLast();
      if (stack.isNotEmpty) {
        frame = stack.last;
        frameOffset = frameOffsetStack.removeLast();
      }

      catchStack.removeLast();
      if (callStack.removeLast() == -1) {
        throw exception is WrappedException
            ? exception
            : WrappedException(exception);
      }
    }
    var catchOffset = catchFrame.removeLast();
    if (catchOffset < 0) {
      rethrowException = exception;
      catchOffset = -catchOffset;
    } else {
      inCatch = true;
    }
    frameOffset = frameOffsetStack.last;
    returnValue =
        exception is WrappedException ? exception.exception : exception;
    _prOffset = catchOffset;
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
      identical(this, other) ||
      other is Runtime && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// An internal exception thrown while executing code in a [Runtime].
class RuntimeException implements Exception {
  const RuntimeException(this.runtime, this.caughtException, this.stackTrace);

  /// The runtime that threw the exception.
  final Runtime runtime;

  /// The exception that was thrown.
  final Object caughtException;

  /// The stack trace of the exception.
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
    var scopeNames = '';
    var scopes = runtime.scopeNameStack.reversed.toList();
    // Print out up to 4 scope names from the end and 4 from the start, skipping
    // those in the middle
    int numScopes = scopes.length <= 8 ? scopes.length : 4;

    for (int i = 0; i < numScopes && i < 4; i++) {
      scopeNames += 'at ${scopes[i]}\n';
    }

    if (scopes.length > 8) {
      scopeNames += '...';
    }

    if (scopes.length > 4) {
      for (int i = scopes.length - numScopes; i < scopes.length; i++) {
        scopeNames += 'at ${scopes[i]}\n';
      }
    }

    return 'dart_eval runtime exception: $caughtException\n'
        '${stackTrace.toString().split("\n").take(3).join('\n')}\n'
        '$scopeNames\n'
        'RUNTIME STATE\n'
        '=============\n'
        'Program offset: ${runtime._prOffset - 1}\n'
        'Stack sample: ${formatStackSample(runtime.stack.last, 10, runtime.frameOffset)}\n'
        'Args sample: ${formatStackSample(runtime.args, 6)}\n'
        'Call stack: ${runtime.callStack}\n'
        'TRACE:\n$prStr';
  }
}

/// Wraps an exception thrown by bytecode inside a Runtime. Signals to the
/// bridge to rethrow the underlying exception directly rather than
/// wrapping it in a [RuntimeException].
class WrappedException implements Exception {
  const WrappedException(this.exception);

  final Object exception;

  @override
  String toString() {
    return 'WrappedException: $exception';
  }
}
