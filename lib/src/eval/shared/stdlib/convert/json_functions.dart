// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';


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
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object), nullable: true),
          false,
        ),
      ],
      namedParams: [
        BridgeParameter(
          'toEncodable',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.function),
            nullable: true,
          ),
          true,
        ),
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
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          false,
        ),
      ],
      namedParams: [
        BridgeParameter(
          'reviver',
          BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.function),
            nullable: true,
          ),
          true,
        ),
      ],
    ),
  );

  static const __$jsonEncode = $Function(_$encode);
  static $Value? _$encode(Runtime runtime, $Value? target, List<$Value?> args) {
    final toEncodable = args[1]?.$value as EvalCallable?;
    return $String(
      jsonEncode(
        args[0]?.$reified,
        toEncodable: toEncodable == null
            ? null
            : (object) {
                return toEncodable.call(runtime, null, [
                  runtime.wrapPrimitive(object) ?? object as $Value?,
                ])?.$value;
              },
      ),
    );
  }

  static const __$jsonDecode = $Function(_$decode);
  static $Value? _$decode(Runtime runtime, $Value? target, List<$Value?> args) {
    final reviver = args[1]?.$value as EvalCallable?;
    return runtime.wrap(
      jsonDecode(
        args[0]?.$value,
        reviver: reviver == null
            ? null
            : (key, value) {
                return reviver.call(runtime, null, [
                  runtime.wrapPrimitive(key) ?? key as $Value?,
                  runtime.wrapPrimitive(value) ?? value as $Value?,
                ])?.$value;
              },
      ),
      recursive: true,
    );
  }
}
