import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

class $Iterator<E> implements Iterator, $Instance {
  $Iterator.wrap(this.$value) : _superclass = $Object($value);

  @override
  final Iterator<E> $value;

  @override
  Iterator<E> get $reified => $value;

  final $Instance _superclass;

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'current':
        return $value.current as $Value;
      case 'moveNext':
        return __moveNext;
    }
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    throw UnimplementedError();
  }

  static const $Function __moveNext = $Function(_moveNext);

  static $Value? _moveNext(final Runtime runtime, final $Value? target, final List<$Value?> args) {
    return $bool(((target as $Value).$value as Iterator).moveNext());
  }

  @override
  E get current => $value.current;

  @override
  bool moveNext() => $value.moveNext();

  @override
  int get $runtimeType => throw UnimplementedError();
}

class $Iterator$bridge<E> with $Bridge implements Iterator<E> {
  const $Iterator$bridge(List<Object?> _);

  static const $type =
      BridgeClassTypeDeclaration('dart:core', 'Iterator', isAbstract: true, generics: {'E': BridgeGenericParam()});

  @override
  $Value? $bridgeGet(String identifier) {
    switch (identifier) {
      case 'current':
        throw UnimplementedError();
    }
    throw UnimplementedError();
  }

  @override
  bool moveNext() => $_invoke('moveNext', []);

  @override
  E get current => $_get('current');

  @override
  void $bridgeSet(String identifier, $Value value) {
    throw UnimplementedError();
  }

  @override
  int get $runtimeType => throw UnimplementedError();
}
