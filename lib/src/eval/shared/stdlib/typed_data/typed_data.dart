import 'dart:typed_data';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [ByteBuffer]
class $ByteBuffer implements $Instance {
  /// Compile-time class definition for [$ByteBuffer]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(TypedDataTypes.byteBuffer)),
      constructors: {},
      methods: {
        'asUint8List': BridgeMethodDef(BridgeFunctionDef(
            params: [
              BridgeParameter('offsetInBytes',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true),
              BridgeParameter(
                  'length',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int),
                      nullable: true),
                  true)
            ],
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List)))),
      },
      getters: {
        'lengthInBytes': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
      },
      wrap: true);

  final $Instance _superclass;

  /// Wrap a [ByteBuffer] in a [$ByteBuffer]
  $ByteBuffer.wrap(this.$value) : _superclass = $Object($value);

  @override
  final ByteBuffer $value;

  @override
  ByteBuffer get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(TypedDataTypes.byteBuffer);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'asUint8List':
        return __asUint8List;
      case 'lengthInBytes':
        return $int($value.lengthInBytes);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __asUint8List = $Function(_asUint8List);

  static $Value? _asUint8List(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteBuffer;
    return $Uint8List.wrap(
        self.$value.asUint8List(args[0]?.$value ?? 0, args[1]?.$value as int?));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper for [TypedData]
class $TypedData implements $Instance {
  /// Compile-time class definition for [$TypedData]
  static const $declaration =
      BridgeClassDef(BridgeClassType(BridgeTypeRef(TypedDataTypes.typedData)),
          constructors: {},
          methods: {},
          getters: {
            'lengthInBytes': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
            'elementSizeInBytes': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
            'offsetInBytes': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
            'buffer': BridgeMethodDef(BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.byteBuffer)))),
          },
          wrap: true);

  final $Instance _superclass;

  /// Wrap a [TypedData] in a [$TypedData]
  $TypedData.wrap(this.$value) : _superclass = $Object($value);

  @override
  final TypedData $value;

  @override
  TypedData get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(TypedDataTypes.typedData);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'lengthInBytes':
        return $int($value.lengthInBytes);
      case 'elementSizeInBytes':
        return $int($value.elementSizeInBytes);
      case 'offsetInBytes':
        return $int($value.offsetInBytes);
      case 'buffer':
        return $ByteBuffer.wrap($value.buffer);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper for [ByteData]
class $ByteData implements $Instance {
  /// Compile-time class definition for [$ByteData]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(TypedDataTypes.byteData), $implements: [
        BridgeTypeRef(TypedDataTypes.typedData),
      ]),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.byteData)),
                params: [
                  BridgeParameter('length',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
                ]),
            isFactory: true),
        'view': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.byteData)),
                params: [
                  BridgeParameter(
                      'buffer',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.byteBuffer)),
                      false),
                  BridgeParameter(
                      'offsetInBytes',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
                      false),
                  BridgeParameter('length',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
                ]),
            isFactory: true),
      },
      methods: {
        'getInt8': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getUint8': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getInt16': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getUint16': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getInt32': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getUint32': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getInt64': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getUint64': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'getFloat32': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)))),
        'getFloat64': BridgeMethodDef(BridgeFunctionDef(params: [
          BridgeParameter('byteOffset',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
        ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)))),
        'setInt8': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setUint8': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setInt16': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setUint16': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setInt32': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setUint32': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setInt64': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setUint64': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setFloat32': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
        'setFloat64': BridgeMethodDef(BridgeFunctionDef(
          params: [
            BridgeParameter('byteOffset',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
            BridgeParameter('value',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.double)), false)
          ],
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
        )),
      },
      getters: {},
      wrap: true);

  final $Instance _superclass;

  /// Wrap a [ByteData] in a [$ByteData]
  $ByteData.wrap(this.$value) : _superclass = $TypedData.wrap($value);

  /// Create a new [$ByteData] wrapping [ByteData.new]
  static $ByteData $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $ByteData.wrap(ByteData(args[0]?.$value as int));
  }

  /// Create a new [$ByteData] wrapping [ByteData.view]
  static $ByteData $view(Runtime runtime, $Value? target, List<$Value?> args) {
    return $ByteData.wrap(ByteData.view(args[0]?.$value as ByteBuffer,
        args[1]?.$value as int, args[2]?.$value as int));
  }

  @override
  final ByteData $value;

  @override
  ByteData get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(TypedDataTypes.byteData);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'getInt8':
        return __getInt8;
      case 'getUint8':
        return __getUint8;
      case 'getInt16':
        return __getInt16;
      case 'getUint16':
        return __getUint16;
      case 'getInt32':
        return __getInt32;
      case 'getUint32':
        return __getUint32;
      case 'getInt64':
        return __getInt64;
      case 'getUint64':
        return __getUint64;
      case 'getFloat32':
        return __getFloat32;
      case 'getFloat64':
        return __getFloat64;
      case 'setInt8':
        return __setInt8;
      case 'setUint8':
        return __setUint8;
      case 'setInt16':
        return __setInt16;
      case 'setUint16':
        return __setUint16;
      case 'setInt32':
        return __setInt32;
      case 'setUint32':
        return __setUint32;
      case 'setInt64':
        return __setInt64;
      case 'setUint64':
        return __setUint64;
      case 'setFloat32':
        return __setFloat32;
      case 'setFloat64':
        return __setFloat64;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __getInt8 = $Function(_getInt8);

  static $Value? _getInt8(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getInt8(args[0]!.$value as int));
  }

  static const $Function __getUint8 = $Function(_getUint8);

  static $Value? _getUint8(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getUint8(args[0]!.$value as int));
  }

  static const $Function __getInt16 = $Function(_getInt16);

  static $Value? _getInt16(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getInt16(args[0]!.$value as int));
  }

  static const $Function __getUint16 = $Function(_getUint16);

  static $Value? _getUint16(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getUint16(args[0]!.$value as int));
  }

  static const $Function __getInt32 = $Function(_getInt32);

  static $Value? _getInt32(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getInt32(args[0]!.$value as int));
  }

  static const $Function __getUint32 = $Function(_getUint32);

  static $Value? _getUint32(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getUint32(args[0]!.$value as int));
  }

  static const $Function __getInt64 = $Function(_getInt64);

  static $Value? _getInt64(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getInt64(args[0]!.$value as int));
  }

  static const $Function __getUint64 = $Function(_getUint64);

  static $Value? _getUint64(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $int(self.$value.getUint64(args[0]!.$value as int));
  }

  static const $Function __getFloat32 = $Function(_getFloat32);

  static $Value? _getFloat32(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $double(self.$value.getFloat32(args[0]!.$value as int));
  }

  static const $Function __getFloat64 = $Function(_getFloat64);

  static $Value? _getFloat64(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    return $double(self.$value.getFloat64(args[0]!.$value as int));
  }

  static const $Function __setInt8 = $Function(_setInt8);

  static $Value? _setInt8(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setInt8(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setUint8 = $Function(_setUint8);

  static $Value? _setUint8(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setUint8(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setInt16 = $Function(_setInt16);

  static $Value? _setInt16(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setInt16(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setUint16 = $Function(_setUint16);

  static $Value? _setUint16(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setUint16(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setInt32 = $Function(_setInt32);

  static $Value? _setInt32(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setInt32(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setUint32 = $Function(_setUint32);

  static $Value? _setUint32(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setUint32(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setInt64 = $Function(_setInt64);

  static $Value? _setInt64(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setInt64(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setUint64 = $Function(_setUint64);

  static $Value? _setUint64(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setUint64(args[0]!.$value as int, args[1]!.$value as int);
    return null;
  }

  static const $Function __setFloat32 = $Function(_setFloat32);

  static $Value? _setFloat32(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setFloat32(args[0]!.$value as int, args[1]!.$value as double);
    return null;
  }

  static const $Function __setFloat64 = $Function(_setFloat64);

  static $Value? _setFloat64(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $ByteData;
    self.$value.setFloat64(args[0]!.$value as int, args[1]!.$value as double);
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper for [Uint8List]
class $Uint8List implements $Instance {
  /// Compile-time class definition for [$AssertionError]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(TypedDataTypes.uint8List), $implements: [
        BridgeTypeRef(TypedDataTypes.typedData),
        BridgeTypeRef(CoreTypes.list,
            [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])
      ]),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List)),
                params: [
                  BridgeParameter('length',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
                ]),
            isFactory: true),
        'fromList': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List)),
                params: [
                  BridgeParameter(
                      'elements',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)),
                      false)
                ]),
            isFactory: true),
        'view': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List)),
                params: [
                  BridgeParameter(
                      'buffer',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.byteBuffer)),
                      false),
                  BridgeParameter(
                      'offsetInBytes',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
                      false),
                  BridgeParameter('length',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false)
                ]),
            isFactory: true),
        'sublistView': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List)),
                params: [
                  BridgeParameter(
                      'data',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(TypedDataTypes.typedData)),
                      false),
                  BridgeParameter(
                      'start',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
                      false),
                  BridgeParameter('end',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true)
                ]),
            isFactory: true),
      },
      methods: {
        'sublist': BridgeMethodDef(BridgeFunctionDef(
            params: [
              BridgeParameter('start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), false),
              BridgeParameter('end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)), true)
            ],
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(TypedDataTypes.uint8List)))),
      },
      getters: {},
      wrap: true);

  final $Instance _implements1;
  final $Instance _implements2;

  /// Wrap a [Uint8List] in a [$Uint8List]
  $Uint8List.wrap(this.$value)
      : _implements1 = $List.wrap($value),
        _implements2 = $TypedData.wrap($value);

  /// Create a new [$Uint8List] wrapping [Uint8List.new]
  static $Uint8List $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Uint8List.wrap(Uint8List(args[0]?.$value));
  }

  /// Create a new [$Uint8List] wrapping [Uint8List.fromList]
  static $Uint8List $fromList(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final list = (args[0]!.$reified as List).cast<int>();
    return $Uint8List.wrap(Uint8List.fromList(list));
  }

  /// Create a new [$Uint8List] wrapping [Uint8List.view]
  static $Uint8List $view(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Uint8List.wrap(Uint8List.view(
        args[0]?.$value, args[1]?.$value, args[2]?.$value as int?));
  }

  /// Create a new [$Uint8List] wrapping [Uint8List.sublistView]
  static $Uint8List $sublistView(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Uint8List.wrap(Uint8List.sublistView(
        args[0]?.$value, args[1]?.$value, args[2]?.$value as int?));
  }

  @override
  final Uint8List $value;

  @override
  Uint8List get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(TypedDataTypes.uint8List);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'sublist':
        return __sublist;
    }
    try {
      return _implements1.$getProperty(runtime, identifier);
    } on UnimplementedError catch (_) {
      return _implements2.$getProperty(runtime, identifier);
    }
  }

  static const $Function __sublist = $Function(_sublist);
  static $Value? _sublist(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $Uint8List;
    return $Uint8List.wrap(
        self.$value.sublist(args[0]!.$value as int, args[1]?.$value as int?));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    try {
      return _implements1.$setProperty(runtime, identifier, value);
    } on UnimplementedError catch (_) {
      return _implements2.$setProperty(runtime, identifier, value);
    }
  }
}
