import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/override.dart';
import 'package:dart_eval/stdlib/core.dart';

class $Iterator<E> implements Iterator<E>, $Instance {
  static void configureForCompile(Compiler compiler) {
    compiler.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    //runtime.registerBridgeFunc('dart:core', 'Future.delayed', const _$Future_delayed());
  }

  static const $type = BridgeTypeRef.spec(BridgeTypeSpec('dart:core', 'Iterator'));

  static const $declaration = BridgeClassDef(BridgeClassType($type, generics: {'E': BridgeGenericParam()}),
      constructors: {},
      methods: {
        'moveNext':
            BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.type(RuntimeTypes.boolType))))
      },
      getters: {'current': BridgeMethodDef(BridgeFunctionDef(returns: BridgeTypeAnnotation(BridgeTypeRef.ref('E'))))},
      setters: {},
      fields: {},
      wrap: true);
  $Iterator(String id, Iterator<E> value) : $value = runtimeOverride(id) as Iterator<E>? ?? value;

  $Iterator.wrap(this.$value);

  @override
  final Iterator<E> $value;

  @override
  Iterator<E> get $reified {
    // iterate through the iterator and map to $value
    final values = <E>[];
    while ($value.moveNext()) {
      values.add(($value.current as $Value).$value);
    }
    return values.iterator;
  }

  late final $Instance _superclass = $Object($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'moveNext':
        return __moveNext;
      case 'current':
        return $value.current as $Value?;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __moveNext = $Function(_moveNext);

  static $Value? _moveNext(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target!.$value as Iterator).moveNext());
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}

  @override
  E get current => $value.current;

  @override
  bool moveNext() => $value.moveNext();

  @override
  int get $runtimeType => throw UnimplementedError();
}
