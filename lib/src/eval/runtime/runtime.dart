import 'dart:typed_data';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io.dart';
import 'package:dart_eval/src/eval/shared/stdlib/math.dart';
import 'package:dart_eval/src/eval/shared/stdlib/typed_data.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'typed/typed_export_adapter.dart';
import 'typed/typed_frame.dart';
import 'typed/typed_interop.dart';
import 'typed/typed_global_state.dart';

part 'typed_interop_runtime.dart';

typedef TypeAutowrapper = $Value? Function(dynamic);

class _UnloadedBridgeFunction {
  const _UnloadedBridgeFunction(this.library, this.name, this.func)
    : registers = null;
  const _UnloadedBridgeFunction.registers(
    this.library,
    this.name,
    this.registers,
  ) : func = null;

  final String library;
  final String name;
  final EvalCallableFunc? func;
  final EvalRegisterFunc? registers;
}

class _UnloadedEnumValues {
  const _UnloadedEnumValues(this.library, this.name, this.values);
  final String library;
  final String name;
  final Map<String, $Value> values;
}

/// A [Runtime] is a virtual machine instance that executes typed bytecode.
///
/// It can be created from a [Program] or from serialized bytecode, using the
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
  static const int versionCode = 104;

  /// Construct a runtime from a typed bytecode buffer. When possible, use the
  /// [Runtime.ofProgram] constructor instead to reduce loading time.
  Runtime(this._buffer) : id = _id++, _fromBytes = true;

  static $Value? _fn(Runtime rt, $Value? target, List<$Value?> args) {
    throw UnimplementedError(
      'Tried to invoke a nonexistent external function; did you forget to add it with registerBridgeFunc()?',
    );
  }

  static const _defaultFunction = $Function(_fn);

  /// Create a [Runtime] from a [Program]. This constructor should be preferred
  /// where possible as it avoids overhead of loading bytecode.
  Runtime.ofProgram(Program program) : id = _id++, _fromBytes = false {
    _loadProgram(program);
  }

  void _loadProgram(Program program) {
    _typedProgram = program.typedProgram;
    typedGlobals = TypedGlobalState(_typedProgram, this);
    _exports.clear();
    for (final declaration in _typedProgram.exports) {
      (_exports[declaration.library] ??= {})[declaration.name] = declaration;
    }
    _typeTypes = program.typeTypes;
    typeIds = program.typeIds;
    _libraryMap = program.bridgeLibraryMappings;
    _externalFunctionMap = program.bridgeFunctionMappings;
    var bridgeCount = 0;
    for (final library in _externalFunctionMap.values) {
      for (final id in library.values) {
        if (id >= bridgeCount) bridgeCount = id + 1;
      }
    }
    _bridgeFunctions = List.filled(bridgeCount, _defaultFunction.call);
    _bridgeRegisterFunctions = List.filled(bridgeCount, null);
    _bridgeEnumMappings = program.enumMappings;
    overrideMap = program.overrideMap;
    _constantPool = [...program.constantPool];
  }

  void _load() {
    _loadProgram(Program.read(_buffer));
    _setupBridging();
  }

  void _setupBridging() {
    for (final ulb in _unloadedBrFunc) {
      final libIndex = _libraryMap[ulb.library];
      if (libIndex == null ||
          _externalFunctionMap[libIndex]?[ulb.name] == null) {
        continue;
      }
      final id = _externalFunctionMap[libIndex]![ulb.name]!;
      _bridgeFunctions[id] = ulb.func ?? _defaultFunction.call;
      _bridgeRegisterFunctions[id] = ulb.registers;
    }

    for (final ule in _unloadedEnumValues) {
      final libIndex = _libraryMap[ule.library]!;
      final mapping = _bridgeEnumMappings[libIndex]![ule.name]!;
      for (final value in ule.values.entries) {
        typedGlobals.write(mapping[value.key]!, value.value);
      }
    }
  }

  /// Add a plugin to the runtime, which can register bridge functions.
  void addPlugin(EvalPlugin plugin) {
    _plugins.add(plugin);
  }

  /// Register a bridged runtime top-level/static function or class constructor.
  void registerBridgeFunc(
    String library,
    String name,
    EvalCallableFunc fn, {
    bool isBridge = false,
  }) {
    _unloadedBrFunc.add(
      _UnloadedBridgeFunction(library, isBridge ? '#$name' : name, fn),
    );
  }

  /// Register a generated bridge that consumes canonical R/S/C arguments.
  /// C is borrowed overflow storage when the signature has over three arguments.
  void registerBridgeFuncRegisters(
    String library,
    String name,
    EvalRegisterFunc fn, {
    bool isBridge = false,
  }) {
    _unloadedBrFunc.add(
      _UnloadedBridgeFunction.registers(
        library,
        isBridge ? '#$name' : name,
        fn,
      ),
    );
  }

  /// Register bridged runtime enum values.
  void registerBridgeEnumValues(
    String library,
    String name,
    Map<String, $Value> values,
  ) {
    _unloadedEnumValues.add(_UnloadedEnumValues(library, name, values));
  }

  void _setup() {
    if (_didSetup) {
      return;
    }
    for (final plugin in _plugins) {
      plugin.configureForRuntime(this);
    }
    if (_fromBytes) {
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
        "or eval() function.",
      );
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
          ? $Map.wrap(
              value.map(
                (key, value) => MapEntry(
                  wrap(key, recursive: true),
                  wrap(value, recursive: true),
                ),
              ),
            )
          : $Map.wrap(value);
    }
    for (final wrapper in _typeAutowrappers) {
      final wrapped = wrapper(value);
      if (wrapped != null) {
        return wrapped;
      }
    }
    return wrapPrimitive(value) ??
        (throw Exception(
          'Cannot wrap $value (${value.runtimeType}).'
          'If the type is known explicitly, use \${TypeName}.wrap(value); '
          'otherwise, try adding a type autowrapper with '
          'runtime.addTypeAutowrapper().',
        ));
  }

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
        final result = (toString as EvalCallable).call(this, value, const []);
        return result?.$value;
      }
    }
    return (value?.$value).toString();
  }

  var _didSetup = false;
  var _libraryMap = <String, int>{};
  late final List<EvalCallableFunc> _bridgeFunctions;
  late final List<EvalRegisterFunc?> _bridgeRegisterFunctions;
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
  List<Object?> _constantPool = [];
  late TypedGlobalState typedGlobals;
  var overrideMap = <String, OverrideSpec>{};
  final _permissions = <String, List<Permission>>{};
  final _typeAutowrappers = <TypeAutowrapper>[];

  static int _id = 0;
  final int id;

  /// Stores the [BridgeData] for each bridge class in the program.
  static final bridgeData = Expando<BridgeData>();

  /// Serialized program buffer
  late ByteBuffer _buffer;

  /// Whether the program is loaded from serialized bytecode rather than from a
  /// [Program].
  final bool _fromBytes;

  late final List<Set<int>> _typeTypes;
  late final Map<int, Map<String, int>> typeIds;
  late final Map<int, Map<String, int>> _externalFunctionMap;
  late final Map<int, Map<String, Map<String, int>>> _bridgeEnumMappings;

  /// Lookup a type ID from a [BridgeTypeSpec]
  int lookupType(BridgeTypeSpec spec) {
    final libIndex = _libraryMap[spec.library]!;
    return typeIds[libIndex]![spec.name]!;
  }

  late TypedProgram _typedProgram;
  final _exports = <String, Map<String, TypedExport>>{};

  /// Invoke an exported function by declared parameter names. Missing optional
  /// parameters use their defaults; an explicitly supplied null stays null.
  dynamic executeLib(
    String library,
    String name, {
    Map<String, Object?> arguments = const {},
  }) {
    _setup();
    final declaration = _exports[library]?[name];
    if (declaration != null) {
      final entry = TypedExportAdapter.bind(
        _typedProgram,
        declaration,
        arguments,
        runtime: this,
      );
      return TypedInterop.exportExternal(
        _executeTypedEntry(declaration.functionId, entry),
        runtime: this,
      );
    }
    throw ArgumentError(
      'No exported function $library::$name. Check Compiler.entrypoints.',
    );
  }

  /// Execute a typed function using values in its declared register ABI.
  Object? execute(int functionId, {List<Object?> arguments = const []}) {
    _setup();
    return _executeTypedEntry(
      functionId,
      TypedEntry.fromValues(_typedProgram.functions[functionId], arguments),
    );
  }

  Object? _executeTypedEntry(int functionId, TypedEntry entry) {
    try {
      return TypedMachine.runEntry(
        _typedProgram,
        entry,
        functionId,
        runtime: this,
      );
    } on RuntimeException {
      rethrow;
    } on WrappedException catch (error) {
      throw error.exception;
    } catch (error, trace) {
      throw RuntimeException(this, error, trace);
    }
  }

  /// Throw an exception from the VM. This will unwind the stack until a
  /// catch block is found.
  Never $throw(dynamic exception) {
    throw exception is WrappedException
        ? exception
        : WrappedException(exception as Object);
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
    return 'dart_eval runtime exception: $caughtException\n$stackTrace';
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
