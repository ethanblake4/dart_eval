import 'dart:convert';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/codec.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert/converter.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';

/// dart_eval wrapper for [JsonDecoder]
class $JsonDecoder implements $Instance {
  /// Compile-time bridge type reference for [$JsonDecoder]
  static const $type = BridgeTypeRef(ConvertTypes.jsonDecoder);

  /// Compile-time bridge class declaration for [$JsonDecoder]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
          ])),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('reviver',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)), true)
        ]))
      },
      methods: {},
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Utf8Decoder] in a [$Utf8Decoder].
  $JsonDecoder.wrap(this.$value);

  static $JsonDecoder $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final reviver = args[0]?.$value as EvalCallable?;
    return $JsonDecoder.wrap(JsonDecoder(reviver == null
        ? null
        : (key, value) {
            return reviver.call(runtime, null, [
              runtime.wrapPrimitive(key) ?? key as $Value?,
              runtime.wrapPrimitive(value) ?? value as $Value?
            ])?.$value;
          }));
  }

  late final $Instance _superclass = $Converter.wrap($value);

  @override
  final JsonDecoder $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        return _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [JsonEncoder]
class $JsonEncoder implements $Instance {
  /// Compile-time bridge type reference for [$JsonEncoder]
  static const $type = BridgeTypeRef(ConvertTypes.jsonEncoder);

  /// Compile-time bridge class declaration for [$JsonEncoder]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          ])),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('toEncodable',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)), true)
        ]))
      },
      methods: {},
      getters: {},
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Utf8Encoder] in a [$Utf8Encoder].
  $JsonEncoder.wrap(this.$value);

  static $JsonEncoder $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final toEncodable = args[0]?.$value as EvalCallable?;
    return $JsonEncoder.wrap(JsonEncoder(toEncodable == null
        ? null
        : (object) {
            return toEncodable.call(runtime, null,
                [runtime.wrapPrimitive(object) ?? object as $Value?])?.$value;
          }));
  }

  late final $Instance _superclass = $Converter.wrap($value);

  @override
  final JsonEncoder $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        return _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}

/// dart_eval wrapper for [JsonCodec]
class $JsonCodec implements $Instance {
  /// Compile-time bridge type reference for [$JsonCodec]
  static const $type = BridgeTypeRef(ConvertTypes.jsonCodec);

  /// Compile-time bridge class declaration for [$JsonCodec]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, $extends: BridgeTypeRef(ConvertTypes.encoding)),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [],
            namedParams: [
              BridgeParameter('reviver',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)), true)
            ]))
      },
      methods: {},
      getters: {
        'decoder': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.jsonDecoder)))),
        'encoder': BridgeMethodDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.jsonEncoder)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  /// Wrap a [Utf8Codec] in a [$Utf8Codec].
  $JsonCodec.wrap(this.$value);

  static $JsonCodec $new(Runtime runtime, $Value? target, List<$Value?> args) {
    final reviver = args[0]?.$value as EvalCallable?;
    return $JsonCodec.wrap(JsonCodec(
        reviver: reviver == null
            ? null
            : (key, value) {
                return reviver.call(runtime, null, [
                  runtime.wrapPrimitive(key) ?? key as $Value?,
                  runtime.wrapPrimitive(value) ?? value as $Value?
                ])?.$value;
              }));
  }

  late final $Instance _superclass = $Codec.wrap($value);

  @override
  final JsonCodec $value;

  @override
  get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'decoder':
        return $JsonDecoder.wrap($value.decoder);
      case 'encoder':
        return $JsonEncoder.wrap($value.encoder);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        return _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(ConvertTypes.jsonCodec);
}

class $JsonEncodeAndDecode {
  static const _library = 'dart:convert';

  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeTopLevelFunction(_$jsonEncode);
    registry.defineBridgeTopLevelFunction(_$jsonDecode);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(_library, 'jsonEncode', __$jsonEncode.call);
    runtime.registerBridgeFunc(_library, 'jsonDecode', __$jsonDecode.call);
  }

  static const _$jsonEncode = BridgeFunctionDeclaration(
    _library,
    'jsonEncode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(
        BridgeTypeRef(CoreTypes.string),
        nullable: false,
      ),
      params: [
        BridgeParameter(
          'object',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object),
            nullable: true,
          ),
          false,
        )
      ],
      namedParams: [
        BridgeParameter(
          'toEncodable',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.function),
            nullable: true,
          ),
          true,
        )
      ],
    ),
  );

  static const _$jsonDecode = BridgeFunctionDeclaration(
    _library,
    'jsonDecode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(
        BridgeTypeRef(CoreTypes.dynamic),
        nullable: true,
      ),
      params: [
        BridgeParameter(
          'source',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string),
          ),
          false,
        )
      ],
      namedParams: [
        BridgeParameter(
          'reviver',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.function),
            nullable: true,
          ),
          true,
        )
      ],
    ),
  );

  static const __$jsonEncode = $Function(_$encode);
  static $Value? _$encode(Runtime runtime, $Value? target, List<$Value?> args) {
    final toEncodable = args[1]?.$value as EvalCallable?;
    return $String(jsonEncode(args[0]?.$reified,
        toEncodable: toEncodable == null
            ? null
            : (object) {
                return toEncodable.call(runtime, null, [
                  runtime.wrapPrimitive(object) ?? object as $Value?
                ])?.$value;
              }));
  }

  static const __$jsonDecode = $Function(_$decode);
  static $Value? _$decode(Runtime runtime, $Value? target, List<$Value?> args) {
    final reviver = args[1]?.$value as EvalCallable?;
    return runtime.wrap(
        jsonDecode(args[0]?.$value,
            reviver: reviver == null
                ? null
                : (key, value) {
                    return reviver.call(runtime, null, [
                      runtime.wrapPrimitive(key) ?? key as $Value?,
                      runtime.wrapPrimitive(value) ?? value as $Value?
                    ])?.$value;
                  }),
        recursive: true);
  }
}
