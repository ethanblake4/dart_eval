import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'dart:io';

/// dart_eval bimodal wrapper for [HttpStatus]
class $HttpStatus implements HttpStatus, $Instance {
  /// Configure the [$HttpStatus] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.continue_*g',
        __$static$continue_.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.switchingProtocols*g', __$static$switchingProtocols.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.processing*g',
        __$static$processing.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.ok*g', __$static$ok.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.created*g', __$static$created.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.accepted*g', __$static$accepted.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.nonAuthoritativeInformation*g',
        __$static$nonAuthoritativeInformation.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.noContent*g',
        __$static$noContent.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.resetContent*g',
        __$static$resetContent.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.partialContent*g', __$static$partialContent.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.multiStatus*g',
        __$static$multiStatus.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.alreadyReported*g', __$static$alreadyReported.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.imUsed*g', __$static$imUsed.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.multipleChoices*g', __$static$multipleChoices.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.movedPermanently*g', __$static$movedPermanently.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.found*g', __$static$found.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.movedTemporarily*g', __$static$movedTemporarily.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.seeOther*g', __$static$seeOther.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.notModified*g',
        __$static$notModified.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.useProxy*g', __$static$useProxy.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.temporaryRedirect*g', __$static$temporaryRedirect.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.permanentRedirect*g', __$static$permanentRedirect.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.badRequest*g',
        __$static$badRequest.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.unauthorized*g',
        __$static$unauthorized.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.paymentRequired*g', __$static$paymentRequired.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.forbidden*g',
        __$static$forbidden.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.notFound*g', __$static$notFound.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.methodNotAllowed*g', __$static$methodNotAllowed.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.notAcceptable*g', __$static$notAcceptable.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.proxyAuthenticationRequired*g',
        __$static$proxyAuthenticationRequired.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.requestTimeout*g', __$static$requestTimeout.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.conflict*g', __$static$conflict.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.gone*g', __$static$gone.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.lengthRequired*g', __$static$lengthRequired.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.preconditionFailed*g', __$static$preconditionFailed.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.requestEntityTooLarge*g',
        __$static$requestEntityTooLarge.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.requestUriTooLong*g', __$static$requestUriTooLong.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.unsupportedMediaType*g',
        __$static$unsupportedMediaType.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.requestedRangeNotSatisfiable*g',
        __$static$requestedRangeNotSatisfiable.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.expectationFailed*g', __$static$expectationFailed.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.misdirectedRequest*g', __$static$misdirectedRequest.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.unprocessableEntity*g', __$static$unprocessableEntity.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'HttpStatus.locked*g', __$static$locked.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.failedDependency*g', __$static$failedDependency.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.upgradeRequired*g', __$static$upgradeRequired.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.preconditionRequired*g',
        __$static$preconditionRequired.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.tooManyRequests*g', __$static$tooManyRequests.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.requestHeaderFieldsTooLarge*g',
        __$static$requestHeaderFieldsTooLarge.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.connectionClosedWithoutResponse*g',
        __$static$connectionClosedWithoutResponse.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.unavailableForLegalReasons*g',
        __$static$unavailableForLegalReasons.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.clientClosedRequest*g', __$static$clientClosedRequest.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.internalServerError*g', __$static$internalServerError.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.notImplemented*g', __$static$notImplemented.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.badGateway*g',
        __$static$badGateway.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.serviceUnavailable*g', __$static$serviceUnavailable.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.gatewayTimeout*g', __$static$gatewayTimeout.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.httpVersionNotSupported*g',
        __$static$httpVersionNotSupported.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.variantAlsoNegotiates*g',
        __$static$variantAlsoNegotiates.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'HttpStatus.insufficientStorage*g', __$static$insufficientStorage.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.loopDetected*g',
        __$static$loopDetected.call);
    runtime.registerBridgeFunc($type.spec!.library, 'HttpStatus.notExtended*g',
        __$static$notExtended.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.networkAuthenticationRequired*g',
        __$static$networkAuthenticationRequired.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'HttpStatus.networkConnectTimeoutError*g',
        __$static$networkConnectTimeoutError.call);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(IoTypes.httpStatus);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: null,
      $implements: [],
      isAbstract: true,
    ),
    constructors: {},
    fields: {
      'continue_': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'switchingProtocols': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'processing': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'ok': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'created': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'accepted': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'nonAuthoritativeInformation': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'noContent': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'resetContent': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'partialContent': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'multiStatus': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'alreadyReported': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'imUsed': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'multipleChoices': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'movedPermanently': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'found': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'movedTemporarily': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'seeOther': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'notModified': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'useProxy': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'temporaryRedirect': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'permanentRedirect': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'badRequest': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'unauthorized': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'paymentRequired': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'forbidden': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'notFound': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'methodNotAllowed': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'notAcceptable': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'proxyAuthenticationRequired': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'requestTimeout': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'conflict': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'gone': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'lengthRequired': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'preconditionFailed': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'requestEntityTooLarge': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'requestUriTooLong': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'unsupportedMediaType': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'requestedRangeNotSatisfiable': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'expectationFailed': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'misdirectedRequest': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'unprocessableEntity': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'locked': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'failedDependency': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'upgradeRequired': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'preconditionRequired': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'tooManyRequests': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'requestHeaderFieldsTooLarge': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'connectionClosedWithoutResponse': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'unavailableForLegalReasons': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'clientClosedRequest': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'internalServerError': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'notImplemented': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'badGateway': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'serviceUnavailable': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'gatewayTimeout': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'httpVersionNotSupported': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'variantAlsoNegotiates': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'insufficientStorage': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'loopDetected': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'notExtended': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'networkAuthenticationRequired': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
      'networkConnectTimeoutError': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []),
              nullable: false),
          isStatic: true),
    },
    methods: {},
    getters: {},
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [HttpStatus] in an [$HttpStatus]
  $HttpStatus.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  HttpStatus get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final HttpStatus $value;

  static const __$static$continue_ = $Function(_$static$continue_);
  static $Value? _$static$continue_(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.continue_;
    return $int($result);
  }

  static const __$static$switchingProtocols =
      $Function(_$static$switchingProtocols);
  static $Value? _$static$switchingProtocols(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.switchingProtocols;
    return $int($result);
  }

  static const __$static$processing = $Function(_$static$processing);
  static $Value? _$static$processing(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.processing;
    return $int($result);
  }

  static const __$static$ok = $Function(_$static$ok);
  static $Value? _$static$ok(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.ok;
    return $int($result);
  }

  static const __$static$created = $Function(_$static$created);
  static $Value? _$static$created(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.created;
    return $int($result);
  }

  static const __$static$accepted = $Function(_$static$accepted);
  static $Value? _$static$accepted(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.accepted;
    return $int($result);
  }

  static const __$static$nonAuthoritativeInformation =
      $Function(_$static$nonAuthoritativeInformation);
  static $Value? _$static$nonAuthoritativeInformation(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.nonAuthoritativeInformation;
    return $int($result);
  }

  static const __$static$noContent = $Function(_$static$noContent);
  static $Value? _$static$noContent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.noContent;
    return $int($result);
  }

  static const __$static$resetContent = $Function(_$static$resetContent);
  static $Value? _$static$resetContent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.resetContent;
    return $int($result);
  }

  static const __$static$partialContent = $Function(_$static$partialContent);
  static $Value? _$static$partialContent(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.partialContent;
    return $int($result);
  }

  static const __$static$multiStatus = $Function(_$static$multiStatus);
  static $Value? _$static$multiStatus(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.multiStatus;
    return $int($result);
  }

  static const __$static$alreadyReported = $Function(_$static$alreadyReported);
  static $Value? _$static$alreadyReported(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.alreadyReported;
    return $int($result);
  }

  static const __$static$imUsed = $Function(_$static$imUsed);
  static $Value? _$static$imUsed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.imUsed;
    return $int($result);
  }

  static const __$static$multipleChoices = $Function(_$static$multipleChoices);
  static $Value? _$static$multipleChoices(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.multipleChoices;
    return $int($result);
  }

  static const __$static$movedPermanently =
      $Function(_$static$movedPermanently);
  static $Value? _$static$movedPermanently(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.movedPermanently;
    return $int($result);
  }

  static const __$static$found = $Function(_$static$found);
  static $Value? _$static$found(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.found;
    return $int($result);
  }

  static const __$static$movedTemporarily =
      $Function(_$static$movedTemporarily);
  static $Value? _$static$movedTemporarily(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.movedTemporarily;
    return $int($result);
  }

  static const __$static$seeOther = $Function(_$static$seeOther);
  static $Value? _$static$seeOther(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.seeOther;
    return $int($result);
  }

  static const __$static$notModified = $Function(_$static$notModified);
  static $Value? _$static$notModified(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.notModified;
    return $int($result);
  }

  static const __$static$useProxy = $Function(_$static$useProxy);
  static $Value? _$static$useProxy(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.useProxy;
    return $int($result);
  }

  static const __$static$temporaryRedirect =
      $Function(_$static$temporaryRedirect);
  static $Value? _$static$temporaryRedirect(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.temporaryRedirect;
    return $int($result);
  }

  static const __$static$permanentRedirect =
      $Function(_$static$permanentRedirect);
  static $Value? _$static$permanentRedirect(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.permanentRedirect;
    return $int($result);
  }

  static const __$static$badRequest = $Function(_$static$badRequest);
  static $Value? _$static$badRequest(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.badRequest;
    return $int($result);
  }

  static const __$static$unauthorized = $Function(_$static$unauthorized);
  static $Value? _$static$unauthorized(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.unauthorized;
    return $int($result);
  }

  static const __$static$paymentRequired = $Function(_$static$paymentRequired);
  static $Value? _$static$paymentRequired(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.paymentRequired;
    return $int($result);
  }

  static const __$static$forbidden = $Function(_$static$forbidden);
  static $Value? _$static$forbidden(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.forbidden;
    return $int($result);
  }

  static const __$static$notFound = $Function(_$static$notFound);
  static $Value? _$static$notFound(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.notFound;
    return $int($result);
  }

  static const __$static$methodNotAllowed =
      $Function(_$static$methodNotAllowed);
  static $Value? _$static$methodNotAllowed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.methodNotAllowed;
    return $int($result);
  }

  static const __$static$notAcceptable = $Function(_$static$notAcceptable);
  static $Value? _$static$notAcceptable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.notAcceptable;
    return $int($result);
  }

  static const __$static$proxyAuthenticationRequired =
      $Function(_$static$proxyAuthenticationRequired);
  static $Value? _$static$proxyAuthenticationRequired(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.proxyAuthenticationRequired;
    return $int($result);
  }

  static const __$static$requestTimeout = $Function(_$static$requestTimeout);
  static $Value? _$static$requestTimeout(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.requestTimeout;
    return $int($result);
  }

  static const __$static$conflict = $Function(_$static$conflict);
  static $Value? _$static$conflict(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.conflict;
    return $int($result);
  }

  static const __$static$gone = $Function(_$static$gone);
  static $Value? _$static$gone(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.gone;
    return $int($result);
  }

  static const __$static$lengthRequired = $Function(_$static$lengthRequired);
  static $Value? _$static$lengthRequired(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.lengthRequired;
    return $int($result);
  }

  static const __$static$preconditionFailed =
      $Function(_$static$preconditionFailed);
  static $Value? _$static$preconditionFailed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.preconditionFailed;
    return $int($result);
  }

  static const __$static$requestEntityTooLarge =
      $Function(_$static$requestEntityTooLarge);
  static $Value? _$static$requestEntityTooLarge(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.requestEntityTooLarge;
    return $int($result);
  }

  static const __$static$requestUriTooLong =
      $Function(_$static$requestUriTooLong);
  static $Value? _$static$requestUriTooLong(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.requestUriTooLong;
    return $int($result);
  }

  static const __$static$unsupportedMediaType =
      $Function(_$static$unsupportedMediaType);
  static $Value? _$static$unsupportedMediaType(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.unsupportedMediaType;
    return $int($result);
  }

  static const __$static$requestedRangeNotSatisfiable =
      $Function(_$static$requestedRangeNotSatisfiable);
  static $Value? _$static$requestedRangeNotSatisfiable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.requestedRangeNotSatisfiable;
    return $int($result);
  }

  static const __$static$expectationFailed =
      $Function(_$static$expectationFailed);
  static $Value? _$static$expectationFailed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.expectationFailed;
    return $int($result);
  }

  static const __$static$misdirectedRequest =
      $Function(_$static$misdirectedRequest);
  static $Value? _$static$misdirectedRequest(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.misdirectedRequest;
    return $int($result);
  }

  static const __$static$unprocessableEntity =
      $Function(_$static$unprocessableEntity);
  static $Value? _$static$unprocessableEntity(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.unprocessableEntity;
    return $int($result);
  }

  static const __$static$locked = $Function(_$static$locked);
  static $Value? _$static$locked(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.locked;
    return $int($result);
  }

  static const __$static$failedDependency =
      $Function(_$static$failedDependency);
  static $Value? _$static$failedDependency(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.failedDependency;
    return $int($result);
  }

  static const __$static$upgradeRequired = $Function(_$static$upgradeRequired);
  static $Value? _$static$upgradeRequired(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.upgradeRequired;
    return $int($result);
  }

  static const __$static$preconditionRequired =
      $Function(_$static$preconditionRequired);
  static $Value? _$static$preconditionRequired(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.preconditionRequired;
    return $int($result);
  }

  static const __$static$tooManyRequests = $Function(_$static$tooManyRequests);
  static $Value? _$static$tooManyRequests(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.tooManyRequests;
    return $int($result);
  }

  static const __$static$requestHeaderFieldsTooLarge =
      $Function(_$static$requestHeaderFieldsTooLarge);
  static $Value? _$static$requestHeaderFieldsTooLarge(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.requestHeaderFieldsTooLarge;
    return $int($result);
  }

  static const __$static$connectionClosedWithoutResponse =
      $Function(_$static$connectionClosedWithoutResponse);
  static $Value? _$static$connectionClosedWithoutResponse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.connectionClosedWithoutResponse;
    return $int($result);
  }

  static const __$static$unavailableForLegalReasons =
      $Function(_$static$unavailableForLegalReasons);
  static $Value? _$static$unavailableForLegalReasons(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.unavailableForLegalReasons;
    return $int($result);
  }

  static const __$static$clientClosedRequest =
      $Function(_$static$clientClosedRequest);
  static $Value? _$static$clientClosedRequest(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.clientClosedRequest;
    return $int($result);
  }

  static const __$static$internalServerError =
      $Function(_$static$internalServerError);
  static $Value? _$static$internalServerError(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.internalServerError;
    return $int($result);
  }

  static const __$static$notImplemented = $Function(_$static$notImplemented);
  static $Value? _$static$notImplemented(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.notImplemented;
    return $int($result);
  }

  static const __$static$badGateway = $Function(_$static$badGateway);
  static $Value? _$static$badGateway(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.badGateway;
    return $int($result);
  }

  static const __$static$serviceUnavailable =
      $Function(_$static$serviceUnavailable);
  static $Value? _$static$serviceUnavailable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.serviceUnavailable;
    return $int($result);
  }

  static const __$static$gatewayTimeout = $Function(_$static$gatewayTimeout);
  static $Value? _$static$gatewayTimeout(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.gatewayTimeout;
    return $int($result);
  }

  static const __$static$httpVersionNotSupported =
      $Function(_$static$httpVersionNotSupported);
  static $Value? _$static$httpVersionNotSupported(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.httpVersionNotSupported;
    return $int($result);
  }

  static const __$static$variantAlsoNegotiates =
      $Function(_$static$variantAlsoNegotiates);
  static $Value? _$static$variantAlsoNegotiates(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.variantAlsoNegotiates;
    return $int($result);
  }

  static const __$static$insufficientStorage =
      $Function(_$static$insufficientStorage);
  static $Value? _$static$insufficientStorage(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.insufficientStorage;
    return $int($result);
  }

  static const __$static$loopDetected = $Function(_$static$loopDetected);
  static $Value? _$static$loopDetected(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.loopDetected;
    return $int($result);
  }

  static const __$static$notExtended = $Function(_$static$notExtended);
  static $Value? _$static$notExtended(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.notExtended;
    return $int($result);
  }

  static const __$static$networkAuthenticationRequired =
      $Function(_$static$networkAuthenticationRequired);
  static $Value? _$static$networkAuthenticationRequired(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.networkAuthenticationRequired;
    return $int($result);
  }

  static const __$static$networkConnectTimeoutError =
      $Function(_$static$networkConnectTimeoutError);
  static $Value? _$static$networkConnectTimeoutError(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = HttpStatus.networkConnectTimeoutError;
    return $int($result);
  }
}
