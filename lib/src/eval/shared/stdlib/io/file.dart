import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/date_time.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/future.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/file_system_entity.dart';

/// dart_eval wrapper for [File]
class $File implements $Instance {
  /// Wrap a [File] in a [$File]
  $File.wrap(this.$value);

  @override
  final File $value;

  @override
  get $reified => $value;

  late final $Instance _superclass = $FileSystemEntity.wrap($value);

  /// Compile-time bridged type reference for [$File]
  static const $type = BridgeTypeRef(IoTypes.file);

  /// Compile-time bridged class declaration for [$File]
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
              BridgeParameter('exclusive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'createSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [],
            namedParams: [
              BridgeParameter('recursive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
              BridgeParameter('exclusive',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'rename': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.future, [BridgeTypeAnnotation($type)])),
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
        'openRead': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                  [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))]))
            ])),
            params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int),
                      nullable: true),
                  true),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int),
                      nullable: true),
                  true),
            ],
            namedParams: [])),
        'openWrite': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.ioSink)),
            params: [],
            namedParams: [
              //BridgeParameter('mode', BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileModeType)), true),
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
            ])),
        'length': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))],
            )),
            params: [],
            namedParams: [])),
        'lengthSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            params: [],
            namedParams: [])),
        'lastAccessed': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime))],
            )),
            params: [],
            namedParams: [])),
        'lastAccessedSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
            params: [],
            namedParams: [])),
        'lastModified': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime))],
            )),
            params: [],
            namedParams: [])),
        'lastModifiedSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
            params: [],
            namedParams: [])),
        'setLastAccessed': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))],
            )),
            params: [
              BridgeParameter(
                  'time',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                  false)
            ],
            namedParams: [])),
        'setLastAccessedSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'time',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                  false)
            ],
            namedParams: [])),
        'setLastModified': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))],
            )),
            params: [
              BridgeParameter(
                  'time',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                  false)
            ],
            namedParams: [])),
        'setLastModifiedSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'time',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dateTime)),
                  false)
            ],
            namedParams: [])),
        'readAsString': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))],
            )),
            params: [],
            namedParams: [
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
            ])),
        'readAsStringSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            params: [],
            namedParams: [
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
            ])),
        'readAsBytes': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                    [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))]))
              ],
            )),
            params: [],
            namedParams: [])),
        'readAsBytesSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
            params: [],
            namedParams: [])),
        'writeAsString': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))],
            )),
            params: [
              BridgeParameter('contents',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
            ],
            namedParams: [
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
              //BridgeParameter('mode', BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileModeType)), true),
              BridgeParameter('flush',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'writeAsStringSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter('contents',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)), false)
            ],
            namedParams: [
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
              //BridgeParameter('mode', BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileModeType)), true),
              BridgeParameter('flush',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'writeAsBytes': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType))],
            )),
            params: [
              BridgeParameter(
                  'bytes',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                      [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
                  false)
            ],
            namedParams: [
              //BridgeParameter('mode', BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileModeType)), true),
              BridgeParameter('flush',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'writeAsBytesSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
            params: [
              BridgeParameter(
                  'bytes',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                      [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))])),
                  false)
            ],
            namedParams: [
              //BridgeParameter('mode', BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileModeType)), true),
              BridgeParameter('flush',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)), true),
            ])),
        'readAsLines': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(
              CoreTypes.future,
              [
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                    [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))]))
              ],
            )),
            params: [],
            namedParams: [
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
            ])),
        'readAsLinesSync': BridgeMethodDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list,
                [BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string))])),
            params: [],
            namedParams: [
              //BridgeParameter('encoding', BridgeTypeAnnotation(BridgeTypeRef(ConvertTypes.encodingType)), true),
            ])),
      },
      wrap: true);

  static $File $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $File.wrap(File(args[0]!.$value));
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
      case 'lastAccessed':
        return _lastAccessed;
      case 'lastAccessedSync':
        return _lastAccessedSync;
      case 'setLastAccessed':
        return _setLastAccessed;
      case 'setLastAccessedSync':
        return _setLastAccessedSync;
      case 'lastModified':
        return _lastModified;
      case 'lastModifiedSync':
        return _lastModifiedSync;
      case 'setLastModified':
        return _setLastModified;
      case 'setLastModifiedSync':
        return _setLastModifiedSync;
      case 'length':
        return _length;
      case 'lengthSync':
        return _lengthSync;
      /*case 'open':
        return _open;
      case 'openSync':
        return _openSync;*/
      case 'readAsString':
        return _readAsString;
      case 'readAsStringSync':
        return _readAsStringSync;
      case 'readAsBytes':
        return _readAsBytes;
      case 'readAsBytesSync':
        return _readAsBytesSync;
      case 'readAsLines':
        return _readAsLines;
      case 'readAsLinesSync':
        return _readAsLinesSync;
      case 'writeAsString':
        return _writeAsString;
      case 'writeAsStringSync':
        return _writeAsStringSync;
      case 'writeAsBytes':
        return _writeAsBytes;
      case 'writeAsBytesSync':
        return _writeAsBytesSync;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function _create = $Function(__create);

  static $Value? __create(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:write', entity.path);
    return $Future.wrap(entity.create().then((value) => $File.wrap(value)));
  }

  static const $Function _createSync = $Function(__createSync);

  static $Value? __createSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:write', entity.path);
    entity.createSync();
    return null;
  }

  static const $Function _lastAccessed = $Function(__lastAccessed);

  static $Value? __lastAccessed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future
        .wrap(entity.lastAccessed().then((value) => $DateTime.wrap(value)));
  }

  static const $Function _lastAccessedSync = $Function(__lastAccessedSync);

  static $Value? __lastAccessedSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $DateTime.wrap(entity.lastAccessedSync());
  }

  static const $Function _lastModified = $Function(__lastModified);

  static $Value? __lastModified(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future
        .wrap(entity.lastModified().then((value) => $DateTime.wrap(value)));
  }

  static const $Function _lastModifiedSync = $Function(__lastModifiedSync);

  static $Value? __lastModifiedSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $DateTime.wrap(entity.lastModifiedSync());
  }

  static const $Function _length = $Function(__length);

  static $Value? __length(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future.wrap(entity.length().then((value) => $int(value)));
  }

  static const $Function _lengthSync = $Function(__lengthSync);

  static $Value? __lengthSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $int(entity.lengthSync());
  }

  /*static const $Function _open = $Function(__open);

  static $Value? __open(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future.wrap(entity.open().then((value) => $RandomAccessFile.wrap(value)));
  }

  static const $Function _openSync = $Function(__openSync);

  static $Value? __openSync(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $RandomAccessFile.wrap(entity.openSync());
  }*/

  static const $Function _readAsString = $Function(__readAsString);

  static $Value? __readAsString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future.wrap(entity.readAsString().then((value) => $String(value)));
  }

  static const $Function _readAsStringSync = $Function(__readAsStringSync);

  static $Value? __readAsStringSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $String(entity.readAsStringSync());
  }

  static const $Function _readAsBytes = $Function(__readAsBytes);

  static $Value? __readAsBytes(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future
        .wrap(entity.readAsBytes().then((value) => $List.wrap(value)));
  }

  static const $Function _readAsBytesSync = $Function(__readAsBytesSync);

  static $Value? __readAsBytesSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $List.wrap(entity.readAsBytesSync());
  }

  static const $Function _readAsLines = $Function(__readAsLines);

  static $Value? __readAsLines(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $Future
        .wrap(entity.readAsLines().then((value) => $List.wrap(value)));
  }

  static const $Function _readAsLinesSync = $Function(__readAsLinesSync);

  static $Value? __readAsLinesSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    runtime.assertPermission('filesystem:read', entity.path);
    return $List.wrap(entity.readAsLinesSync());
  }

  static const $Function _rename = $Function(__rename);

  static $Value? __rename(Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final newPath = args[0]!.$value as String;
    runtime.assertPermission('filesystem:write', entity.path);
    runtime.assertPermission('filesystem:write', newPath);
    return $Future
        .wrap(entity.rename(newPath).then((value) => $File.wrap(value)));
  }

  static const $Function _renameSync = $Function(__renameSync);

  static $Value? __renameSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final newPath = args[0]!.$value as String;
    runtime.assertPermission('filesystem:write', entity.path);
    runtime.assertPermission('filesystem:write', newPath);
    return $File.wrap(entity.renameSync(newPath));
  }

  static const $Function _setLastAccessed = $Function(__setLastAccessed);

  static $Value? __setLastAccessed(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final time = args[0]!.$value as DateTime;
    runtime.assertPermission('filesystem:write', entity.path);
    return $Future.wrap(entity.setLastAccessed(time));
  }

  static const $Function _setLastAccessedSync =
      $Function(__setLastAccessedSync);

  static $Value? __setLastAccessedSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final time = args[0]!.$value as DateTime;
    runtime.assertPermission('filesystem:write', entity.path);
    entity.setLastAccessedSync(time);
    return null;
  }

  static const $Function _setLastModified = $Function(__setLastModified);

  static $Value? __setLastModified(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final time = args[0]!.$value as DateTime;
    runtime.assertPermission('filesystem:write', entity.path);
    return $Future.wrap(entity.setLastModified(time));
  }

  static const $Function _setLastModifiedSync =
      $Function(__setLastModifiedSync);

  static $Value? __setLastModifiedSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final time = args[0]!.$value as DateTime;
    runtime.assertPermission('filesystem:write', entity.path);
    entity.setLastModifiedSync(time);
    return null;
  }

  static const $Function _writeAsString = $Function(__writeAsString);

  static $Value? __writeAsString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final contents = args[0]!.$value as String;
    //final mode = args[1]!.$value as FileMode;
    //final encoding = args[2]!.$value as Encoding;
    runtime.assertPermission('filesystem:write', entity.path);
    return $Future.wrap(
        entity.writeAsString(contents /*, mode: mode, encoding: encoding*/));
  }

  static const $Function _writeAsStringSync = $Function(__writeAsStringSync);

  static $Value? __writeAsStringSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final contents = args[0]!.$value as String;
    //final mode = args[1]!.$value as FileMode;
    //final encoding = args[2]!.$value as Encoding;
    runtime.assertPermission('filesystem:write', entity.path);
    entity.writeAsStringSync(contents /*, mode: mode, encoding: encoding*/);
    return null;
  }

  static const $Function _writeAsBytes = $Function(__writeAsBytes);

  static $Value? __writeAsBytes(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final bytes = args[0]!.$value as List<int>;
    //final mode = args[1]!.$value as FileMode;
    runtime.assertPermission('filesystem:write', entity.path);
    return $Future.wrap(entity.writeAsBytes(bytes /*, mode: mode*/));
  }

  static const $Function _writeAsBytesSync = $Function(__writeAsBytesSync);

  static $Value? __writeAsBytesSync(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final entity = target!.$value as File;
    final bytes = args[0]!.$value as List<int>;
    //final mode = args[1]!.$value as FileMode;
    runtime.assertPermission('filesystem:write', entity.path);
    entity.writeAsBytesSync(bytes /*, mode: mode*/);
    return null;
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
