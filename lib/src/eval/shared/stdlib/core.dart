import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/comparable.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/date_time.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/enum.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/errors.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/exceptions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/identical.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/iterator.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pattern.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/record.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/regexp.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/stack_trace.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/string_buffer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/symbol.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/uri.dart';
import 'core/duration.dart';
import 'core/future.dart';
import 'core/map_entry.dart';
import 'core/print.dart';

/// [EvalPlugin] for the `dart:core` library
class DartCorePlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:core';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    configurePrintForCompile(registry);
    configureIdenticalForCompile(registry);
    registry.defineBridgeClass($dynamicCls);
    registry.defineBridgeClass($voidCls);
    registry.defineBridgeClass($neverCls);
    registry.defineBridgeClass($recordCls);
    registry.defineBridgeClass($Type.$declaration);
    registry.defineBridgeClass($null.$declaration);
    registry.defineBridgeClass($Object.$declaration);
    registry.defineBridgeClass($enumDeclaration);
    registry.defineBridgeClass($bool.$declaration);
    registry.defineBridgeClass($Function.$declaration);
    registry.defineBridgeClass($Symbol.$declaration);
    registry.defineBridgeClass($Invocation.$declaration);
    registry.defineBridgeClass($num.$declaration);
    registry.defineBridgeClass($int.$declaration);
    registry.defineBridgeClass($double.$declaration);
    registry.defineBridgeClass($String.$declaration);
    registry.defineBridgeClass($Iterable.$declaration);
    registry.defineBridgeClass($Iterator.$declaration);
    registry.defineBridgeClass($List.$declaration);
    registry.defineBridgeClass($Map.$declaration);
    registry.defineBridgeClass($MapEntry.$declaration);
    registry.defineBridgeClass($Duration.$declaration);
    registry.defineBridgeClass($Future.$declaration);
    registry.defineBridgeClass($Stream.$declaration);
    registry.defineBridgeClass($DateTime.$declaration);
    registry.defineBridgeClass($Uri.$declaration);
    registry.defineBridgeClass($Pattern.$declaration);
    registry.defineBridgeClass($Match.$declaration);
    registry.defineBridgeClass($RegExp.$declaration);
    registry.defineBridgeClass($RegExpMatch.$declaration);
    registry.defineBridgeClass($AssertionError.$declaration);
    registry.defineBridgeClass($RangeError.$declaration);
    registry.defineBridgeClass($Comparable.$declaration);
    registry.defineBridgeClass($StringBuffer.$declaration);
    registry.defineBridgeClass($Exception.$declaration);
    registry.defineBridgeClass($FormatException.$declaration);
    registry.defineBridgeClass($ArgumentError.$declaration);
    registry.defineBridgeClass($StateError.$declaration);
    registry.defineBridgeClass($Set.$declaration);
    registry.defineBridgeClass($Sink.$declaration);
    $StackTrace.configureForCompile(registry);
    $Error.configureForCompile(registry);
    registry.defineBridgeClass($TypeError.$declaration);
    registry.defineBridgeClass($NoSuchMethodError.$declaration);
    $UnimplementedError.configureForCompile(registry);
    $UnsupportedError.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    configurePrintForRuntime(runtime);
    configureIdenticalForRuntime(runtime);
    $String.configureForRuntime(runtime);
    $List.configureForRuntime(runtime);
    $MapEntry.configureForRuntime(runtime);
    $Iterable.configureForRuntime(runtime);
    $Duration.configureForRuntime(runtime);
    $Future.configureForRuntime(runtime);
    $DateTime.configureForRuntime(runtime);
    $Uri.configureForRuntime(runtime);
    $Map.configureForRuntime(runtime);
    $Set.configureForRuntime(runtime);
    $RegExp.configureForRuntime(runtime);
    $AssertionError.configureForRuntime(runtime);
    $StringBuffer.configureForRuntime(runtime);
    $RangeError.configureForRuntime(runtime);
    $Symbol.configureForRuntime(runtime);
    $Exception.configureForRuntime(runtime);
    $FormatException.configureForRuntime(runtime);
    $ArgumentError.configureForRuntime(runtime);
    $StateError.configureForRuntime(runtime);
    runtime.registerBridgeFuncRegisters('dart:core', 'num.parse', $num.$parse);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'num.tryParse',
      $num.$tryParse,
    );
    runtime.registerBridgeFuncRegisters('dart:core', 'int.parse', $int.$parse);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'int.tryParse',
      $int.$tryParse,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Object.hash',
      $Object.$hash,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'double.nan*g',
      $double.$nan,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'double.infinity*g',
      $double.$infinity,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'double.negativeInfinity*g',
      $double.$negativeInfinity,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'double.parse',
      $double.$parse,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'double.tryParse',
      $double.$tryParse,
    );
    $StackTrace.configureForRuntime(runtime);
    $Error.configureForRuntime(runtime);
    $UnimplementedError.configureForRuntime(runtime);
    $UnsupportedError.configureForRuntime(runtime);
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Stream.empty',
      $Stream.$empty,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Stream.value',
      $Stream.$_value,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Stream.fromIterable',
      $Stream.$fromIterable,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:async',
      'Stream.periodic',
      $Stream.$periodic,
    );
  }
}
