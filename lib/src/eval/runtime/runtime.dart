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
import 'package:dart_eval/src/eval/shared/runtime_type_descriptor.dart';
import 'package:dart_eval/stdlib/core.dart';

import 'typed/typed_export_adapter.dart';
import 'typed/typed_frame.dart';
import 'typed/typed_interop.dart';
import 'typed/typed_global_state.dart';

part 'typed_interop_runtime.dart';

typedef TypeAutowrapper = $Value? Function(dynamic);

class _UnloadedBridgeFunction {
  const _UnloadedBridgeFunction(this.library, this.name, this.registers);

  final String library;
  final String name;
  final EvalRegisterFunc registers;
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
/// [registerBridgeFuncRegisters] or [addPlugin].
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
  static const int versionCode = 105;

  /// Construct a runtime from a typed bytecode buffer. When possible, use the
  /// [Runtime.ofProgram] constructor instead to reduce loading time.
  Runtime(this._buffer) : id = _id++, _fromBytes = true;

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
    // Supertype sets and descriptor rows are shared with the program. They are
    // only ever read or appended to; [_mutableTypeTypes] detaches a program row
    // the first time an import or interned resolution mutates it.
    _typeTypes = List.of(program.typeTypes);
    _programTypeCount = program.typeTypes.length;
    _detachedTypeRows = null;
    _typeDescriptors = program.typeDescriptors.isEmpty
        ? List.generate(program.typeTypes.length, (id) => [id, 0])
        : List.of(program.typeDescriptors);
    _descriptorIndex.clear();
    _indexedDescriptors = 0;
    _typeTableVersion++;
    typeIds = program.typeIds;
    _libraryMap = program.bridgeLibraryMappings;
    _typeIdentities = List.filled(
      _typeDescriptors.length,
      null,
      growable: true,
    );
    _typeEnvironmentRequirements.clear();
    _nominalTypeIds.clear();
    for (final library in _libraryMap.entries) {
      for (final type
          in typeIds[library.value]?.entries ??
              const <MapEntry<String, int>>[]) {
        final identity = (library: library.key, name: type.key);
        _typeIdentities[type.value] = identity;
        _nominalTypeIds[identity] = type.value;
      }
    }
    _importedRuntimeTypes.clear();
    _externalFunctionMap = program.bridgeFunctionMappings;
    var bridgeCount = 0;
    for (final library in _externalFunctionMap.values) {
      for (final id in library.values) {
        if (id >= bridgeCount) bridgeCount = id + 1;
      }
    }
    _bridgeFunctions = List.filled(bridgeCount, null);
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
      _bridgeFunctions[id] = ulb.registers;
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

  /// Register a bridged runtime top-level/static function or class
  /// constructor consuming canonical R/S/C arguments.
  /// C is borrowed overflow storage when the signature has over three arguments.
  void registerBridgeFuncRegisters(
    String library,
    String name,
    EvalRegisterFunc fn, {
    bool isBridge = false,
  }) {
    _unloadedBrFunc.add(
      _UnloadedBridgeFunction(library, isBridge ? '#$name' : name, fn),
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
          ? $List.wrap(
              value.map((v) => wrap(v, recursive: true)).toList(),
              runtimeTypeId: _wrappedCollectionType(CoreTypes.list, [
                CoreTypes.dynamic,
              ]),
              runtime: this,
            )
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
              runtimeTypeId: _wrappedCollectionType(CoreTypes.map, [
                value is Map<String, dynamic>
                    ? CoreTypes.string
                    : CoreTypes.dynamic,
                CoreTypes.dynamic,
              ]),
              runtime: this,
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

  // Recursive wrapping erases arbitrary host generic arguments. Preserve the
  // String-key witness used by JSON maps; never infer arguments from contents.
  int _wrappedCollectionType(
    BridgeTypeSpec type,
    List<BridgeTypeSpec> arguments,
  ) {
    _setup();
    final nominal = lookupType(type);
    return _internResolvedType(
      [nominal, 0, for (final argument in arguments) lookupType(argument)],
      nominal,
      null,
      const [],
      <int, int>{},
    );
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
        final result = (toString as EvalCallable).call(
          this,
          value,
          null,
          null,
          0,
        );
        return result?.$value;
      }
    }
    return (value?.$value).toString();
  }

  var _didSetup = false;
  var _libraryMap = <String, int>{};
  late final List<EvalRegisterFunc?> _bridgeFunctions;
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
  late final List<List<int>> _typeDescriptors;
  final _typeEnvironmentRequirements = <int, bool>{};
  late final List<({String library, String name})?> _typeIdentities;
  final _nominalTypeIds = <({String library, String name}), int>{};
  final _importedRuntimeTypes = <Runtime, Map<int, int>>{};

  /// Rows below this index belong to the loaded program and share its
  /// supertype sets. Interned rows at or above it are always runtime-private.
  int _programTypeCount = 0;

  /// Program-range rows already detached from the shared supertype sets.
  Set<int>? _detachedTypeRows;

  /// Bumped whenever the descriptor table grows or a supertype set mutates,
  /// so memoized subtype and environment-resolution results never go stale.
  int _typeTableVersion = 0;

  /// One-entry memo for repeated (actual, expected, owner) subtype checks.
  int _subtypeMemoActual = -1;
  int _subtypeMemoExpected = -1;
  int? _subtypeMemoOwner;
  int _subtypeMemoVersion = -1;
  bool _subtypeMemoResult = false;

  /// Memoized environment resolutions keyed on (type, ownerType) for calls
  /// without callable type arguments. Cleared on [_typeTableVersion] changes.
  final _resolvedEnvironmentTypes = <(int, int?), int>{};
  int _resolvedEnvironmentTypesVersion = -1;

  /// Lazily built hash index over [_typeDescriptors]; entries are descriptor
  /// content hashes mapped to candidate row ids.
  final _descriptorIndex = <int, List<int>>{};
  int _indexedDescriptors = 0;
  late final Map<int, Map<String, int>> typeIds;
  late final Map<int, Map<String, int>> _externalFunctionMap;
  late final Map<int, Map<String, Map<String, int>>> _bridgeEnumMappings;

  /// Lookup a type ID from a [BridgeTypeSpec]
  int lookupType(BridgeTypeSpec spec) {
    final libIndex = _libraryMap[spec.library]!;
    return typeIds[libIndex]![spec.name]!;
  }

  /// Import a runtime type descriptor from [origin] into this runtime.
  ///
  /// Descriptor IDs are program-local. Values that cross a runtime boundary
  /// use this method to retain their nominal and structural type identity.
  /// Imported descriptors and their cache belong to the destination runtime.
  int importRuntimeType(Runtime origin, int id) {
    _setup();
    origin._setup();
    if (identical(this, origin)) return id;
    if (id < 0 || id >= origin._typeDescriptors.length) {
      throw RangeError.index(id, origin._typeDescriptors, 'id');
    }
    final cache = _importedRuntimeTypes[origin] ??= {};
    final cached = cache[id];
    if (cached != null) return cached;

    final source = origin._typeDescriptors[id];
    final descriptor = _translateRuntimeTypeDescriptor(origin, source);
    var translated = _findRuntimeTypeDescriptor(descriptor);
    if (translated < 0) {
      translated = _typeDescriptors.length;
      _typeDescriptors.add(descriptor);
      _typeTypes.add(<int>{});
      _typeIdentities.add(null);
    }
    cache[id] = translated;
    final translatedTypes = _mutableTypeTypes(translated);
    translatedTypes.addAll(
      origin._typeTypes[id].map((type) => importRuntimeType(origin, type)),
    );
    translatedTypes.add(translated);
    _typeTableVersion++;
    return translated;
  }

  int _importNominalType(Runtime origin, int id) {
    final identity = origin._typeIdentities[id];
    if (identity == null) {
      throw StateError('Runtime type $id has no nominal identity');
    }
    final existing = _nominalTypeIds[identity];
    if (existing != null) return existing;

    // Reserve the nominal ID before importing its supertypes. Every nominal
    // supertype set contains the type itself.
    final translated = _typeDescriptors.length;
    _nominalTypeIds[identity] = translated;
    _typeIdentities.add(identity);
    _typeDescriptors.add([translated, 0]);
    _typeTypes.add({translated});
    (_importedRuntimeTypes[origin] ??= {})[id] = translated;
    _mutableTypeTypes(translated).addAll(
      origin._typeTypes[id].map((type) => importRuntimeType(origin, type)),
    );
    _typeTableVersion++;
    return translated;
  }

  List<int> _translateRuntimeTypeDescriptor(Runtime origin, List<int> source) {
    final nominal = _importNominalType(origin, source[0]);
    if (source.length < 3 || source[2] >= 0) {
      return [
        nominal,
        source[1],
        for (final argument in source.skip(2))
          importRuntimeType(origin, argument),
      ];
    }
    return switch (source[2]) {
      RuntimeTypeDescriptorTag.record => [
        nominal,
        source[1],
        source[2],
        source[3],
        source[4],
        for (final type in source.skip(5).take(source[3]))
          importRuntimeType(origin, type),
        for (var i = 5 + source[3]; i < source.length; i += 2) ...[
          _importRuntimeTypeName(origin, source[i]),
          importRuntimeType(origin, source[i + 1]),
        ],
      ],
      RuntimeTypeDescriptorTag.function => [
        nominal,
        source[1],
        source[2],
        importRuntimeType(origin, source[3]),
        source[4],
        source[5],
        source[6],
        for (final type in source.skip(7).take(source[5]))
          importRuntimeType(origin, type),
        for (var i = 7 + source[5]; i < source.length; i += 3) ...[
          _importRuntimeTypeName(origin, source[i]),
          source[i + 1],
          importRuntimeType(origin, source[i + 2]),
        ],
      ],
      RuntimeTypeDescriptorTag.typeParameter => [
        nominal,
        source[1],
        source[2],
        source[3] == RuntimeTypeDescriptorTag.callableTypeParameterOwner
            ? source[3]
            : _importNominalType(origin, source[3]),
        source[4],
        importRuntimeType(origin, source[5]),
      ],
      _ => throw StateError('Unknown runtime type descriptor tag ${source[2]}'),
    };
  }

  int _importRuntimeTypeName(Runtime origin, int index) {
    final name = origin._constantPool[index];
    if (name is! String) {
      throw StateError('Runtime type name is not a string');
    }
    final existing = _constantPool.indexOf(name);
    if (existing >= 0) return existing;
    _constantPool.add(name);
    return _constantPool.length - 1;
  }

  /// Returns the supertype set for [id], detaching it from the shared program
  /// table first when an import or interned resolution needs to mutate it.
  Set<int> _mutableTypeTypes(int id) {
    var types = _typeTypes[id];
    if (id < _programTypeCount && (_detachedTypeRows ??= <int>{}).add(id)) {
      types = _typeTypes[id] = {...types};
    }
    return types;
  }

  int _findRuntimeTypeDescriptor(List<int> descriptor) {
    while (_indexedDescriptors < _typeDescriptors.length) {
      final row = _typeDescriptors[_indexedDescriptors];
      (_descriptorIndex[Object.hashAll(row)] ??= []).add(_indexedDescriptors);
      _indexedDescriptors++;
    }
    final bucket = _descriptorIndex[Object.hashAll(descriptor)];
    if (bucket == null) return -1;
    for (final id in bucket) {
      final candidate = _typeDescriptors[id];
      if (candidate.length != descriptor.length) continue;
      var equal = true;
      for (var i = 0; i < descriptor.length; i++) {
        if (candidate[i] != descriptor[i]) {
          equal = false;
          break;
        }
      }
      if (equal) return id;
    }
    return -1;
  }

  /// Whether two runtime-local descriptor IDs denote the same Dart type.
  bool runtimeTypesEqual(int id, Runtime otherRuntime, int otherId) =>
      id == importRuntimeType(otherRuntime, otherId);

  /// A program-independent hash for a runtime type descriptor.
  int runtimeTypeHash(int id) => _runtimeTypeSemanticKey(id).hashCode;

  String _runtimeTypeSemanticKey(int id) {
    final descriptor = _typeDescriptors[id];
    final nominal = _typeIdentities[descriptor[0]];
    final nominalKey = nominal == null
        ? '#${descriptor[0]}'
        : '${nominal.library.length}:${nominal.library}'
              '${nominal.name.length}:${nominal.name}';
    if (descriptor.length < 3 || descriptor[2] >= 0) {
      return 'n$nominalKey?${descriptor[1]}<${descriptor.skip(2).map(_runtimeTypeSemanticKey).join(',')}>';
    }
    return switch (descriptor[2]) {
      RuntimeTypeDescriptorTag.record =>
        'r?${descriptor[1]}:${descriptor[3]}:${descriptor[4]}:'
            '${[for (final type in descriptor.skip(5).take(descriptor[3])) _runtimeTypeSemanticKey(type), for (var i = 5 + descriptor[3]; i < descriptor.length; i += 2) '${_constantPool[descriptor[i]]}:${_runtimeTypeSemanticKey(descriptor[i + 1])}'].join(',')}',
      RuntimeTypeDescriptorTag.function =>
        'f?${descriptor[1]}:${descriptor[4]}:${descriptor[5]}:${descriptor[6]}:'
            '${_runtimeTypeSemanticKey(descriptor[3])}:'
            '${[for (final type in descriptor.skip(7).take(descriptor[5])) _runtimeTypeSemanticKey(type), for (var i = 7 + descriptor[5]; i < descriptor.length; i += 3) '${_constantPool[descriptor[i]]}:${descriptor[i + 1]}:${_runtimeTypeSemanticKey(descriptor[i + 2])}'].join(',')}',
      RuntimeTypeDescriptorTag.typeParameter =>
        'p?${descriptor[1]}:'
            '${descriptor[3] < 0 ? descriptor[3] : _typeIdentities[descriptor[3]]}:'
            '${descriptor[4]}:${_runtimeTypeSemanticKey(descriptor[5])}',
      _ => throw StateError(
        'Unknown runtime type descriptor tag ${descriptor[2]}',
      ),
    };
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
