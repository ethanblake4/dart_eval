import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [Symbol]
class $Symbol implements $Instance {
  static const _$type = BridgeTypeRef(CoreTypes.symbol);

  static const $declaration = BridgeClassDef(
    BridgeClassType(_$type),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(_$type),
          params: [
            BridgeParameter(
              'name',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
        ),
      ),
    },
    methods: {},
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Symbol.wrap(Symbol(args[0]!.$value));
  }

  final $Instance _superclass;

  /// Wrap a [Symbol] in a [$Symbol]
  $Symbol.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Symbol $value;

  @override
  Symbol get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.symbol);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
