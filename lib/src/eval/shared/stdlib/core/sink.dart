// ignore_for_file: unused_import
// ignore_for_file: unnecessary_import
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'sink.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval wrapper binding for [Sink]
class $Sink implements $Instance {
  /// Compile-time type declaration of [$Sink]
  static const $type = BridgeTypeRef(CoreTypes.sink);

  /// Compile-time class declaration of [$Sink]
  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      isAbstract: true,
      generics: {'T': BridgeGenericParam()},
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
      'add': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [
            BridgeParameter(
              'data',
              BridgeTypeAnnotation(BridgeTypeRef.ref('T')),
              false,
            ),
          ],
        ),
      ),
      'close': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          namedParams: [],
          params: [],
        ),
      ),
    },
    getters: {},
    setters: {},
    fields: {},
    wrap: true,
  );

  final $Instance _superclass;

  @override
  final Sink $value;

  @override
  Sink get $reified => $value;

  /// Wrap a [Sink] in a [$Sink]
  $Sink.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(CoreTypes.sink);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'add':
        return __add;

      case 'close':
        return __close;
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  static const $Function __add = $Function(_add);
  static $Value? _add(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $Sink;
    self.$value.add(args[0]!.$value);
    return null;
  }

  static const $Function __close = $Function(_close);
  static $Value? _close(Runtime runtime, $Value? target, List<$Value?> args) {
    final self = target as $Sink;
    self.$value.close();
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
