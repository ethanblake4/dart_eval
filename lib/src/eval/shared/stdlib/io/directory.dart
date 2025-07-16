import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/future.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/file_system_entity.dart';

/// dart_eval wrapper for [Directory]
class $Directory implements $Instance {
  /// Wrap a [Directory] in a [$Directory]
  $Directory.wrap(this.$value);

  @override
  final Directory $value;

  @override
  get $reified => $value;

  late final $Instance _superclass = $FileSystemEntity.wrap($value);

  /// Compile-time bridged type reference for [$Directory]
  static const $type = BridgeTypeRef(IoTypes.directory);

  /// Compile-time bridged class declaration for [$Directory]
  static const $declaration = BridgeClassDef(
      BridgeClassType($type, $extends: $FileSystemEntity.$type),
      constructors: {
        '': BridgeConstructorDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
        ], namedParams: []))
      },
      methods: {
        'create': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))])),
            params: [],
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'createSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [],
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'rename': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.future, [BridgeTypeAnnotation($type)])),
            params: [
              BridgeParameter('newPath',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
            ],
            namedParams: [])),
        'renameSync': BridgeMethodDef(
            BridgeFunctionDef(returns: BridgeTypeAnnotation($type), params: [
          BridgeParameter('newPath',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
        ], namedParams: [])),
        'list': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.stream, [
                BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileSystemEntity))
              ]),
            ),
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
              BridgeParameter('followLinks',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'listSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileSystemEntity))
            ])),
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
              BridgeParameter('followLinks',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
      },
      wrap: true);

  static $Directory $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $Directory.wrap(Directory(args[0]!.$value));
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'create':
        return _create;
      case 'createSync':
        return _createSync;
      case 'rename':
        return _rename;
      case 'renameSync':
        return _renameSync;
      case 'list':
        return _list;
      case 'listSync':
        return _listSync;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }

  static const $Function _create = $Function(__create);

  static $Value? __create(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as Directory;
    runtime.assertPermission('filesystem:write', entity.path);
    return $Future
        .wrap(entity.create().then((value) => $Directory.wrap(value)));
  }

  static const $Function _createSync = $Function(__createSync);

  static $Value? __createSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as Directory;
    runtime.assertPermission('filesystem:write', entity.path);
    entity.createSync();
    return null;
  }

  static const $Function _rename = $Function(__rename);

  static $Value? __rename(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as Directory;
    runtime.assertPermission('filesystem:write', entity.path);
    final newPath = args[0]!.$value as String;
    runtime.assertPermission('filesystem:write', newPath);
    return $Future
        .wrap(entity.rename(newPath).then((value) => $Directory.wrap(value)));
  }

  static const $Function _renameSync = $Function(__renameSync);

  static $Value? __renameSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as Directory;
    runtime.assertPermission('filesystem:write', entity.path);
    final newPath = args[0]!.$value as String;
    runtime.assertPermission('filesystem:write', newPath);
    return $Directory.wrap(entity.renameSync(newPath));
  }

  static const $Function _list = $Function(__list);

  static $Value? __list(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as Directory;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Stream.wrap(entity
        .list(
            recursive: args[0]?.$value as bool? ?? false,
            followLinks: args[1]?.$value as bool? ?? false)
        .map((event) => $FileSystemEntity.wrap(event)));
  }

  static const $Function _listSync = $Function(__listSync);

  static $Value? __listSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as Directory;
    runtime.assertPermission('filesystem:read', entity.path);
    return $List.wrap(entity
        .listSync(
            recursive: args[0]?.$value as bool? ?? false,
            followLinks: args[1]?.$value as bool? ?? false)
        .map((item) => $FileSystemEntity.wrap(item))
        .toList());
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);
}
