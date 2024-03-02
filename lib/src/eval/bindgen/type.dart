import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';

String bridgeTypeRefFromType(DartType type) {
  if (type is TypeParameterType) {
    return 'BridgeTypeRef.ref(\'${type.element.name}\')';
  }
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
  if (type is FunctionType) {
    return 'CoreTypes.function';
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

String? wrapVar(BindgenContext ctx, DartType type, String expr,
    [bool forFunc = false]) {
  if (type is VoidType) {
    if (forFunc) {
      return '\$null()';
    }
    return 'null';
  }

  if (type.isDartCoreNull) {
    return '\$null()';
  }

  var wrapped = wrapType(ctx, type, expr);

  if (wrapped == null) {
    if (ctx.unknownTypes.add(type.element!.name!)) {
      print('Warning: type ${type.element!.name} is not bound, '
          'falling back to wrapAlways()');
    }
    wrapped = 'runtime.wrapAlways($expr)';
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

  if (type is DynamicType) {
    return '\$Object($expr)';
  }

  if (type is FunctionType) {
    return wrapFunctionType(ctx, type, expr);
  }

  if (type.isDartCoreFunction) {
    return '\$Function((runtime, target, args) => $expr())';
  }

  final element = type.element ??
      (throw BindingGenerationError('Type $type has no element'));
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

  if (type is TypeParameterType) {
    final bound = type.bound;
    if (bound is! DynamicType) {
      return wrapVar(ctx, bound, expr);
    }
  }

  return null;
}

String wrapFunctionType(BindgenContext ctx, FunctionType type, String expr) {
  var buffer = StringBuffer('\$Function((runtime, target, args) { ');
  if (type.returnType is! VoidType && !type.returnType.isDartCoreNull) {
    buffer.write('final funcResult = ');
  }
  buffer.write('$expr(');
  var i = 0;
  for (; i < type.normalParameterTypes.length; i++) {
    buffer.write('args[$i]');
    final _type = type.normalParameterTypes[i];
    if (_type.nullabilitySuffix == NullabilitySuffix.question) {
      buffer.write('?.\$value');
    } else {
      buffer.write('!.\$value');
    }
    if (i < type.normalParameterTypes.length - 1) {
      buffer.write(', ');
    }
  }

  if (type.optionalParameterNames.isNotEmpty) {
    for (var j = i; j < type.optionalParameterNames.length + i; j++) {
      if (type.normalParameterTypes.isNotEmpty) {
        buffer.write(', ');
      }
      final _type = type.optionalParameterTypes[i];
      buffer.write('args[$j]');
      if (_type.nullabilitySuffix == NullabilitySuffix.question) {
        buffer.write('?.\$value');
      } else {
        buffer.write('!.\$value');
      }
      if (j < type.optionalParameterNames.length + i - 1) {
        buffer.write(', ');
      }
    }
  }

  if (type.namedParameterTypes.isNotEmpty) {
    if (type.normalParameterTypes.isNotEmpty ||
        type.optionalParameterNames.isNotEmpty) {
      buffer.write(', ');
    }

    var k = i;
    type.namedParameterTypes.forEach((_name, _type) {
      buffer.write(_name);
      buffer.write(': args[$k]');
      if (_type.nullabilitySuffix == NullabilitySuffix.question) {
        buffer.write('?.\$value');
      } else {
        buffer.write('!.\$value');
      }
      if (k < type.namedParameterTypes.length + i - 1) {
        buffer.write(', ');
      }
    });
  }
  buffer.write(
      '); return ${wrapVar(ctx, type.returnType, 'funcResult', true)}; })');
  return buffer.toString();
}
