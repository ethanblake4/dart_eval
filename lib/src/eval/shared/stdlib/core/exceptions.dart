import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// dart_eval wrapper for [Exception]
class $Exception implements Exception, $Instance {
  /// Compile-time class definition for [$Exception]
  static const $declaration = BridgeClassDef(
    BridgeClassType(BridgeTypeRef(CoreTypes.exception)),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.exception)),
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
    },
    wrap: true,
  );

  final $Instance _superclass;

  /// Wrap a [Exception] in a [$Exception]
  $Exception.wrap(this.$value) : _superclass = $Object($value);

  /// Create a new [$Exception] wrapping [Exception.new]
  static $Exception $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Exception.wrap(Exception(args[0]?.$value));
  }

  @override
  final Exception $value;

  @override
  Exception get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.exception);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper for [FormatException]
class $FormatException implements FormatException, $Instance {
  /// Compile-time class definition for [$FormatException]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.formatException),
      $implements: [BridgeTypeRef(CoreTypes.exception)],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.exception)),
          params: [
            BridgeParameter(
              'message',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
              true,
            ),
            BridgeParameter(
              'source',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              true,
            ),
            BridgeParameter(
              'offset',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.int),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
    },
    wrap: true,
  );

  final $Instance _superclass;

  /// Wrap a [FormatException] in a [$FormatException]
  $FormatException.wrap(this.$value) : _superclass = $Object($value);

  /// Create a new [$FormatException] wrapping [FormatException.new]
  static $FormatException $new(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    return $FormatException.wrap(
      FormatException(args[0]?.$value ?? '', args[1]?.$value, args[2]?.$value),
    );
  }

  @override
  final FormatException $value;

  @override
  FormatException get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.formatException);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String get message => $value.message;

  @override
  int? get offset => $value.offset;

  @override
  get source => $value.source;
}
