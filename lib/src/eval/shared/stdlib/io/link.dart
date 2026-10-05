// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: unnecessary_cast
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'dart:io';

import 'package:dart_eval/stdlib/io.dart'
    hide
        $Platform,
        $Link,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket,
        $ZLibCodec,
        $GZipCodec,
        $ZLibEncoder,
        $ZLibDecoder,
        $FileSystemException;
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Platform,
        $Link,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket,
        $ZLibCodec,
        $GZipCodec,
        $ZLibEncoder,
        $ZLibDecoder,
        $FileSystemException;
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Platform,
        $Link,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket,
        $ZLibCodec,
        $GZipCodec,
        $ZLibEncoder,
        $ZLibDecoder,
        $FileSystemException;

/// dart_eval wrapper binding for [Link]
class $Link implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters('dart:io', 'Link.', $Link.$new);

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Link.fromUri',
      $Link.$fromUri,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Link]
  static const $spec = BridgeTypeSpec('dart:io', 'Link');

  /// Compile-time type declaration of [$Link]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Link]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      $implements: [BridgeTypeRef(IoTypes.fileSystemEntity, [])],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),

      'fromUri': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [
            BridgeParameter(
              'uri',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
              false,
            ),
          ],
        ),
        isFactory: true,
      ),
    },

    methods: {
      'create': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.link, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'recursive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),
          ],
          params: [
            BridgeParameter(
              'target',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'createSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'recursive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),
          ],
          params: [
            BridgeParameter(
              'target',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'updateSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'target',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'update': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.link, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'target',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'resolveSymbolicLinks': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'resolveSymbolicLinksSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'rename': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.link, [])),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'newPath',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'renameSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.link, [])),
          namedParams: [],
          params: [
            BridgeParameter(
              'newPath',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'delete': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.fileSystemEntity, [])),
            ]),
          ),
          namedParams: [
            BridgeParameter(
              'recursive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),
          ],
          params: [],
        ),

        isAbstract: true,
      ),

      'deleteSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [
            BridgeParameter(
              'recursive',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
              true,
              defaultValueSource: "false",
            ),
          ],
          params: [],
        ),

        isAbstract: true,
      ),

      'target': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),

      'targetSync': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    getters: {
      'absolute': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(IoTypes.link, [])),
          namedParams: [],
          params: [],
        ),

        isAbstract: true,
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Link.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Link.wrap(Link((r as $String).$value));
  }

  /// Wrapper for the [Link.fromUri] constructor
  static $Value? $fromUri(Runtime runtime, Object? r, Object? s, Object? c) {
    return $Link.wrap(Link.fromUri((r as $Value?)!.$value));
  }

  final $Instance _superclass;

  @override
  final Link $value;

  @override
  Link get $reified => $value;

  /// Wrap a [Link] in a [$Link]
  $Link.wrap(this.$value) : _superclass = $FileSystemEntity.wrap($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'absolute':
        final _absolute = $value.absolute;
        return $Link.wrap(_absolute);
      case 'create':
        return $Closure(__create.func, this);

      case 'createSync':
        return $Closure(__createSync.func, this);

      case 'updateSync':
        return $Closure(__updateSync.func, this);

      case 'update':
        return $Closure(__update.func, this);

      case 'resolveSymbolicLinks':
        return $Closure(__resolveSymbolicLinks.func, this);

      case 'resolveSymbolicLinksSync':
        return $Closure(__resolveSymbolicLinksSync.func, this);

      case 'rename':
        return $Closure(__rename.func, this);

      case 'renameSync':
        return $Closure(__renameSync.func, this);

      case 'delete':
        return $Closure(__delete.func, this);

      case 'deleteSync':
        return $Closure(__deleteSync.func, this);

      case 'target':
        return $Closure(__target.func, this);

      case 'targetSync':
        return $Closure(__targetSync.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __create = $Function(_create);
  static $Value? _create(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    final self = target! as $Link;
    final result = self.$value.create(
      (r as $String).$value,
      recursive: (s is $Value ? s : null) == null ? false : (s as $bool).$value,
    );
    return $Future.wrap(
      result.then((e) => $Link.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(IoTypes.link),
      ]),
    );
  }

  static const $Function __createSync = $Function(_createSync);
  static $Value? _createSync(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    final self = target! as $Link;
    self.$value.createSync(
      (r as $String).$value,
      recursive: (s is $Value ? s : null) == null ? false : (s as $bool).$value,
    );
    return null;
  }

  static const $Function __updateSync = $Function(_updateSync);
  static $Value? _updateSync(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    final self = target! as $Link;
    self.$value.updateSync((r as $String).$value);
    return null;
  }

  static const $Function __update = $Function(_update);
  static $Value? _update(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    final self = target! as $Link;
    final result = self.$value.update((r as $String).$value);
    return $Future.wrap(
      result.then((e) => $Link.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(IoTypes.link),
      ]),
    );
  }

  static const $Function __resolveSymbolicLinks = $Function(
    _resolveSymbolicLinks,
  );
  static $Value? _resolveSymbolicLinks(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission('filesystem:read', (target! as $Link).$value.path);
    final self = target! as $Link;
    final result = self.$value.resolveSymbolicLinks();
    return $Future.wrap(
      result.then((e) => $String(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  static const $Function __resolveSymbolicLinksSync = $Function(
    _resolveSymbolicLinksSync,
  );
  static $Value? _resolveSymbolicLinksSync(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission('filesystem:read', (target! as $Link).$value.path);
    final self = target! as $Link;
    final result = self.$value.resolveSymbolicLinksSync();
    return $String(result);
  }

  static const $Function __rename = $Function(_rename);
  static $Value? _rename(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    runtime.assertPermission('filesystem:write', Runtime.permissionData(r));
    final self = target! as $Link;
    final result = self.$value.rename((r as $String).$value);
    return $Future.wrap(
      result.then((e) => $Link.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(IoTypes.link),
      ]),
    );
  }

  static const $Function __renameSync = $Function(_renameSync);
  static $Value? _renameSync(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    runtime.assertPermission('filesystem:write', Runtime.permissionData(r));
    final self = target! as $Link;
    final result = self.$value.renameSync((r as $String).$value);
    return $Link.wrap(result);
  }

  static const $Function __delete = $Function(_delete);
  static $Value? _delete(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    final self = target! as $Link;
    final result = self.$value.delete(
      recursive: (r is $Value ? r : null) == null ? false : (r as $bool).$value,
    );
    return $Future.wrap(
      result.then((e) => $FileSystemEntity.wrap(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(IoTypes.fileSystemEntity),
      ]),
    );
  }

  static const $Function __deleteSync = $Function(_deleteSync);
  static $Value? _deleteSync(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission(
      'filesystem:write',
      (target! as $Link).$value.path,
    );
    final self = target! as $Link;
    self.$value.deleteSync(
      recursive: (r is $Value ? r : null) == null ? false : (r as $bool).$value,
    );
    return null;
  }

  static const $Function __target = $Function(_target);
  static $Value? _target(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission('filesystem:read', (target! as $Link).$value.path);
    final self = target! as $Link;
    final result = self.$value.target();
    return $Future.wrap(
      result.then((e) => $String(e)),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  static const $Function __targetSync = $Function(_targetSync);
  static $Value? _targetSync(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    runtime.assertPermission('filesystem:read', (target! as $Link).$value.path);
    final self = target! as $Link;
    final result = self.$value.targetSync();
    return $String(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
