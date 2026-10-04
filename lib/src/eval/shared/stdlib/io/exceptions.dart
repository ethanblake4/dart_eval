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
import 'package:dart_eval/stdlib/io.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket;

import '../core/uri.dart';
import '../core/exceptions.dart';

/// dart_eval wrapper binding for [SocketException]
class $SocketException implements SocketException, $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'SocketException.',
      $SocketException.$new,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'SocketException.closed',
      $SocketException.$closed,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$SocketException]
  static const $spec = BridgeTypeSpec('dart:io', 'SocketException');

  /// Compile-time type declaration of [$SocketException]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$SocketException]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.object, []),
        BridgeTypeRef(CoreTypes.exception, []),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'osError',
              BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.osError, []),
                nullable: true,
              ),
              true,
            ),

            BridgeParameter(
              'address',
              BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddress, []),
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
          ],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),

      'closed': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),

      'osError': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(IoTypes.osError, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'address': BridgeFieldDef(
        BridgeTypeAnnotation(
          BridgeTypeRef(IoTypes.internetAddress, []),
          nullable: true,
        ),
        isStatic: false,
      ),

      'port': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, []), nullable: true),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [SocketException.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    final _arg2OrNull = c is List && c.length > 0 ? c[0] as $Value? : null;
    final _arg3OrNull = c is List && c.length > 1 ? c[1] as $Value? : null;

    return $SocketException.wrap(
      SocketException(
        (r as $String).$value,
        osError: (s is $Value ? s : null)?.$value,
        address: _arg2OrNull?.$value,
        port: _arg3OrNull?.$value,
      ),
    );
  }

  /// Wrapper for the [SocketException.closed] constructor
  static $Value? $closed(Runtime runtime, Object? r, Object? s, Object? c) {
    return $SocketException.wrap(SocketException.closed());
  }

  final $Instance _superclass;

  @override
  final SocketException $value;

  @override
  SocketException get $reified => $value;

  /// Wrap a [SocketException] in a [$SocketException]
  $SocketException.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        final _message = $value.message;
        return $String(_message);
      case 'osError':
        final _osError = $value.osError;
        return _osError == null ? const $null() : $OSError.wrap(_osError);
      case 'address':
        final _address = $value.address;
        return _address == null
            ? const $null()
            : $InternetAddress.wrap(_address);
      case 'port':
        final _port = $value.port;
        return _port == null ? const $null() : $int(_port);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String get message => $value.message;

  @override
  OSError? get osError => $value.osError;

  @override
  InternetAddress? get address => $value.address;

  @override
  int? get port => $value.port;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [HttpException]
class $HttpException implements HttpException, $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'HttpException.',
      $HttpException.$new,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$HttpException]
  static const $spec = BridgeTypeSpec('dart:io', 'HttpException');

  /// Compile-time type declaration of [$HttpException]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$HttpException]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [
        BridgeTypeRef(CoreTypes.object, []),
        BridgeTypeRef(CoreTypes.exception, []),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [
            BridgeParameter(
              'uri',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.uri, []),
                nullable: true,
              ),
              true,
            ),
          ],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'message': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),

      'uri': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, []), nullable: true),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [HttpException.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HttpException.wrap(
      HttpException(
        (r as $String).$value,
        uri: (s is $Value ? s : null)?.$value,
      ),
    );
  }

  final $Instance _superclass;

  @override
  final HttpException $value;

  @override
  HttpException get $reified => $value;

  /// Wrap a [HttpException] in a [$HttpException]
  $HttpException.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        final _message = $value.message;
        return $String(_message);
      case 'uri':
        final _uri = $value.uri;
        return _uri == null ? const $null() : $Uri.wrap(_uri);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String get message => $value.message;

  @override
  Uri? get uri => $value.uri;

  @override
  String toString() => $value.toString();
}

/// dart_eval wrapper binding for [OSError]
class $OSError implements OSError, $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:io', 'OSError.', $OSError.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'OSError.noErrorCode*g',
      $OSError.$noErrorCode,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$OSError]
  static const $spec = BridgeTypeSpec('dart:io', 'OSError');

  /// Compile-time type declaration of [$OSError]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$OSError]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,

      $implements: [BridgeTypeRef(CoreTypes.exception, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              true,
              defaultValueSource: "\"\"",
            ),

            BridgeParameter(
              'errorCode',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
              true,
              defaultValueSource: "noErrorCode",
            ),
          ],
        ),
        isFactory: false,
      ),
    },

    methods: {},
    getters: {},
    setters: {},
    fields: {
      'noErrorCode': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'message': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: false,
      ),

      'errorCode': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: false,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [OSError.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $OSError.wrap(
      OSError(
        (r is $Value ? r : null) == null ? "" : (r as $String).$value,
        (s is $Value ? s : null) == null
            ? OSError.noErrorCode
            : (s as $int).$value,
      ),
    );
  }

  /// Wrapper for the [OSError.noErrorCode] getter
  static $Value? $noErrorCode(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = OSError.noErrorCode;
    return $int(value);
  }

  final $Instance _superclass;

  @override
  final OSError $value;

  @override
  OSError get $reified => $value;

  /// Wrap a [OSError] in a [$OSError]
  $OSError.wrap(this.$value) : _superclass = $Exception.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        final _message = $value.message;
        return $String(_message);
      case 'errorCode':
        final _errorCode = $value.errorCode;
        return $int(_errorCode);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String get message => $value.message;

  @override
  int get errorCode => $value.errorCode;

  @override
  String toString() => $value.toString();
}
