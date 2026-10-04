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

import 'dart:async';

import './stream_transformer.dart';

import 'package:dart_eval/stdlib/async.dart'
    hide
        $Completer,
        $Timer,
        $TimeoutException,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $EventSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamTransformerBase,
        $StreamView,
        $StreamController;
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Completer,
        $Timer,
        $TimeoutException,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $EventSink,
        $StreamIterator,
        $StreamTransformer,
        $StreamTransformerBase,
        $StreamView,
        $StreamController;
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';

/// dart_eval bridge binding for [StreamTransformerBase]
class $StreamTransformerBase$bridge<S, T> extends StreamTransformerBase<S, T>
    with $Bridge<StreamTransformerBase<S, T>> {
  /// Forwarded constructor for [StreamTransformerBase.new]
  $StreamTransformerBase$bridge();

  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'StreamTransformerBase.',
      $StreamTransformerBase$bridge.$new,
      isBridge: true,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StreamTransformerBase$bridge]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamTransformerBase');

  /// Compile-time type declaration of [$StreamTransformerBase$bridge]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StreamTransformerBase]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'S': BridgeGenericParam(), 'T': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(AsyncTypes.streamTransformer, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
          BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
        ]),
      ],
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          namedParams: [],
          params: [],
        ),
        isFactory: false,
      ),
    },

    methods: {
      'bind': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.stream, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
            ]),
          ),
          namedParams: [],
          params: [
            BridgeParameter(
              'stream',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stream, [
                  BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
                ]),
              ),
              false,
            ),
          ],
        ),

        isAbstract: true,
      ),

      'cast': BridgeMethodDef(
        BridgeFunctionDef(
          generics: {'RS': BridgeGenericParam(), 'RT': BridgeGenericParam()},
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(AsyncTypes.streamTransformer, [
              BridgeTypeAnnotation(BridgeTypeRef.ref('RS')),
              BridgeTypeAnnotation(BridgeTypeRef.ref('RT')),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: false,
    bridge: true,
  );

  /// Proxy for the [StreamTransformerBase.new] constructor
  static $Value? $new(Runtime runtime, Object? r, Object? s, Object? c) {
    return $StreamTransformerBase$bridge();
  }

  @override
  $Value? $bridgeGet(String identifier) {
    final runtime = $runtime;
    switch (identifier) {
      case 'cast':
        return $Function((runtime, target, r, s, c) {
          final result = super.cast();
          return $StreamTransformer.wrap(result);
        });
    }
    return $bridgeGetObject(
      identifier,
      hashCode: () => super.hashCode,
      equals: (other) => super == other,
      toString: () => super.toString(),
    );
  }

  @override
  void $bridgeSet(String identifier, $Value value) {}

  @override
  Stream<T> bind(Stream<S> stream) {
    final runtime = $runtime;
    return $_invoke('bind', [
      $Stream.wrap(stream.map((e) => runtime.wrapAlways(e, recursive: true))),
    ]);
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    final runtime = $runtime;
    return $_invoke('cast', []);
  }
}

/// dart_eval lightweight wrapper binding for [StreamTransformerBase]
class $StreamTransformerBase<S, T> implements $Instance {
  /// Compile-time type specification of [$StreamTransformerBase]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamTransformerBase');

  /// Compile-time type declaration of [$StreamTransformerBase]
  static const $type = BridgeTypeRef($spec);

  final $Instance _superclass;

  @override
  final StreamTransformerBase<S, T> $value;

  @override
  StreamTransformerBase<S, T> get $reified => $value;

  /// Wrap a [StreamTransformerBase] in a [$StreamTransformerBase]
  $StreamTransformerBase.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) {
    final data = Runtime.bridgeData[this];
    return data == null
        ? runtime.lookupType($spec)
        : runtime.importRuntimeType(data.runtime, data.$runtimeType);
  }

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'bind':
        return $Closure(__bind.func, this);

      case 'cast':
        return $Closure(__cast.func, this);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __bind = $Function(_bind);
  static $Value? _bind(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamTransformerBase;
    final result = self.$value.bind((r as $Value?)!.$value);
    return $Stream.wrap(
      result.map(
        (e) => (e is List || e is Map || e is Set
            ? TypedInterop.boxExternal(e, runtime: runtime)!
            : runtime.wrapAlways(e)),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.stream, [
        runtime.runtimeTypeArgumentAt(self.$getRuntimeType(runtime), 1) ??
            runtime.lookupType(CoreTypes.dynamic),
      ]),
    );
  }

  static const $Function __cast = $Function(_cast);
  static $Value? _cast(
    Runtime runtime,
    $Value? target,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final self = target! as $StreamTransformerBase;
    final result = self.$value.cast();
    return $StreamTransformer.wrap(result);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
