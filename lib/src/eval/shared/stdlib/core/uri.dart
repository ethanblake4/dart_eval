import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Uri]
class $Uri implements $Instance {
  /// Configures the runtime for the [Uri] class
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc('dart:core', 'Uri.parse', $parse);
  }

  /// Bridge type spec for [$Uri]
  static const $type = BridgeTypeRef(CoreTypes.uri);

  /// Bridge class declaration for [$Uri]
  static const $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {},
      methods: {
        'parse': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
              BridgeParameter('uri', BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.stringType)), false)
            ], namedParams: []),
            isStatic: true)
      },
      getters: {},
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

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  String toString() => $value.toString();
}
