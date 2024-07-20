import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/typed_data.dart';

/// dart_eval wrapper for [Uri]
class $Uri implements $Instance {
  /// Configure the [$Uri] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.', __$Uri$new.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.http', __$Uri$http.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.https', __$Uri$https.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.file', __$Uri$file.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.directory', __$Uri$directory.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.dataFromString', __$Uri$dataFromString.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.dataFromBytes', __$Uri$dataFromBytes.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.base*g', __$static$getter$base.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.parse', __$static$method$parse.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.tryParse', __$static$method$tryParse.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.encodeComponent',
        __$static$method$encodeComponent.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.encodeQueryComponent',
        __$static$method$encodeQueryComponent.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.decodeComponent',
        __$static$method$decodeComponent.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.decodeQueryComponent',
        __$static$method$decodeQueryComponent.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.encodeFull', __$static$method$encodeFull.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'Uri.decodeFull', __$static$method$decodeFull.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.splitQueryString',
        __$static$method$splitQueryString.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.parseIPv4Address',
        __$static$method$parseIPv4Address.call,
        isBridge: false);
    runtime.registerBridgeFunc($type.spec!.library, 'Uri.parseIPv6Address',
        __$static$method$parseIPv6Address.call,
        isBridge: false);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(CoreTypes.uri);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: null,
      $implements: [],
      isAbstract: true,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          namedParams: [
            BridgeParameter(
                'scheme',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'userInfo',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'host',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'port',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                    nullable: true),
                true),
            BridgeParameter(
                'path',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'pathSegments',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.iterable, [
                      BridgeTypeRef(CoreTypes.string, []),
                    ]),
                    nullable: true),
                true),
            BridgeParameter(
                'query',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'queryParameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.dynamic, []),
                    ]),
                    nullable: true),
                true),
            BridgeParameter(
                'fragment',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true)
          ],
        ),
        isFactory: true,
      ),
      'http': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'authority',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false),
            BridgeParameter(
                'unencodedPath',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                true),
            BridgeParameter(
                'queryParameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.dynamic, []),
                    ]),
                    nullable: true),
                true)
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'https': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'authority',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false),
            BridgeParameter(
                'unencodedPath',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                true),
            BridgeParameter(
                'queryParameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.dynamic, []),
                    ]),
                    nullable: true),
                true)
          ],
          namedParams: [],
        ),
        isFactory: true,
      ),
      'file': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'path',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'windows',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: true),
                true)
          ],
        ),
        isFactory: true,
      ),
      'directory': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'path',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'windows',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: true),
                true)
          ],
        ),
        isFactory: true,
      ),
      'dataFromString': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'content',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'mimeType',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'encoding',
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                    nullable: true),
                true),
            BridgeParameter(
                'parameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.string, []),
                    ]),
                    nullable: true),
                true),
            BridgeParameter(
                'base64',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: false),
                true)
          ],
        ),
        isFactory: true,
      ),
      'dataFromBytes': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'bytes',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.list, [
                      BridgeTypeRef(CoreTypes.int, []),
                    ]),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'mimeType',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                true),
            BridgeParameter(
                'parameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.string, []),
                    ]),
                    nullable: true),
                true),
            BridgeParameter(
                'percentEncoded',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: false),
                true)
          ],
        ),
        isFactory: true,
      )
    },
    fields: {},
    methods: {
      'parse': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'uri',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  true),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'tryParse': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: true),
            params: [
              BridgeParameter(
                  'uri',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  true),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'encodeComponent': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'component',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'encodeQueryComponent': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'component',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'encoding',
                  BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: true),
      'decodeComponent': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'encodedComponent',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'decodeQueryComponent': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'encodedComponent',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'encoding',
                  BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: true),
      'encodeFull': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'uri',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'decodeFull': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'uri',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'splitQueryString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeRef(CoreTypes.string, []),
                  BridgeTypeRef(CoreTypes.string, []),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'query',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'encoding',
                  BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: true),
      'parseIPv4Address': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeRef(CoreTypes.int, []),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'host',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'parseIPv6Address': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeRef(CoreTypes.int, []),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'host',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: false),
                  true),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'isScheme': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'scheme',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'toFilePath': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [
              BridgeParameter(
                  'windows',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                      nullable: true),
                  true)
            ],
          ),
          isStatic: false),
      'replace': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [],
            namedParams: [
              BridgeParameter(
                  'scheme',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: true),
                  true),
              BridgeParameter(
                  'userInfo',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: true),
                  true),
              BridgeParameter(
                  'host',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: true),
                  true),
              BridgeParameter(
                  'port',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                      nullable: true),
                  true),
              BridgeParameter(
                  'path',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: true),
                  true),
              BridgeParameter(
                  'pathSegments',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.iterable, [
                        BridgeTypeRef(CoreTypes.string, []),
                      ]),
                      nullable: true),
                  true),
              BridgeParameter(
                  'query',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: true),
                  true),
              BridgeParameter(
                  'queryParameters',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(CoreTypes.map, [
                        BridgeTypeRef(CoreTypes.string, []),
                        BridgeTypeRef(CoreTypes.dynamic, []),
                      ]),
                      nullable: true),
                  true),
              BridgeParameter(
                  'fragment',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: true),
                  true)
            ],
          ),
          isStatic: false),
      'removeFragment': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'resolve': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'reference',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'resolveUri': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'reference',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'normalizePath': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {
      'base': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'scheme': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'authority': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'userInfo': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'host': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'port': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'path': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'query': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'fragment': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'pathSegments': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeRef(CoreTypes.string, []),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'queryParameters': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeRef(CoreTypes.string, []),
                  BridgeTypeRef(CoreTypes.string, []),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'queryParametersAll': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeRef(CoreTypes.string, []),
                  BridgeTypeRef(CoreTypes.list, [
                    BridgeTypeRef(CoreTypes.string, []),
                  ]),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isAbsolute': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasScheme': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasAuthority': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasPort': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasQuery': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasFragment': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasEmptyPath': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hasAbsolutePath': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'origin': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'data': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uriData, []),
                nullable: true),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'hashCode': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [Uri] in an [$Uri]
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
        return $List.wrap(List.generate($value.pathSegments.length, (index) {
          return $String($value.pathSegments[index]);
        }));
      case 'queryParameters':
        return $Map.wrap($value.queryParameters.map((key, value) {
          return $MapEntry.wrap(MapEntry(
            key is $Value ? key : $String(key),
            value is $Value ? value : $String(value),
          ));
        }));
      case 'queryParametersAll':
        return $Map.wrap($value.queryParametersAll.map((key, value) {
          return $MapEntry.wrap(MapEntry(
            key is $Value ? key : $String(key),
            value is $Value
                ? value
                : $List.wrap(List.generate(value.length, (index) {
                    return $String(value[index]);
                  })),
          ));
        }));
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
      case 'data':
        return $value.data == null ? $null() : $UriData.wrap($value.data!);
      case 'hashCode':
        return $int($value.hashCode);
      case 'isScheme':
        return __$isScheme;
      case 'toFilePath':
        return __$toFilePath;
      case 'replace':
        return __$replace;
      case 'removeFragment':
        return __$removeFragment;
      case 'resolve':
        return __$resolve;
      case 'resolveUri':
        return __$resolveUri;
      case 'normalizePath':
        return __$normalizePath;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  Uri get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final Uri $value;

  static const __$static$getter$base = $Function(_$static$getter$base);
  static $Value? _$static$getter$base(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Uri.wrap(Uri.base);
  }

  static const __$isScheme = $Function(_$isScheme);
  static $Value? _$isScheme(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final scheme = args[0]?.$value as String;
    final $result = $this.isScheme(scheme);
    return $bool($result);
  }

  static const __$toFilePath = $Function(_$toFilePath);
  static $Value? _$toFilePath(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final windows = args[0]?.$value as bool?;
    final $result = $this.toFilePath(windows: windows);
    return $String($result);
  }

  static const __$replace = $Function(_$replace);
  static $Value? _$replace(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final scheme = args[0]?.$value as String?;
    final userInfo = args[1]?.$value as String?;
    final host = args[2]?.$value as String?;
    final port = args[3]?.$value as int?;
    final path = args[4]?.$value as String?;
    final pathSegments = (args[5]?.$reified as Iterable?)?.cast<String>();
    final query = args[6]?.$value as String?;
    final queryParameters =
        (args[7]?.$reified as Map?)?.cast<String, dynamic>();
    final fragment = args[8]?.$value as String?;
    final $result = $this.replace(
      scheme: scheme,
      userInfo: userInfo,
      host: host,
      port: port,
      path: path,
      pathSegments: pathSegments,
      query: query,
      queryParameters: queryParameters,
      fragment: fragment,
    );
    return $Uri.wrap($result);
  }

  static const __$removeFragment = $Function(_$removeFragment);
  static $Value? _$removeFragment(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final $result = $this.removeFragment();
    return $Uri.wrap($result);
  }

  static const __$resolve = $Function(_$resolve);
  static $Value? _$resolve(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final reference = args[0]?.$value as String;
    final $result = $this.resolve(reference);
    return $Uri.wrap($result);
  }

  static const __$resolveUri = $Function(_$resolveUri);
  static $Value? _$resolveUri(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final reference = args[0]?.$value as Uri;
    final $result = $this.resolveUri(reference);
    return $Uri.wrap($result);
  }

  static const __$normalizePath = $Function(_$normalizePath);
  static $Value? _$normalizePath(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as Uri;
    final $result = $this.normalizePath();
    return $Uri.wrap($result);
  }

  static const __$static$method$parse = $Function(_$static$method$parse);
  static $Value? _$static$method$parse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]?.$value as String;
    final start = args[1]?.$value as int? ?? 0;
    final end = args[2]?.$value as int?;
    final $result = Uri.parse(uri, start, end);
    return $Uri.wrap($result);
  }

  static const __$static$method$tryParse = $Function(_$static$method$tryParse);
  static $Value? _$static$method$tryParse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]?.$value as String;
    final start = args[1]?.$value as int? ?? 0;
    final end = args[2]?.$value as int?;
    final $result = Uri.tryParse(uri, start, end);
    return $result == null ? $null() : $Uri.wrap($result);
  }

  static const __$static$method$encodeComponent =
      $Function(_$static$method$encodeComponent);
  static $Value? _$static$method$encodeComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final component = args[0]?.$value as String;
    final $result = Uri.encodeComponent(component);
    return $String($result);
  }

  static const __$static$method$encodeQueryComponent =
      $Function(_$static$method$encodeQueryComponent);
  static $Value? _$static$method$encodeQueryComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final component = args[0]?.$value as String;
    final encoding = args[1]?.$value as Encoding? ?? utf8;
    final $result = Uri.encodeQueryComponent(component, encoding: encoding);
    return $String($result);
  }

  static const __$static$method$decodeComponent =
      $Function(_$static$method$decodeComponent);
  static $Value? _$static$method$decodeComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final encodedComponent = args[0]?.$value as String;
    final $result = Uri.decodeComponent(encodedComponent);
    return $String($result);
  }

  static const __$static$method$decodeQueryComponent =
      $Function(_$static$method$decodeQueryComponent);
  static $Value? _$static$method$decodeQueryComponent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final encodedComponent = args[0]?.$value as String;
    final encoding = args[1]?.$value as Encoding? ?? utf8;
    final $result =
        Uri.decodeQueryComponent(encodedComponent, encoding: encoding);
    return $String($result);
  }

  static const __$static$method$encodeFull =
      $Function(_$static$method$encodeFull);
  static $Value? _$static$method$encodeFull(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]?.$value as String;
    final $result = Uri.encodeFull(uri);
    return $String($result);
  }

  static const __$static$method$decodeFull =
      $Function(_$static$method$decodeFull);
  static $Value? _$static$method$decodeFull(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]?.$value as String;
    final $result = Uri.decodeFull(uri);
    return $String($result);
  }

  static const __$static$method$splitQueryString =
      $Function(_$static$method$splitQueryString);
  static $Value? _$static$method$splitQueryString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final query = args[0]?.$value as String;
    final encoding = args[1]?.$value as Encoding? ?? utf8;
    final $result = Uri.splitQueryString(
      query,
      encoding: encoding,
    );
    return $Map.wrap($result.map((key, value) {
      return $MapEntry.wrap(MapEntry(
        key is $Value ? key : $String(key),
        value is $Value ? value : $String(value),
      ));
    }));
  }

  static const __$static$method$parseIPv4Address =
      $Function(_$static$method$parseIPv4Address);
  static $Value? _$static$method$parseIPv4Address(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final host = args[0]?.$value as String;
    final $result = Uri.parseIPv4Address(host);
    return $List.wrap(List.generate($result.length, (index) {
      return $int($result[index]);
    }));
  }

  static const __$static$method$parseIPv6Address =
      $Function(_$static$method$parseIPv6Address);
  static $Value? _$static$method$parseIPv6Address(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final host = args[0]?.$value as String;
    final start = args[1]?.$value as int? ?? 0;
    final end = args[2]?.$value as int?;
    final $result = Uri.parseIPv6Address(host, start, end);
    return $List.wrap(List.generate($result.length, (index) {
      return $int($result[index]);
    }));
  }

  static const __$Uri$new = $Function(_$Uri$new);
  static $Value? _$Uri$new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final scheme = args[0]?.$value as String?;
    final userInfo = args[1]?.$value as String?;
    final host = args[2]?.$value as String?;
    final port = args[3]?.$value as int?;
    final path = args[4]?.$value as String?;
    final pathSegments = (args[5]?.$reified as Iterable?)?.cast<String>();
    final query = args[6]?.$value as String?;
    final queryParameters =
        (args[7]?.$reified as Map?)?.cast<String, dynamic>();
    final fragment = args[8]?.$value as String?;
    return $Uri.wrap(Uri(
      scheme: scheme,
      userInfo: userInfo,
      host: host,
      port: port,
      path: path,
      pathSegments: pathSegments,
      query: query,
      queryParameters: queryParameters,
      fragment: fragment,
    ));
  }

  static const __$Uri$http = $Function(_$Uri$http);
  static $Value? _$Uri$http(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final authority = args[0]?.$value as String;
    final unencodedPath = args[1]?.$value as String;
    final queryParameters =
        (args[2]?.$reified as Map?)?.cast<String, dynamic>();
    return $Uri.wrap(Uri.http(
      authority,
      unencodedPath,
      queryParameters,
    ));
  }

  static const __$Uri$https = $Function(_$Uri$https);
  static $Value? _$Uri$https(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final authority = args[0]?.$value as String;
    final unencodedPath = args[1]?.$value as String;
    final queryParameters =
        (args[2]?.$reified as Map?)?.cast<String, dynamic>();
    return $Uri.wrap(Uri.https(
      authority,
      unencodedPath,
      queryParameters,
    ));
  }

  static const __$Uri$file = $Function(_$Uri$file);
  static $Value? _$Uri$file(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final path = args[0]?.$value as String;
    final windows = args[1]?.$value as bool?;
    return $Uri.wrap(Uri.file(path, windows: windows));
  }

  static const __$Uri$directory = $Function(_$Uri$directory);
  static $Value? _$Uri$directory(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final path = args[0]?.$value as String;
    final windows = args[1]?.$value as bool?;
    return $Uri.wrap(Uri.directory(path, windows: windows));
  }

  static const __$Uri$dataFromString = $Function(_$Uri$dataFromString);
  static $Value? _$Uri$dataFromString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final content = args[0]?.$value as String;
    final mimeType = args[1]?.$value as String?;
    final encoding = args[2]?.$value as Encoding?;
    final parameters = (args[3]?.$reified as Map?)?.cast<String, String>();
    final base64 = (args[4]?.$value as bool?) ?? false;
    return $Uri.wrap(Uri.dataFromString(
      content,
      mimeType: mimeType,
      encoding: encoding,
      parameters: parameters,
      base64: base64,
    ));
  }

  static const __$Uri$dataFromBytes = $Function(_$Uri$dataFromBytes);
  static $Value? _$Uri$dataFromBytes(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final bytes = (args[0]?.$reified as List).cast<int>();
    final mimeType = args[1]?.$value as String? ?? "application/octet-stream";
    final parameters = (args[2]?.$reified as Map?)?.cast<String, String>();
    final percentEncoded = (args[3]?.$value as bool?) ?? false;
    return $Uri.wrap(Uri.dataFromBytes(
      bytes,
      mimeType: mimeType,
      parameters: parameters,
      percentEncoded: percentEncoded,
    ));
  }
}

/// dart_eval wrapper for [UriData]
class $UriData implements UriData, $Instance {
  /// Configure the [$UriData] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'UriData.fromString', __$UriData$fromString.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'UriData.fromBytes', __$UriData$fromBytes.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'UriData.fromUri', __$UriData$fromUri.call,
        isBridge: false);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'UriData.parse', __$static$method$parse.call,
        isBridge: false);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(CoreTypes.uriData);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: null,
      $implements: [],
      isAbstract: false,
    ),
    constructors: {
      'fromString': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'content',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'mimeType',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true),
            BridgeParameter(
                'encoding',
                BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                    nullable: true),
                true),
            BridgeParameter(
                'parameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.string, []),
                    ]),
                    nullable: true),
                true),
            BridgeParameter(
                'base64',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: false),
                true)
          ],
        ),
        isFactory: true,
      ),
      'fromBytes': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'bytes',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.list, [
                      BridgeTypeRef(CoreTypes.int, []),
                    ]),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'mimeType',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                true),
            BridgeParameter(
                'parameters',
                BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.map, [
                      BridgeTypeRef(CoreTypes.string, []),
                      BridgeTypeRef(CoreTypes.string, []),
                    ]),
                    nullable: true),
                true),
            BridgeParameter(
                'percentEncoded',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                    nullable: false),
                true)
          ],
        ),
        isFactory: true,
      ),
      'fromUri': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'uri',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                    nullable: false),
                false)
          ],
          namedParams: [],
        ),
        isFactory: true,
      )
    },
    fields: {},
    methods: {
      'parse': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uriData, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'uri',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'isMimeType': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'mimeType',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'isCharset': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'charset',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'isEncoding': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'encoding',
                  BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: false),
      'contentAsBytes': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(TypedDataTypes.uint8List, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'contentAsString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [
              BridgeParameter(
                  'encoding',
                  BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, []),
                      nullable: true),
                  true)
            ],
          ),
          isStatic: false),
      'toString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {
      'uri': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'mimeType': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'charset': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isBase64': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'contentText': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'parameters': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeRef(CoreTypes.string, []),
                  BridgeTypeRef(CoreTypes.string, []),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [UriData] in an [$UriData]
  $UriData.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'uri':
        return $Uri.wrap($value.uri);
      case 'mimeType':
        return $String($value.mimeType);
      case 'charset':
        return $String($value.charset);
      case 'isBase64':
        return $bool($value.isBase64);
      case 'contentText':
        return $String($value.contentText);
      case 'parameters':
        return $Map.wrap($value.parameters.map((key, value) {
          return $MapEntry.wrap(MapEntry(
            key is $Value ? key : $String(key),
            value is $Value ? value : $String(value),
          ));
        }));
      case 'isMimeType':
        return __$isMimeType;
      case 'isCharset':
        return __$isCharset;
      case 'isEncoding':
        return __$isEncoding;
      case 'contentAsBytes':
        return __$contentAsBytes;
      case 'contentAsString':
        return __$contentAsString;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  UriData get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final UriData $value;

  @override
  String get charset => $value.charset;

  @override
  String get contentText => $value.contentText;

  @override
  bool get isBase64 => $value.isBase64;

  @override
  String get mimeType => $value.mimeType;

  @override
  Map<String, String> get parameters => $value.parameters;

  @override
  Uri get uri => $value.uri;

  @override
  bool isMimeType(String mimeType) => $value.isMimeType(mimeType);

  static const __$isMimeType = $Function(_$isMimeType);
  static $Value? _$isMimeType(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as UriData;
    final mimeType = args[0]?.$value as String;
    final $result = $this.isMimeType(mimeType);
    return $bool($result);
  }

  @override
  bool isCharset(String charset) => $value.isCharset(charset);

  static const __$isCharset = $Function(_$isCharset);
  static $Value? _$isCharset(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as UriData;
    final charset = args[0]?.$value as String;
    final $result = $this.isCharset(charset);
    return $bool($result);
  }

  @override
  bool isEncoding(Encoding encoding) => $value.isEncoding(encoding);

  static const __$isEncoding = $Function(_$isEncoding);
  static $Value? _$isEncoding(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as UriData;
    final encoding = args[0]?.$value as Encoding;
    final $result = $this.isEncoding(encoding);
    return $bool($result);
  }

  @override
  Uint8List contentAsBytes() => $value.contentAsBytes();

  static const __$contentAsBytes = $Function(_$contentAsBytes);
  static $Value? _$contentAsBytes(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as UriData;
    final $result = $this.contentAsBytes();
    return $Uint8List.wrap($result);
  }

  @override
  String contentAsString({Encoding? encoding}) =>
      $value.contentAsString(encoding: encoding);

  static const __$contentAsString = $Function(_$contentAsString);
  static $Value? _$contentAsString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $this = target?.$value as UriData;
    final encoding = args[0]?.$value as Encoding?;
    final $result = $this.contentAsString(encoding: encoding);
    return $String($result);
  }

  static const __$static$method$parse = $Function(_$static$method$parse);
  static $Value? _$static$method$parse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]?.$value as String;
    final $result = UriData.parse(uri);
    return $UriData.wrap($result);
  }

  static const __$UriData$fromString = $Function(_$UriData$fromString);
  static $Value? _$UriData$fromString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final content = args[0]?.$value as String;
    final mimeType = args[1]?.$value as String?;
    final encoding = args[2]?.$value as Encoding?;
    final parameters = (args[3]?.$reified as Map?)?.cast<String, String>();
    final base64 = ((args[4]?.$value as bool?)) ?? false;
    return $UriData.wrap(UriData.fromString(
      content,
      mimeType: mimeType,
      encoding: encoding,
      parameters: parameters,
      base64: base64,
    ));
  }

  static const __$UriData$fromBytes = $Function(_$UriData$fromBytes);
  static $Value? _$UriData$fromBytes(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final bytes = (args[0]?.$reified as List).cast<int>();
    final mimeType = args[1]?.$value as String? ?? "application/octet-stream";
    final parameters = (args[2]?.$reified as Map?)?.cast<String, String>();
    final percentEncoded = args[3]?.$value as bool? ?? false;
    return $UriData.wrap(UriData.fromBytes(
      bytes,
      mimeType: mimeType,
      parameters: parameters,
      percentEncoded: percentEncoded,
    ));
  }

  static const __$UriData$fromUri = $Function(_$UriData$fromUri);
  static $Value? _$UriData$fromUri(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final uri = args[0]?.$value as Uri;
    return $UriData.wrap(UriData.fromUri(
      uri,
    ));
  }
}
