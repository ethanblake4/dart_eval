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

import 'dart:typed_data';

import 'package:dart_eval/stdlib/core.dart'
    hide $ByteBuffer, $TypedData, $ByteData, $Uint8List;
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

/// dart_eval wrapper binding for [ByteBuffer]
class $ByteBuffer implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ByteBuffer]
  static const $spec = BridgeTypeSpec('dart:typed_data', 'ByteBuffer');

  /// Compile-time type declaration of [$ByteBuffer]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ByteBuffer]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'asUint8List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asInt8List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asUint8ClampedList': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asUint16List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asInt16List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asUint32List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asInt32List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asUint64List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asInt64List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asInt32x4List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asFloat32List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asFloat64List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asFloat32x4List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asFloat64x2List': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'asByteData': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.byteData, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'lengthInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final ByteBuffer $value;

  @override
  ByteBuffer get $reified => $value;

  /// Wrap a [ByteBuffer] in a [$ByteBuffer]
  $ByteBuffer.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'lengthInBytes':
        final _lengthInBytes = $value.lengthInBytes;
        return $int(_lengthInBytes);
      case 'asUint8List':
        return __asUint8List;

      case 'asInt8List':
        return __asInt8List;

      case 'asUint8ClampedList':
        return __asUint8ClampedList;

      case 'asUint16List':
        return __asUint16List;

      case 'asInt16List':
        return __asInt16List;

      case 'asUint32List':
        return __asUint32List;

      case 'asInt32List':
        return __asInt32List;

      case 'asUint64List':
        return __asUint64List;

      case 'asInt64List':
        return __asInt64List;

      case 'asInt32x4List':
        return __asInt32x4List;

      case 'asFloat32List':
        return __asFloat32List;

      case 'asFloat64List':
        return __asFloat64List;

      case 'asFloat32x4List':
        return __asFloat32x4List;

      case 'asFloat64x2List':
        return __asFloat64x2List;

      case 'asByteData':
        return __asByteData;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __asUint8List = $Function(_asUint8List);
  static $Value? _asUint8List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asUint8List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Uint8List.wrap(result);
  }

  static const $Function __asInt8List = $Function(_asInt8List);
  static $Value? _asInt8List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asInt8List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asUint8ClampedList = $Function(_asUint8ClampedList);
  static $Value? _asUint8ClampedList(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asUint8ClampedList(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asUint16List = $Function(_asUint16List);
  static $Value? _asUint16List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asUint16List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asInt16List = $Function(_asInt16List);
  static $Value? _asInt16List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asInt16List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asUint32List = $Function(_asUint32List);
  static $Value? _asUint32List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asUint32List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asInt32List = $Function(_asInt32List);
  static $Value? _asInt32List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asInt32List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asUint64List = $Function(_asUint64List);
  static $Value? _asUint64List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asUint64List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asInt64List = $Function(_asInt64List);
  static $Value? _asInt64List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asInt64List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asInt32x4List = $Function(_asInt32x4List);
  static $Value? _asInt32x4List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asInt32x4List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asFloat32List = $Function(_asFloat32List);
  static $Value? _asFloat32List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asFloat32List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asFloat64List = $Function(_asFloat64List);
  static $Value? _asFloat64List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asFloat64List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asFloat32x4List = $Function(_asFloat32x4List);
  static $Value? _asFloat32x4List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asFloat32x4List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asFloat64x2List = $Function(_asFloat64x2List);
  static $Value? _asFloat64x2List(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asFloat64x2List(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Object(result);
  }

  static const $Function __asByteData = $Function(_asByteData);
  static $Value? _asByteData(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteBuffer;
    final result = self.$value.asByteData(
      (r is $Value ? r : null) == null ? 0 : (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $ByteData.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [TypedData]
class $TypedData implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$TypedData]
  static const $spec = BridgeTypeSpec('dart:typed_data', 'TypedData');

  /// Compile-time type declaration of [$TypedData]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$TypedData]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {
      'elementSizeInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'offsetInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'lengthInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'buffer': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.byteBuffer, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final TypedData $value;

  @override
  TypedData get $reified => $value;

  /// Wrap a [TypedData] in a [$TypedData]
  $TypedData.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'elementSizeInBytes':
        final _elementSizeInBytes = $value.elementSizeInBytes;
        return $int(_elementSizeInBytes);
      case 'offsetInBytes':
        final _offsetInBytes = $value.offsetInBytes;
        return $int(_offsetInBytes);
      case 'lengthInBytes':
        final _lengthInBytes = $value.lengthInBytes;
        return $int(_lengthInBytes);
      case 'buffer':
        final _buffer = $value.buffer;
        return $ByteBuffer.wrap(_buffer);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [ByteData]
class $ByteData implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'ByteData.',
      $ByteData.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'ByteData.view',
      $ByteData.$view,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'ByteData.sublistView',
      $ByteData.$sublistView,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$ByteData]
  static const $spec = BridgeTypeSpec('dart:typed_data', 'ByteData');

  /// Compile-time type declaration of [$ByteData]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$ByteData]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [BridgeTypeRef(TypedDataTypes.typedData, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'length',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'view': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'buffer',
              BridgeTypeAnnotation(
                BridgeTypeRef(TypedDataTypes.byteBuffer, []),
              ),
              false,
            ),

            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'sublistView': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'data',
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.typedData, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'asUnmodifiableView': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.byteData, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'getInt8': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'setInt8': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'getUint8': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'setUint8': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'getInt16': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setInt16': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getUint16': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setUint16': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getInt32': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setInt32': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getUint32': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setUint32': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getInt64': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setInt64': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getUint64': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setUint64': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getFloat32': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setFloat32': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'getFloat64': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),

      'setFloat64': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double, [])),
              false,
            ),

            BridgeParameter(
              'endian',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'elementSizeInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'offsetInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'lengthInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'buffer': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.byteBuffer, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [ByteData.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ByteData.wrap(ByteData((r as $int).$value));
  }

  /// Wrapper for the [ByteData.view] constructor
  static $Value? $view(Runtime runtime, Object? r, Object? s, Object? c) {
    return $ByteData.wrap(
      ByteData.view(
        (r as $Value?)!.$value,
        (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
        (c is $Value ? c : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [ByteData.sublistView] constructor
  static $Value? $sublistView(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $ByteData.wrap(
      ByteData.sublistView(
        (r as $Value?)!.$value,
        (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
        (c is $Value ? c : null)?.$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final ByteData $value;

  @override
  ByteData get $reified => $value;

  /// Wrap a [ByteData] in a [$ByteData]
  $ByteData.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'elementSizeInBytes':
        final _elementSizeInBytes = $value.elementSizeInBytes;
        return $int(_elementSizeInBytes);
      case 'offsetInBytes':
        final _offsetInBytes = $value.offsetInBytes;
        return $int(_offsetInBytes);
      case 'lengthInBytes':
        final _lengthInBytes = $value.lengthInBytes;
        return $int(_lengthInBytes);
      case 'buffer':
        final _buffer = $value.buffer;
        return $ByteBuffer.wrap(_buffer);
      case 'asUnmodifiableView':
        return __asUnmodifiableView;

      case 'getInt8':
        return __getInt8;

      case 'setInt8':
        return __setInt8;

      case 'getUint8':
        return __getUint8;

      case 'setUint8':
        return __setUint8;

      case 'getInt16':
        return __getInt16;

      case 'setInt16':
        return __setInt16;

      case 'getUint16':
        return __getUint16;

      case 'setUint16':
        return __setUint16;

      case 'getInt32':
        return __getInt32;

      case 'setInt32':
        return __setInt32;

      case 'getUint32':
        return __getUint32;

      case 'setUint32':
        return __setUint32;

      case 'getInt64':
        return __getInt64;

      case 'setInt64':
        return __setInt64;

      case 'getUint64':
        return __getUint64;

      case 'setUint64':
        return __setUint64;

      case 'getFloat32':
        return __getFloat32;

      case 'setFloat32':
        return __setFloat32;

      case 'getFloat64':
        return __getFloat64;

      case 'setFloat64':
        return __setFloat64;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __asUnmodifiableView = $Function(_asUnmodifiableView);
  static $Value? _asUnmodifiableView(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.asUnmodifiableView();
    return $ByteData.wrap(result);
  }

  static const $Function __getInt8 = $Function(_getInt8);
  static $Value? _getInt8(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getInt8((r as $int).$value);
    return $int(result);
  }

  static const $Function __setInt8 = $Function(_setInt8);
  static $Value? _setInt8(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setInt8((r as $int).$value, (s as $int).$value);
    return null;
  }

  static const $Function __getUint8 = $Function(_getUint8);
  static $Value? _getUint8(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getUint8((r as $int).$value);
    return $int(result);
  }

  static const $Function __setUint8 = $Function(_setUint8);
  static $Value? _setUint8(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setUint8((r as $int).$value, (s as $int).$value);
    return null;
  }

  static const $Function __getInt16 = $Function(_getInt16);
  static $Value? _getInt16(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getInt16(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __setInt16 = $Function(_setInt16);
  static $Value? _setInt16(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setInt16(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getUint16 = $Function(_getUint16);
  static $Value? _getUint16(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getUint16(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __setUint16 = $Function(_setUint16);
  static $Value? _setUint16(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setUint16(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getInt32 = $Function(_getInt32);
  static $Value? _getInt32(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getInt32(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __setInt32 = $Function(_setInt32);
  static $Value? _setInt32(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setInt32(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getUint32 = $Function(_getUint32);
  static $Value? _getUint32(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getUint32(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __setUint32 = $Function(_setUint32);
  static $Value? _setUint32(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setUint32(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getInt64 = $Function(_getInt64);
  static $Value? _getInt64(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getInt64(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __setInt64 = $Function(_setInt64);
  static $Value? _setInt64(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setInt64(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getUint64 = $Function(_getUint64);
  static $Value? _getUint64(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getUint64(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __setUint64 = $Function(_setUint64);
  static $Value? _setUint64(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setUint64(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getFloat32 = $Function(_getFloat32);
  static $Value? _getFloat32(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getFloat32(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $double(result);
  }

  static const $Function __setFloat32 = $Function(_setFloat32);
  static $Value? _setFloat32(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setFloat32(
      (r as $int).$value,
      (s as $double).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  static const $Function __getFloat64 = $Function(_getFloat64);
  static $Value? _getFloat64(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    final result = self.$value.getFloat64(
      (r as $int).$value,
      (s is $Value ? s : null) == null
          ? Endian.big
          : (s is $Value ? s : null)?.$value,
    );
    return $double(result);
  }

  static const $Function __setFloat64 = $Function(_setFloat64);
  static $Value? _setFloat64(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $ByteData;
    self.$value.setFloat64(
      (r as $int).$value,
      (s as $double).$value,
      (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? Endian.big
          : (c is List && (c as List).length > 0
                    ? (c as List)[0] as $Value?
                    : null)
                ?.$value,
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper binding for [Uint8List]
class $Uint8List implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'Uint8List.',
      $Uint8List.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'Uint8List.fromList',
      $Uint8List.$fromList,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'Uint8List.view',
      $Uint8List.$view,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'Uint8List.sublistView',
      $Uint8List.$sublistView,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:typed_data',
      'Uint8List.bytesPerElement*g',
      $Uint8List.$bytesPerElement,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Uint8List]
  static const $spec = BridgeTypeSpec('dart:typed_data', 'Uint8List');

  /// Compile-time type declaration of [$Uint8List]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Uint8List]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        ]),
        BridgeTypeRef(TypedDataTypes.typedData, []),
        BridgeTypeRef(CoreTypes.list, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        ]),
        BridgeTypeRef(CoreTypes.iterable, [
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'length',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'fromList': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'elements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'view': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'buffer',
              BridgeTypeAnnotation(
                BridgeTypeRef(TypedDataTypes.byteBuffer, []),
              ),
              false,
            ),

            BridgeParameter(
              'offsetInBytes',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'length',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'sublistView': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'data',
              BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.typedData, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'R': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('R')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'followedBy': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'map': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'toElement',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    params: [
                      BridgeParameter(
                        'e',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'where': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'whereType': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'expand': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'toElements',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                      ]),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'contains': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'forEach': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'action',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.voidType),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'reduce': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'fold': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'T': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
          namedParams: [],
          params: [
            BridgeParameter(
              'initialValue',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),

            BridgeParameter(
              'combine',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                    params: [
                      BridgeParameter(
                        'previousValue',
                        BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
                        false,
                      ),

                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'every': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'join': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'separator',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),
          ],
        ),
      ),

      'any': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'toList': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'growable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [],
        ),
      ),

      'toSet': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.set, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'take': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'takeWhile': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'skip': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'count',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'skipWhile': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'value',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'firstWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'lastWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'singleWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [
            BridgeParameter(
              'orElse',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'elementAt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      '[]=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'addAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'sort': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'compare',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.int, []),
                    ),
                    params: [
                      BridgeParameter(
                        'a',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),

                      BridgeParameter(
                        'b',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'shuffle': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'random',
              BridgeTypeAnnotation(
                BridgeTypeRef(MathTypes.random, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'indexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
      ),

      'indexWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
      ),

      'lastIndexWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'lastIndexOf': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'start',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),

      'insert': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'element',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'insertAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'setAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'remove': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object, []),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),

      'removeAt': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'index',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'removeLast': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'removeWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      'retainWhere': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'test',
              BridgeTypeAnnotation(
                BridgeTypeRef.genericFunction(
                  BridgeFunctionDef(
                    returns: BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.bool, []),
                    ),
                    params: [
                      BridgeParameter(
                        'element',
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                        false,
                      ),
                    ],
                    namedParams: [],
                  ),
                ),
              ),
              false,
            ),
          ],
        ),
      ),

      '+': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'sublist': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'getRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'setRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'iterable',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),

            BridgeParameter(
              'skipCount',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
            ),
          ],
        ),
      ),

      'removeRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'fillRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'fillValue',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),

      'replaceRange': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'start',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'end',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),

            BridgeParameter(
              'replacements',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
                ]),
              ),
              false,
            ),
          ],
        ),
      ),

      'asMap': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'asUnmodifiableView': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.uint8List, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {
      'elementSizeInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'offsetInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'lengthInBytes': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'buffer': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(TypedDataTypes.byteBuffer, []),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'reversed': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterable, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'iterator': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.iterator, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
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

      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'single': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {
      'first': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'last': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),

      'length': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'newLength',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              false,
            ),
          ],
        ),
      ),
    },
    fields: {
      'bytesPerElement': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Uint8List.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uint8List.wrap(Uint8List((r as $int).$value));
  }

  /// Wrapper for the [Uint8List.fromList] constructor
  static $Value? $fromList(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uint8List.wrap(
      Uint8List.fromList(((r as $Value?)!.$reified as List).cast<int>()),
    );
  }

  /// Wrapper for the [Uint8List.view] constructor
  static $Value? $view(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uint8List.wrap(
      Uint8List.view(
        (r as $Value?)!.$value,
        (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
        (c is $Value ? c : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [Uint8List.sublistView] constructor
  static $Value? $sublistView(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $Uint8List.wrap(
      Uint8List.sublistView(
        (r as $Value?)!.$value,
        (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
        (c is $Value ? c : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [Uint8List.bytesPerElement] getter
  static $Value? $bytesPerElement(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uint8List.bytesPerElement;
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final Uint8List $value;

  @override
  Uint8List get $reified => $value;

  /// Wrap a [Uint8List] in a [$Uint8List]
  $Uint8List.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'length':
        final _length = $value.length;
        return $int(_length);
      case 'iterator':
        final _iterator = $value.iterator;
        return $Iterator.wrap(_iterator);
      case 'isEmpty':
        final _isEmpty = $value.isEmpty;
        return $bool(_isEmpty);
      case 'isNotEmpty':
        final _isNotEmpty = $value.isNotEmpty;
        return $bool(_isNotEmpty);
      case 'first':
        final _first = $value.first;
        return $int(_first);
      case 'last':
        final _last = $value.last;
        return $int(_last);
      case 'single':
        final _single = $value.single;
        return $int(_single);
      case 'reversed':
        final _reversed = $value.reversed;
        return $Iterable.wrap((_reversed).map((e) => $int(e)));
      case 'elementSizeInBytes':
        final _elementSizeInBytes = $value.elementSizeInBytes;
        return $int(_elementSizeInBytes);
      case 'offsetInBytes':
        final _offsetInBytes = $value.offsetInBytes;
        return $int(_offsetInBytes);
      case 'lengthInBytes':
        final _lengthInBytes = $value.lengthInBytes;
        return $int(_lengthInBytes);
      case 'buffer':
        final _buffer = $value.buffer;
        return $ByteBuffer.wrap(_buffer);
      case 'cast':
        return __cast;

      case 'followedBy':
        return __followedBy;

      case 'map':
        return __map;

      case 'where':
        return __where;

      case 'whereType':
        return __whereType;

      case 'expand':
        return __expand;

      case 'contains':
        return __contains;

      case 'forEach':
        return __forEach;

      case 'reduce':
        return __reduce;

      case 'fold':
        return __fold;

      case 'every':
        return __every;

      case 'join':
        return __join;

      case 'any':
        return __any;

      case 'toList':
        return __toList;

      case 'toSet':
        return __toSet;

      case 'take':
        return __take;

      case 'takeWhile':
        return __takeWhile;

      case 'skip':
        return __skip;

      case 'skipWhile':
        return __skipWhile;

      case 'firstWhere':
        return __firstWhere;

      case 'lastWhere':
        return __lastWhere;

      case 'singleWhere':
        return __singleWhere;

      case 'elementAt':
        return __elementAt;

      case '[]':
        return __operatorIndexGet;

      case '[]=':
        return __operatorIndexSet;

      case 'add':
        return __add;

      case 'addAll':
        return __addAll;

      case 'sort':
        return __sort;

      case 'shuffle':
        return __shuffle;

      case 'indexOf':
        return __indexOf;

      case 'indexWhere':
        return __indexWhere;

      case 'lastIndexWhere':
        return __lastIndexWhere;

      case 'lastIndexOf':
        return __lastIndexOf;

      case 'clear':
        return __clear;

      case 'insert':
        return __insert;

      case 'insertAll':
        return __insertAll;

      case 'setAll':
        return __setAll;

      case 'remove':
        return __remove;

      case 'removeAt':
        return __removeAt;

      case 'removeLast':
        return __removeLast;

      case 'removeWhere':
        return __removeWhere;

      case 'retainWhere':
        return __retainWhere;

      case '+':
        return __operatorPlus;

      case 'sublist':
        return __sublist;

      case 'getRange':
        return __getRange;

      case 'setRange':
        return __setRange;

      case 'removeRange':
        return __removeRange;

      case 'fillRange':
        return __fillRange;

      case 'replaceRange':
        return __replaceRange;

      case 'asMap':
        return __asMap;

      case 'asUnmodifiableView':
        return __asUnmodifiableView;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.cast();
    return $List.view(result, (e) => runtime.wrapAlways(e, recursive: true));
  }

  static const $Function __followedBy = $Function(_followedBy);
  static $Value? _followedBy(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.followedBy((r as $Value?)!.$value);
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __map = $Function(_map);
  static $Value? _map(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.map((int e) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(e),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __where = $Function(_where);
  static $Value? _where(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.where((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __whereType = $Function(_whereType);
  static $Value? _whereType(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.whereType();
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __expand = $Function(_expand);
  static $Value? _expand(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.expand((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap(
      (result).map((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __contains = $Function(_contains);
  static $Value? _contains(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.contains((r as $Value?)!.$reified);
    return $bool(result);
  }

  static const $Function __forEach = $Function(_forEach);
  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.forEach((int element) {
      ((r as $Value?)! as EvalCallable)(runtime, null, $int(element), null, 1);
    });
    return null;
  }

  static const $Function __reduce = $Function(_reduce);
  static $Value? _reduce(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.reduce((int value, int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(value),
        $int(element),
        2,
      )?.$value;
    });
    return $int(result);
  }

  static const $Function __fold = $Function(_fold);
  static $Value? _fold(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.fold((r as $Value?)!.$value, (
      dynamic previousValue,
      int element,
    ) {
      return ((s as $Value?)! as EvalCallable)(
        runtime,
        null,
        runtime.wrapAlways(previousValue, recursive: true),
        $int(element),
        2,
      )?.$value;
    });
    return runtime.wrapAlways(result, recursive: true);
  }

  static const $Function __every = $Function(_every);
  static $Value? _every(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.every((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    });
    return $bool(result);
  }

  static const $Function __join = $Function(_join);
  static $Value? _join(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.join(
      (r is $Value ? r : null) == null ? "" : (r as $String).$value,
    );
    return $String(result);
  }

  static const $Function __any = $Function(_any);
  static $Value? _any(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.any((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    });
    return $bool(result);
  }

  static const $Function __toList = $Function(_toList);
  static $Value? _toList(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.toList(
      growable: (r is $Value ? r : null) == null ? true : (r as $bool).$value,
    );
    return $List.view(result, (e) => $int(e));
  }

  static const $Function __toSet = $Function(_toSet);
  static $Value? _toSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.toSet();
    return $Set.wrap((result).map((e) => $int(e)).toSet());
  }

  static const $Function __take = $Function(_take);
  static $Value? _take(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.take((r as $int).$value);
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __takeWhile = $Function(_takeWhile);
  static $Value? _takeWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.takeWhile((int value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(value),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __skip = $Function(_skip);
  static $Value? _skip(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.skip((r as $int).$value);
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __skipWhile = $Function(_skipWhile);
  static $Value? _skipWhile(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.skipWhile((int value) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(value),
        null,
        1,
      )?.$value;
    });
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __firstWhere = $Function(_firstWhere);
  static $Value? _firstWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.firstWhere(
      (int element) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          $int(element),
          null,
          1,
        )?.$value;
      },
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : () {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return $int(result);
  }

  static const $Function __lastWhere = $Function(_lastWhere);
  static $Value? _lastWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.lastWhere(
      (int element) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          $int(element),
          null,
          1,
        )?.$value;
      },
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : () {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return $int(result);
  }

  static const $Function __singleWhere = $Function(_singleWhere);
  static $Value? _singleWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.singleWhere(
      (int element) {
        return ((r as $Value?)! as EvalCallable)(
          runtime,
          null,
          $int(element),
          null,
          1,
        )?.$value;
      },
      orElse:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : () {
              return ((s is $Value ? s : null)! as EvalCallable?)
                  ?.call(runtime, null, null, null, 0)
                  ?.$value;
            },
    );
    return $int(result);
  }

  static const $Function __elementAt = $Function(_elementAt);
  static $Value? _elementAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.elementAt((r as $int).$value);
    return $int(result);
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value[(r as $int).$value];
    return $int(result);
  }

  static const $Function __operatorIndexSet = $Function(_operatorIndexSet);
  static $Value? _operatorIndexSet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value[(r as $int).$value] = (s as $int).$value;
    return null;
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.add((r as $int).$value);
    return null;
  }

  static const $Function __addAll = $Function(_addAll);
  static $Value? _addAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.addAll((r as $Value?)!.$value);
    return null;
  }

  static const $Function __sort = $Function(_sort);
  static $Value? _sort(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.sort(
      (r is $Value ? r : null) == null || (r is $Value ? r : null) is $null
          ? null
          : (int a, int b) {
              return ((r is $Value ? r : null)! as EvalCallable?)
                  ?.call(runtime, null, $int(a), $int(b), 2)
                  ?.$value;
            },
    );
    return null;
  }

  static const $Function __shuffle = $Function(_shuffle);
  static $Value? _shuffle(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.shuffle((r is $Value ? r : null)?.$value);
    return null;
  }

  static const $Function __indexOf = $Function(_indexOf);
  static $Value? _indexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.indexOf(
      (r as $int).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
    );
    return $int(result);
  }

  static const $Function __indexWhere = $Function(_indexWhere);
  static $Value? _indexWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.indexWhere((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    }, (s is $Value ? s : null) == null ? 0 : (s as $int).$value);
    return $int(result);
  }

  static const $Function __lastIndexWhere = $Function(_lastIndexWhere);
  static $Value? _lastIndexWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.lastIndexWhere((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    }, (s is $Value ? s : null)?.$value);
    return $int(result);
  }

  static const $Function __lastIndexOf = $Function(_lastIndexOf);
  static $Value? _lastIndexOf(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.lastIndexOf(
      (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $int(result);
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.clear();
    return null;
  }

  static const $Function __insert = $Function(_insert);
  static $Value? _insert(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.insert((r as $int).$value, (s as $int).$value);
    return null;
  }

  static const $Function __insertAll = $Function(_insertAll);
  static $Value? _insertAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.insertAll((r as $int).$value, (s as $Value?)!.$value);
    return null;
  }

  static const $Function __setAll = $Function(_setAll);
  static $Value? _setAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.setAll((r as $int).$value, (s as $Value?)!.$value);
    return null;
  }

  static const $Function __remove = $Function(_remove);
  static $Value? _remove(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.remove((r as $Value?)!.$reified);
    return $bool(result);
  }

  static const $Function __removeAt = $Function(_removeAt);
  static $Value? _removeAt(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.removeAt((r as $int).$value);
    return $int(result);
  }

  static const $Function __removeLast = $Function(_removeLast);
  static $Value? _removeLast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.removeLast();
    return $int(result);
  }

  static const $Function __removeWhere = $Function(_removeWhere);
  static $Value? _removeWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.removeWhere((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    });
    return null;
  }

  static const $Function __retainWhere = $Function(_retainWhere);
  static $Value? _retainWhere(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.retainWhere((int element) {
      return ((r as $Value?)! as EvalCallable)(
        runtime,
        null,
        $int(element),
        null,
        1,
      )?.$value;
    });
    return null;
  }

  static const $Function __operatorPlus = $Function(_operatorPlus);
  static $Value? _operatorPlus(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result =
        (self.$value + ((r as $Value?)!.$reified as List).cast<int>());
    return $List.view(result, (e) => $int(e));
  }

  static const $Function __sublist = $Function(_sublist);
  static $Value? _sublist(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.sublist(
      (r as $int).$value,
      (s is $Value ? s : null)?.$value,
    );
    return $Uint8List.wrap(result);
  }

  static const $Function __getRange = $Function(_getRange);
  static $Value? _getRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.getRange((r as $int).$value, (s as $int).$value);
    return $Iterable.wrap((result).map((e) => $int(e)));
  }

  static const $Function __setRange = $Function(_setRange);
  static $Value? _setRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.setRange(
      (r as $int).$value,
      (s as $int).$value,
      ((c as List<Object?>)[0] as $Value?)!.$value,
      (c is List && (c as List).length > 1
                  ? (c as List)[1] as $Value?
                  : null) ==
              null
          ? 0
          : ((c is List && (c as List).length > 1 ? (c as List)[1] : null)
                    as $int)
                .$value,
    );
    return null;
  }

  static const $Function __removeRange = $Function(_removeRange);
  static $Value? _removeRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.removeRange((r as $int).$value, (s as $int).$value);
    return null;
  }

  static const $Function __fillRange = $Function(_fillRange);
  static $Value? _fillRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.fillRange(
      (r as $int).$value,
      (s as $int).$value,
      (c is List && (c as List).length > 0 ? (c as List)[0] as $Value? : null)
          ?.$value,
    );
    return null;
  }

  static const $Function __replaceRange = $Function(_replaceRange);
  static $Value? _replaceRange(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    self.$value.replaceRange(
      (r as $int).$value,
      (s as $int).$value,
      ((c as List<Object?>)[0] as $Value?)!.$value,
    );
    return null;
  }

  static const $Function __asMap = $Function(_asMap);
  static $Value? _asMap(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.asMap();
    return wrapMap(result, (key, value) => MapEntry($int(key), $int(value)));
  }

  static const $Function __asUnmodifiableView = $Function(_asUnmodifiableView);
  static $Value? _asUnmodifiableView(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uint8List;
    final result = self.$value.asUnmodifiableView();
    return $Uint8List.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'first':
        $value.first = value.$reified;
        return;
      case 'last':
        $value.last = value.$reified;
        return;
      case 'length':
        $value.length = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
