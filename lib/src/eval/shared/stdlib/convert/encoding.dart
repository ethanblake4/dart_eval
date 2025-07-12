// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'encoding.dart';
import 'dart:convert';
import 'package:dart_eval/stdlib/convert.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/async.dart';

/// dart_eval wrapper binding for [Encoding]
class $Encoding implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        'dart:convert', 'Encoding.getByName', $Encoding.$getByName);
  }

  /// Compile-time type specification of [$Encoding]
  static const $spec = ConvertTypes.encoding;

  /// Compile-time type declaration of [$Encoding]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Encoding]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      $extends: BridgeTypeRef(ConvertTypes.codec, [
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
            [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []))]))
      ]),
    ),
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
      'decodeStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []))])),
          namedParams: [],
          params: [
            BridgeParameter(
              'byteStream',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream, [
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                    [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []))]))
              ])),
              false,
            ),
          ],
        ),
      ),
      'getByName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
              BridgeTypeRef(BridgeTypeSpec('dart:convert', 'Encoding'), []),
              nullable: true),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                  nullable: true),
              false,
            ),
          ],
        ),
        isStatic: true,
      ),
    },
    getters: {
      'encoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []))]))
          ])),
          namedParams: [],
          params: [],
        ),
      ),
      'decoder': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.converter, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []))])),
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []))
          ])),
          namedParams: [],
          params: [],
        ),
      ),
      'name': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
  );

  /// Wrapper for the [Encoding.getByName] method
  static $Value? $getByName(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = Encoding.getByName(args[0]!.$value);
    return value == null ? $null() : $Encoding.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Encoding $value;

  @override
  Encoding get $reified => $value;

  /// Wrap a [Encoding] in a [$Encoding]
  $Encoding.wrap(this.$value) : _superclass = $Codec.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'encoder':
        final _encoder = $value.encoder;
        return $Converter.wrap(_encoder);

      case 'decoder':
        final _decoder = $value.decoder;
        return $Converter.wrap(_decoder);

      case 'name':
        final _name = $value.name;
        return $String(_name);
      case 'decodeStream':
        return __decodeStream;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __decodeStream = $Function(_decodeStream);
  static $Value? _decodeStream(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $Encoding;
    final result = self.$value.decodeStream(args[0]!.$value);
    return $Future.wrap(result.then((e) => $String(e)));
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
