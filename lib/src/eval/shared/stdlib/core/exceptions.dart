import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// dart_eval wrapper for [Exception]
class $Exception implements Exception, $Instance {
  /// Compile-time class definition for [$Exception]
  static const $declaration =
      BridgeClassDef(BridgeClassType(BridgeTypeRef(CoreTypes.exception)),
          constructors: {
            '': BridgeConstructorDef(BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.exception)),
                params: [
                  BridgeParameter(
                      'message',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true)
                ]))
          },
          wrap: true);

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
