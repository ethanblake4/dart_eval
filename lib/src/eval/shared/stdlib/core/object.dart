// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval [$Instance] representation of an [Object]
class $Object implements $Instance {
  $Object(this.$value);

  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.object),
          $extends: BridgeTypeRef(CoreTypes.dynamic), isAbstract: true),
      constructors: {},
      methods: {
        '!=': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [
              BridgeParameter(
                  'other',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic),
                      nullable: true),
                  false)
            ])),
        '==': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [
              BridgeParameter(
                  'other',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic),
                      nullable: true),
                  false)
            ])),
        'toString': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            params: [])),
        'hash': BridgeMethodDef(
            BridgeFunctionDef(
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
                params: [
                  BridgeParameter(
                      'object1',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      false),
                  BridgeParameter(
                      'object2',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      false),
                  BridgeParameter(
                      'object3',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object4',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object5',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object6',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object7',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object8',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object9',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object10',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object11',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object12',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                  BridgeParameter(
                      'object13',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true),
                ],
                namedParams: []),
            isStatic: true),
      },
      getters: {
        'hashCode': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            params: [])),
        'runtimeType': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type)),
            params: [])),
      },
      wrap: true);

  @override
  final Object $value;

  @override
  dynamic get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '==':
        return __equals;
      case '!=':
        return __not_equals;
      case 'toString':
        return __toString;
      case 'hashCode':
        return $int($value.hashCode);
    }

    throw UnimplementedError();
  }

  /// dart_eval implementation of [Object.hash]
  ///
  /// Strange implementation is due to the use of internal-only APIs in the
  /// original method
  static $int $hash(Runtime runtime, $Value? target, List<$Value?> args) {
    final object1 = args[0]?.$value;
    final object2 = args[1]?.$value;
    final object3 = args.length > 2 ? args[2] : null;
    final object4 = args.length > 3 ? args[3] : null;
    final object5 = args.length > 4 ? args[4] : null;
    final object6 = args.length > 5 ? args[5] : null;
    final object7 = args.length > 6 ? args[6] : null;
    final object8 = args.length > 7 ? args[7] : null;
    final object9 = args.length > 8 ? args[8] : null;
    final object10 = args.length > 9 ? args[9] : null;
    final object11 = args.length > 10 ? args[10] : null;
    final object12 = args.length > 11 ? args[11] : null;
    final object13 = args.length > 12 ? args[12] : null;

    if (null == args[2]) {
      return $int(Object.hash(object1, object2));
    }
    if (null == args[3]) {
      return $int(Object.hash(object1, object2, object3!.$value));
    }
    if (null == args[4]) {
      return $int(
          Object.hash(object1, object2, object3!.$value, object4!.$value));
    }
    if (null == args[5]) {
      return $int(Object.hash(
          object1, object2, object3!.$value, object4!.$value, object5!.$value));
    }
    if (null == args[6]) {
      return $int(Object.hash(object1, object2, object3!.$value,
          object4!.$value, object5!.$value, object6!.$value));
    }
    if (null == args[7]) {
      return $int(Object.hash(object1, object2, object3!.$value,
          object4!.$value, object5!.$value, object6!.$value, object7!.$value));
    }
    if (null == args[8]) {
      return $int(Object.hash(
          object1,
          object2,
          object3!.$value,
          object4!.$value,
          object5!.$value,
          object6!.$value,
          object7!.$value,
          object8!.$value));
    }
    if (null == args[9]) {
      return $int(Object.hash(
          object1,
          object2,
          object3!.$value,
          object4!.$value,
          object5!.$value,
          object6!.$value,
          object7!.$value,
          object8!.$value,
          object9!.$value));
    }
    if (null == args[10]) {
      return $int(Object.hash(
          object1,
          object2,
          object3!.$value,
          object4!.$value,
          object5!.$value,
          object6!.$value,
          object7!.$value,
          object8!.$value,
          object9!.$value,
          object10!.$value));
    }
    if (null == args[11]) {
      return $int(Object.hash(
          object1,
          object2,
          object3!.$value,
          object4!.$value,
          object5!.$value,
          object6!.$value,
          object7!.$value,
          object8!.$value,
          object9!.$value,
          object10!.$value,
          object11!.$value));
    }
    if (null == args[12]) {
      return $int(Object.hash(
          object1,
          object2,
          object3!.$value,
          object4!.$value,
          object5!.$value,
          object6!.$value,
          object7!.$value,
          object8!.$value,
          object9!.$value,
          object10!.$value,
          object11!.$value,
          object12!.$value));
    }
    return $int(Object.hash(
        object1,
        object2,
        object3!.$value,
        object4!.$value,
        object5!.$value,
        object6!.$value,
        object7!.$value,
        object8!.$value,
        object9!.$value,
        object10!.$value,
        object11!.$value,
        object12!.$value,
        object13!.$value));
  }

  static const $Function __equals = $Function(_equals);

  static $Value? _equals(Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target?.$value == other?.$value);
  }

  static const $Function __not_equals = $Function(_not_equals);

  static $Value? _not_equals(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final other = args[0];
    return $bool(target!.$value != other!.$value);
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $String(target!.$reified.toString());
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.object);
}
