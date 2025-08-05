import 'dart:collection';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';

/// Writeback-capable wrapper for [ListQueue] with type mapping function
class $ListQueue<E> implements $Instance {
  static const $type = BridgeTypeRef(CollectionTypes.listQueue);
  static const $declaration = BridgeClassDef(
      BridgeClassType($type,
          $extends: BridgeTypeRef(CoreTypes.iterable),
          generics: {'E': BridgeGenericParam()}),
      constructors: {},
      methods: {
        'add': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'value',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'addAll': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'iterable',
                    BridgeTypeAnnotation(
                        BridgeTypeRef(CoreTypes.iterable, [
                          BridgeTypeAnnotation(BridgeTypeRef.ref('E', [])),
                        ]),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'addFirst': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'value',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'addLast': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'value',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'remove': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'value',
                    BridgeTypeAnnotation(BridgeTypeRef.ref('E', []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'retainWhere': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'test',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
        'removeWhere': BridgeMethodDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType, []),
                  nullable: false),
              params: [
                BridgeParameter(
                    'test',
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.function, []),
                        nullable: false),
                    false)
              ],
              namedParams: [],
            ),
            isStatic: false),
      },
      wrap: true);

  $ListQueue(this.$value, this.mapper) : _superclass = $Iterable.wrap($value);

  @override
  final ListQueue<E> $value;
  final $Value Function(E) mapper;

  final $Instance _superclass;

  $Value $map(E value) {
    if (value == null) return $null();
    return mapper(value);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'add':
        return __add;
      case 'addAll':
        return __addAll;
      case 'addFirst':
        return __addFirst;
      case 'addLast':
        return __addLast;
      case 'where':
        return __where;
      case 'first':
        return $map($value.first);
      case 'last':
        return $map($value.last);
      case 'single':
        return $map($value.single);
      case 'remove':
        return __remove;
      case 'retainWhere':
        return __retainWhere;
      case 'removeWhere':
        return __removeWhere;
      case 'takeWhile':
        return __takeWhile;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __add = $Function(_add);

  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0]!;
    (target! as ListQueue).add(value.$value);
    return null;
  }

  static const $Function __addAll = $Function(_addAll);

  static $Value? _addAll(Runtime runtime, $Value? target, List<$Value?> args) {
    (target! as ListQueue).addAll(args[0]!.$reified);
    return null;
  }

  static const $Function __addFirst = $Function(_addFirst);
  static $Value? _addFirst(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0]!;
    (target! as ListQueue).addFirst(value.$value);
    return null;
  }

  static const $Function __addLast = $Function(_addLast);
  static $Value? _addLast(Runtime runtime, $Value? target, List<$Value?> args) {
    final value = args[0]!;
    (target! as ListQueue).addLast(value.$value);
    return null;
  }

  static const $Function __remove = $Function(_remove);

  static $Value? _remove(Runtime runtime, $Value? target, List<$Value?> args) {
    return $bool((target! as ListQueue).remove(args[0]!.$reified));
  }

  static const $Function __where = $Function(_where);

  static $Value? _where(Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = target! as $ListQueue;
    return $Iterable.wrap(view.$value
        .where((e) => test.call(runtime, null, [e])!.$value as bool)
        .map((e) => view.$map(e)));
  }

  static const $Function __retainWhere = $Function(_retainWhere);

  static $Value? _retainWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = (target! as $ListQueue);

    view.$value.retainWhere(
        (e) => test.call(runtime, null, [view.$map(e)])!.$value as bool);
    return null;
  }

  static const $Function __removeWhere = $Function(_removeWhere);

  static $Value? _removeWhere(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = (target! as $ListQueue);

    view.$value.removeWhere(
        (e) => test.call(runtime, null, [view.$map(e)])!.$value as bool);
    return null;
  }

  static const $Function __takeWhile = $Function(_takeWhile);

  static $Value? _takeWhile(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final test = args[0] as EvalCallable;
    final view = (target! as $ListQueue);

    return $Iterable.wrap(view.$value
        .takeWhile((e) => test.call(runtime, null, [view.$map(e)])!.$value));
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CollectionTypes.listQueue);

  @override
  get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
