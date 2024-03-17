// ignore_for_file: non_constant_identifier_names

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/stack_trace.dart';

/// dart_eval bimodal wrapper for [Error]
class $Error implements Error, $Instance {
  /// Configure the [$Error] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        _$type.spec!.library, 'Error.', __$Error$new.call);
    runtime.registerBridgeFunc(_$type.spec!.library, 'Error.safeToString',
        __$static$method$safeToString.call);
    runtime.registerBridgeFunc(_$type.spec!.library,
        'Error.throwWithStackTrace', __$static$method$throwWithStackTrace.call);
  }

  late final $Instance _superclass = $Object($value);

  static const _$type = BridgeTypeRef(CoreTypes.error);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      _$type,
      $extends: null,
      $implements: [],
      isAbstract: false,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(_$type),
          params: [],
          namedParams: [],
        ),
        isFactory: false,
      )
    },
    fields: {},
    methods: {
      'safeToString': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'object',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, []),
                      nullable: true),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'throwWithStackTrace': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.never, []),
                nullable: false),
            params: [
              BridgeParameter(
                  'error',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object, []),
                      nullable: false),
                  false),
              BridgeParameter(
                  'stackTrace',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stackTrace, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
    },
    getters: {
      'stackTrace': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.stackTrace, []),
                nullable: true),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [Error] in an [$Error]
  $Error.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'stackTrace':
        return $value.stackTrace == null
            ? $null()
            : $StackTrace.wrap($value.stackTrace!);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(_$type.spec!);

  @override
  Error get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final Error $value;

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  static const __$static$method$safeToString =
      $Function(_$static$method$safeToString);
  static $Value? _$static$method$safeToString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final object = args[0]?.$value as Object;
    final $result = Error.safeToString(object);
    return $String($result);
  }

  static const __$static$method$throwWithStackTrace =
      $Function(_$static$method$throwWithStackTrace);
  static $Value? _$static$method$throwWithStackTrace(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final error = args[0]?.$value as Object;
    final stackTrace = args[1]?.$reified as StackTrace;
    return Error.throwWithStackTrace(error, stackTrace);
  }

  static const __$Error$new = $Function(_$Error$new);
  static $Value? _$Error$new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $Error.wrap(Error());
  }
}

/// dart_eval bimodal wrapper for [UnsupportedError]
class $UnsupportedError implements UnsupportedError, $Instance {
  /// Configure the [$UnsupportedError] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(_$type.spec!.library, 'UnsupportedError.',
        __$UnsupportedError$new.call);
  }

  late final $Instance _superclass = $Error.wrap($value);

  static const _$type = BridgeTypeRef(CoreTypes.unsupportedError);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      _$type,
      $extends: BridgeTypeRef(CoreTypes.error, []),
      $implements: [],
      isAbstract: false,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(_$type),
          params: [
            BridgeParameter(
                'message',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [],
        ),
        isFactory: false,
      )
    },
    fields: {
      'message': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
              nullable: true),
          isStatic: false),
    },
    methods: {},
    getters: {},
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [UnsupportedError] in an [$UnsupportedError]
  $UnsupportedError.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        return $value.message == null ? $null() : $String($value.message!);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(_$type.spec!);

  @override
  UnsupportedError get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final UnsupportedError $value;

  @override
  String? get message => $value.message;

  static const __$UnsupportedError$new = $Function(_$UnsupportedError$new);
  static $Value? _$UnsupportedError$new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final message = args[0]?.$value as String;
    return $UnsupportedError.wrap(UnsupportedError(message));
  }

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}

/// dart_eval bimodal wrapper for [UnimplementedError]
class $UnimplementedError implements UnimplementedError, $Instance {
  /// Configure the [$UnimplementedError] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(_$type.spec!.library, 'UnimplementedError.',
        __$UnimplementedError$new.call);
  }

  late final $Instance _superclass = $Error.wrap($value);

  static const _$type = BridgeTypeRef(CoreTypes.unimplementedError);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      _$type,
      $extends: BridgeTypeRef(CoreTypes.error, []),
      $implements: [
        BridgeTypeRef(CoreTypes.unsupportedError, []),
      ],
      isAbstract: false,
    ),
    constructors: {
      '': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(_$type),
          params: [
            BridgeParameter(
                'message',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: true),
                true)
          ],
          namedParams: [],
        ),
        isFactory: false,
      )
    },
    fields: {
      'message': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
              nullable: true),
          isStatic: false),
    },
    methods: {},
    getters: {},
    setters: {},
    bridge: false,
    wrap: true,
  );

  /// Wrap an [UnimplementedError] in an [$UnimplementedError]
  $UnimplementedError.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        return $value.message == null ? $null() : $String($value.message!);
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType(_$type.spec!);

  @override
  UnimplementedError get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final UnimplementedError $value;

  @override
  String? get message => $value.message;

  static const __$UnimplementedError$new = $Function(_$UnimplementedError$new);
  static $Value? _$UnimplementedError$new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final message = args[0]?.$value as String;
    return $UnimplementedError.wrap(UnimplementedError(message));
  }

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}

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

/// dart_eval wrapper for [ArgumentError]
class $ArgumentError implements ArgumentError, $Instance {
  static const $declaration = BridgeClassDef(
      BridgeClassType(BridgeTypeRef(CoreTypes.argumentError)),
      constructors: {
        '': BridgeConstructorDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.argumentError)),
            params: [
              BridgeParameter(
                  'message',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                      nullable: true),
                  true)
            ])),
        'value': BridgeConstructorDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.argumentError)),
            params: [
              BridgeParameter(
                  'value',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.object),
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
        'notNull': BridgeConstructorDef(BridgeFunctionDef(
            returns:
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.argumentError)),
            params: [
              BridgeParameter(
                  'name',
                  BridgeTypeAnnotation(
                    BridgeTypeRef(CoreTypes.string),
                  ),
                  false),
            ])),
      },
      methods: {},
      getters: {
        'message': BridgeMethodDef(
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
        'invalidValue': BridgeMethodDef(
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

  /// Wrap a [ArgumentError] in a [$ArgumentError]
  $ArgumentError.wrap(this.$value) : _superclass = $Object($value);

  @override
  final ArgumentError $value;

  @override
  ArgumentError get $reified => $value;

  /// Create a new [$ArgumentError] wrapping [ArgumentError.new]
  static $ArgumentError $new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $ArgumentError.wrap(ArgumentError(args[0]?.$value));
  }

  /// Create a new [$ArgumentError] wrapping [ArgumentError.value]
  static $ArgumentError $_value(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $ArgumentError.wrap(
        ArgumentError.value(args[0]?.$value, args[1]?.$value, args[2]?.$value));
  }

  /// Create a new [$ArgumentError] wrapping [ArgumentError.notNull]
  static $ArgumentError $notNull(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $ArgumentError.wrap(ArgumentError.notNull(args[0]?.$value));
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.argumentError);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        return $value.message == null ? $null() : $Object($value.message!);
      case 'name':
        return $value.name == null ? $null() : $String($value.name!);
      case 'invalidValue':
        return $value.invalidValue == null
            ? $null()
            : $Object($value.invalidValue!);
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
  String? get name => $value.name;

  @override
  Object? get invalidValue => $value.invalidValue;

  @override
  StackTrace? get stackTrace => $value.stackTrace;
}

/// dart_eval wrapper for [StateError]
class $StateError implements $Instance, StateError {
  static const $declaration =
      BridgeClassDef(BridgeClassType(BridgeTypeRef(CoreTypes.stateError)),
          constructors: {
            '': BridgeConstructorDef(BridgeFunctionDef(
                returns:
                    BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.stateError)),
                params: [
                  BridgeParameter(
                      'message',
                      BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.object),
                          nullable: true),
                      true)
                ])),
          },
          methods: {},
          getters: {},
          setters: {},
          fields: {
            'message': BridgeFieldDef(
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
                isStatic: false),
          },
          wrap: true);

  final $Instance _superclass;

  $StateError.wrap(this.$value) : _superclass = $Object($value);

  @override
  final StateError $value;

  @override
  StateError get $reified => $value;

  static $StateError $new(Runtime runtime, $Value? target, List<$Value?> args) {
    return $StateError.wrap(StateError(args[0]?.$value));
  }

  @override
  int $getRuntimeType(Runtime runtime) =>
      runtime.lookupType(CoreTypes.stateError);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'message':
        return $String($value.message);
    }
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }

  @override
  StackTrace? get stackTrace => $value.stackTrace;

  @override
  String get message => $value.message;
}
