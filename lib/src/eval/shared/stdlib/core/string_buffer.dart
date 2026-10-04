// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $BigInt,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Runes,
        $RuneIterator,
        $Expando,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $pragma,
        $Error,
        $StackOverflowError,
        $OutOfMemoryError,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink,
        $Enum;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// dart_eval bridge binding for [StringBuffer]
class $StringBuffer$bridge extends StringBuffer with $Bridge<StringBuffer> {
  /// Forwarded constructor for [StringBuffer.new]
  $StringBuffer$bridge([super.content]);

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'StringBuffer.',
      $StringBuffer$bridge.$new,
      isBridge: true,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StringBuffer$bridge]
  static const $spec = BridgeTypeSpec('dart:core', 'StringBuffer');

  /// Compile-time type declaration of [$StringBuffer$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StringBuffer]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [BridgeTypeRef(CoreTypes.stringSink, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'content',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
              defaultValueSource: "\"\"",
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'write': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'object',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'writeAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'objects',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'separator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "\"\"",
            ),
          ],
        ),
      ),

      'writeln': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'obj',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              true,
              defaultValueSource: "\"\"",
            ),
          ],
        ),
      ),

      'writeCharCode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'charCode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'isNotEmpty': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [StringBuffer.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StringBuffer$bridge(
      (r is $Value ? r : null) == null
          ? ""
          : TypedInterop.exportExternal(
              (r is $Value ? r : null),
              runtime: runtime,
            ) as Object,
    );
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'length':
        final _length = super.length;
        return $int(_length);

      case 'isEmpty':
        final _isEmpty = super.isEmpty;
        return $bool(_isEmpty);

      case 'isNotEmpty':
        final _isNotEmpty = super.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'write':
        return $Function((runtime, target, r, s, c) {
          super.write(
            TypedInterop.exportExternal((r as $Value?), runtime: runtime)
                as Object?,
          );
          return null;
        });
      case 'writeAll':
        return $Function((runtime, target, r, s, c) {
          super.writeAll(
            TypedInterop.exportIterable((r as $Value?), runtime),
            (s is $Value ? s : null) == null ? "" : (s as $String).$value,
          );
          return null;
        });
      case 'writeln':
        return $Function((runtime, target, r, s, c) {
          super.writeln(
            (r is $Value ? r : null) == null
                ? ""
                : TypedInterop.exportExternal(
                    (r is $Value ? r : null),
                    runtime: runtime,
                  ) as Object?,
          );
          return null;
        });
      case 'writeCharCode':
        return $Function((runtime, target, r, s, c) {
          super.writeCharCode((r as $int).$value);
          return null;
        });
      case 'toString':
        return $Function((runtime, target, r, s, c) {
          final result = super.toString();
          return $String(result);
        });
      case 'clear':
        return $Function((runtime, target, r, s, c) {
          super.clear();
          return null;
        });
    }
    return null;
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

  @override
  int get length => Runtime.bridgeData[this]?.subclass == null
      ? super.length
      : $_get('length');

  @override
  bool get isEmpty => Runtime.bridgeData[this]?.subclass == null
      ? super.isEmpty
      : $_get('isEmpty');

  @override
  bool get isNotEmpty => Runtime.bridgeData[this]?.subclass == null
      ? super.isNotEmpty
      : $_get('isNotEmpty');

  @override
  void write(Object? object) {
    if (Runtime.bridgeData[this]?.subclass == null) {
      super.write(object);
      return;
    }
    final runtime = $runtime;
    $_invoke('write', [
      (object is List || object is Map || object is Set
          ? TypedInterop.boxExternal(object, runtime: runtime)!
          : runtime.wrapAlways(object)),
    ]);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    if (Runtime.bridgeData[this]?.subclass == null) {
      super.writeAll(objects, separator);
      return;
    }
    final runtime = $runtime;
    $_invoke('writeAll', [
      $Iterable.wrap(
        (objects).map((e) => runtime.wrapAlways(e, recursive: true)),
      ),
      $String(separator),
    ]);
  }

  @override
  void writeln([Object? obj = ""]) {
    if (Runtime.bridgeData[this]?.subclass == null) {
      super.writeln(obj);
      return;
    }
    final runtime = $runtime;
    $_invoke('writeln', [
      (obj is List || obj is Map || obj is Set
          ? TypedInterop.boxExternal(obj, runtime: runtime)!
          : runtime.wrapAlways(obj)),
    ]);
  }

  @override
  void writeCharCode(int charCode) {
    if (Runtime.bridgeData[this]?.subclass == null) {
      super.writeCharCode(charCode);
      return;
    }
    final runtime = $runtime;
    $_invoke('writeCharCode', [$int(charCode)]);
  }

  @override
  String toString() {
    if (Runtime.bridgeData[this]?.subclass == null) {
      return super.toString();
    }
    final runtime = $runtime;
    return $_invoke('toString', []);
  }

  @override
  void clear() {
    if (Runtime.bridgeData[this]?.subclass == null) {
      super.clear();
      return;
    }
    final runtime = $runtime;
    $_invoke('clear', []);
  }
}

/// dart_eval lightweight wrapper binding for [StringBuffer]
class $StringBuffer implements $Instance {
  /// Compile-time type specification of [$StringBuffer]
  static const $spec = BridgeTypeSpec('dart:core', 'StringBuffer');

  /// Compile-time type declaration of [$StringBuffer]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final StringBuffer $value;

  @override
  StringBuffer get $reified => $value;

  /// Wrap a [StringBuffer] in a [$StringBuffer]
  $StringBuffer.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        final _length = $value.length;
        return $int(_length);
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $bool(_isEmpty);
      case 'isNotEmpty':
        final _isNotEmpty = $value.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'write':
        return $Closure(__write.func, this);

      case 'writeAll':
        return $Closure(__writeAll.func, this);

      case 'writeln':
        return $Closure(__writeln.func, this);

      case 'writeCharCode':
        return $Closure(__writeCharCode.func, this);

      case 'toString':
        return $Closure(__toString.func, this);

      case 'clear':
        return $Closure(__clear.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __write = $Function(_write);
  static $Value? _write(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.write(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
    );
    return null;
  }

  static const $Function __writeAll = $Function(_writeAll);
  static $Value? _writeAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.writeAll(
      TypedInterop.exportIterable((r as $Value?), runtime),
      (s is $Value ? s : null) == null ? "" : (s as $String).$value,
    );
    return null;
  }

  static const $Function __writeln = $Function(_writeln);
  static $Value? _writeln(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.writeln(
      (r is $Value ? r : null) == null
          ? ""
          : TypedInterop.exportExternal(
              (r is $Value ? r : null),
              runtime: runtime,
            ) as Object?,
    );
    return null;
  }

  static const $Function __writeCharCode = $Function(_writeCharCode);
  static $Value? _writeCharCode(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.writeCharCode((r as $int).$value);
    return null;
  }

  static const $Function __toString = $Function(_toString);
  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    final result = self.$value.toString();
    return $String(result);
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StringBuffer;
    self.$value.clear();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
