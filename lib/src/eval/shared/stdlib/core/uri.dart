import 'dart:convert';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Uri]
class $Uri implements $Instance {
  /// Configures the runtime for the [Uri] class
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'Uri.parse', $parse);
    runtime.registerBridgeFunc('dart:core', 'Uri.tryParse', $tryParse);
    runtime.registerBridgeFunc('dart:core', 'Uri.encodeFull', $encodeFull);
    runtime.registerBridgeFunc('dart:core', 'Uri.decodeFull', $decodeFull);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.encodeComponent', $encodeComponent);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.decodeComponent', $decodeComponent);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.decodeQueryComponent', $decodeQueryComponent);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.encodeQueryComponent', $encodeQueryComponent);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.dataFromBytes', $dataFromBytes);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.dataFromString', $dataFromString);
    runtime.registerBridgeFunc('dart:core', 'Uri.directory', $directory);
    runtime.registerBridgeFunc('dart:core', 'Uri.file', $file);
    runtime.registerBridgeFunc('dart:core', 'Uri.http', $http);
    runtime.registerBridgeFunc('dart:core', 'Uri.https', $https);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.parseIPv4Address', $parseIPv4Address);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.parseIPv6Address', $parseIPv6Address);
    runtime.registerBridgeFunc(
        'dart:core', 'Uri.splitQueryString', $splitQueryString);
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
        'encodeComponent': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'component',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
        'decodeComponent': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'encodedComponent',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false)
                ],
                namedParams: []),
            isStatic: true),
        'decodeQueryComponent': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'encodedComponent',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: [
                  BridgeParameter(
                      'encoding',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(ConvertTypes.encoding)),
                      true)
                ]),
            isStatic: true),
        'encodeQueryComponent': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'component',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: [
                  BridgeParameter(
                      'encoding',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(ConvertTypes.encoding)),
                      true)
                ]),
            isStatic: true),
        'dataFromBytes': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'bytes',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list, [
                        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))
                      ])),
                      false),
                ],
                namedParams: [
                  BridgeParameter(
                      'mimeType',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      true),
                  BridgeParameter(
                      'parameters',
                      BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.map, [
                          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))
                        ]),
                      ),
                      true),
                  BridgeParameter(
                      'percentEncoded',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
                      true),
                ]),
            isStatic: true),
        'dataFromString': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'content',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: [
                  BridgeParameter(
                      'mimeType',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      true),
                  BridgeParameter(
                      'parameters',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.map, [
                            BridgeTypeAnnotation(
                                BridgeTypeRef(CoreTypes.string)),
                            BridgeTypeAnnotation(
                                BridgeTypeRef(CoreTypes.string))
                          ]),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'base64',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
                      true),
                ]),
            isStatic: true),
        'directory': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'path',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: [
                  BridgeParameter('windows',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true)
                ]),
            isStatic: true),
        'file': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'path',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: [
                  BridgeParameter('windows',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true)
                ]),
            isStatic: true),
        'http': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'authority',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                  BridgeParameter(
                      'unencodedPath',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      true),
                  BridgeParameter(
                      'queryParameters',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.map, [
                            BridgeTypeAnnotation(
                                BridgeTypeRef(CoreTypes.string)),
                            BridgeTypeAnnotation(
                                BridgeTypeRef(CoreTypes.dynamic))
                          ]),
                          nullable: true),
                      true),
                ],
                namedParams: []),
            isStatic: true),
        'https': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                params: [
                  BridgeParameter(
                      'authority',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                  BridgeParameter(
                      'unencodedPath',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      true),
                  BridgeParameter(
                      'queryParameters',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.map, [
                            BridgeTypeAnnotation(
                                BridgeTypeRef(CoreTypes.string)),
                            BridgeTypeAnnotation(
                                BridgeTypeRef(CoreTypes.dynamic))
                          ]),
                          nullable: true),
                      true),
                ],
                namedParams: []),
            isStatic: true),
        'parseIPv4Address': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                    [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
                params: [
                  BridgeParameter(
                      'host',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: []),
            isStatic: true),
        'parseIPv6Address': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                    [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
                params: [
                  BridgeParameter(
                      'host',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                  BridgeParameter(
                      'start',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      true),
                  BridgeParameter(
                      'end',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                          nullable: true),
                      true),
                ],
                namedParams: []),
            isStatic: true),
        'splitQueryString': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))
                ])),
                params: [
                  BridgeParameter(
                      'query',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: [
                  BridgeParameter(
                      'encoding',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(ConvertTypes.encoding)),
                      true)
                ]),
            isStatic: true),
        'resolve': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
                params: [
                  BridgeParameter(
                      'reference',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
                ],
                namedParams: []),
            isStatic: true),
        'normalizePath': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
                params: [],
                namedParams: []),
            isStatic: true),
        'removeFragment': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
                params: [],
                namedParams: []),
            isStatic: true),
        'resolveUri': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
                params: [
                  BridgeParameter(
                      'reference',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                      false),
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
        return wrapList<String>($value.pathSegments, (e) => $String(e));
      case 'queryParameters':
        return wrapMap<String, String>($value.queryParameters,
            (key, value) => MapEntry($String(key), $String(value)));
      case 'queryParametersAll':
        return wrapMap<String, List<String>>(
            $value.queryParametersAll,
            (key, value) => MapEntry(
                $String(key), wrapList<String>(value, (e) => $String(e))));
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
      case 'resolve':
        return __resolve;
      case 'normalizePath':
        return __normalizePath;
      case 'removeFragment':
        return __removeFragment;
      case 'resolveUri':
        return __resolveUri;

      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function __resolve = $Function(_resolve);
  static $Value? _resolve(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $Uri.wrap((target as $Uri).$value.resolve(args[0]!.$value));
  }

  static const $Function __normalizePath = $Function(_normalizePath);
  static $Value? _normalizePath(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $Uri.wrap((target as $Uri).$value.normalizePath());
  }

  static const $Function __removeFragment = $Function(_removeFragment);
  static $Value? _removeFragment(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $Uri.wrap((target as $Uri).$value.removeFragment());
  }

  static const $Function __resolveUri = $Function(_resolveUri);
  static $Value? _resolveUri(
      final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $Uri.wrap((target as $Uri).$value.resolveUri(args[0]!.$value));
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

  static $Value? $encodeComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(Uri.encodeComponent(args[0]!.$value));
  }

  static $Value? $decodeComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(Uri.decodeComponent(args[0]!.$value));
  }

  static $Value? $decodeQueryComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(Uri.decodeQueryComponent(args[0]!.$value,
        encoding: (args[1]?.$value as Encoding?) ?? utf8));
  }

  static $Value? $encodeQueryComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(Uri.encodeQueryComponent(args[0]!.$value,
        encoding: (args[1]?.$value as Encoding?) ?? utf8));
  }

  static $Value? $dataFromBytes(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final bytes = (args[0]!.$value as List)
        .map((e) => (e is $Value ? e.$reified : e) as int)
        .toList();
    final parameters = (args[2]?.$value as Map?)?.map((key, value) =>
        MapEntry(key.$reified.toString(), value.$reified.toString()));
    return $Uri.wrap(Uri.dataFromBytes(bytes,
        mimeType: args[1]?.$value ?? "application/octet-stream",
        parameters: parameters,
        percentEncoded: args[3]?.$value ?? false));
  }

  static $Value? $dataFromString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final parameters = (args[2]?.$value as Map?)?.map((key, value) =>
        MapEntry(key.$reified.toString(), value.$reified.toString()));
    return $Uri.wrap(Uri.dataFromString(args[0]!.$value,
        mimeType: args[1]?.$value ?? "application/octet-stream",
        parameters: parameters,
        base64: args[3]?.$value ?? false));
  }

  static $Value? $directory(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Uri.wrap(Uri.directory(args[0]!.$value,
        windows: (args[1]?.$value as bool?) ?? false));
  }

  static $Value? $file(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Uri.wrap(Uri.file(args[0]!.$value,
        windows: (args[1]?.$value as bool?) ?? false));
  }

  static $Value? $http(Runtime runtime, $Value? target, List<$Value?> args) {
    final queryParameters = (args[2]?.$value as Map?)?.map(
        (key, value) => MapEntry(key.$reified.toString(), value.$reified));
    return $Uri.wrap(
        Uri.http(args[0]!.$value, args[1]?.$value ?? "", queryParameters));
  }

  static $Value? $https(Runtime runtime, $Value? target, List<$Value?> args) {
    final queryParameters = (args[2]?.$value as Map?)?.map(
        (key, value) => MapEntry(key.$reified.toString(), value.$reified));
    return $Uri.wrap(
        Uri.https(args[0]!.$value, args[1]?.$value ?? "", queryParameters));
  }

  static $Value? $parseIPv4Address(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap(
        Uri.parseIPv4Address(args[0]!.$value).map((e) => $int(e)).toList());
  }

  static $Value? $parseIPv6Address(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $List.wrap(Uri.parseIPv6Address(
            args[0]!.$value, args[1]?.$value ?? 0, args[2]?.$value)
        .map((e) => $int(e))
        .toList());
  }

  static $Value? $splitQueryString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return wrapMap<String, String>(
        Uri.splitQueryString(args[0]!.$value,
            encoding: (args[1]?.$value as Encoding?) ?? utf8),
        (key, value) => MapEntry($String(key), $String(value)));
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  String toString() => $value.toString();
}
