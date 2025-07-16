import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/directory.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [FileSystemEntity]
class $FileSystemEntity implements $Instance {
  /// Wrap a [FileSystemEntity] in a [$FileSystemEntity]
  $FileSystemEntity.wrap(this.$value);

  @override
  final FileSystemEntity $value;

  late final $Instance _superclass = $Object($value);

  /// Compile-time bridged type reference for [$FileSystemEntity]
  static const $type = BridgeTypeRef(IoTypes.fileSystemEntity);

  /// Compile-time bridged class declaration for [$FileSystemEntity]
  static const $declaration = BridgeClassDef(BridgeClassType($type),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type), params: [], namedParams: []))
      },
      methods: {
        'exists': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool))])),
            params: [],
            namedParams: [])),
        'existsSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
            params: [],
            namedParams: [])),
        'delete': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))])),
            params: [],
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true)
            ])),
        'deleteSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [],
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true)
            ])),
        'rename': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileSystemEntity))
            ])),
            params: [
              BridgeParameter('newPath', BridgeTypeAnnotation($type), false)
            ],
            namedParams: [])),
        'renameSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type),
            params: [
              BridgeParameter('newPath', BridgeTypeAnnotation($type), false)
            ],
            namedParams: [])),
      },
      getters: {
        'path': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            params: [],
            namedParams: [])),
        'absolute': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation($type), params: [], namedParams: [])),
        'parent': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.directory)),
            params: [],
            namedParams: [])),
        'uri': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
            params: [],
            namedParams: [])),
      },
      wrap: true);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'path':
        return $String($value.path);
      case 'absolute':
        return $FileSystemEntity.wrap($value.absolute);
      case 'parent':
        runtime.assertPermission('filesystem:read', $value.path);
        return $Directory.wrap($value.parent);
      case 'uri':
        return $Uri.wrap($value.uri);
      case 'exists':
        return _exists;
      case 'existsSync':
        return _existsSync;
      case 'delete':
        return _delete;
      case 'deleteSync':
        return _deleteSync;
      case 'rename':
        return _rename;
      case 'renameSync':
        return _renameSync;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function _exists = $Function(__exists);

  static $Value? __exists(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as FileSystemEntity;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future.wrap(entity.exists().then((value) => $bool(value)));
  }

  static const $Function _existsSync = $Function(__existsSync);

  static $Value? __existsSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as FileSystemEntity;
    runtime.assertPermission('filesystem:read', entity.path);
    return $bool(entity.existsSync());
  }

  static const $Function _delete = $Function(__delete);

  static $Value? __delete(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as FileSystemEntity;
    runtime.assertPermission('filesystem:write', entity.path);
    final recursive = args[0]?.$value as bool?;
    return $Future.wrap(entity
        .delete(recursive: recursive ?? false)
        .then((value) => $FileSystemEntity.wrap(value)));
  }

  static const $Function _deleteSync = $Function(__deleteSync);

  static $Value? __deleteSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as FileSystemEntity;
    runtime.assertPermission('filesystem:write', entity.path);
    final recursive = args[0]?.$value as bool?;
    entity.deleteSync(recursive: recursive ?? false);
    return null;
  }

  static const $Function _rename = $Function(__rename);

  static $Value? __rename(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as FileSystemEntity;
    runtime.assertPermission('filesystem:write', entity.path);
    final newPath = args[0]!.$value as String;
    return $Future.wrap(
        entity.rename(newPath).then((value) => $FileSystemEntity.wrap(value)));
  }

  static const $Function _renameSync = $Function(__renameSync);

  static $Value? __renameSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as FileSystemEntity;
    runtime.assertPermission('filesystem:write', entity.path);
    final newPath = args[0]!.$value as String;
    return $FileSystemEntity.wrap(entity.renameSync(newPath));
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
