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
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Duration,
        $DateTime,
        $Iterator,
        $Comparable,
        $Sink,
        $StackTrace,
        $StringBuffer,
        $Symbol,
        $MapEntry,
        $Stopwatch,
        $Error,
        $TypeError,
        $NoSuchMethodError,
        $RangeError,
        $AssertionError,
        $ArgumentError,
        $StateError,
        $UnsupportedError,
        $UnimplementedError,
        $Invocation,
        $Exception,
        $FormatException,
        $Uri,
        $Pattern,
        $Match,
        $RegExp,
        $RegExpMatch,
        $StringSink;
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

/// dart_eval wrapper binding for [Uri]
class $Uri implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:core', 'Uri.', $Uri.$new);

    runtime.registerBridgeFuncRegisters('dart:core', 'Uri.http', $Uri.$http);

    runtime.registerBridgeFuncRegisters('dart:core', 'Uri.https', $Uri.$https);

    runtime.registerBridgeFuncRegisters('dart:core', 'Uri.file', $Uri.$file);

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.directory',
      $Uri.$directory,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.dataFromString',
      $Uri.$dataFromString,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.dataFromBytes',
      $Uri.$dataFromBytes,
    );

    runtime.registerBridgeFuncRegisters('dart:core', 'Uri.parse', $Uri.$parse);

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.tryParse',
      $Uri.$tryParse,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.encodeComponent',
      $Uri.$encodeComponent,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.encodeQueryComponent',
      $Uri.$encodeQueryComponent,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.decodeComponent',
      $Uri.$decodeComponent,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.decodeQueryComponent',
      $Uri.$decodeQueryComponent,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.encodeFull',
      $Uri.$encodeFull,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.decodeFull',
      $Uri.$decodeFull,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.splitQueryString',
      $Uri.$splitQueryString,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.parseIPv4Address',
      $Uri.$parseIPv4Address,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Uri.parseIPv6Address',
      $Uri.$parseIPv6Address,
    );

    runtime.registerBridgeFuncRegisters('dart:core', 'Uri.base*g', $Uri.$base);
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Uri]
  static const $spec = BridgeTypeSpec('dart:core', 'Uri');

  /// Compile-time type declaration of [$Uri]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Uri]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'scheme',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'userInfo',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'host',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'port',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'path',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'pathSegments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'query',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'queryParameters',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'fragment',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),
        isFactory: true,
      ),

      'http': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'authority',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'unencodedPath',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),

            BridgeParameter(
              'queryParameters',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'https': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'authority',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'unencodedPath',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),

            BridgeParameter(
              'queryParameters',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
        isFactory: true,
      ),

      'file': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'windows',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'directory': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'windows',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'dataFromString': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'mimeType',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'encoding',
              BridgeTypeAnnotation(
                BridgeTypeRef(ConvertTypes.encoding, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'parameters',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'base64',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'content',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'dataFromBytes': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'mimeType',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
            ),

            BridgeParameter(
              'parameters',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'percentEncoded',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
            ),
          ],
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
        isFactory: true,
      ),
    },

    methods: {
      'isScheme': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'scheme',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'toFilePath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [
            BridgeParameter(
              'windows',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.bool, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),
      ),

      'replace': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [
            BridgeParameter(
              'scheme',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'userInfo',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'host',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'port',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'path',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'pathSegments',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.iterable, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'query',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'queryParameters',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.map, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ]),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'fragment',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.string, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [],
        ),
      ),

      'removeFragment': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'resolve': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'reference',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
      ),

      'resolveUri': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'reference',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
              false,
            ),
          ],
        ),
      ),

      'normalizePath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'parse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'uri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

        isStatic: true,
      ),

      'tryParse': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.uri, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'uri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

        isStatic: true,
      ),

      'encodeComponent': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'component',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'encodeQueryComponent': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [
            BridgeParameter(
              'encoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'component',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'decodeComponent': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'encodedComponent',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'decodeQueryComponent': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [
            BridgeParameter(
              'encoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'encodedComponent',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'encodeFull': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'uri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'decodeFull': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'uri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'splitQueryString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'encoding',
              BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encoding, [])),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'query',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isStatic: true,
      ),

      'parseIPv4Address': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'host',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

        isStatic: true,
      ),

      'parseIPv6Address': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'host',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
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

        isStatic: true,
      ),
    },
    getters: {
      'base': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'scheme': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'authority': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'userInfo': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'host': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'port': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'path': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'query': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'fragment': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'pathSegments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'queryParameters': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'queryParametersAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.list, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
                ]),
              ),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'isAbsolute': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasScheme': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasAuthority': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasPort': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasQuery': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasFragment': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasEmptyPath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'hasAbsolutePath': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'origin': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),
      ),

      'data': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.object, []),
            nullable: true,
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

  /// Wrapper for the [Uri.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;
    final _arg5OrNull = c is List && c.length > 3 ? c[3] as $Value? : null;
    final _arg6OrNull = c is List && c.length > 4 ? c[4] as $Value? : null;
    final _arg7OrNull = c is List && c.length > 5 ? c[5] as $Value? : null;
    final _arg8OrNull = c is List && c.length > 6 ? c[6] as $Value? : null;

    return $Uri.wrap(
      Uri(
        scheme: (r is $Value ? r : null)?.$value,
        userInfo: (s is $Value ? s : null)?.$value,
        host: _arg2OrNull?.$value,
        port: _arg3OrNull?.$value,
        path: _arg4OrNull?.$value,
        pathSegments: _arg5OrNull?.$value,
        query: _arg6OrNull?.$value,
        queryParameters: (_arg7OrNull?.$reified as Map?)
            ?.cast<String, dynamic>(),
        fragment: _arg8OrNull?.$value,
      ),
    );
  }

  /// Wrapper for the [Uri.http] constructor
  static $Value? $http(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uri.wrap(
      Uri.http(
        (r as $String).$value,
        (s as $String).$value,
        ((c is $Value ? c : null)?.$reified as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  /// Wrapper for the [Uri.https] constructor
  static $Value? $https(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uri.wrap(
      Uri.https(
        (r as $String).$value,
        (s as $String).$value,
        ((c is $Value ? c : null)?.$reified as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  /// Wrapper for the [Uri.file] constructor
  static $Value? $file(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uri.wrap(
      Uri.file(
        (r as $String).$value,
        windows: (s is $Value ? s : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [Uri.directory] constructor
  static $Value? $directory(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Uri.wrap(
      Uri.directory(
        (r as $String).$value,
        windows: (s is $Value ? s : null)?.$value,
      ),
    );
  }

  /// Wrapper for the [Uri.dataFromString] constructor
  static $Value? $dataFromString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;
    final _arg4OrNull = c is List && c.length > 2 ? c[2] as $Value? : null;

    return $Uri.wrap(
      Uri.dataFromString(
        (r as $String).$value,
        mimeType: (s is $Value ? s : null)?.$value,
        encoding: _arg2OrNull?.$value,
        parameters: (_arg3OrNull?.$reified as Map?)?.cast<String, String>(),
        base64: _arg4OrNull == null ? false : (_arg4OrNull as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [Uri.dataFromBytes] constructor
  static $Value? $dataFromBytes(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    return $Uri.wrap(
      Uri.dataFromBytes(
        ((r as $Value?)!.$reified as List).cast<int>(),
        mimeType: (s is $Value ? s : null) == null
            ? "application/octet-stream"
            : (s as $String).$value,
        parameters: (_arg2OrNull?.$reified as Map?)?.cast<String, String>(),
        percentEncoded: _arg3OrNull == null
            ? false
            : (_arg3OrNull as $bool).$value,
      ),
    );
  }

  /// Wrapper for the [Uri.parse] method
  static $Value? $parse(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Uri.parse(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is $Value ? c : null)?.$value,
    );
    return $Uri.wrap(value);
  }

  /// Wrapper for the [Uri.tryParse] method
  static $Value? $tryParse(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Uri.tryParse(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is $Value ? c : null)?.$value,
    );
    return value == null ? const $null() : $Uri.wrap(value);
  }

  /// Wrapper for the [Uri.encodeComponent] method
  static $Value? $encodeComponent(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.encodeComponent((r as $String).$value);
    return $String(value);
  }

  /// Wrapper for the [Uri.encodeQueryComponent] method
  static $Value? $encodeQueryComponent(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.encodeQueryComponent(
      (r as $String).$value,
      encoding: (s is $Value ? s : null) == null
          ? utf8
          : (s is $Value ? s : null)?.$value,
    );
    return $String(value);
  }

  /// Wrapper for the [Uri.decodeComponent] method
  static $Value? $decodeComponent(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.decodeComponent((r as $String).$value);
    return $String(value);
  }

  /// Wrapper for the [Uri.decodeQueryComponent] method
  static $Value? $decodeQueryComponent(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.decodeQueryComponent(
      (r as $String).$value,
      encoding: (s is $Value ? s : null) == null
          ? utf8
          : (s is $Value ? s : null)?.$value,
    );
    return $String(value);
  }

  /// Wrapper for the [Uri.encodeFull] method
  static $Value? $encodeFull(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Uri.encodeFull((r as $String).$value);
    return $String(value);
  }

  /// Wrapper for the [Uri.decodeFull] method
  static $Value? $decodeFull(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Uri.decodeFull((r as $String).$value);
    return $String(value);
  }

  /// Wrapper for the [Uri.splitQueryString] method
  static $Value? $splitQueryString(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.splitQueryString(
      (r as $String).$value,
      encoding: (s is $Value ? s : null) == null
          ? utf8
          : (s is $Value ? s : null)?.$value,
    );
    return wrapMap(
      value,
      (key, value) => MapEntry($String(key), $String(value)),
    );
  }

  /// Wrapper for the [Uri.parseIPv4Address] method
  static $Value? $parseIPv4Address(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.parseIPv4Address(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is $Value ? c : null)?.$value,
    );
    return $List.view(value, (e) => $int(e));
  }

  /// Wrapper for the [Uri.parseIPv6Address] method
  static $Value? $parseIPv6Address(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Uri.parseIPv6Address(
      (r as $String).$value,
      (s is $Value ? s : null) == null ? 0 : (s as $int).$value,
      (c is $Value ? c : null)?.$value,
    );
    return $List.view(value, (e) => $int(e));
  }

  /// Wrapper for the [Uri.base] getter
  static $Value? $base(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Uri.base;
    return $Uri.wrap(value);
  }

  final $Instance _superclass;

  @override
  final Uri $value;

  @override
  Uri get $reified => $value;

  /// Wrap a [Uri] in a [$Uri]
  $Uri.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'scheme':
        final _scheme = $value.scheme;
        return $String(_scheme);
      case 'authority':
        final _authority = $value.authority;
        return $String(_authority);
      case 'userInfo':
        final _userInfo = $value.userInfo;
        return $String(_userInfo);
      case 'host':
        final _host = $value.host;
        return $String(_host);
      case 'port':
        final _port = $value.port;
        return $int(_port);
      case 'path':
        final _path = $value.path;
        return $String(_path);
      case 'query':
        final _query = $value.query;
        return $String(_query);
      case 'fragment':
        final _fragment = $value.fragment;
        return $String(_fragment);
      case 'pathSegments':
        final _pathSegments = $value.pathSegments;
        return $List.view(_pathSegments, (e) => $String(e));
      case 'queryParameters':
        final _queryParameters = $value.queryParameters;
        return wrapMap(
          _queryParameters,
          (key, value) => MapEntry($String(key), $String(value)),
        );
      case 'queryParametersAll':
        final _queryParametersAll = $value.queryParametersAll;
        return wrapMap(
          _queryParametersAll,
          (key, value) =>
              MapEntry($String(key), $List.view(value, (e) => $String(e))),
        );
      case 'isAbsolute':
        final _isAbsolute = $value.isAbsolute;
        return $bool(_isAbsolute);
      case 'hasScheme':
        final _hasScheme = $value.hasScheme;
        return $bool(_hasScheme);
      case 'hasAuthority':
        final _hasAuthority = $value.hasAuthority;
        return $bool(_hasAuthority);
      case 'hasPort':
        final _hasPort = $value.hasPort;
        return $bool(_hasPort);
      case 'hasQuery':
        final _hasQuery = $value.hasQuery;
        return $bool(_hasQuery);
      case 'hasFragment':
        final _hasFragment = $value.hasFragment;
        return $bool(_hasFragment);
      case 'hasEmptyPath':
        final _hasEmptyPath = $value.hasEmptyPath;
        return $bool(_hasEmptyPath);
      case 'hasAbsolutePath':
        final _hasAbsolutePath = $value.hasAbsolutePath;
        return $bool(_hasAbsolutePath);
      case 'origin':
        final _origin = $value.origin;
        return $String(_origin);
      case 'data':
        final _data = $value.data;
        return _data == null ? const $null() : $Object(_data);
      case 'isScheme':
        return __isScheme;

      case 'toFilePath':
        return __toFilePath;

      case 'replace':
        return __replace;

      case 'removeFragment':
        return __removeFragment;

      case 'resolve':
        return __resolve;

      case 'resolveUri':
        return __resolveUri;

      case 'normalizePath':
        return __normalizePath;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __isScheme = $Function(_isScheme);
  static $Value? _isScheme(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.isScheme((r as $String).$value);
    return $bool(result);
  }

  static const $Function __toFilePath = $Function(_toFilePath);
  static $Value? _toFilePath(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.toFilePath(
      windows: (r is $Value ? r : null)?.$value,
    );
    return $String(result);
  }

  static const $Function __replace = $Function(_replace);
  static $Value? _replace(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.replace(
      scheme: (r is $Value ? r : null)?.$value,
      userInfo: (s is $Value ? s : null)?.$value,
      host:
          (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null)
              ?.$value,
      port:
          (c is List && (c as List).length > 1
                  ? (c as List)[1] as $Value?
                  : null)
              ?.$value,
      path:
          (c is List && (c as List).length > 2
                  ? (c as List)[2] as $Value?
                  : null)
              ?.$value,
      pathSegments:
          (c is List && (c as List).length > 3
                  ? (c as List)[3] as $Value?
                  : null)
              ?.$value,
      query:
          (c is List && (c as List).length > 4
                  ? (c as List)[4] as $Value?
                  : null)
              ?.$value,
      queryParameters:
          ((c is List && (c as List).length > 5
                          ? (c as List)[5] as $Value?
                          : null)
                      ?.$reified
                  as Map?)
              ?.cast<String, dynamic>(),
      fragment:
          (c is List && (c as List).length > 6
                  ? (c as List)[6] as $Value?
                  : null)
              ?.$value,
    );
    return $Uri.wrap(result);
  }

  static const $Function __removeFragment = $Function(_removeFragment);
  static $Value? _removeFragment(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.removeFragment();
    return $Uri.wrap(result);
  }

  static const $Function __resolve = $Function(_resolve);
  static $Value? _resolve(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.resolve((r as $String).$value);
    return $Uri.wrap(result);
  }

  static const $Function __resolveUri = $Function(_resolveUri);
  static $Value? _resolveUri(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.resolveUri((r as $Value?)!.$value);
    return $Uri.wrap(result);
  }

  static const $Function __normalizePath = $Function(_normalizePath);
  static $Value? _normalizePath(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $Uri;
    final result = self.$value.normalizePath();
    return $Uri.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
