// ignore_for_file: unused_import, unnecessary_import
// ignore_for_file: always_specify_types, avoid_redundant_argument_values
// ignore_for_file: sort_constructors_first
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: prefer_is_empty
// ignore_for_file: undefined_hidden_name
// ignore_for_file: dead_code, unused_local_variable
// ignore_for_file: unnecessary_type_check, unnecessary_non_null_assertion
// ignore_for_file: sdk_version_since
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: argument_type_not_assignable_to_error_handler
// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

import 'dart:async';
import 'package:dart_eval/stdlib/core.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamTransformer,
        $StreamView,
        $StreamController;
import 'package:dart_eval/stdlib/async.dart'
    hide
        $Completer,
        $Timer,
        $Zone,
        $StreamSubscription,
        $StreamSink,
        $StreamTransformer,
        $StreamView,
        $StreamController;

/// dart_eval wrapper binding for [StreamSink]
class $StreamSink<S> implements $Instance {
  /// Configure this class for use in a [Runtime]
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {}

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$StreamSink]
  static const $spec = BridgeTypeSpec('dart:async', 'StreamSink');

  /// Compile-time type declaration of [$StreamSink]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$StreamSink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,

      generics: {'S': BridgeGenericParam()},

      $implements: [
        BridgeTypeRef(CoreTypes.object, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
        ]),
        BridgeTypeRef(CoreTypes.sink, [
          BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
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
      'addStream': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
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
      ),

      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),

      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'event',
              BridgeTypeAnnotation(BridgeTypeRef.ref('S')),
              false,
            ),
          ],
        ),
      ),

      'addError': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'error',
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, [])),
              false,
            ),

            BridgeParameter(
              'stackTrace',
              BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stackTrace, []),
                nullable: true,
              ),
              true,
            ),
          ],
        ),
      ),
    },
    getters: {
      'done': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.future, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
            ]),
          ),
          namedParams: [],
          params: [],
        ),
      ),
    },
    setters: {},
    fields: {},
    wrap: true,
    bridge: false,
  );

  final $Instance _superclass;

  @override
  final StreamSink<S> $value;

  @override
  StreamSink get $reified => $value;

  /// Wrap a [StreamSink] in a [$StreamSink]
  $StreamSink.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'done':
        final _done = $value.done;
        return $Future.wrap(
          _done.then((e) => runtime.wrapAlways(e, recursive: true)),
        );
      case 'addStream':
        return __addStream;

      case 'close':
        return __close;

      case 'add':
        return __add;

      case 'addError':
        return __addError;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __addStream = $Function(_addStream);
  static $Value? _addStream(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $StreamSink;
    final result = self.$value.addStream(args[0]!.$value);
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $StreamSink;
    final result = self.$value.close();
    return $Future.wrap(
      result.then((e) => runtime.wrapAlways(e, recursive: true)),
    );
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target! as $StreamSink;
    self.$value.add(args[0]!.$value);
    return null;
  }

  static const $Function __addError = $Function(_addError);
  static $Value? _addError(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    final self = target! as $StreamSink;
    self.$value.addError(
      args[0]!.$reified,
      (args.length > 1 ? args[1] : null)?.$value,
    );
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
