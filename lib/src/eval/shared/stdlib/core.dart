import 'dart:async';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/src/eval/shared/stdlib/async/stream.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection/extensions.dart'
    as collection_extensions;
import 'package:dart_eval/src/eval/shared/stdlib/core/base.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/big_int.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/comparable.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/date_time.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/enum_bindings.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/extensions.dart'
    as core_extensions;
import 'package:dart_eval/src/eval/shared/stdlib/core/errors.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/expando.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/symbol_literal.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/error_hooks.dart'
    as assertion_hooks;
import 'package:dart_eval/src/eval/shared/stdlib/core/exceptions.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/identical.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/iterator.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/invocation.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/iterable_bridge.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/num.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/object.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pattern.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/pragma.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/record.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/regexp.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/runes.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/sink.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/stack_trace.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/stopwatch.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/string_buffer.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/symbol.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/typedefs.dart'
    as core_typedefs;
import 'package:dart_eval/src/eval/shared/stdlib/core/type.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core/uri.dart';
import 'core/duration.dart';
import 'core/future.dart';
import 'core/map_entry.dart';
import 'core/print.dart';

final _sdkCoreSource = DartSource(
  'dart:core',
  '${core_typedefs.sdkTypedefsSource.stringSource!}\n'
      '${core_extensions.sdkExtensionsSource.stringSource!}\n'
      '${collection_extensions.sdkExtensionsSource.stringSource!}',
);

/// [EvalPlugin] for the `dart:core` library
class DartCorePlugin implements EvalPlugin {
  @override
  String get identifier => 'dart:core';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    registry.addSource(_sdkCoreSource);
    configurePrintForCompile(registry);
    configureIdenticalForCompile(registry);
    configureSymbolLiteralsForCompile(registry);
    registry.defineBridgeClass($dynamicCls);
    assertion_hooks.configureAssertionForCompile(registry);
    registry.defineBridgeClass($voidCls);
    registry.defineBridgeClass($neverCls);
    registry.defineBridgeClass($recordCls);
    registry.defineBridgeClass($Type.$declaration);
    registry.defineBridgeClass($null.$declaration);
    registry.defineBridgeClass($Object.$declaration);
    $Enum.configureForCompile(registry);
    registry.defineBridgeClass($bool.$declaration);
    registry.defineBridgeClass($Function.$declaration);
    registry.defineBridgeClass($Symbol.$declaration);
    registry.defineBridgeClass($Invocation.$declaration);
    registry.defineBridgeClass($num.$declaration);
    registry.defineBridgeClass($int.$declaration);
    registry.defineBridgeClass($BigInt.$declaration);
    registry.defineBridgeClass($double.$declaration);
    registry.defineBridgeClass($String.$declaration);
    $Runes.configureForCompile(registry);
    $RuneIterator.configureForCompile(registry);
    registry.defineBridgeClass($Iterable$bridge.$declaration);
    registry.defineBridgeClass($Iterator.$declaration);
    registry.defineBridgeClass($List.$declaration);
    registry.defineBridgeClass($Map.$declaration);
    registry.defineBridgeClass($MapEntry.$declaration);
    $Stopwatch.configureForCompile(registry);
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
    registry.defineBridgeClass($StringBuffer$bridge.$declaration);
    $Expando.configureForCompile(registry);
    $StackOverflowError.configureForCompile(registry);
    $OutOfMemoryError.configureForCompile(registry);
    registry.defineBridgeClass($Exception.$declaration);
    registry.defineBridgeClass($FormatException.$declaration);
    registry.defineBridgeClass($ArgumentError.$declaration);
    registry.defineBridgeClass($StateError.$declaration);
    registry.defineBridgeClass($Set.$declaration);
    registry.defineBridgeClass($Sink.$declaration);
    $StackTrace.configureForCompile(registry);
    $pragma.configureForCompile(registry);
    $Error$bridge.configureForCompile(registry);
    registry.defineBridgeClass($TypeError.$declaration);
    registry.defineBridgeClass($NoSuchMethodError.$declaration);
    $UnimplementedError.configureForCompile(registry);
    $UnsupportedError.configureForCompile(registry);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    $BigInt.configureForRuntime(runtime);
    $Enum.configureForRuntime(runtime);
    configurePrintForRuntime(runtime);
    configureIdenticalForRuntime(runtime);
    configureSymbolLiteralsForRuntime(runtime);
    $String.configureForRuntime(runtime);
    $Runes.configureForRuntime(runtime);
    $RuneIterator.configureForRuntime(runtime);
    $List.configureForRuntime(runtime);
    $MapEntry.configureForRuntime(runtime);
    $Iterable$bridge.configureForRuntime(runtime);
    $Iterable.configureForRuntime(runtime);
    $Stopwatch.configureForRuntime(runtime);
    $Duration.configureForRuntime(runtime);
    $Future.configureForRuntime(runtime);
    $DateTime.configureForRuntime(runtime);
    $Uri.configureForRuntime(runtime);
    $Map.configureForRuntime(runtime);
    $Set.configureForRuntime(runtime);
    $RegExp.configureForRuntime(runtime);
    $AssertionError.configureForRuntime(runtime);
    assertion_hooks.configureAssertionForRuntime(runtime);
    $StringBuffer$bridge.configureForRuntime(runtime);
    $Expando.configureForRuntime(runtime);
    $StackOverflowError.configureForRuntime(runtime);
    $OutOfMemoryError.configureForRuntime(runtime);
    $RangeError.configureForRuntime(runtime);
    $Symbol.configureForRuntime(runtime);
    $Exception.configureForRuntime(runtime);
    $FormatException.configureForRuntime(runtime);
    $ArgumentError.configureForRuntime(runtime);
    $StateError.configureForRuntime(runtime);
    $TypeError.configureForRuntime(runtime);
    $NoSuchMethodError.configureForRuntime(runtime);
    $Invocation.configureForRuntime(runtime);
    runtime.registerBridgeFuncRegisters('dart:core', 'num.parse', $num.$parse);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'num.tryParse',
      $num.$tryParse,
    );
    runtime.registerBridgeFuncRegisters('dart:core', 'int.parse', $int.$parse);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'int.fromEnvironment',
      $int.$fromEnvironment,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'bool.fromEnvironment',
      $bool.$fromEnvironment,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'bool.hasEnvironment',
      $bool.$hasEnvironment,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'bool.parse',
      $bool.$parse,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'bool.tryParse',
      $bool.$tryParse,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'int.tryParse',
      $int.$tryParse,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Function.apply',
      $Function.$apply,
    );
    runtime.registerBridgeFuncRegisters('dart:core', 'Object.', $Object.$new);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Object.hash',
      $Object.$hash,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Object.hashAll',
      $Object.$hashAll,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Object.hashAllUnordered',
      $Object.$hashAllUnordered,
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
    $pragma.configureForRuntime(runtime);
    $Error$bridge.configureForRuntime(runtime);
    $UnimplementedError.configureForRuntime(runtime);
    $UnsupportedError.configureForRuntime(runtime);
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.empty',
      $Stream.$empty,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.',
      $Stream$bridge.$new,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.value',
      $Stream.$_value,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.error',
      $Stream.$error,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.fromFuture',
      $Stream.$fromFuture,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.fromIterable',
      $Stream.$fromIterable,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'Stream.periodic',
      $Stream.$periodic,
      isBridge: true,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'deferred_loadLibrary',
      _deferredLoadLibrary,
    );
    runtime.registerBridgeFuncRegisters(
      'dart:core',
      'deferred_checkLoaded',
      _deferredCheckLoaded,
    );
  }
}

final _deferredImports = Expando<_DeferredImports>();

final class _DeferredImports {
  final loaded = <String>{};
  final loads = <String, Future<Null>>{};
}

_DeferredImports _importsFor(Runtime runtime) =>
    _deferredImports[runtime] ??= _DeferredImports();

$Value? _deferredLoadLibrary(Runtime runtime, Object? r, Object? s, Object? c) {
  final key = (r as $Value).$value as String;
  return $Closure((runtime, target, r, s, c) {
    final state = _importsFor(runtime);
    return $Future.wrap(
      state.loads.putIfAbsent(
        key,
        () => Future<Null>(() {
          state.loaded.add(key);
          return null;
        }),
      ),
      runtime: runtime,
      runtimeTypeId: runtime.internParameterizedType(CoreTypes.future, [
        runtime.lookupType(CoreTypes.nullType),
      ]),
    );
  });
}

$Value? _deferredCheckLoaded(Runtime runtime, Object? r, Object? s, Object? c) {
  final key = (r as $Value).$value as String;
  if (!_importsFor(runtime).loaded.contains(key)) {
    throw StateError('Deferred import "$key" has not been loaded');
  }
  return null;
}
