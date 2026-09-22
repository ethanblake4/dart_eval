// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval [$Instance] representation of an [Object]
class $Object implements $Instance {
  $Object(this.$value);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      BridgeTypeRef(CoreTypes.object),
      $extends: BridgeTypeRef(CoreTypes.dynamic),
      isAbstract: true,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object)),
          params: [],
        ),
        isFactory: false,
      ),
    },
    methods: {
      '!=': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.dynamic),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),
      '==': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
          params: [
            BridgeParameter(
              'other',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.dynamic),
                nullable: true,
              ),
              false,
            ),
          ],
        ),
      ),
      'toString': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
          params: [],
        ),
      ),
      'hash': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [
            BridgeParameter(
              'object1',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              false,
            ),
            BridgeParameter(
              'object2',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              false,
            ),
            BridgeParameter(
              'object3',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object4',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object5',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object6',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object7',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object8',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object9',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object10',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object11',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object12',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
            BridgeParameter(
              'object13',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.object),
                nullable: true,
              ),
              true,
            ),
          ],
          namedParams: [],
        ),
        isStatic: true,
      ),
    },
    getters: {
      'hashCode': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          params: [],
        ),
      ),
      'runtimeType': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.type)),
          params: [],
        ),
      ),
    },
    wrap: true,
  );

  @override
  final Object $value;

  @override
  dynamic get $reified => $value;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case '==':
        return $Closure(__equals.func, this);
      case '!=':
        return $Closure(__not_equals.func, this);
      case 'toString':
        return $Closure(__toString.func, this);
      case 'hashCode':
        return $int($value.hashCode);
    }

    throw NoSuchMethodError.withInvocation(
      $value,
      Invocation.method(Symbol(identifier), null),
    );
  }

  /// Wrapper for the [Object.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Object(Object());
  }

  /// dart_eval implementation of [Object.hash]
  ///
  /// Strange implementation is due to the use of internal-only APIs in the
  /// original method
  static $int $hash(Runtime runtime, Object? r, Object? s, Object? c) {
    final object1 = (r as $Value?)?.$value;
    final object2 = (s as $Value?)?.$value;
    final rest = c as List<Object?>;
    final object3 = rest[0] as $Value?;
    final object4 = rest[1] as $Value?;
    final object5 = rest[2] as $Value?;
    final object6 = rest[3] as $Value?;
    final object7 = rest[4] as $Value?;
    final object8 = rest[5] as $Value?;
    final object9 = rest[6] as $Value?;
    final object10 = rest[7] as $Value?;
    final object11 = rest[8] as $Value?;
    final object12 = rest[9] as $Value?;
    final object13 = rest[10] as $Value?;

    if (null == object3) {
      return $int(Object.hash(object1, object2));
    }
    if (null == object4) {
      return $int(Object.hash(object1, object2, object3.$value));
    }
    if (null == object5) {
      return $int(
        Object.hash(object1, object2, object3.$value, object4.$value),
      );
    }
    if (null == object6) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
        ),
      );
    }
    if (null == object7) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
        ),
      );
    }
    if (null == object8) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
          object7.$value,
        ),
      );
    }
    if (null == object9) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
          object7.$value,
          object8.$value,
        ),
      );
    }
    if (null == object10) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
          object7.$value,
          object8.$value,
          object9.$value,
        ),
      );
    }
    if (null == object11) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
          object7.$value,
          object8.$value,
          object9.$value,
          object10.$value,
        ),
      );
    }
    if (null == object12) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
          object7.$value,
          object8.$value,
          object9.$value,
          object10.$value,
          object11.$value,
        ),
      );
    }
    if (null == object13) {
      return $int(
        Object.hash(
          object1,
          object2,
          object3.$value,
          object4.$value,
          object5.$value,
          object6.$value,
          object7.$value,
          object8.$value,
          object9.$value,
          object10.$value,
          object11.$value,
          object12.$value,
        ),
      );
    }
    return $int(
      Object.hash(
        object1,
        object2,
        object3.$value,
        object4.$value,
        object5.$value,
        object6.$value,
        object7.$value,
        object8.$value,
        object9.$value,
        object10.$value,
        object11.$value,
        object12.$value,
        object13.$value,
      ),
    );
  }

  static const $Function __equals = $Function(_equals);

  static $Value? _equals(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target?.$value == other?.$value);
  }

  static const $Function __not_equals = $Function(_not_equals);

  static $Value? _not_equals(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final other = (r as $Value?);
    return $bool(target!.$value != other!.$value);
  }

  static const $Function __toString = $Function(_toString);

  static $Value? _toString(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    return $String(target!.$reified.toString());
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw NoSuchMethodError.withInvocation(
      $value,
      Invocation.setter(Symbol(identifier), value),
    );
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.object);
}
