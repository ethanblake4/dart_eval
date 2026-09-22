import 'dart:io';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/io_sink.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper for [HttpClient]
class $HttpClient implements $Instance {
  $HttpClient.wrap(this.$value);

  @override
  final HttpClient $value;

  late final $Instance _superclass = $Object($value);

  /// Compile-time bridged type reference for [$HttpClient]
  static const $type = BridgeTypeRef(BridgeTypeSpec('dart:io', 'HttpClient'));

  /// Compile-time bridged class declaration for [$HttpClient]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          namedParams: [],
        ),
      ),
    },
    methods: {
      'get': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.httpClientRequest)),
            ]),
          ),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'post': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.httpClientRequest)),
            ]),
          ),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'put': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.httpClientRequest)),
            ]),
          ),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
            BridgeParameter(
              'port',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
              false,
            ),
            BridgeParameter(
              'path',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'getUrl': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.httpClientRequest)),
            ]),
          ),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'postUrl': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.httpClientRequest)),
            ]),
          ),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
      'putUrl': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(IoTypes.httpClientRequest)),
            ]),
          ),
          params: [
            BridgeParameter(
              'url',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri)),
              false,
            ),
          ],
          namedParams: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  static $HttpClient $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $HttpClient.wrap(HttpClient());
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'get':
        return $Closure(__get.func, this);
      case 'post':
        return $Closure(__post.func, this);
      case 'put':
        return $Closure(__put.func, this);
      case 'getUrl':
        return $Closure(__getUrl.func, this);
      case 'postUrl':
        return $Closure(__postUrl.func, this);
      case 'putUrl':
        return $Closure(__putUrl.func, this);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __get = $Function(_get);

  static $Value? _get(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final url = (r as $Value?)!.$value as String;
    final port = (s as $Value?)!.$value as int;
    final path = ((c as List<Object?>)[0] as $Value?)!.$value as String;
    if (!runtime.checkPermission('network', '$url/$path')) {
      runtime.assertPermission('network', '$url:$port/$path');
    }
    final request = (target!.$value as HttpClient).get(url, port, path);
    return $Future.wrap(
      request.then((value) => $HttpClientRequest.wrap(value)),
    );
  }

  static const $Function __post = $Function(_post);

  static $Value? _post(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final url = (r as $Value?)!.$value as String;
    final port = (s as $Value?)!.$value as int;
    final path = ((c as List<Object?>)[0] as $Value?)!.$value as String;
    if (!runtime.checkPermission('network', '$url/$path')) {
      runtime.assertPermission('network', '$url:$port/$path');
    }
    final request = (target!.$value as HttpClient).post(url, port, path);
    return $Future.wrap(
      request.then((value) => $HttpClientRequest.wrap(value)),
    );
  }

  static const $Function __put = $Function(_put);

  static $Value? _put(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final url = (r as $Value?)!.$value as String;
    final port = (s as $Value?)!.$value as int;
    final path = ((c as List<Object?>)[0] as $Value?)!.$value as String;
    if (!runtime.checkPermission('network', '$url/$path')) {
      runtime.assertPermission('network', '$url:$port/$path');
    }
    final request = (target!.$value as HttpClient).put(url, port, path);
    return $Future.wrap(
      request.then((value) => $HttpClientRequest.wrap(value)),
    );
  }

  static const $Function __getUrl = $Function(_getUrl);

  static $Value? _getUrl(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final url = (r as $Value?)!.$value as Uri;
    runtime.assertPermission('network', url.toString());
    final request = (target!.$value as HttpClient).getUrl(url);
    return $Future.wrap(
      request.then((value) => $HttpClientRequest.wrap(value)),
    );
  }

  static const $Function __postUrl = $Function(_postUrl);

  static $Value? _postUrl(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final url = (r as $Value?)!.$value as Uri;
    runtime.assertPermission('network', url.toString());
    final request = (target!.$value as HttpClient).postUrl(url);
    return $Future.wrap(
      request.then((value) => $HttpClientRequest.wrap(value)),
    );
  }

  static const $Function __putUrl = $Function(_putUrl);

  static $Value? _putUrl(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final url = (r as $Value?)!.$value as Uri;
    runtime.assertPermission('network', url.toString());
    final request = (target!.$value as HttpClient).putUrl(url);
    return $Future.wrap(
      request.then((value) => $HttpClientRequest.wrap(value)),
    );
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {}
}

/// dart_eval wrapper for [HttpClientRequest]
class $HttpClientRequest implements $Instance {
  $HttpClientRequest.wrap(this.$value);

  @override
  final HttpClientRequest $value;

  /// Compile-time bridged type reference for [$HttpClientRequest]
  static const $type = BridgeTypeRef(
    BridgeTypeSpec('dart:io', 'HttpClientRequest'),
  );

  /// Compile-time bridged class declaration for [$HttpClientRequest]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true, $implements: [$IOSink.$type]),
    constructors: {},
    methods: {
      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation($HttpClientResponse.$type),
            ]),
          ),
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  late final _superclass = $IOSink.wrap($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'close':
        return $Closure(__close.func, this);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  static const $Function __close = $Function(_close);

  static $Value? _close(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final request = target!.$value as HttpClientRequest;
    return $Future.wrap(
      request.close().then((value) => $HttpClientResponse.wrap(value)),
    );
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }
}

/// dart_eval wrapper for [HttpClientResponse]
class $HttpClientResponse implements $Instance {
  $HttpClientResponse.wrap(this.$value);

  @override
  final HttpClientResponse $value;

  /// Compile-time bridged type reference for [$HttpClientResponse]
  static const $type = BridgeTypeRef(
    BridgeTypeSpec('dart:io', 'HttpClientResponse'),
  );

  /// Compile-time bridged class declaration for [$HttpClientResponse]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      $extends: BridgeTypeRef(CoreTypes.stream, [
        BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.list, [
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
          ]),
        ),
      ]),
    ),
    constructors: {},
    methods: {},
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  late final _superclass = $Stream.wrap($value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    _superclass.$setProperty(runtime, identifier, value);
  }
}
