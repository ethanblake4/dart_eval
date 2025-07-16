import 'dart:io';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/typed_data/typed_data.dart';
import 'package:dart_eval/stdlib/core.dart';

/// dart_eval bimodal wrapper for [InternetAddressType]
class $InternetAddressType implements $Instance {
  /// Configure the [$InternetAddressType] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'InternetAddressType.IPv4*g', __$static$IPv4.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'InternetAddressType.IPv6*g', __$static$IPv6.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'InternetAddressType.unix*g', __$static$unix.call);
    runtime.registerBridgeFunc(
        $type.spec!.library, 'InternetAddressType.any*g', __$static$any.call);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(IoTypes.internetAddressType);

  static const $declaration = BridgeClassDef(
    BridgeClassType(
      $type,
      $extends: null,
      $implements: [],
      isAbstract: false,
    ),
    constructors: {},
    fields: {
      'IPv4': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(IoTypes.internetAddressType, []),
              nullable: false),
          isStatic: true),
      'IPv6': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(IoTypes.internetAddressType, []),
              nullable: false),
          isStatic: true),
      'unix': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(IoTypes.internetAddressType, []),
              nullable: false),
          isStatic: true),
      'any': BridgeFieldDef(
          BridgeTypeAnnotation(BridgeTypeRef(IoTypes.internetAddressType, []),
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
      'name': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
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

  /// Wrap an [InternetAddressType] in an [$InternetAddressType]
  $InternetAddressType.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'name':
        return $String($value.name);
      case 'toString':
        return __$toString;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  InternetAddressType get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final InternetAddressType $value;

  static const __$static$IPv4 = $Function(_$static$IPv4);
  static $Value? _$static$IPv4(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = InternetAddressType.IPv4;
    return $InternetAddressType.wrap($result);
  }

  static const __$static$IPv6 = $Function(_$static$IPv6);
  static $Value? _$static$IPv6(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = InternetAddressType.IPv6;
    return $InternetAddressType.wrap($result);
  }

  static const __$static$unix = $Function(_$static$unix);
  static $Value? _$static$unix(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = InternetAddressType.unix;
    return $InternetAddressType.wrap($result);
  }

  static const __$static$any = $Function(_$static$any);
  static $Value? _$static$any(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final $result = InternetAddressType.any;
    return $InternetAddressType.wrap($result);
  }

  @override
  String toString() => $value.toString();
  static const __$toString = $Function(_$toString);
  static $Value? _$toString(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final obj = target?.$value as InternetAddressType;
    final $result = obj.toString();
    return $String($result);
  }
}

/// dart_eval bimodal wrapper for [InternetAddress]
class $InternetAddress implements InternetAddress, $Instance {
  /// Configure the [$InternetAddress] wrapper for use in a [Runtime]
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFunc(
        $type.spec!.library, 'InternetAddress.', __$InternetAddress$new.call);
    runtime.registerBridgeFunc(
        $type.spec!.library,
        'InternetAddress.fromRawAddress',
        __$InternetAddress$fromRawAddress.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'InternetAddress.loopbackIPv4*g', __$static$getter$loopbackIPv4.call);
    runtime.registerBridgeFunc($type.spec!.library,
        'InternetAddress.loopbackIPv6*g', __$static$getter$loopbackIPv6.call);
    runtime.registerBridgeFunc($type.spec!.library, 'InternetAddress.anyIPv4*g',
        __$static$getter$anyIPv4.call);
    runtime.registerBridgeFunc($type.spec!.library, 'InternetAddress.anyIPv6*g',
        __$static$getter$anyIPv6.call);
    runtime.registerBridgeFunc($type.spec!.library, 'InternetAddress.lookup',
        __$static$method$lookup.call);
    runtime.registerBridgeFunc($type.spec!.library, 'InternetAddress.tryParse',
        __$static$method$tryParse.call);
  }

  late final $Instance _superclass = $Object($value);

  static const $type = BridgeTypeRef(IoTypes.internetAddress);

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
          params: [
            BridgeParameter(
                'address',
                BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'type',
                BridgeTypeAnnotation(
                    BridgeTypeRef(IoTypes.internetAddressType, []),
                    nullable: true),
                true)
          ],
        ),
        isFactory: true,
      ),
      'fromRawAddress': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation($type),
          params: [
            BridgeParameter(
                'rawAddress',
                BridgeTypeAnnotation(
                    BridgeTypeRef(TypedDataTypes.uint8List, []),
                    nullable: false),
                false)
          ],
          namedParams: [
            BridgeParameter(
                'type',
                BridgeTypeAnnotation(
                    BridgeTypeRef(IoTypes.internetAddressType, []),
                    nullable: true),
                true)
          ],
        ),
        isFactory: true,
      )
    },
    fields: {},
    methods: {
      'lookup': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.future, [
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.list, [
                    BridgeTypeAnnotation(
                        BridgeTypeRef(IoTypes.internetAddress, [])),
                  ])),
                ]),
                nullable: false),
            params: [
              BridgeParameter(
                  'host',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [
              BridgeParameter(
                  'type',
                  BridgeTypeAnnotation(
                      BridgeTypeRef(IoTypes.internetAddressType, []),
                      nullable: false),
                  true)
            ],
          ),
          isStatic: true),
      'tryParse': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddress, []),
                nullable: true),
            params: [
              BridgeParameter(
                  'address',
                  BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                      nullable: false),
                  false)
            ],
            namedParams: [],
          ),
          isStatic: true),
      'reverse': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(CoreTypes.future, [
                  BridgeTypeAnnotation(
                      BridgeTypeRef(IoTypes.internetAddress, [])),
                ]),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
    },
    getters: {
      'loopbackIPv4': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddress, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'loopbackIPv6': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddress, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'anyIPv4': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddress, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'anyIPv6': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddress, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'type': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(IoTypes.internetAddressType, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'address': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'host': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'rawAddress': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(
                BridgeTypeRef(TypedDataTypes.uint8List, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isLoopback': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isLinkLocal': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
                nullable: false),
            params: [],
            namedParams: [],
          ),
          isStatic: false),
      'isMulticast': BridgeMethodDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, []),
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

  /// Wrap an [InternetAddress] in an [$InternetAddress]
  $InternetAddress.wrap(this.$value);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'type':
        return $InternetAddressType.wrap($value.type);
      case 'address':
        return $String($value.address);
      case 'host':
        return $String($value.host);
      case 'rawAddress':
        return $Uint8List.wrap($value.rawAddress);
      case 'isLoopback':
        return $bool($value.isLoopback);
      case 'isLinkLocal':
        return $bool($value.isLinkLocal);
      case 'isMulticast':
        return $bool($value.isMulticast);
      case 'reverse':
        return __$reverse;
      default:
        return _superclass.$getProperty(runtime, identifier);
    }
  }

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  InternetAddress get $reified => $value;

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    switch (identifier) {
      default:
        _superclass.$setProperty(runtime, identifier, value);
    }
  }

  @override
  final InternetAddress $value;

  @override
  InternetAddressType get type => $value.type;

  @override
  String get address => $value.address;

  @override
  String get host => $value.host;

  @override
  Uint8List get rawAddress => $value.rawAddress;

  @override
  bool get isLoopback => $value.isLoopback;

  @override
  bool get isLinkLocal => $value.isLinkLocal;

  @override
  bool get isMulticast => $value.isMulticast;

  static const __$static$getter$loopbackIPv4 =
      $Function(_$static$getter$loopbackIPv4);
  static $Value? _$static$getter$loopbackIPv4(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $InternetAddress.wrap(InternetAddress.loopbackIPv4);
  }

  static const __$static$getter$loopbackIPv6 =
      $Function(_$static$getter$loopbackIPv6);
  static $Value? _$static$getter$loopbackIPv6(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $InternetAddress.wrap(InternetAddress.loopbackIPv6);
  }

  static const __$static$getter$anyIPv4 = $Function(_$static$getter$anyIPv4);
  static $Value? _$static$getter$anyIPv4(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $InternetAddress.wrap(InternetAddress.anyIPv4);
  }

  static const __$static$getter$anyIPv6 = $Function(_$static$getter$anyIPv6);
  static $Value? _$static$getter$anyIPv6(
      Runtime runtime, $Value? target, List<$Value?> args) {
    return $InternetAddress.wrap(InternetAddress.anyIPv6);
  }

  @override
  Future<InternetAddress> reverse() => $value.reverse();
  static const __$reverse = $Function(_$reverse);
  static $Value? _$reverse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final obj = target?.$value as InternetAddress;
    final $result = obj.reverse();
    return $Future.wrap($result.then((value) => $InternetAddress.wrap(value)));
  }

  static const __$static$method$lookup = $Function(_$static$method$lookup);
  static $Value? _$static$method$lookup(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final host = args[0]?.$value as String;
    final type =
        args[1]?.$reified as InternetAddressType? ?? InternetAddressType.any;
    final $result = InternetAddress.lookup(host, type: type);
    return $Future.wrap($result.then(
      (value) => $List.wrap(List.generate((value).length, (index) {
        return $InternetAddress.wrap(value[index]);
      })),
    ));
  }

  static const __$static$method$tryParse = $Function(_$static$method$tryParse);
  static $Value? _$static$method$tryParse(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final address = args[0]?.$value as String;
    final $result = InternetAddress.tryParse(address);
    return $result == null ? $null() : $InternetAddress.wrap($result);
  }

  static const __$InternetAddress$new = $Function(_$InternetAddress$new);
  static $Value? _$InternetAddress$new(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final address = args[0]?.$value as String;
    final type = args[1]?.$value as InternetAddressType;
    return $InternetAddress.wrap(InternetAddress(address, type: type));
  }

  static const __$InternetAddress$fromRawAddress =
      $Function(_$InternetAddress$fromRawAddress);
  static $Value? _$InternetAddress$fromRawAddress(
      Runtime runtime, $Value? target, List<$Value?> args) {
    final rawAddress = args[0]?.$reified as Uint8List;
    final type = args[1]?.$value as InternetAddressType;
    return $InternetAddress
        .wrap(InternetAddress.fromRawAddress(rawAddress, type: type));
  }
}
