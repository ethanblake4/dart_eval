import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart' show $null;
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'typed_export.dart';
import 'typed_frame.dart';
import 'typed_function.dart';
import 'typed_instance.dart';
import 'typed_interop.dart';
import 'typed_program.dart';

/// Bind the public host map once, before entering the register interpreter.
abstract final class TypedExportAdapter {
  static TypedEntry bind(
    TypedProgram program,
    TypedExport declaration,
    Map<String, Object?> arguments, {
    Runtime? runtime,
  }) {
    final parameters = declaration.parameters;
    final names = {for (final parameter in parameters) parameter.name};
    for (final name in arguments.keys) {
      if (!names.contains(name)) {
        throw ArgumentError.value(
          name,
          'arguments',
          'Unknown parameter for ${declaration.name}',
        );
      }
    }
    final function = program.functions[declaration.functionId];
    if (parameters.length != function.argumentKinds.length) {
      throw StateError(
        'Export parameter metadata does not match ${declaration.name}',
      );
    }
    final values = <Object?>[];
    for (var i = 0; i < parameters.length; i++) {
      final parameter = parameters[i];
      final supplied = arguments.containsKey(parameter.name);
      if (!supplied && parameter.isRequired) {
        throw ArgumentError('Missing required parameter ${parameter.name}');
      }
      final original = supplied
          ? arguments[parameter.name]
          : parameter.defaultValue;
      final needsNativeValidation =
          parameter.typeLibrary == 'dart:core' &&
          const {
            'int',
            'double',
            'num',
            'bool',
            'String',
            'List',
            'Map',
            'Set',
            'Iterable',
            'Function',
          }.contains(parameter.typeName);
      var value = original is $null
          ? null
          : needsNativeValidation
          ? TypedInterop.exportExternal(original, runtime: runtime)
          : original;
      if (parameter.typeLibrary == 'dart:core' &&
          parameter.typeName == 'double' &&
          value is num) {
        value = value.toDouble();
      }
      final boxed = _validate(
        value,
        parameter,
        runtime,
        original,
        function.argumentKinds[i] == TypedArgumentKind.object,
      );
      values.add(switch (function.argumentKinds[i]) {
        TypedArgumentKind.integer => value as int,
        TypedArgumentKind.doublePrecision => (value as num).toDouble(),
        TypedArgumentKind.boolean => value as bool,
        TypedArgumentKind.string => value as String,
        TypedArgumentKind.object => boxed,
      });
    }
    return TypedEntry.fromValues(function, values);
  }

  static $Value? _validate(
    Object? value,
    TypedExportParameter parameter,
    Runtime? runtime,
    Object? original,
    bool needsBox,
  ) {
    Never invalid() => throw ArgumentError.value(
      value,
      parameter.name,
      'Expected ${parameter.typeLibrary}::${parameter.typeName}${parameter.nullable ? '?' : ''}',
    );
    if (value == null) {
      if (!parameter.nullable && parameter.typeName != 'dynamic') invalid();
      return null;
    }
    if (parameter.typeLibrary == 'dart:core') {
      final matches = switch (parameter.typeName) {
        'dynamic' || 'Object' => true,
        'int' => value is int,
        'double' => value is num,
        'num' => value is num,
        'bool' => value is bool,
        'String' => value is String,
        'List' => value is List,
        'Map' => value is Map,
        'Set' => value is Set,
        'Iterable' => value is Iterable,
        'Function' => value is Function || value is EvalCallable,
        'Null' || 'Never' => false,
        _ => null,
      };
      if (matches == true) {
        if (!needsBox) return null;
        if (original is $Value && parameter.typeName != 'double') {
          return original;
        }
        return TypedInterop.boxExternal(value, runtime: runtime);
      }
      if (matches == false) invalid();
    }
    if (value is TypedInstance) {
      $Instance? current = value.dispatchRoot;
      while (current is TypedInstance) {
        if (current.descriptor.name == parameter.typeName &&
            current.descriptor.library == parameter.typeLibrary) {
          return value;
        }
        current = current.superclass;
      }
    }
    final boxed = original is $Value
        ? original
        : TypedInterop.boxExternal(value, runtime: runtime);
    if (boxed != null &&
        runtime != null &&
        runtime.isTypedExternalAssignable(
          boxed,
          parameter.typeLibrary,
          parameter.typeName,
        )) {
      return boxed;
    }
    invalid();
  }
}
