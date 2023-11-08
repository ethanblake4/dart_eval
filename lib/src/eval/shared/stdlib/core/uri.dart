import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/utils/wap_helper.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Uri]
class $Uri implements $Instance {
  /// Configures the runtime for the [Uri] class
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'Uri.parse', $parse);
    runtime.registerBridgeFunc('dart:core', 'Uri.tryParse', $tryParse);
    runtime.registerBridgeFunc('dart:core', 'Uri.encodeFull', $encodeFull);
    runtime.registerBridgeFunc('dart:core', 'Uri.decodeFull', $decodeFull);
  }

  /// Bridge type spec for [$Uri]
  static const $type = BridgeTypeRef(CoreTypes.uri);

  /// Bridge class declaration for [$Uri]
  static const $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {},
      methods: {
        'parse': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
              BridgeParameter('uri',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
            ], namedParams: []),
            isStatic: true),
        'tryParse': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation($type, nullable: true),
                params: [
                  BridgeParameter(
                      'uri',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
        'encodeFull': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'uri',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
        'decodeFull': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'uri',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
      },
      getters: {
        'scheme': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'authority': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'userInfo': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'host': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'port': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)))),
        'path': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'query': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'fragment': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
        'pathSegments': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list)))),
        'queryParameters': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map)))),
        'queryParametersAll': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map)))),
        'isAbsolute': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasScheme': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasAuthority': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasPort': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasQuery': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasFragment': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasEmptyPath': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'hasAbsolutePath': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)))),
        'origin': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)))),
      },
      setters: {},
      fields: {},
      wrap: true);

  late final $Instance _superclass = $Object($value);

  /// The wrapped [Uri]
  @override
  final Uri $value;

  @override
  Uri get $reified => $value;

  /// Wrap a [Uri] in a [$Uri]
  $Uri.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'scheme':
        return $String($value.scheme);
      case 'authority':
        return $String($value.authority);
      case 'userInfo':
        return $String($value.userInfo);
      case 'host':
        return $String($value.host);
      case 'port':
        return $int($value.port);
      case 'path':
        return $String($value.path);
      case 'query':
        return $String($value.query);
      case 'fragment':
        return $String($value.fragment);
      case 'pathSegments':
        return wrapList($value.pathSegments, (e) => $String(e));
      case 'queryParameters':
        return wrapMap($value.queryParameters,
            (key, value) => MapEntry($String(key), $String(value)));
      case 'queryParametersAll':
        return wrapMap(
            $value.queryParametersAll,
            (key, value) =>
                MapEntry($String(key), wrapList(value, (e) => $String(e))));
      case 'isAbsolute':
        return $bool($value.isAbsolute);
      case 'hasScheme':
        return $bool($value.hasScheme);
      case 'hasAuthority':
        return $bool($value.hasAuthority);
      case 'hasPort':
        return $bool($value.hasPort);
      case 'hasQuery':
        return $bool($value.hasQuery);
      case 'hasFragment':
        return $bool($value.hasFragment);
      case 'hasEmptyPath':
        return $bool($value.hasEmptyPath);
      case 'hasAbsolutePath':
        return $bool($value.hasAbsolutePath);
      case 'origin':
        return $String($value.origin);

      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static $Value? $parse(Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]!.$value as String;
    return $Uri.wrap(Uri.parse(uri));
  }

  static $Value? $tryParse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]!.$value as String;
    final result = Uri.tryParse(uri);
    return result == null ? $null() : $Uri.wrap(result);
  }

  static $Value? $encodeFull(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]!.$value as String;
    return $String(Uri.encodeFull(uri));
  }

  static $Value? $decodeFull(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]!.$value as String;
    return $String(Uri.decodeFull(uri));
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  String toString() => $value.toString();
}
