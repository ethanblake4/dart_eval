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
import 'package:dart_eval/src/eval/runtime/ops/xval_ops.dart';
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

/// A [Runtime] is a virtual machine instance that executes XEVC bytecode.
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

  /// Construct a runtime from an XEVC buffer. When possible, use the
  /// [Runtime.ofProgram] constructor instead to reduce loading time.
  Runtime(this._buffer)
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
        _typeTypes = program.typeTypes,
        //typeNames = program.typeNames,
        typeIds = program.typeIds,
        _runtimeTypes = program.runtimeTypes,
        _libraryMap = program.bridgeLibraryMappings,
        _externalFunctionMap = program.bridgeFunctionMappings,
        _bridgeEnumMappings = program.enumMappings,
        _globalInitializers = program.globalInitializers,
        overrideMap = program.overrideMap {
    _declarations = program.topLevelDeclarations;
    _constantPool.addAll(program.constantPool);
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
    final xevc = Uint8List.view(_buffer);

    // header: xvc##{ver}###{ctlen}##{ft64_ct}##{it64_ct}##{it32_ct}##{f16_ct}
    final m1 = xevc[0], m2 = xevc[1], m3 = xevc[2];
    final version = xevc[3] << 8 | xevc[4];

    if (m1 != 0x58 || m2 != 0x56 || m3 != 0x43) {
      throw Exception('dart_eval runtime error: Not an XEVC file');
    }
    if (version != versionCode) {
      var vstr = version.toString();
      if (vstr.length < 3) {
        vstr = '0$vstr';
      }
      throw Exception(
          'dart_eval runtime error: XEVC bytecode is version $vstr, but runtime'
          ' supports version $versionCode.\n'
          'Try using the same version of dart_eval for compiling as the version'
          ' in your application.');
    }

    final ctlen = xevc[5] << 16 | xevc[6] << 8 | xevc[7];
    final ft64ct = xevc[8] << 8 | xevc[9];
    final it64ct = xevc[10] << 8 | xevc[11];
    final it32ct = xevc[12] << 8 | xevc[13];
    final f32ct = xevc[14] << 8 | xevc[15];

    var offset = 16;

    // longlist: ########{int1}########{int2}
    // doublelist: ########{float1}########{float2}
    // intlist: ####{int1}####{int2}
    // floatlist: ####{float1}####{float2}

    _longlist = _buffer.asInt64List(offset, offset += it64ct * 8);
    _doublelist = _buffer.asFloat64List(offset, offset += ft64ct * 8);
    _intlist = _buffer.asInt32List(offset, offset += it32ct * 4);
    _floatlist = _buffer.asFloat32List(offset, offset += f32ct * 4);

    final utf8decoder = utf8.decoder;

    // idt: ##{count}#{len1}identifier1#{len2}ident2
    var idtCount = xevc[offset++] << 8 | xevc[offset++];
    final idt = List.filled(idtCount, "");
    for (var i = 0; i < idtCount; i++) {
      final len = xevc[offset++];
      idt[i] = utf8decoder.convert(xevc, offset, offset += len);
    }

    _identifierTable = idt;

    // ct: ["json"]
    _constantPool = const JsonDecoder()
        .convert(utf8decoder.convert(xevc, offset, offset += ctlen));

    // ** declarations: ##{count}##{lib1}##{idt1}####{off1}##{lib2}##{idt2}####{off2} **
    final decCount = xevc[offset++] << 8 | xevc[offset++];
    final decs = <int, Map<String, int>>{};
    for (var i = 0; i < decCount; i++) {
      final lib = xevc[offset++] << 8 | xevc[offset++];
      final idtCount = xevc[offset++] << 8 | xevc[offset++];
      final idts = <String, int>{};
      for (var j = 0; j < idtCount; j++) {
        final idtIndex = xevc[offset++] << 8 | xevc[offset++];
        final off = xevc[offset++] << 24 |
            xevc[offset++] << 16 |
            xevc[offset++] << 8 |
            xevc[offset++];
        idts[idt[idtIndex]] = off;
      }
      decs[lib] = idts;
    }

    _declarations = decs;

    final dynamicType = 0;
    final objectType = 1;

    // ** typeTypes: ###{typecount}#{kbyte}###{type1} **
    final typecount =
        xevc[offset++] << 16 | xevc[offset++] << 8 | xevc[offset++];
    final typeTypes = List.generate(
        typecount, (i) => <int>{i, objectType, dynamicType},
        growable: false);
    typeTypes[0].remove(objectType);

    // (kbyte 0 = end,  <= 32 = skipN + 2, > 32 = typelen + 32)
    for (var i = 2;; i++) {
      final kbyte = xevc[offset++];
      if (kbyte == 0) {
        break;
      }
      if (kbyte <= 32) {
        i += kbyte - 2;
      } else {
        final typelen = kbyte - 32;
        final end = offset + typelen * 3;
        while (offset < end) {
          typeTypes[i]
              .add(xevc[offset++] << 16 | xevc[offset++] << 8 | xevc[offset++]);
        }
      }
    }

    _typeTypes = typeTypes;

    // ** typeIds: ##{start}#{kbyte}##{len1}##{idt1} **
    final ti = <int, Map<String, int>>{};
    final start = xevc[offset++] << 8 | xevc[offset++];

    // (id increments by 1)
    // (kbyte 0 = accept, 1 = end, >0 = iinc + 127)
    for (var lib = start, type = 0;; lib++) {
      final kbyte = xevc[offset++];
      if (kbyte == 1) {
        break;
      }
      if (kbyte > 0) {
        lib += kbyte - 127;
        break;
      }
      final len = (xevc[offset++] << 8 | xevc[offset++]) + type;
      final ids = <String, int>{};
      for (; type < len; type++) {
        final idtIndex = xevc[offset++] << 8 | xevc[offset++];
        final idtName = idt[idtIndex];
        ids[idtName] = type;
      }
      ti[lib] = ids;
    }

    typeIds = ti;

    // ** libraryMap: #{dLen}#{d1len}string#{d2len}string#{kbyte}filepath **
    final definesLen = xevc[offset++];
    final libraryMap = <String, int>{};

    var defines = List.filled(definesLen, "");
    for (var i = 0; i < definesLen; i++) {
      final dlen = xevc[offset++];
      defines[i] = (utf8decoder.convert(xevc, offset, offset += dlen));
    }

    // (kbyte 0 = defineend, 1-5 = definestart, 6-128 = strlen - 6,
    // 128-192= iinc + 160, 192-255=(iinc + 224) >> 4, 255 = end)
    // iinc 1/iteration by default

    var lib = "";
    var end = "";
    loop:
    for (var i = 0;;) {
      final kbyte = xevc[offset++];
      switch (kbyte) {
        case 255:
          break loop;
        case 0:
          end = defines[0];
          break;
        case < 5:
          lib = defines[kbyte - 1];
          break;
        case <= 128:
          final len = kbyte + 6;
          lib += utf8decoder.convert(xevc, offset, offset += len) + end;
          libraryMap[lib] = i++;
          end = "";
          break;
        case <= 192:
          i += kbyte - 160;
          break;
        default:
          i += (kbyte - 224) << 4;
          break;
      }
    }

    _libraryMap = libraryMap;

    // ** externalFuncMap: ##{count}##{libId}#{kbyte}##{idt} **
    final externalFuncMap = <int, Map<String, int>>{};
    final count = xevc[offset++] << 8 | xevc[offset++];

    // (auto increment +1)
    // (kbyte 0 = end, 1 = setprefix, 2 = *g, 3 = *s, 4 = clear,
    // 5-100 = execN + 5, >100 = execNdot + 5)
    final blank = "";
    var postfix = blank, prefix = blank;
    for (var id = 0, i = 0, lib = 0; i < count; i++) {
      libloop:
      while (true) {
        final kbyte = xevc[offset++];
        switch (kbyte) {
          case 0:
            break libloop;
          case 1:
            final sid = xevc[offset++] << 8 | xevc[offset++];
            prefix = idt[sid];
            break;
          case 2:
            postfix = "*g";
            break;
          case 3:
            postfix = "*s";
            break;
          case 4:
            prefix = postfix = blank;
            break;
          case <= 100:
            final it = kbyte - 5;
            for (var j = 0; j < it; j++) {
              final idtIndex = xevc[offset++] << 8 | xevc[offset++];
              final name = prefix + idt[idtIndex] + postfix;
              externalFuncMap[lib]![name] = id++;
              postfix = blank;
            }
            break;
          default:
            final it = kbyte - 105;
            for (var j = 0; j < it; j++) {
              final idtIndex = xevc[offset++] << 8 | xevc[offset++];
              final name = prefix + '.' + idt[idtIndex] + postfix;
              externalFuncMap[lib]![name] = id++;
              postfix = blank;
            }
            break;
        }
      }
    }

    _externalFunctionMap = externalFuncMap;

    // globalInitializers: ##{start}##{kbyte} (0 = end, > 0 = iinc)
    final gstart = xevc[offset++] << 8 | xevc[offset++];
    var gi = <int>[];
    for (var i = gstart;;) {
      final kbyte = xevc[offset++] << 8 | xevc[offset++];
      if (kbyte == 0) {
        break;
      }
      i += kbyte;
      gi.add(i);
    }

    _globalInitializers = gi.toList(growable: false);

    // overrideMap: ##{length}json
    final overridesLength = xevc[offset++] << 8 | xevc[offset++];
    final encodedOverrideMap =
        utf8decoder.convert(xevc, offset, offset += overridesLength);

    overrideMap = (json.decode(encodedOverrideMap) as Map)
        .cast<String, List>()
        .map((key, value) => MapEntry(key, OverrideSpec(value[0], value[1])));

    // enumMappings: ##{length}json
    final enumMappingsLength = xevc[offset++] << 8 | xevc[offset++];
    final encodedEnumMappings =
        utf8decoder.convert(xevc, offset, offset += enumMappingsLength);

    // runtimeTypes: ##{length}json
    final runtimeTypesLength = xevc[offset++] << 8 | xevc[offset++];
    final encodedRuntimeTypes =
        utf8decoder.convert(xevc, offset, offset += runtimeTypesLength);

    _bridgeEnumMappings = (json.decode(encodedEnumMappings) as Map).map(
        (k, v) => MapEntry(
            int.parse(k),
            (v as Map)
                .map((key, value) =>
                    MapEntry(key, (value as Map).cast<String, int>()))
                .cast<String, Map<String, int>>()));

    final classes = /* TODO (json.decode(encodedInstanceDecs).map((k, v) =>
            MapEntry(int.parse(k), (v as Map).cast<String, List>())) as Map)
        .cast<int, Map<String, List>>(); */
        {};

    classes.forEach((file, $class) {
      declaredClasses[file] = {
        for (final decl in $class.entries)
          decl.key: EvalClass.fromJson(decl.value)
      };
    });

    _runtimeTypes = [
      for (final s in (json.decode(encodedRuntimeTypes) as List))
        RuntimeTypeSet.fromJson(s as List)
    ];

    _setupBridging();
  }

  void _setupBridging() {
    for (final ulb in _unloadedBrFunc) {
      final libIndex = _libraryMap[ulb.library];
      if (libIndex == null ||
          _externalFunctionMap[libIndex]?[ulb.name] == null) {
        continue;
      }
      _bridgeFunctions[_externalFunctionMap[libIndex]![ulb.name]!] = ulb.func;
    }

    for (final ule in _unloadedEnumValues) {
      final libIndex = _libraryMap[ule.library]!;
      final mapping = _bridgeEnumMappings[libIndex]![ule.name]!;
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
  var _libraryMap = <String, int>{};
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
  var _identifierTable = List<String>.filled(0, "");
  var _longlist = Int64List(0);
  var _intlist = Int32List(0);
  var _floatlist = Float32List(0);
  var _doublelist = Float64List(0);
  var _constantPool = List<dynamic>.filled(0, null);
  final globals = List<Object?>.filled(20000, null);
  var _globalInitializers = <int>[];
  var overrideMap = <String, OverrideSpec>{};
  final _permissions = <String, List<Permission>>{};
  final _typeAutowrappers = <TypeAutowrapper>[];

  static int _id = 0;
  final int id;

  /// Stores the [BridgeData] for each bridge class in the program.
  static final bridgeData = Expando<BridgeData>();

  /// Binary XEVC bytecode
  late ByteBuffer _buffer;

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
  final pr = <dynamic>[];

  /// The most recent return value
  Object? returnValue;

  bool _inCatch = false;

  /// 0 = throw, 1 = return, 2 = break, 3 = continue
  int _catchControlFlowOutcome = -1;

  /// The exception to be rethrown
  Object? _rethrowException;

  /// Last return value from a catch block
  Object? _returnFromCatch;

  /// [frameOffset]s for each stack frame
  final frameOffsetStack = <int>[0];

  /// The program's call stack. If a function returns it will pop the last
  /// element from this stack and set [_prOffset] to the popped value.
  final callStack = <int>[0];

  /// The program's catch stack. If a function throws it will pop the last
  /// element from this stack and set [_prOffset] to the popped value.
  final catchStack = <List<int>>[];

  var _declarations = <int, Map<String, int>>{};
  final declaredClasses = <int, Map<String, EvalClass>>{};
  final xdeclaredClasses = <EvalClass>[];
  //late final List<String> typeNames;
  late final List<Set<int>> _typeTypes;
  late final Map<int, Map<String, int>> typeIds;
  late final List<RuntimeTypeSet> _runtimeTypes;
  late final Map<int, Map<String, int>> _externalFunctionMap;
  late final Map<int, Map<String, Map<String, int>>> _bridgeEnumMappings;

  /// Lookup a type ID from a [BridgeTypeSpec]
  int lookupType(BridgeTypeSpec spec) {
    final libIndex = _libraryMap[spec.library]!;
    return typeIds[libIndex]![spec.name]!;
  }

  /// Offset in the current stack frame
  int frameOffset = 0;

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
    if (_declarations[_libraryMap[library]] == null) {
      throw ArgumentError('Cannot find $library, maybe it wasn\'t declared as'
          ' an entrypoint?');
    }
    return execute(_declarations[_libraryMap[library]!]![name]!);
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

  /// pr: Program bytecode
  /// idt: Identifier table
  /// ct: Constant table
  /// cs: Call stack
  /// ts: Exception trap (catch) stack
  /// s: Stack
  /// t: Stack trace (scope names)
  /// pc8/16: Program counters
  /// si: Stack index
  /// fi: Frame index
  /// fis: Frame index stack
  /// r0, r1: Primary registers (r0 is accumulator)
  /// r3: Secondary register
  /// args: Arguments
  dynamic _run(
      Uint8List pr,
      List<int> cs,
      List<int> fis,
      List<List<int>> ts,
      List<List<Object?>> s,
      List<String> t,
      int pc,
      int si,
      int fi,
      Object? r0,
      Object? r1,
      Object? r2,
      List<Object?> args) {
    // current stack frame
    var fr = s[si];

    final idt = _identifierTable, ct = _constantPool;
    final ilist = _intlist,
        llist = _longlist,
        flist = _floatlist,
        dlist = _doublelist;

    // ignore: unused_label
    execloop:
    while (true) {
      switch (pr[pc++]) {
        case Xops.scope:
          // scope (Ix u16): Push scope with specified name
          t[si] = idt[pr[pc++] << 8 | pr[pc++]];
          break;
        case Xops.asyncscope:
          // asyncscope (Ix u16): Push scope with specified name and push
          // Completer
          t[si] = idt[pr[pc++] << 8 | pr[pc++]];
          fr[fi++] = Completer();
          break;
        case Xops.popscope:
          // popscope: Pop scope
          si--;
          fr = s[si];
          break;
        case Xops.lc0:
          // lc0 (Cx u16): Load constant Cx into register 0
          r0 = ct[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lc1:
          // lc0 (Cx u16): Load constant Cx into register 1
          r1 = ct[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lc0boxs:
          // lc0boxs (Cx u16): Load constant Cx into register 0 and box string
          r0 = $String(ct[pr[pc++] << 8 | pr[pc++]] as String);
          break;

        case Xops.lc1boxs:
          // lc1boxs (Cx u16): Load constant Cx into register 1 and box string
          r1 = $String(ct[pr[pc++] << 8 | pr[pc++]] as String);
          break;

        case Xops.lc0p:
          // lc0p (Cx u16): Load constant Cx into register 0 and push
          fr[fi++] = r0 = ct[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lc1p:
          // lc1p (Cx u16): Load constant Cx into register 1 and push
          fr[fi++] = r1 = ct[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lcf0box:
          // lcf0box (Cx u16): Load constant Cx into register 0 and box double
          r0 = $double(flist[pr[pc++] << 8 | pr[pc++]]);
          break;

        case Xops.lcf1box:
          // lcf0box (Cx u16): Load constant Cx into register 1 and box double
          r1 = $double(flist[pr[pc++] << 8 | pr[pc++]]);
          break;

        case Xops.lci0:
          // lci0 (Cx u16): Load constant Cx into register 0 as integer
          r0 = ilist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lci1:
          // lci1 (Cx u16): Load constant Cx into register 1 as integer
          r1 = ilist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lcl0:
          // lcl0 (Cx u16): Load constant Cx into register 0 as long
          r0 = llist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lcl1:
          // lcl1 (Cx u16): Load constant Cx into register 1 as long
          r1 = llist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lci0p:
          // lci0p (Cx u16): Load constant Cx into register 0 as integer and push
          fr[fi++] = r0 = ilist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lci1p:
          // lci1p (Cx u16): Load constant Cx into register 1 as integer and push
          fr[fi++] = r1 = ilist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lcd0:
          // lcd0 (Cx u16): Load constant Cx into register 0 as double
          r0 = dlist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.lcd1:
          // lcd1 (Cx u16): Load constant Cx into register 1 as double
          r1 = dlist[pr[pc++] << 8 | pr[pc++]];
          break;

        case Xops.ls0:
          // ls0 (*Sx u8): Load stack value at Sx into register 0
          r0 = fr[pr[pc++]];
          break;

        case Xops.ls1:
          // ls1 (*Sx u8): Load stack value at Sx into register 1
          r1 = fr[pr[pc++]];
          break;

        case Xops.lprop0i:
          // lprop0i (u8): Load property Ix from register 0 into register 0
          final object = r0 as $InstanceImpl;
          r1 = object.values[pr[pc++]];
          break;

        case Xops.lprop1i:
          // lprop1i (u8): Load property Ix from register 0 into register 1
          final object = r1 as $InstanceImpl;
          r1 = object.values[pr[pc++]];
          break;

        case Xops.jump:
          // jump (Jx i16): Jump relative (constant)
          pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          break;

        case Xops.jumpf:
          // jumpf (Jx i16): Jump relative (false)
          if (r0 == false) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.jumpt:
          // jumpt (Jx i16): Jump relative (true)
          if (r0 == true) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.jumpnnil:
          // jumpnnil (Jx i16): Jump relative (not null)
          if (r0 != null) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.push0:
          // push0: Push register 0 onto stack
          fr[fi++] = r0;
          break;

        case Xops.push1:
          // push1: Push register 1 onto stack
          fr[fi++] = r1;
          break;

        case Xops.sets0:
          // sets0 (*Sx u8): Set stack value at Sx to register 0
          fr[pr[pc++]] = r0;
          break;

        case Xops.sets1:
          // sets1 (*Sx u8): Set stack value at Sx to register 1
          fr[pr[pc++]] = r1;
          break;

        case Xops.lii0:
          // lii0 (u16 + 0xff): Load immediate integer into register 0
          r0 = pr[pc++] << 8 | pr[pc++] - 0xff;
          break;

        case Xops.lii1:
          // lii1 (u16 + 0xff): Load immediate integer into register 1
          r1 = pr[pc++] << 8 | pr[pc++] - 0xff;
          break;

        case Xops.lii0b:
          // lii0b (u16 + 0xff): Load immediate integer into register 0 and box
          r0 = $int(pr[pc++] << 8 | pr[pc++] - 0xff);
          break;

        case Xops.lii1b:
          // lii1b (u16 + 0xff): Load immediate integer into register 1 and box
          r1 = $int(pr[pc++] << 8 | pr[pc++] - 0xff);
          break;

        case Xops.lii0p:
          // lii0p (u16 + 0xff): Load immediate integer into register 0 and push
          fr[fi++] = r0 = pr[pc++] << 8 | pr[pc++] - 0xff;
          break;

        case Xops.lii1p:
          // lii1p (u16 + 0xff): Load immediate integer into register 1 and push
          fr[fi++] = r1 = pr[pc++] << 8 | pr[pc++] - 0xff;
          break;

        case Xops.lii0bp:
          // lii0bp (u16 + 0xff): Load immediate integer into register 0, box, and
          // push
          fr[fi++] = r0 = $int(pr[pc++] << 8 | pr[pc++] - 0xff);
          break;

        case Xops.lii1bp:
          // lii1bp (u16 + 0xff): Load immediate integer into register 1, box, and
          // push
          fr[fi++] = r1 = $int(pr[pc++] << 8 | pr[pc++] - 0xff);
          break;

        case Xops.ltrue0:
          // ltrue0: Load true into register 0
          r0 = true;
          break;

        case Xops.ltrue1:
          // ltrue1: Load true into register 1
          r1 = true;
          break;

        case Xops.lfalse0:
          // lfalse0: Load false into register 0
          r0 = false;
          break;

        case Xops.lfalse1:
          // lfalse1: Load false into register 1
          r1 = false;
          break;

        case Xops.lnull0:
          // lnull0: Load null into register 0
          r0 = null;
          break;

        case Xops.lnull1:
          // lnull1: Load null into register 1
          r1 = null;
          break;

        case Xops.lnull0b:
          // lnull0b: Load null into register 0 and box
          r0 = $null();
          break;

        case Xops.lnull1b:
          // lnull1b: Load null into register 1 and box
          r1 = $null();
          break;

        case Xops.lnull0p:
          // lnull0p: Load null into register 0 and push
          fr[fi++] = r0 = null;
          break;

        case Xops.lnull1p:
          // lnull1p: Load null into register 1 and push
          fr[fi++] = r1 = null;
          break;

        case Xops.lnull0bp:
          // lnull0bp: Load null into register 0, box, and push
          fr[fi++] = r0 = $null();
          break;

        case Xops.lnull1bp:
          // lnull1bp: Load null into register 1, box, and push
          fr[fi++] = r1 = $null();
          break;

        case Xops.ltrue0p:
          // ltrue0p: Load true into register 0 and push
          fr[fi++] = r0 = true;
          break;

        case Xops.ltrue1p:
          // ltrue1p: Load true into register 1 and push
          fr[fi++] = r1 = true;
          break;

        case Xops.lfalse0p:
          // lfalse0p: Load false into register 0 and push
          fr[fi++] = r0 = false;
          break;

        case Xops.lfalse1p:
          // lfalse1p: Load false into register 1 and push
          fr[fi++] = r1 = false;
          break;

        case Xops.ltrue0b:
          // ltrue0b: Load true into register 0 and box
          r0 = $bool(true);
          break;

        case Xops.ltrue1b:
          // ltrue1b: Load true into register 1 and box
          r1 = $bool(true);
          break;

        case Xops.lfalse0b:
          // lfalse0b: Load false into register 0 and box
          r0 = $bool(false);
          break;

        case Xops.lfalse1b:
          // lfalse1b: Load false into register 1 and box
          r1 = $bool(false);
          break;

        case Xops.ltrue0bp:
          // ltrue0bp: Load true into register 0, box, and push
          fr[fi++] = r0 = $bool(true);
          break;

        case Xops.ltrue1bp:
          // ltrue1bp: Load true into register 1, box, and push
          fr[fi++] = r1 = $bool(true);
          break;

        case Xops.lfalse0bp:
          // lfalse0bp: Load false into register 0, box, and push
          fr[fi++] = r0 = $bool(false);
          break;

        case Xops.lfalse1bp:
          // lfalse1bp: Load false into register 1, box, and push
          fr[fi++] = r1 = $bool(false);
          break;

        case Xops.lctype0:
          // lctype0 (u16 id): Load constant type with ID into register 0
          r0 = $TypeImpl(pr[pc++] << 8 | pr[pc++]);
          break;

        case Xops.lctype1:
          // lctype1 (u16 id): Load constant type with ID into register 1
          r1 = $TypeImpl(pr[pc++] << 8 | pr[pc++]);
          break;

        case Xops.swap01:
          // swap01: Swap registers 0 and 1
          final temp = r0;
          r0 = r1;
          r1 = temp;
          break;

        case Xops.swap02:
          // swap02: Swap registers 0 and 2
          final temp = r0;
          r0 = r2;
          r2 = temp;
          break;

        case Xops.swap12:
          // swap12: Swap registers 1 and 2
          final temp = r1;
          r1 = r2;
          r2 = temp;
          break;

        case Xops.dup0:
          // dup0: Duplicate register 0
          r1 = r0;
          break;

        case Xops.dup1:
          // dup1: Duplicate register 1
          r0 = r1;
          break;

        case Xops.lg0:
          // lg0 (u16): Load global with index into register 0
          final index = pr[pc++] << 8 | pr[pc++];
          var value = globals[index];
          if (value == null) {
            _call(20, fis, fi, s, si, cs, ts, pc);
            fi = 0;
            pc = _globalInitializers[index];
          } else {
            r0 = value;
          }
          break;

        case Xops.sg0:
          // sg0 (u16): Store register 0 in global with index
          globals[pr[pc++] << 8 | pr[pc++]] = r0;
          break;

        case Xops.isp:
          // isp (u8): Increment stack pointer
          fi++;
          break;

        case Xops.iadd:
          // iadd: Add registers 0 and 1 as ints
          r0 = (r0 as int) + (r1 as int);
          break;

        case Xops.iadds:
          // iadds (*Sx): Add register 1 and stack and store in register 0
          r0 = (r1 as int) + (fr[pr[pc++]] as int);
          break;

        case Xops.iaddsp:
          // iaddsp (u8): Add register 1 and stack, store in register 0, and push
          fr[fi++] = r0 = (r1 as int) + (fr[pr[pc++]] as int);
          break;

        case Xops.iinc0:
          // iinc0: Increment register 0
          r0 = (r0 as int) + 1;
          break;

        case Xops.iinc1:
          // iinc1: Increment register 1
          r1 = (r1 as int) + 1;
          break;

        case Xops.isinc:
          // isinc (u8): Increment stack value at Sx
          fr[pr[pc++]] = (fr[pr[pc++]] as int) + 1;
          break;

        case Xops.isub:
          // isub: Subtract registers 0 and 1 as ints
          r0 = (r0 as int) - (r1 as int);
          break;

        case Xops.isubs:
          // isubs (*Sx): Subtract register 1 from stack and store in register 0
          r0 = (r1 as int) - (fr[pr[pc++]] as int);
          break;

        case Xops.isubsp:
          // isubsp (u8): Subtract register 1 from stack, store in register 0, and
          // push
          fr[fi++] = r0 = (r1 as int) - (fr[pr[pc++]] as int);
          break;

        case Xops.imul:
          // imul: Multiply registers 0 and 1 as ints
          r0 = (r0 as int) * (r1 as int);
          break;

        case Xops.imuls:
          // imuls (*Sx): Multiply register 1 and stack and store in register 0
          r0 = (r1 as int) * (fr[pr[pc++]] as int);
          break;

        case Xops.imulsp:
          // imulsp (u8): Multiply register 1 and stack, store in register 0, and
          // push
          fr[fi++] = r0 = (r1 as int) * (fr[pr[pc++]] as int);
          break;

        case Xops.idiv:
          // idiv: Divide registers 0 and 1 as ints
          r0 = (r0 as int) / (r1 as int);
          break;

        case Xops.idivs:
          // idivs (*Sx): Divide register 1 by stack and store in register 0
          r0 = (r1 as int) / (fr[pr[pc++]] as int);
          break;

        case Xops.idivsp:
          // idivsp (u8): Divide register 1 by stack, store in register 0, and push
          fr[fi++] = r0 = (r1 as int) ~/ (fr[pr[pc++]] as int);
          break;

        case Xops.iidiv:
          // iidiv: Integer divide registers 0 and 1
          r0 = (r0 as int) ~/ (r1 as int);
          break;

        case Xops.iidivs:
          // iidivs (*Sx): Integer divide register 1 by stack and store in register 0
          r0 = (r1 as int) ~/ (fr[pr[pc++]] as int);
          break;

        case Xops.iidivsp:
          // iidivsp (u8): Integer divide register 1 by stack, store in register 0,
          // and push
          fr[fi++] = r0 = (r1 as int) ~/ (fr[pr[pc++]] as int);
          break;

        case Xops.ilt:
          // ilt: Compare registers 0 and 1 as ints
          r0 = (r0 as int) < (r1 as int);
          break;

        case Xops.iltj:
          // iltj (Jx i16): Jump relative (less than)
          if ((r0 as int) < (r1 as int)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.ilteq:
          // ilteq: Compare registers 0 and 1 as ints (less than or equal)
          r0 = (r0 as int) <= (r1 as int);
          break;

        case Xops.ilteqj:
          // ilteqj (Jx i16): Jump relative (less than or equal)
          if ((r0 as int) <= (r1 as int)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.ieq:
          // ieq: Compare registers 0 and 1 as ints
          r0 = (r0 as int) == (r1 as int);
          break;

        case Xops.ieqj:
          // ieqj (Jx i16): Jump relative (equal)
          if ((r0 as int) == (r1 as int)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.iand:
          // iand: Bitwise AND registers 0 and 1
          r0 = (r0 as int) & (r1 as int);
          break;

        case Xops.ior:
          // ior: Bitwise OR registers 0 and 1
          r0 = (r0 as int) | (r1 as int);
          break;

        case Xops.ixor:
          // ixor: Bitwise XOR registers 0 and 1
          r0 = (r0 as int) ^ (r1 as int);
          break;

        case Xops.imod:
          // imod: Modulo registers 0 and 1
          r0 = (r0 as int) % (r1 as int);
          break;

        case Xops.ishl:
          // ishl: Bitwise shift left registers 0 and 1
          r0 = (r0 as int) << (r1 as int);
          break;

        case Xops.ishr:
          // ishr: Bitwise shift right registers 0 and 1
          r0 = (r0 as int) >> (r1 as int);
          break;

        case Xops.itoa:
          // itoa: Convert int to string
          r1 = (r0 as int).toString();
          break;

        case Xops.dadd:
          // dadd: Add registers 0 and 1 as doubles
          r0 = (r0 as double) + (r1 as double);
          break;

        case Xops.dadds:
          // dadds (*Sx): Add register 1 and stack and store in register 0
          r0 = (r1 as double) + (fr[pr[pc++]] as double);
          break;

        case Xops.daddsp:
          // daddsp (u8): Add register 1 and stack, store in register 0, and push
          fr[fi++] = r0 = (r1 as double) + (fr[pr[pc++]] as double);
          break;

        case Xops.dsub:
          // dsub: Subtract registers 0 and 1 as doubles
          r0 = (r0 as double) - (r1 as double);
          break;

        case Xops.dsubs:
          // dsubs (*Sx): Subtract register 1 from stack and store in register 0
          r0 = (r1 as double) - (fr[pr[pc++]] as double);
          break;

        case Xops.dsubsp:
          // dsubsp (u8): Subtract register 1 from stack, store in register 0, and
          // push
          fr[fi++] = r0 = (r1 as double) - (fr[pr[pc++]] as double);
          break;

        case Xops.dmul:
          // dmul: Multiply registers 0 and 1 as doubles
          r0 = (r0 as double) * (r1 as double);
          break;

        case Xops.dmuls:
          // dmuls (*Sx): Multiply register 1 and stack and store in register 0
          r0 = (r1 as double) * (fr[pr[pc++]] as double);
          break;

        case Xops.dmulsp:
          // dmulsp (u8): Multiply register 1 and stack, store in register 0, and
          // push
          fr[fi++] = r0 = (r1 as double) * (fr[pr[pc++]] as double);
          break;

        case Xops.ddiv:
          // ddiv: Divide registers 0 and 1 as doubles
          r0 = (r0 as double) / (r1 as double);
          break;

        case Xops.ddivs:
          // ddivs (*Sx): Divide register 1 by stack and store in register 0
          r0 = (r1 as double) / (fr[pr[pc++]] as double);
          break;

        case Xops.ddivsp:
          // ddivsp (u8): Divide register 1 by stack, store in register 0, and push
          fr[fi++] = r0 = (r1 as double) / (fr[pr[pc++]] as double);
          break;

        case Xops.dmod:
          // dmod: Modulo registers 0 and 1 as doubles
          r0 = (r0 as double) % (r1 as double);
          break;

        case Xops.dlt:
          // dlt: Compare registers 0 and 1 as doubles
          r0 = (r0 as double) < (r1 as double);
          break;

        case Xops.dltj:
          // dltj (Jx i16): Jump relative (less than)
          if ((r0 as double) < (r1 as double)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.dlteq:
          // dlteq: Compare registers 0 and 1 as doubles (less than or equal)
          r0 = (r0 as double) <= (r1 as double);
          break;

        case Xops.dlteqj:
          // dlteqj (Jx i16): Jump relative (less than or equal)
          if ((r0 as double) <= (r1 as double)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.deq:
          // deq: Compare registers 0 and 1 as doubles
          r0 = (r0 as double) == (r1 as double);
          break;

        case Xops.deqj:
          // deqj (Jx i16): Jump relative (equal)
          if ((r0 as double) == (r1 as double)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.dtoa:
          // dtoa: Convert double to string
          r1 = (r0 as double).toString();
          break;

        case Xops.nadd:
          // nadd: Add registers 0 and 1 as nums
          r0 = (r0 as num) + (r1 as num);
          break;

        case Xops.nadds:
          // nadds (*Sx): Add register 1 and stack and store in register 0
          r0 = (r1 as num) + (fr[pr[pc++]] as num);
          break;

        case Xops.naddsp:
          // naddsp (u8): Add register 1 and stack, store in register 0, and push
          fr[fi++] = r0 = (r1 as num) + (fr[pr[pc++]] as num);
          break;

        case Xops.nsub:
          // nsub: Subtract registers 0 and 1 as nums
          r0 = (r0 as num) - (r1 as num);
          break;

        case Xops.nsubs:
          // nsubs (*Sx): Subtract register 1 from stack and store in register 0
          r0 = (r1 as num) - (fr[pr[pc++]] as num);
          break;

        case Xops.nsubsp:
          // nsubsp (u8): Subtract register 1 from stack, store in register 0, and
          // push
          fr[fi++] = r0 = (r1 as num) - (fr[pr[pc++]] as num);
          break;

        case Xops.nmul:
          // nmul: Multiply registers 0 and 1 as nums
          r0 = (r0 as num) * (r1 as num);
          break;

        case Xops.nmuls:
          // nmuls (*Sx): Multiply register 1 and stack and store in register 0
          r0 = (r1 as num) * (fr[pr[pc++]] as num);
          break;

        case Xops.nmulsp:
          // nmulsp (u8): Multiply register 1 and stack, store in register 0, and
          // push
          fr[fi++] = r0 = (r1 as num) * (fr[pr[pc++]] as num);
          break;

        case Xops.ndiv:
          // ndiv: Divide registers 0 and 1 as nums
          r0 = (r0 as num) / (r1 as num);
          break;

        case Xops.ndivs:
          // ndivs (*Sx): Divide register 1 by stack and store in register 0
          r0 = (r1 as num) / (fr[pr[pc++]] as num);
          break;

        case Xops.ndivsp:
          // ndivsp (u8): Divide register 1 by stack, store in register 0, and push
          fr[fi++] = r0 = (r1 as num) / (fr[pr[pc++]] as num);
          break;

        case Xops.nidiv:
          // nidiv: Integer divide registers 0 and 1 as nums
          r0 = (r0 as num) ~/ (r1 as num);
          break;

        case Xops.nidivs:
          // nidivs (*Sx): Integer divide register 1 by stack and store in register 0
          r0 = (r1 as num) ~/ (fr[pr[pc++]] as num);
          break;

        case Xops.nidivsp:
          // nidivsp (u8): Integer divide register 1 by stack, store in register 0,
          // and push
          fr[fi++] = r0 = (r1 as num) ~/ (fr[pr[pc++]] as num);
          break;

        case Xops.nlt:
          // nlt: Compare registers 0 and 1 as nums
          r0 = (r0 as num) < (r1 as num);
          break;

        case Xops.nltj:
          // nltj (Jx i16): Jump relative (less than)
          if ((r0 as num) < (r1 as num)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.nlteq:
          // nlteq: Compare registers 0 and 1 as nums (less than or equal)
          r0 = (r0 as num) <= (r1 as num);
          break;

        case Xops.nlteqj:
          // nlteqj (Jx i16): Jump relative (less than or equal)
          if ((r0 as num) <= (r1 as num)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.numeq:
          // numeq: Compare registers 0 and 1 as nums
          r0 = (r0 as num) == (r1 as num);
          break;

        case Xops.numeqj:
          // numeqj (Jx i16): Jump relative (equal)
          if ((r0 as num) == (r1 as num)) {
            pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          } else {
            pc += 2;
          }
          break;

        case Xops.nmod:
          // nmod: Modulo registers 0 and 1 as nums
          r0 = (r0 as num) % (r1 as num);
          break;

        case Xops.ntoa:
          // ntoa: Convert num to string
          r1 = (r0 as num).toString();
          break;

        case Xops.bnot:
          // bnot: Not bool r0
          r0 = !(r0 as bool);
          break;

        case Xops.band:
          // band: And bool registers 0 and 1
          r0 = (r0 as bool) && (r1 as bool);
          break;

        case Xops.bor:
          // bor: Or bool registers 0 and 1
          r0 = (r0 as bool) || (r1 as bool);
          break;

        case Xops.unbox0:
          // unbox0: Unbox register 0
          r0 = (r0 as $Value).$value;
          break;

        case Xops.unbox1:
          // unbox1: Unbox register 1
          r1 = (r1 as $Value).$value;
          break;

        case Xops.boxi0:
          // boxi0: Box register 0 as int
          r0 = $int(r0 as int);
          break;

        case Xops.boxi1:
          // boxi1: Box register 1 as int
          r1 = $int(r1 as int);
          break;

        case Xops.boxd0:
          // boxd0: Box register 0 as double
          r0 = $double(r0 as double);
          break;

        case Xops.boxd1:
          // boxd1: Box register 1 as double
          r1 = $double(r1 as double);
          break;

        case Xops.boxn0:
          // boxn0: Box register 0 as num
          r0 = $num(r0 as num);
          break;

        case Xops.boxn1:
          // boxn1: Box register 1 as num
          r1 = $num(r1 as num);
          break;

        case Xops.boxb0:
          // boxb0: Box register 0 as bool
          r0 = $bool(r0 as bool);
          break;

        case Xops.boxb1:
          // boxb1: Box register 1 as bool
          r1 = $bool(r1 as bool);
          break;

        case Xops.boxs0:
          // boxs0: Box register 0 as string
          r0 = $String(r0 as String);
          break;

        case Xops.boxs1:
          // boxs1: Box register 1 as string
          r1 = $String(r1 as String);
          break;

        case Xops.boxl0:
          // boxl0: Box register 0 as list
          r0 = $List.wrap(r0 as List);
          break;

        case Xops.boxl1:
          // boxl1: Box register 1 as list
          r1 = $List.wrap(r1 as List);
          break;

        case Xops.boxm0:
          // boxm0: Box register 0 as map
          r0 = $Map.wrap(r0 as Map);
          break;

        case Xops.boxm1:
          // boxm1: Box register 1 as map
          r1 = $Map.wrap(r1 as Map);
          break;

        case Xops.boxnilq0:
          // boxnilq0: Box register 0 as null if null
          r0 = r0 == null ? $null() : r0;
          break;

        case Xops.boxnilq1:
          // boxnilq1: Box register 1 as null if null
          r1 = r1 == null ? $null() : r1;
          break;

        case Xops.newcls:
          // newcls (u24 idx, u8 vlen): Create new instance of class with ID
          // and push
          final classId = pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];
          final vlen = pr[pc++];

          r0 = $InstanceImpl(xdeclaredClasses[classId], r0 as $Instance?,
              List.filled(vlen, null));

          break;

        case Xops.newbr:
          // newbr (u24 cstr): Create new bridge with constructor ID
          // and push
          final cstr = pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];
          final $subclass = r0 as $Instance?;

          final _argsLen = args.length;

          final _mappedArgs = List<$Value?>.filled(_argsLen, null);
          for (var i = 0; i < _argsLen; i++) {
            _mappedArgs[i] = (args[i] as $Value?);
          }

          args = [];

          final $runtimeType = 1;
          r0 = _bridgeFunctions[cstr](this, null, _mappedArgs) as $Instance;
          Runtime.bridgeData[r0] = BridgeData(
              this, $runtimeType, $subclass ?? BridgeDelegatingShim());
          break;

        case Xops.newbss:
          // newbss (u24 cstr): Create new bridge super shim in r0
          r0 = r2 = BridgeSuperShim();
          break;

        case Xops.linkbss:
          // linkbss: Link bridge super shim in r2 to bridge class in r0
          (r2 as BridgeSuperShim).bridge = r0 as $Bridge;
          break;

        case Xops.call:
          // call (u8 framelen, i16 offset): Static call (relative 16-bit)
          _call(pr[pc++] << 2, fis, fi, s, si, cs, ts, pc);
          fi = 0;
          pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          break;

        case Xops.wcall:
          // wcall (u8 framelen, u32 offset): Static call (absolute 32-bit)
          _call(pr[pc++] << 2, fis, fi, s, si, cs, ts, pc);
          fi = 0;
          pc = pr[pc++] << 24 | pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];
          break;

        case Xops.tailcall:
          // tailcall (u8 framelen, i16 offset): Tail call (relative 16-bit)
          s.last = List.filled(pr[pc++] << 2, null);
          fi = 0;
          pc += (pr[pc++] << 8 | pr[pc++]) - Xops.i16Half;
          break;

        case Xops.wtailcall:
          // wtailcall (u32 offset): Tail call (absolute 32-bit)
          s.last = List.filled(pr[pc++] << 2, null);
          fi = 0;
          pc = pr[pc++] << 24 | pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];
          break;

        case Xops.invoke:
          // invoke (Ix name): Invoke method with name on object in register 0
          final _method = idt[pr[pc++] << 8 | pr[pc++]];
          var object = r0;

          while (true) {
            if (object is $InstanceImpl) {
              final methods = object.evalClass.methods;
              final _offset = methods[_method];
              if (_offset == null) {
                object = object.evalSuperclass;
                continue;
              }
              // TODO get frame length from method
              _call(60, fis, fi, s, si, cs, ts, pc);
              fi = 0;
              pc = _offset;
              return;
            }

            if (_method == 'call' && object is EvalFunctionPtr) {
              args = _checkCallFuncPtr(object, args);
              _call(object.frameLen, fis, fi, s, si, cs, ts, pc);
              fi = 0;
              pc = object.offset;
              return;
            }

            final method = ((object as $Instance).$getProperty(this, _method)
                as EvalFunction);
            try {
              r0 = method.call(this, object, args.cast());
            } catch (e) {
              $throw(e);
            }
            args = [];
            return;
          }

        case Xops.invokex:
          // invokex (u24 id): Invoke external method with ID
          final _args = args;
          final _argsLen = _args.length;
          final id = pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];

          final _mappedArgs = List<$Value?>.filled(_argsLen, null);
          for (var i = 0; i < _argsLen; i++) {
            _mappedArgs[i] = (_args[i] as $Value?);
          }

          args = [];
          final result = _bridgeFunctions[id](this, null, _mappedArgs);
          if (result != null) {
            r0 = result;
          }
          break;

        case Xops.invokex1:
          // invokex1 (u24 id): Invoke external method with 1 argument from r0
          final id = pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];
          final result = _bridgeFunctions[id](this, null, [r0 as $Value?]);
          if (result != null) {
            r0 = result;
          }
          break;

        case Xops.lprop0:
          // lprop0 (Ix name): Load property with name from object in register 0
          final prop = idt[pr[pc++] << 8 | pr[pc++]];
          var base = r0;
          var object = base;
          while (true) {
            if (object is $InstanceImpl) {
              base = object;
              final evalClass = object.evalClass;
              final _offset = evalClass.getters[prop];
              if (_offset == null) {
                final method = evalClass.methods[prop];
                if (method == null) {
                  object = object.evalSuperclass;
                  if (object == null) {
                    r0 = (base as $InstanceImpl).getCoreObjectProperty(prop);
                    return;
                  }
                  continue;
                }
                r0 = EvalStaticFunctionPtr(object, method);
                return;
              }
              r0 = object;
              _call(40, fis, fi, s, si, cs, ts, pc);
              fi = 0;
              pc = _offset;
              return;
            }

            r0 = ((object as $Instance).$getProperty(this, prop));

            args = [];
            return;
          }

        case Xops.lprop1:
          // lprop1 (Ix name): Load property with name from object in register 1
          final prop = idt[pr[pc++] << 8 | pr[pc++]];
          var base = r1;
          var object = base;
          while (true) {
            if (object is $InstanceImpl) {
              base = object;
              final evalClass = object.evalClass;
              final _offset = evalClass.getters[prop];
              if (_offset == null) {
                final method = evalClass.methods[prop];
                if (method == null) {
                  object = object.evalSuperclass;
                  if (object == null) {
                    r0 = (base as $InstanceImpl).getCoreObjectProperty(prop);
                    return;
                  }
                  continue;
                }
                r0 = EvalStaticFunctionPtr(object, method);
                return;
              }
              r0 = object;
              _call(40, fis, fi, s, si, cs, ts, pc);
              fi = 0;
              pc = _offset;
              return;
            }

            r0 = ((object as $Instance).$getProperty(this, prop));

            args = [];
            return;
          }

        case Xops.pop:
          // pop (u8 n): Pop n values from the stack
          fi -= pr[pc++];
          break;

        case Xops.ret:
          // ret: Return from function
          s.removeLast();
          if (s.isNotEmpty) {
            fr = s.last;
            fi = fis.removeLast();
          }
          ts.removeLast();
          if (_inCatch) {
            _catchControlFlowOutcome = 1;
          }
          _inCatch = false;
          final prOffset = cs.removeLast();
          if (prOffset == -1) {
            throw ProgramExit(0);
          }
          pc = prOffset;
          break;

        case Xops.retc:
          // retc: Return from catch block (-2 case)
          final re = _rethrowException;
          if (re != null) {
            $throw(re);
            return;
          }
          if (_catchControlFlowOutcome != 1) {
            return;
          }
          r0 = _returnFromCatch;
          s.removeLast();
          if (s.isNotEmpty) {
            fr = s.last;
            fi = fis.removeLast();
          }
          ts.removeLast();
          if (_inCatch) {
            _catchControlFlowOutcome = 1;
            _inCatch = false;
          }
          final prOffset = cs.removeLast();
          if (prOffset == -1) {
            throw ProgramExit(0);
          }
          pc = prOffset;
          break;

        case Xops.retf:
          // retf: Return to finally block
          s.removeLast();
          if (s.isNotEmpty) {
            fr = s.last;
            fi = fis.removeLast();
          }
          ts.removeLast();
          _inCatch = false;
          final prOffset = cs.removeLast();
          pc = prOffset;
          break;

        case Xops.retasync:
          // retasync (*Sx completer): Return from async function
          final completer = fr[pr[pc++]] as Completer;
          final rv = r0;
          r0 = $Future.wrap(completer.future);
          s.removeLast();
          if (s.isNotEmpty) {
            fr = s.last;
            fi = fis.removeLast();
          }
          ts.removeLast();
          _retSuspend(completer, rv);
          final prOffset = cs.removeLast();
          if (_inCatch) {
            _catchControlFlowOutcome = 1;
            _inCatch = false;
          }
          if (prOffset == -1) {
            throw ProgramExit(0);
          }
          pc = prOffset;
          break;

        case Xops.newlist:
          // newlist (): Create new list in r2
          r2 = [];
          break;

        case Xops.itlen:
          // itlen: Get length of list in r0
          r0 = (r2 as List).length;
          break;

        case Xops.listset:
          // listset: Set list element
          (r2 as List)[r1 as int] = r0;
          break;

        case Xops.listappend:
          // listappend: Append list element
          (r2 as List).add(r0);
          break;

        case Xops.listindex:
          // listindex: Get list element
          r0 = (r2 as List)[r1 as int];
          break;

        case Xops.newmap:
          // newmap (): Create new map in r2
          r2 = {};
          break;

        case Xops.mapset:
          // mapset: Set map element
          (r2 as Map)[r1] = r0;
          break;

        case Xops.mapindex:
          // mapindex: Get map element
          r0 = (r2 as Map)[r1];
          break;

        case Xops.mapremove:
          // mapremove: Remove map element
          (r2 as Map).remove(r1);
          break;

        case Xops.mapcontainskey:
          // mapcontainskey: Check if map contains key
          r0 = (r2 as Map).containsKey(r1);
          break;

        case Xops.newset:
          // newset (): Create new set in r2
          r2 = <dynamic>{};
          break;

        case Xops.setadd:
          // setadd: Add element to set
          (r2 as Set).add(r0);
          break;

        case Xops.setremove:
          // setremove: Remove element from set
          (r2 as Set).remove(r0);
          break;

        case Xops.setcontains:
          // setcontains: Check if set contains element
          r0 = (r2 as Set).contains(r0);
          break;

        case Xops.newfuncptr:
          // newfuncptr (u32 offset, u8 frameLen, u8 argc, Cx pat, Cx sna, Cx snat)
          final offset =
              pr[pc++] << 24 | pr[pc++] << 16 | pr[pc++] << 8 | pr[pc++];
          final frameLen = pr[pc++] << 2;
          final argc = pr[pc++];
          final pat = ct[pr[pc++] << 8 | pr[pc++]];
          final positionalArgTypes = [
            for (final json in pat) RuntimeType.fromJson(json)
          ];
          final sortedNamedArgs = (ct[pr[pc++] << 8 | pr[pc++]] as List);
          final snat = ct[pr[pc++] << 8 | pr[pc++]];
          final sortedNamedArgTypes = [
            for (final json in snat) RuntimeType.fromJson(json)
          ];
          r0 = EvalFunctionPtr(fr, offset, frameLen, argc, positionalArgTypes,
              sortedNamedArgs.cast(), sortedNamedArgTypes);
          break;
      }
    }
  }

  static void _retSuspend(Completer completer, dynamic value) async {
    // create an async gap
    await Future.value(null);

    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  @pragma('vm:prefer-inline')
  void _call(int framelen, List<int> fis, int fi, List<List<Object?>> s, int si,
      List<int> cs, List<List<int>> ts, int pc) {
    fis.add(fi);
    s[si++] = List.filled(framelen, null);
    cs.add(pc);
    ts.add([]);
  }

  @pragma('vm:prefer-inline')
  List _checkCallFuncPtr(EvalFunctionPtr object, List args) {
    final cpat = args[0] as List;
    final cnat = args[2] as List;
    final csPosArgTypes = [for (final a in cpat) _runtimeTypes[a]];
    final csNamedArgs = args[1] as List;
    final csNamedArgTypes = [for (final a in cnat) _runtimeTypes[a]];

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
      final _t = csNamedArgTypes[j];
      final _ti = object.sortedNamedArgTypes[i];
      if (object.sortedNamedArgs[i] == csNamedArgs[j] &&
          _t.isAssignableTo(_ti)) {
        j++;
      }
      i++;
    }

    return [
      if (object.$prev != null) object.$prev,
      for (i = 0; i < object.requiredPositionalArgCount; i++) args[i + 3],
      for (i = object.requiredPositionalArgCount;
          i < totalPositionalArgCount;
          i++)
        if (cp > i) args[i + 3] else null,
      for (i = 0; i < object.sortedNamedArgs.length; i++)
        if (cl > i) args[i + 3 + totalPositionalArgCount] else null
    ];
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
      _rethrowException = exception;
      catchOffset = -catchOffset;
    } else {
      _inCatch = true;
    }
    frameOffset = frameOffsetStack.last;
    returnValue =
        exception is WrappedException ? exception.exception : exception;
    _prOffset = catchOffset;
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
