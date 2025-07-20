import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// Wrapper for [Comparable]
class $Comparable<T> implements Comparable<T>, $Instance {
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.comparable),
          isAbstract: true, generics: {'T': BridgeGenericParam()}),
      constructors: {},
      methods: {
        'compareTo': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            params: [
              BridgeParameter(
                  'other', BridgeTypeAnnotation(BridgeTypeRef.ref('T')), false)
            ]))
      },
      wrap: true);

  /// Wrap a [Comparable] in a [$Comparable].
  $Comparable.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Comparable<T> $value;

  @override
  Comparable<T> get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'compareTo':
        return __compareTo;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.comparable);

  static const $Function __compareTo = $Function(_compareTo);

  static $Value? _compareTo(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    final evalResult = target!.$value.compareTo(other!.$value);

    if (evalResult is int) {
      return $int(evalResult);
    }

    return null;
  }

  @override
  int compareTo(T other) => $value.compareTo(other);

  @override
  bool operator ==(Object other) => $value == other;

  @override
  int get hashCode => $value.hashCode;
}
