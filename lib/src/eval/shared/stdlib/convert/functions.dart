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

import 'dart:convert';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Converter,
        $Codec,
        $Encoding,
        $JsonEncoder,
        $JsonDecoder,
        $JsonCodec,
        $AsciiCodec,
        $AsciiEncoder,
        $AsciiDecoder,
        $Utf8Decoder,
        $Utf8Codec,
        $Utf8Encoder,
        $Base64Encoder,
        $Base64Decoder,
        $Base64Codec,
        $ByteConversionSink,
        $ChunkedConversionSink,
        $HtmlEscapeMode,
        $HtmlEscape,
        $StringConversionSink,
        $ClosableStringSink,
        $LineSplitter;

import '../typed_data/typed_data.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// dart_eval function wrapper binding for [base64Encode]
class $base64EncodeFn {
  const $base64EncodeFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'base64Encode',
      $base64EncodeFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:convert',
    'base64Encode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
      namedParams: [],
      params: [
        BridgeParameter(
          'bytes',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = base64Encode(
      (TypedInterop.exportExternal((r as $Value?), runtime: runtime) as List)
          .cast<int>(),
    );
    return $String(result);
  }
}

/// dart_eval function wrapper binding for [base64Decode]
class $base64DecodeFn {
  const $base64DecodeFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'base64Decode',
      $base64DecodeFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:convert',
    'base64Decode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(
        BridgeTypeRef(TypedDataTypes.uint8List, []),
      ),
      namedParams: [],
      params: [
        BridgeParameter(
          'source',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = base64Decode((r as $String).$value);
    return $Uint8List.wrap(result);
  }
}

/// dart_eval function wrapper binding for [jsonEncode]
class $jsonEncodeFn {
  const $jsonEncodeFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'jsonEncode',
      $jsonEncodeFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:convert',
    'jsonEncode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
      namedParams: [
        BridgeParameter(
          'toEncodable',
          BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.object, []),
                  nullable: true,
                ),
                params: [
                  BridgeParameter(
                    'nonEncodable',
                    BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
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
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = jsonEncode(
      TypedInterop.exportExternal((r as $Value?), runtime: runtime) as Object?,
      toEncodable:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (() {
              final _callbackType0 = runtime.internParameterizedType(
                CoreTypes.object,
                [],
                nullable: true,
              );
              return runtime.cachedCallback(
                (s is $Value ? s : null)! as EvalCallable,
                "Object? Function(Object?);export=false" +
                    ";types=$_callbackType0",
                (_callable) => (Object? nonEncodable) {
                  return TypedInterop.exportExternal(
                    _callable.call(
                      runtime,
                      null,
                      TypedInterop.annotateBridgeType(
                        (nonEncodable == null
                            ? const $null()
                            : $Object(nonEncodable)),
                        runtime,
                        _callbackType0,
                      ),
                      null,
                      1,
                    ),
                    runtime: runtime,
                  ) as Object?;
                },
              );
            })(),
    );
    return $String(result);
  }
}

/// dart_eval function wrapper binding for [jsonDecode]
class $jsonDecodeFn {
  const $jsonDecodeFn();

  static void configureForRuntime(Runtime runtime) {
    return runtime.registerBridgeFuncRegisters(
      'dart:convert',
      'jsonDecode',
      $jsonDecodeFn.callRegisters,
    );
  }

  static const $declaration = BridgeFunctionDeclaration(
    'dart:convert',
    'jsonDecode',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
      namedParams: [
        BridgeParameter(
          'reviver',
          BridgeTypeAnnotation(
            BridgeTypeRef.genericFunction(
              BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.object, []),
                  nullable: true,
                ),
                params: [
                  BridgeParameter(
                    'key',
                    BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
                    false,
                  ),

                  BridgeParameter(
                    'value',
                    BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.object, []),
                      nullable: true,
                    ),
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
      params: [
        BridgeParameter(
          'source',
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          false,
        ),
      ],
    ),
  );

  static $Value? callRegisters(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final result = jsonDecode(
      (r as $String).$value,
      reviver:
          (s is $Value ? s : null) == null || (s is $Value ? s : null) is $null
          ? null
          : (() {
              final _callbackType0 = runtime.internParameterizedType(
                CoreTypes.object,
                [],
                nullable: true,
              );
              final _callbackType1 = runtime.internParameterizedType(
                CoreTypes.object,
                [],
                nullable: true,
              );
              return runtime.cachedCallback(
                (s is $Value ? s : null)! as EvalCallable,
                "Object? Function(Object?, Object?);export=false" +
                    ";types=$_callbackType0,$_callbackType1",
                (_callable) => (Object? key, Object? value) {
                  return TypedInterop.exportExternal(
                    _callable.call(
                      runtime,
                      null,
                      TypedInterop.annotateBridgeType(
                        (key == null ? const $null() : $Object(key)),
                        runtime,
                        _callbackType0,
                      ),
                      TypedInterop.annotateBridgeType(
                        (value == null ? const $null() : $Object(value)),
                        runtime,
                        _callbackType1,
                      ),
                      2,
                    ),
                    runtime: runtime,
                  ) as Object?;
                },
              );
            })(),
    );
    return runtime.wrapAlways(result, recursive: true);
  }
}
