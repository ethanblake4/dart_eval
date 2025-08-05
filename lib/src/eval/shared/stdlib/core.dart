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
    runtime.registerBridgeFunc('dart:core', 'RegExp.', $RegExp.$new);
    runtime.registerBridgeFunc(
        'dart:core', 'AssertionError.', $AssertionError.$new);
    runtime.registerBridgeFunc(
        'dart:core', 'StringBuffer.', $StringBuffer.$new);
    runtime.registerBridgeFunc('dart:core', 'num.parse', $num.$parse);
    runtime.registerBridgeFunc('dart:core', 'num.tryParse', $num.$tryParse);
    runtime.registerBridgeFunc('dart:core', 'int.parse', $int.$parse);
    runtime.registerBridgeFunc('dart:core', 'int.tryParse', $int.$tryParse);
    runtime.registerBridgeFunc('dart:core', 'Object.hash', $Object.$hash);
    runtime.registerBridgeFunc('dart:core', 'RangeError.', $RangeError.$new);
    runtime.registerBridgeFunc(
        'dart:core', 'RangeError.value', $RangeError.$_value);
    runtime.registerBridgeFunc(
        'dart:core', 'RangeError.range', $RangeError.$_range);
    runtime.registerBridgeFunc('dart:core', 'RangeError.checkValidIndex',
        $RangeError.$checkValidIndex);
    runtime.registerBridgeFunc('dart:core', 'RangeError.checkValidRange',
        $RangeError.$checkValidRange);
    runtime.registerBridgeFunc('dart:core', 'RangeError.checkNotNegative',
        $RangeError.$checkNotNegative);
    runtime.registerBridgeFunc('dart:core', 'Symbol.', $Symbol.$new);
    runtime.registerBridgeFunc('dart:core', 'double.nan*g', $double.$nan);
    runtime.registerBridgeFunc(
        'dart:core', 'double.infinity*g', $double.$infinity);
    runtime.registerBridgeFunc(
        'dart:core', 'double.negativeInfinity*g', $double.$negativeInfinity);
    $StackTrace.configureForRuntime(runtime);
    $Error.configureForRuntime(runtime);
    $UnimplementedError.configureForRuntime(runtime);
    $UnsupportedError.configureForRuntime(runtime);
    runtime.registerBridgeFunc(
        'dart:core', 'FormatException.', $FormatException.$new);
    runtime.registerBridgeFunc(
        'dart:core', 'ArgumentError.', $ArgumentError.$new);
    runtime.registerBridgeFunc(
        'dart:core', 'ArgumentError.notNull', $ArgumentError.$notNull);
    runtime.registerBridgeFunc(
        'dart:core', 'ArgumentError.value', $ArgumentError.$_value);
    runtime.registerBridgeFunc('dart:core', 'StateError.', $StateError.$new);
    runtime.registerBridgeFunc('dart:async', 'Stream.empty', $Stream.$empty);
    runtime.registerBridgeFunc('dart:async', 'Stream.value', $Stream.$_value);
    runtime.registerBridgeFunc(
        'dart:async', 'Stream.fromIterable', $Stream.$fromIterable);
    runtime.registerBridgeFunc(
        'dart:async', 'Stream.periodic', $Stream.$periodic);
  }
}
