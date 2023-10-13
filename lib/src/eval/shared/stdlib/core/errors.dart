import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';

/// dart_eval wrapper for [AssertionError]
class $AssertionError implements AssertionError, $Instance {
  /// Compile-time class definition for [$Iterable]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.assertionError)),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.assertionError)),
            params: [
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(
                      BridgeTypeRef.type(RuntimeTypes.objectType),
                      nullable: true),
                  true)
            ]))
      },
      methods: {},
      getters: {
        'message': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef.type(RuntimeTypes.objectType),
                    nullable: true)),
            isStatic: false),
      },
      setters: {},
      fields: {},
      wrap: true);

  final $Instance _superclass;

  /// Wrap a [AssertionError] in a [$AssertionError]
  $AssertionError.wrap(this.$value) : _superclass = $Object($value);

  static $AssertionError $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $AssertionError.wrap(AssertionError(args[0]?.$value));
  }

  @override
  final AssertionError $value;

  @override
  AssertionError get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.assertionError);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier == 'message') {
      return $value.message == null ? $null() : $Object($value.message!);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  Object? get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}
