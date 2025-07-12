import 'dart:collection';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';

/// dart_eval wrapper for [LinkedHashMap]
class $LinkedHashMap implements $Instance {
  /// Compile-type type definition for [$LinkedHashMap]
  static const $type = BridgeTypeRef(CollectionTypes.linkedHashMap);

  /// Compile-time bridge class declaration for [$LinkedHashMap]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, isAbstract: true, generics: {
        'K': BridgeGenericParam(),
        'V': BridgeGenericParam(),
      }, $implements: [
        BridgeTypeRef(CoreTypes.map, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('K')),
          BridgeTypeAnnotation(BridgeTypeRef.ref('V'))
        ])
      ]),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(CollectionTypes.linkedHashMap)),
                namedParams: [
                  BridgeParameter(
                      'equals',
                      BridgeTypeAnnotation(
                          BridgeTypeRef.genericFunction(
                            BridgeFunctionDef(
                                returns: BridgeTypeAnnotation(
                                    BridgeTypeRef(CoreTypes.bool)),
                                params: [
                                  BridgeParameter(
                                      'a',
                                      BridgeTypeAnnotation(
                                          BridgeTypeRef.ref('K')),
                                      false),
                                  BridgeParameter(
                                      'b',
                                      BridgeTypeAnnotation(
                                          BridgeTypeRef.ref('K')),
                                      false),
                                ]),
                          ),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'hashCode',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                      true),
                  BridgeParameter(
                      'isValidKey',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                      true),
                ]),
            isFactory: true),
        'identity': BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CollectionTypes.linkedHashMap)),
            ),
            isFactory: true),
        'from': BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CollectionTypes.linkedHashMap)),
              params: [
                BridgeParameter('other',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map)), false)
              ],
            ),
            isFactory: true),
        'of': BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CollectionTypes.linkedHashMap)),
              params: [
                BridgeParameter('other',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.map)), false)
              ],
            ),
            isFactory: true),
        'fromIterable': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(CollectionTypes.linkedHashMap)),
                params: [
                  BridgeParameter(
                      'iterable',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable)),
                      false)
                ],
                namedParams: [
                  BridgeParameter(
                      'key',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                      true),
                  BridgeParameter(
                      'value',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function)),
                      true),
                ]),
            isFactory: true),
        'fromIterables': BridgeConstructorDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(
                    BridgeTypeRef(CollectionTypes.linkedHashMap)),
                params: [
                  BridgeParameter(
                      'keys',
                      BridgeTypeAnnotation(
                          BridgeTypeRef(CoreTypes.iterable, [])),
                      false),
                  BridgeParameter(
                      'values',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.iterable,
                          [BridgeTypeAnnotation(BridgeTypeRef.ref('V'))])),
                      false)
                ]),
            isFactory: true),
      },
      methods: {},
      getters: {},
      wrap: true);

  /// Wrapper for [LinkedHashMap.new]
  static $Value? $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $LinkedHashMap.wrap(LinkedHashMap(
      equals: args[0] == null
          ? null
          : (a, b) => (args[0] as EvalCallable)(
                  runtime, null, [runtime.wrap(a), runtime.wrap(b)])!
              .$value,
      hashCode: args[1] == null
          ? null
          : (a) => (args[1] as EvalCallable)(runtime, null, [runtime.wrap(a)])!
              .$value,
      isValidKey: args[2] == null
          ? null
          : (a) => (args[2] as EvalCallable)(runtime, null, [runtime.wrap(a)])!
              .$value,
    ));
  }

  /// Wrapper for [LinkedHashMap.identity]
  static $Value? $identity(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $LinkedHashMap.wrap(LinkedHashMap.identity());
  }

  /// Wrapper for [LinkedHashMap.from]
  static $Value? $from(Runtime runtime, $Value? target, List<$Value?> args) {
    return $LinkedHashMap.wrap(LinkedHashMap.from((args[0] as $Map).$value));
  }

  /// Wrapper for [LinkedHashMap.of]
  static $Value? $of(Runtime runtime, $Value? target, List<$Value?> args) {
    return $LinkedHashMap.wrap(LinkedHashMap.of((args[0] as $Map).$value));
  }

  /// Wrapper for [LinkedHashMap.fromIterable]
  static $Value? $fromIterable(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $LinkedHashMap.wrap(LinkedHashMap.fromIterable(
        (args[0] as $Iterable).$value,
        key: args[1] == null
            ? null
            : (a) =>
                (args[1] as EvalCallable)(runtime, null, [runtime.wrap(a)])!
                    .$value,
        value: args[2] == null
            ? null
            : (a) =>
                (args[2] as EvalCallable)(runtime, null, [runtime.wrap(a)])!
                    .$value));
  }

  /// Wrapper for [LinkedHashMap.fromIterables]
  static $Value? $fromIterables(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $LinkedHashMap.wrap(LinkedHashMap.fromIterables(
        (args[0] as $Iterable).$value, (args[1] as $Iterable).$value));
  }

  /// Wrap a [LinkedHashMap] in a [$LinkedHashMap].
  $LinkedHashMap.wrap(this.$value);

  late final $Instance _superclass = $Map.wrap($value);

  @override
  final LinkedHashMap $value;

  @override
  LinkedHashMap get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(ConvertTypes.codec);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
