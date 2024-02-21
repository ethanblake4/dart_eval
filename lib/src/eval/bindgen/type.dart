import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String bridgeTypeRefFromType(DartType type) {
  return 'BridgeTypeRef(${bridgeTypeSpecFrom(type)})';
}

String bridgeTypeSpecFrom(DartType type) {
  final builtin = builtinTypeFrom(type);
  if (builtin != null) {
    return builtin;
  }
  final element = type.element!;
  final lib = element.library!;
  return 'BridgeTypeSpec(\'${lib.source.uri}\', \'${element.name}\')';
}

String? builtinTypeFrom(DartType type) {
  if (type.isDartCoreNull) {
    return 'CoreTypes.nullType';
  }
  if (type.isDartCoreEnum) {
    return 'CoreTypes.enumType';
  }
  if (type is VoidType) {
    return 'CoreTypes.voidType';
  }
  if (type is DynamicType) {
    return 'CoreTypes.dynamicType';
  }

  final element = type.element!;
  final lib = element.library!;
  final name = element.name ?? ' ';
  final lowerCamelCaseName = name[0].toLowerCase() + name.substring(1);

  if (!lib.isInSdk) {
    return null;
  }

  final uri = lib.source.uri.toString();

  if (uri == 'dart:async') {
    return 'AsyncTypes.$lowerCamelCaseName';
  }
  if (uri == 'dart:collection') {
    return 'CollectionTypes.$lowerCamelCaseName';
  }
  if (uri == 'dart:convert') {
    return 'ConvertTypes.$lowerCamelCaseName';
  }
  if (uri == 'dart:core') {
    return 'CoreTypes.$lowerCamelCaseName';
  }
  if (uri == 'dart:io') {
    return 'IoTypes.$lowerCamelCaseName';
  }
  if (uri == 'dart:math') {
    return 'MathTypes.$lowerCamelCaseName';
  }
  if (uri == 'dart:typed_data') {
    return 'TypedDataTypes.$lowerCamelCaseName';
  }
  return null;
}

String? wrapVar(BindgenContext ctx, DartType type, String expr) {
  if (type is VoidType) {
    return 'null';
  }

  if (type.isDartCoreNull) {
    return '\$null()';
  }

  var wrapped = wrapType(ctx, type, expr);

  if (wrapped == null) {
    if (ctx.unknownTypes.add(type.element!.name!)) {
      print('Warning: type ${type.element!.name} is not bound, '
          'falling back to \$Object');
    }
    wrapped = '\$Object($expr)';
  }

  if (type.nullabilitySuffix == NullabilitySuffix.question) {
    return '$expr == null ? \$null() : $wrapped';
  }

  return wrapped;
}

String? wrapType(BindgenContext ctx, DartType type, String expr) {
  if (type is VoidType) {
    return 'null';
  }

  if (type.isDartCoreNull) {
    return '\$null()';
  }

  final element = type.element!;
  final lib = element.library!;
  final name = element.name ?? ' ';

  final defaultCstr = {'int', 'num', 'double', 'bool', 'String', 'Object'};

  if (lib.isInSdk) {
    final dartUri = lib.source.uri.toString();
    final which = dartUri.substring(5);
    ctx.imports.add('package:dart_eval/stdlib/$which.dart');
    if (defaultCstr.contains(name)) {
      return '\$$name($expr)';
    }
    if (name == 'List') {
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '\$List.view($expr, (e) => ${wrapVar(ctx, arg, 'e')})';
    }
    return '\$$name.wrap($expr)';
  }

  final typeEl = type.element;
  if (typeEl is ClassElement &&
      typeEl.metadata.any((e) => e.element?.displayName == 'Bind')) {
    ctx.imports.add(typeEl.library.source.uri.toString());
    return '\$$name.wrap($expr)';
  }

  return null;
}
