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

import 'dart:io';

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket;
import 'package:dart_eval/src/eval/runtime/runtime.dart';

import '../core/date_time.dart';

import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval wrapper binding for [HttpHeaders]
class $HttpHeaders implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.acceptHeader*g',
      $HttpHeaders.$acceptHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.acceptCharsetHeader*g',
      $HttpHeaders.$acceptCharsetHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.acceptEncodingHeader*g',
      $HttpHeaders.$acceptEncodingHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.acceptLanguageHeader*g',
      $HttpHeaders.$acceptLanguageHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.acceptRangesHeader*g',
      $HttpHeaders.$acceptRangesHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlAllowCredentialsHeader*g',
      $HttpHeaders.$accessControlAllowCredentialsHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlAllowHeadersHeader*g',
      $HttpHeaders.$accessControlAllowHeadersHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlAllowMethodsHeader*g',
      $HttpHeaders.$accessControlAllowMethodsHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlAllowOriginHeader*g',
      $HttpHeaders.$accessControlAllowOriginHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlExposeHeadersHeader*g',
      $HttpHeaders.$accessControlExposeHeadersHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlMaxAgeHeader*g',
      $HttpHeaders.$accessControlMaxAgeHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlRequestHeadersHeader*g',
      $HttpHeaders.$accessControlRequestHeadersHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.accessControlRequestMethodHeader*g',
      $HttpHeaders.$accessControlRequestMethodHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.ageHeader*g',
      $HttpHeaders.$ageHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.allowHeader*g',
      $HttpHeaders.$allowHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.authorizationHeader*g',
      $HttpHeaders.$authorizationHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.cacheControlHeader*g',
      $HttpHeaders.$cacheControlHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.connectionHeader*g',
      $HttpHeaders.$connectionHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentEncodingHeader*g',
      $HttpHeaders.$contentEncodingHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentLanguageHeader*g',
      $HttpHeaders.$contentLanguageHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentLengthHeader*g',
      $HttpHeaders.$contentLengthHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentLocationHeader*g',
      $HttpHeaders.$contentLocationHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentMD5Header*g',
      $HttpHeaders.$contentMD5Header,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentRangeHeader*g',
      $HttpHeaders.$contentRangeHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentTypeHeader*g',
      $HttpHeaders.$contentTypeHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.dateHeader*g',
      $HttpHeaders.$dateHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.etagHeader*g',
      $HttpHeaders.$etagHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.expectHeader*g',
      $HttpHeaders.$expectHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.expiresHeader*g',
      $HttpHeaders.$expiresHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.fromHeader*g',
      $HttpHeaders.$fromHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.hostHeader*g',
      $HttpHeaders.$hostHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.ifMatchHeader*g',
      $HttpHeaders.$ifMatchHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.ifModifiedSinceHeader*g',
      $HttpHeaders.$ifModifiedSinceHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.ifNoneMatchHeader*g',
      $HttpHeaders.$ifNoneMatchHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.ifRangeHeader*g',
      $HttpHeaders.$ifRangeHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.ifUnmodifiedSinceHeader*g',
      $HttpHeaders.$ifUnmodifiedSinceHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.lastModifiedHeader*g',
      $HttpHeaders.$lastModifiedHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.locationHeader*g',
      $HttpHeaders.$locationHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.maxForwardsHeader*g',
      $HttpHeaders.$maxForwardsHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.pragmaHeader*g',
      $HttpHeaders.$pragmaHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.proxyAuthenticateHeader*g',
      $HttpHeaders.$proxyAuthenticateHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.proxyAuthorizationHeader*g',
      $HttpHeaders.$proxyAuthorizationHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.rangeHeader*g',
      $HttpHeaders.$rangeHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.refererHeader*g',
      $HttpHeaders.$refererHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.retryAfterHeader*g',
      $HttpHeaders.$retryAfterHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.serverHeader*g',
      $HttpHeaders.$serverHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.teHeader*g',
      $HttpHeaders.$teHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.trailerHeader*g',
      $HttpHeaders.$trailerHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.transferEncodingHeader*g',
      $HttpHeaders.$transferEncodingHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.upgradeHeader*g',
      $HttpHeaders.$upgradeHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.userAgentHeader*g',
      $HttpHeaders.$userAgentHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.varyHeader*g',
      $HttpHeaders.$varyHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.viaHeader*g',
      $HttpHeaders.$viaHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.warningHeader*g',
      $HttpHeaders.$warningHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.wwwAuthenticateHeader*g',
      $HttpHeaders.$wwwAuthenticateHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.contentDisposition*g',
      $HttpHeaders.$contentDisposition,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.cookieHeader*g',
      $HttpHeaders.$cookieHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.setCookieHeader*g',
      $HttpHeaders.$setCookieHeader,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.generalHeaders*g',
      $HttpHeaders.$generalHeaders,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.entityHeaders*g',
      $HttpHeaders.$entityHeaders,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.responseHeaders*g',
      $HttpHeaders.$responseHeaders,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpHeaders.requestHeaders*g',
      $HttpHeaders.$requestHeaders,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$HttpHeaders]
  static const $spec = BridgeTypeSpec('dart:io', 'HttpHeaders');

  /// Compile-time type declaration of [$HttpHeaders]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$HttpHeaders]
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
      '[]': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'value': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'preserveHeaderCase',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),
          ],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'set': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'preserveHeaderCase',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),
          ],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'remove': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),

            BridgeParameter(
              'value',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'removeAll': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
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
                        'name',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.string, []),
                        ),
                        false,
                      ),

                      BridgeParameter(
                        'values',
                        BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.list, [
                            BridgeTypeAnnotation(
                              BridgeTypeRef(CoreTypes.string, []),
                            ),
                          ]),
                        ),
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

        isAbstract: true,
      ),

      'noFolding': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'clear': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    getters: {},
    setters: {},
    fields: {
      'acceptHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'acceptCharsetHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'acceptEncodingHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'acceptLanguageHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'acceptRangesHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlAllowCredentialsHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlAllowHeadersHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlAllowMethodsHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlAllowOriginHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlExposeHeadersHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlMaxAgeHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlRequestHeadersHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'accessControlRequestMethodHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'ageHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'allowHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'authorizationHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'cacheControlHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'connectionHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentEncodingHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentLanguageHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentLengthHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentLocationHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentMD5Header': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentRangeHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentTypeHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'dateHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'etagHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'expectHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'expiresHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'fromHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'hostHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'ifMatchHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'ifModifiedSinceHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'ifNoneMatchHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'ifRangeHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'ifUnmodifiedSinceHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'lastModifiedHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'locationHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'maxForwardsHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'pragmaHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'proxyAuthenticateHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'proxyAuthorizationHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'rangeHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'refererHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'retryAfterHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'serverHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'teHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'trailerHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'transferEncodingHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'upgradeHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'userAgentHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'varyHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'viaHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'warningHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'wwwAuthenticateHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'contentDisposition': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'cookieHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'setCookieHeader': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'generalHeaders': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          ]),
        ),
        isStatic: true,
      ),

      'entityHeaders': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          ]),
        ),
        isStatic: true,
      ),

      'responseHeaders': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          ]),
        ),
        isStatic: true,
      ),

      'requestHeaders': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          ]),
        ),
        isStatic: true,
      ),

      'date': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.dateTime, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'expires': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.dateTime, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'ifModifiedSince': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.dateTime, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'host': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'port': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []), nullable: true),
        isStatic: false,
      ),

      'contentType': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.object, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'contentLength': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),

      'persistentConnection': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),

      'chunkedTransferEncoding': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [HttpHeaders.acceptHeader] getter
  static $Value? $acceptHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.acceptHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.acceptCharsetHeader] getter
  static $Value? $acceptCharsetHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.acceptCharsetHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.acceptEncodingHeader] getter
  static $Value? $acceptEncodingHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.acceptEncodingHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.acceptLanguageHeader] getter
  static $Value? $acceptLanguageHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.acceptLanguageHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.acceptRangesHeader] getter
  static $Value? $acceptRangesHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.acceptRangesHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlAllowCredentialsHeader] getter
  static $Value? $accessControlAllowCredentialsHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlAllowCredentialsHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlAllowHeadersHeader] getter
  static $Value? $accessControlAllowHeadersHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlAllowHeadersHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlAllowMethodsHeader] getter
  static $Value? $accessControlAllowMethodsHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlAllowMethodsHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlAllowOriginHeader] getter
  static $Value? $accessControlAllowOriginHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlAllowOriginHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlExposeHeadersHeader] getter
  static $Value? $accessControlExposeHeadersHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlExposeHeadersHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlMaxAgeHeader] getter
  static $Value? $accessControlMaxAgeHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlMaxAgeHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlRequestHeadersHeader] getter
  static $Value? $accessControlRequestHeadersHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlRequestHeadersHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.accessControlRequestMethodHeader] getter
  static $Value? $accessControlRequestMethodHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.accessControlRequestMethodHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.ageHeader] getter
  static $Value? $ageHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.ageHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.allowHeader] getter
  static $Value? $allowHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.allowHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.authorizationHeader] getter
  static $Value? $authorizationHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.authorizationHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.cacheControlHeader] getter
  static $Value? $cacheControlHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.cacheControlHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.connectionHeader] getter
  static $Value? $connectionHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.connectionHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentEncodingHeader] getter
  static $Value? $contentEncodingHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentEncodingHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentLanguageHeader] getter
  static $Value? $contentLanguageHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentLanguageHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentLengthHeader] getter
  static $Value? $contentLengthHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentLengthHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentLocationHeader] getter
  static $Value? $contentLocationHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentLocationHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentMD5Header] getter
  static $Value? $contentMD5Header(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentMD5Header;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentRangeHeader] getter
  static $Value? $contentRangeHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentRangeHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentTypeHeader] getter
  static $Value? $contentTypeHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentTypeHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.dateHeader] getter
  static $Value? $dateHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.dateHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.etagHeader] getter
  static $Value? $etagHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.etagHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.expectHeader] getter
  static $Value? $expectHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.expectHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.expiresHeader] getter
  static $Value? $expiresHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.expiresHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.fromHeader] getter
  static $Value? $fromHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.fromHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.hostHeader] getter
  static $Value? $hostHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.hostHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.ifMatchHeader] getter
  static $Value? $ifMatchHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.ifMatchHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.ifModifiedSinceHeader] getter
  static $Value? $ifModifiedSinceHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.ifModifiedSinceHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.ifNoneMatchHeader] getter
  static $Value? $ifNoneMatchHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.ifNoneMatchHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.ifRangeHeader] getter
  static $Value? $ifRangeHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.ifRangeHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.ifUnmodifiedSinceHeader] getter
  static $Value? $ifUnmodifiedSinceHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.ifUnmodifiedSinceHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.lastModifiedHeader] getter
  static $Value? $lastModifiedHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.lastModifiedHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.locationHeader] getter
  static $Value? $locationHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.locationHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.maxForwardsHeader] getter
  static $Value? $maxForwardsHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.maxForwardsHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.pragmaHeader] getter
  static $Value? $pragmaHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.pragmaHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.proxyAuthenticateHeader] getter
  static $Value? $proxyAuthenticateHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.proxyAuthenticateHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.proxyAuthorizationHeader] getter
  static $Value? $proxyAuthorizationHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.proxyAuthorizationHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.rangeHeader] getter
  static $Value? $rangeHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.rangeHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.refererHeader] getter
  static $Value? $refererHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.refererHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.retryAfterHeader] getter
  static $Value? $retryAfterHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.retryAfterHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.serverHeader] getter
  static $Value? $serverHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.serverHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.teHeader] getter
  static $Value? $teHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.teHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.trailerHeader] getter
  static $Value? $trailerHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.trailerHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.transferEncodingHeader] getter
  static $Value? $transferEncodingHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.transferEncodingHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.upgradeHeader] getter
  static $Value? $upgradeHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.upgradeHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.userAgentHeader] getter
  static $Value? $userAgentHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.userAgentHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.varyHeader] getter
  static $Value? $varyHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.varyHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.viaHeader] getter
  static $Value? $viaHeader(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = HttpHeaders.viaHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.warningHeader] getter
  static $Value? $warningHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.warningHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.wwwAuthenticateHeader] getter
  static $Value? $wwwAuthenticateHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.wwwAuthenticateHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.contentDisposition] getter
  static $Value? $contentDisposition(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.contentDisposition;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.cookieHeader] getter
  static $Value? $cookieHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.cookieHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.setCookieHeader] getter
  static $Value? $setCookieHeader(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.setCookieHeader;
    return $String(value);
  }

  /// Wrapper for the [HttpHeaders.generalHeaders] getter
  static $Value? $generalHeaders(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.generalHeaders;
    return $List.view(
      value,
      (e) => $String(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  /// Wrapper for the [HttpHeaders.entityHeaders] getter
  static $Value? $entityHeaders(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.entityHeaders;
    return $List.view(
      value,
      (e) => $String(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  /// Wrapper for the [HttpHeaders.responseHeaders] getter
  static $Value? $responseHeaders(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.responseHeaders;
    return $List.view(
      value,
      (e) => $String(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  /// Wrapper for the [HttpHeaders.requestHeaders] getter
  static $Value? $requestHeaders(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = HttpHeaders.requestHeaders;
    return $List.view(
      value,
      (e) => $String(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  final $Instance _superclass;

  @override
  final HttpHeaders $value;

  @override
  HttpHeaders get $reified => $value;

  /// Wrap a [HttpHeaders] in a [$HttpHeaders]
  $HttpHeaders.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'date':
        final _date = $value.date;
        return _date == null ? const $null() : $DateTime.wrap(_date);
      case 'expires':
        final _expires = $value.expires;
        return _expires == null ? const $null() : $DateTime.wrap(_expires);
      case 'ifModifiedSince':
        final _ifModifiedSince = $value.ifModifiedSince;
        return _ifModifiedSince == null
            ? const $null()
            : $DateTime.wrap(_ifModifiedSince);
      case 'host':
        final _host = $value.host;
        return _host == null ? const $null() : $String(_host);
      case 'port':
        final _port = $value.port;
        return _port == null ? const $null() : $int(_port);
      case 'contentType':
        final _contentType = $value.contentType;
        return _contentType == null ? const $null() : $Object(_contentType);
      case 'contentLength':
        final _contentLength = $value.contentLength;
        return $int(_contentLength);
      case 'persistentConnection':
        final _persistentConnection = $value.persistentConnection;
        return $bool(_persistentConnection);
      case 'chunkedTransferEncoding':
        final _chunkedTransferEncoding = $value.chunkedTransferEncoding;
        return $bool(_chunkedTransferEncoding);
      case '[]':
        return $Closure(__operatorIndexGet.func, this);

      case 'value':
        return $Closure(__value.func, this);

      case 'add':
        return $Closure(__add.func, this);

      case 'set':
        return $Closure(__set.func, this);

      case 'remove':
        return $Closure(__remove.func, this);

      case 'removeAll':
        return $Closure(__removeAll.func, this);

      case 'forEach':
        return $Closure(__forEach.func, this);

      case 'noFolding':
        return $Closure(__noFolding.func, this);

      case 'clear':
        return $Closure(__clear.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __operatorIndexGet = $Function(_operatorIndexGet);
  static $Value? _operatorIndexGet(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    final result = self.$value[(r as $String).$value];
    return result == null
        ? const $null()
        : $List.view(
            result,
            (e) => $String(e),
            runtime: runtime,
            runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
              runtime.lookupType(CoreTypes.string),
            ]),
          );
  }

  static const $Function __value = $Function(_value);
  static $Value? _value(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    final result = self.$value.value((r as $String).$value);
    return result == null ? const $null() : $String(result);
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    self.$value.add(
      (r as $String).$value,
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as Object,
      preserveHeaderCase:
          (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? false
          : ((c is List && (c as List).length > 0 ? (c as List)[0] : null)
                    as $bool)
                .$value,
    );
    return null;
  }

  static const $Function __set = $Function(_set);
  static $Value? _set(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    self.$value.set(
      (r as $String).$value,
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as Object,
      preserveHeaderCase:
          (c is List && (c as List).length > 0
                  ? (c as List)[0] as $Value?
                  : null) ==
              null
          ? false
          : ((c is List && (c as List).length > 0 ? (c as List)[0] : null)
                    as $bool)
                .$value,
    );
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
    final self = target! as $HttpHeaders;
    self.$value.remove(
      (r as $String).$value,
      TypedInterop.exportExternal((s as $Value?), runtime: runtime) as Object,
    );
    return null;
  }

  static const $Function __removeAll = $Function(_removeAll);
  static $Value? _removeAll(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    self.$value.removeAll((r as $String).$value);
    return null;
  }

  static const $Function __forEach = $Function(_forEach);
  static $Value? _forEach(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    self.$value.forEach(
      runtime.cachedCallback(
        (r as $Value?)! as EvalCallable,
        "void Function(String, List<String>);export=false",
        (_callable) => (String name, List<String> values) {
          _callable.call(
            runtime,
            null,
            $String(name),
            $List.view(
              values,
              (e) => $String(e),
              runtime: runtime,
              runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
                runtime.lookupType(CoreTypes.string),
              ]),
            ),
            2,
          );
        },
      ),
    );
    return null;
  }

  static const $Function __noFolding = $Function(_noFolding);
  static $Value? _noFolding(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    self.$value.noFolding((r as $String).$value);
    return null;
  }

  static const $Function __clear = $Function(_clear);
  static $Value? _clear(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $HttpHeaders;
    self.$value.clear();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      case 'date':
        $value.date = value.$reified;
        return;
      case 'expires':
        $value.expires = value.$reified;
        return;
      case 'ifModifiedSince':
        $value.ifModifiedSince = value.$reified;
        return;
      case 'host':
        $value.host = value.$reified;
        return;
      case 'port':
        $value.port = value.$reified;
        return;
      case 'contentType':
        $value.contentType = value.$reified;
        return;
      case 'contentLength':
        $value.contentLength = value.$reified;
        return;
      case 'persistentConnection':
        $value.persistentConnection = value.$reified;
        return;
      case 'chunkedTransferEncoding':
        $value.chunkedTransferEncoding = value.$reified;
        return;
    }
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
