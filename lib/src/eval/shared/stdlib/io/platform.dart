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

import 'package:dart_eval/stdlib/core.dart'
    hide
        $Platform,
        $SocketException,
        $HttpException,
        $OSError,
        $HttpHeaders,
        $RedirectInfo,
        $Socket,
        $ZLibCodec,
        $GZipCodec,
        $ZLibEncoder,
        $ZLibDecoder;
import 'package:dart_eval/src/eval/utils/wrap_helper.dart';

import '../core/uri.dart';

import 'package:dart_eval/src/eval/runtime/runtime.dart';

/// dart_eval wrapper binding for [Platform]
class $Platform implements $Instance {
  /// Configure this class for use in a [Runtime]
  static void configureForRuntime(Runtime runtime) {
    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.numberOfProcessors*g',
      $Platform.$numberOfProcessors,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.pathSeparator*g',
      $Platform.$pathSeparator,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.operatingSystem*g',
      $Platform.$operatingSystem,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.operatingSystemVersion*g',
      $Platform.$operatingSystemVersion,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.localHostname*g',
      $Platform.$localHostname,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.version*g',
      $Platform.$version,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.localeName*g',
      $Platform.$localeName,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isLinux*g',
      $Platform.$isLinux,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isMacOS*g',
      $Platform.$isMacOS,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isWindows*g',
      $Platform.$isWindows,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isAndroid*g',
      $Platform.$isAndroid,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isIOS*g',
      $Platform.$isIOS,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isFuchsia*g',
      $Platform.$isFuchsia,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.environment*g',
      $Platform.$environment,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.executable*g',
      $Platform.$executable,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.resolvedExecutable*g',
      $Platform.$resolvedExecutable,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.script*g',
      $Platform.$script,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.executableArguments*g',
      $Platform.$executableArguments,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.packageConfig*g',
      $Platform.$packageConfig,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.lineTerminator*g',
      $Platform.$lineTerminator,
    );

    runtime.registerBridgeFuncRegisters(
      'dart:io',
      'Platform.isWindows*s',
      $Platform.set$isWindows,
    );
  }

  /// Configure this class for use during compilation
  static void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.defineBridgeClass($declaration);
  }

  /// Compile-time type specification of [$Platform]
  static const $spec = BridgeTypeSpec('dart:io', 'Platform');

  /// Compile-time type declaration of [$Platform]
  static const $type = BridgeTypeRef($spec);

  /// Compile-time class declaration of [$Platform]
  static const $declaration = BridgeClassDef(
    BridgeClassType($type, isAbstract: true),
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

    methods: {},
    getters: {
      'localeName': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'environment': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.map, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'executable': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'resolvedExecutable': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'script': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.uri, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'executableArguments': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.list, [
              BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
            ]),
          ),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'packageConfig': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(
            BridgeTypeRef(CoreTypes.string, []),
            nullable: true,
          ),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),

      'lineTerminator': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
          namedParams: [],
          params: [],
        ),

        isStatic: true,
      ),
    },
    setters: {},
    fields: {
      'numberOfProcessors': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int, [])),
        isStatic: true,
      ),

      'pathSeparator': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'operatingSystem': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'operatingSystemVersion': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'localHostname': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'version': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string, [])),
        isStatic: true,
      ),

      'isLinux': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: true,
      ),

      'isMacOS': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: true,
      ),

      'isWindows': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: true,
      ),

      'isAndroid': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: true,
      ),

      'isIOS': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: true,
      ),

      'isFuchsia': BridgeFieldDef(
        BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool, [])),
        isStatic: true,
      ),
    },
    wrap: true,
    bridge: false,
  );

  /// Wrapper for the [Platform.numberOfProcessors] getter
  static $Value? $numberOfProcessors(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.numberOfProcessors;
    return $int(value);
  }

  /// Wrapper for the [Platform.pathSeparator] getter
  static $Value? $pathSeparator(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.pathSeparator;
    return $String(value);
  }

  /// Wrapper for the [Platform.operatingSystem] getter
  static $Value? $operatingSystem(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.operatingSystem;
    return $String(value);
  }

  /// Wrapper for the [Platform.operatingSystemVersion] getter
  static $Value? $operatingSystemVersion(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.operatingSystemVersion;
    return $String(value);
  }

  /// Wrapper for the [Platform.localHostname] getter
  static $Value? $localHostname(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.localHostname;
    return $String(value);
  }

  /// Wrapper for the [Platform.version] getter
  static $Value? $version(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.version;
    return $String(value);
  }

  /// Wrapper for the [Platform.localeName] getter
  static $Value? $localeName(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.localeName;
    return $String(value);
  }

  /// Wrapper for the [Platform.isLinux] getter
  static $Value? $isLinux(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.isLinux;
    return $bool(value);
  }

  /// Wrapper for the [Platform.isMacOS] getter
  static $Value? $isMacOS(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.isMacOS;
    return $bool(value);
  }

  /// Wrapper for the [Platform.isWindows] getter
  static $Value? $isWindows(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.isWindows;
    return $bool(value);
  }

  /// Wrapper for the [Platform.isAndroid] getter
  static $Value? $isAndroid(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.isAndroid;
    return $bool(value);
  }

  /// Wrapper for the [Platform.isIOS] getter
  static $Value? $isIOS(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.isIOS;
    return $bool(value);
  }

  /// Wrapper for the [Platform.isFuchsia] getter
  static $Value? $isFuchsia(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.isFuchsia;
    return $bool(value);
  }

  /// Wrapper for the [Platform.environment] getter
  static $Value? $environment(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.environment;
    return wrapMap(
      value,
      (key, value) => MapEntry($String(key), $String(value)),
    );
  }

  /// Wrapper for the [Platform.executable] getter
  static $Value? $executable(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.executable;
    return $String(value);
  }

  /// Wrapper for the [Platform.resolvedExecutable] getter
  static $Value? $resolvedExecutable(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.resolvedExecutable;
    return $String(value);
  }

  /// Wrapper for the [Platform.script] getter
  static $Value? $script(Runtime runtime, Object? r, Object? s, Object? c) {
    final value = Platform.script;
    return $Uri.wrap(value);
  }

  /// Wrapper for the [Platform.executableArguments] getter
  static $Value? $executableArguments(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.executableArguments;
    return $List.view(
      value,
      (e) => $String(e),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.list, [
        runtime.lookupType(CoreTypes.string),
      ]),
    );
  }

  /// Wrapper for the [Platform.packageConfig] getter
  static $Value? $packageConfig(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.packageConfig;
    return value == null ? const $null() : $String(value);
  }

  /// Wrapper for the [Platform.lineTerminator] getter
  static $Value? $lineTerminator(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    final value = Platform.lineTerminator;
    return $String(value);
  }

  /// Wrapper for the [Platform.isWindows] setter
  static $Value? set$isWindows(
    Runtime runtime,
    Object? r,
    Object? s,
    Object? c,
  ) {
    Platform.isWindows = (r as $bool).$value;
    return null;
  }

  final $Instance _superclass;

  @override
  final Platform $value;

  @override
  Platform get $reified => $value;

  /// Wrap a [Platform] in a [$Platform]
  $Platform.wrap(this.$value) : _superclass = $Object($value);

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($spec);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    return _superclass.$getProperty(runtime, identifier);
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    return _superclass.$setProperty(runtime, identifier, value);
  }
}
