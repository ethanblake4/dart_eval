import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// dart_eval bimodal wrapper for [StackTrace]
class $StackTrace implements StackTrace, $Instance {
  /// Configure the [$StackTrace] wrapper for use in a [Runtime]
  static void configureForCompileTime(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc($type.spec!.library, 'StackTrace.fromString',
        __$StackTrace$fromString.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'StackTrace.empty*g', __$static$empty.call);
    runtime.registerBridgeFunc($type.spec!.library, 'StackTrace.current*g',
        __$static$getter$current.call);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(CoreTypes.stackTrace);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: null,
      $implements: [],
      isAbstract: true,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [],
          namedParams: [],
        ),
        isFactory: false,
      ),
      'StackTrace.fromString': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'stackTraceString',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [],
        ),
        isFactory: true,
      )
    },
    fields: {
      'empty': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, []),
              nullable: false),
          isStatic: true),
    },
    methods: {
      'toString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {
      'current': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stackTrace, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [StackTrace] in an [$StackTrace]
  $StackTrace.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  StackTrace get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final StackTrace $value;

  static const __$static$empty = $Function(_$static$empty);
  static $Value? _$static$empty(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = StackTrace.empty;
    return $StackTrace.wrap($result);
  }

  static const __$static$getter$current = $Function(_$static$getter$current);
  static $Value? _$static$getter$current(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $StackTrace.wrap(StackTrace.current);
  }

  static const __$StackTrace$fromString = $Function(_$StackTrace$fromString);
  static $Value? _$StackTrace$fromString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final stackTraceString = args[0]?.$value as String;
    return $StackTrace.wrap(StackTrace.fromString(
      stackTraceString,
    ));
  }
}
