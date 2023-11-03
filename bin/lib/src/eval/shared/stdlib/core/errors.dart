// ignore_for_file: non_constant_identifier_names

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';

/// dart_eval wrapper for [AssertionError]
class $AssertionError implements AssertionError, $Instance {
  /// Compile-time class definition for [$AssertionError]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.assertionError)),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.assertionError)),
            params: [
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  true)
            ]))
      },
      methods: {},
      getters: {
        'message': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true)),
            isStatic: false),
      },
      setters: {},
      fields: {},
      wrap: true);

  final $Instance _superclass;

  /// Wrap a [AssertionError] in a [$AssertionError]
  $AssertionError.wrap(this.$value) : _superclass = $Object($value);

  /// Create a new [$AssertionError] wrapping [AssertionError.new]
  static $AssertionError $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $AssertionError.wrap(AssertionError(args[0]?.$value));
  }

  @override
  final AssertionError $value;

  @override
  AssertionError get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.assertionError);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    if (identifier == 'message') {
      return $value.message == null ? $null() : $Object($value.message!);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  Object? get message => $value.message;

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}

/// dart_eval wrapper for [RangeError]
class $RangeError implements RangeError, $Instance {
  /// Compile-time class definition for [$RangeError]
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.rangeError)),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.rangeError)),
            params: [
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic),
                      nullable: true),
                  true),
            ])),
        'value': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.rangeError)),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.num),
                  ),
                  false),
              BridgeParameter(
                  'name',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
            ])),
        'range': BridgeConstructorDef(BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.rangeError)),
            params: [
              BridgeParameter(
                  'invalidValue',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object),
                  ),
                  false),
              BridgeParameter(
                  'minValue',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  false),
              BridgeParameter(
                  'maxValue',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  false),
              BridgeParameter(
                  'name',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
            ])),
      },
      methods: {
        'checkValidIndex': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'index',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.int),
                  ),
                  false),
              BridgeParameter(
                  'indexable',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.dynamic),
                  ),
                  false),
              BridgeParameter(
                  'name',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'length',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
            isStatic: true),
        'checkValidRange': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'start',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.int),
                  ),
                  false),
              BridgeParameter(
                  'end',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int),
                      nullable: true),
                  false),
              BridgeParameter(
                  'length',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.int),
                  ),
                  false),
              BridgeParameter(
                  'startName',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'endName',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int))),
            isStatic: true),
        'checkNotNegative': BridgeMethodDef(
            BridgeFunctionDef(params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.num),
                  ),
                  false),
              BridgeParameter(
                  'name',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string),
                      nullable: true),
                  true),
            ], returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.num))),
            isStatic: true),
      },
      getters: {
        'message': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true)),
            isStatic: false),
        'invalidValue': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true)),
            isStatic: false),
        'name': BridgeMethodDef(
            BridgeFunctionDef(
                params: [],
                returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                    nullable: true)),
            isStatic: false),
      },
      setters: {},
      fields: {},
      wrap: true);

  final $Instance _superclass;

  /// Wrap a [RangeError] in a [$RangeError]
  $RangeError.wrap(this.$value) : _superclass = $Object($value);

  @override
  final RangeError $value;

  @override
  get $reified => $value;

  static $RangeError $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $RangeError.wrap(RangeError(args[0]?.$value));
  }

  static $RangeError $_value(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $RangeError.wrap(
        RangeError.value(args[0]?.$value, args[1]?.$value, args[2]?.$value));
  }

  static $RangeError $_range(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $RangeError.wrap(RangeError.range(args[0]?.$value, args[1]?.$value,
        args[2]?.$value, args[3]?.$value, args[4]?.$value));
  }

  static $Value? $checkValidIndex(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $int(RangeError.checkValidIndex(args[0]?.$value, args[1]?.$value,
        args[2]?.$value, args[3]?.$value, args[4]?.$value));
  }

  static $Value? $checkValidRange(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $int(RangeError.checkValidRange(args[0]?.$value, args[1]?.$value,
        args[2]?.$value, args[3]?.$value, args[4]?.$value, args[5]?.$value));
  }

  static $Value? $checkNotNegative(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $num(RangeError.checkNotNegative(
        args[0]?.$value, args[1]?.$value, args[2]?.$value));
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.rangeError);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        return $value.message == null ? $null() : $Object($value.message!);
      case 'invalidValue':
        return $value.invalidValue == null
            ? $null()
            : $num($value.invalidValue!);
      case 'name':
        return $value.name == null ? $null() : $String($value.name!);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  String? get message => $value.message;

  @override
  num? get invalidValue => $value.invalidValue;

  @override
  String? get name => $value.name;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  num? get end => $value.end;

  @override
  num? get start => $value.start;
}
