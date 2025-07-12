import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';

String bridgeTypeRefFromType(BindgenContext ctx, DartType type) {
  if (type is TypeParameterType) {
    return 'BridgeTypeRef.ref(\'${type.element3.name3}\')';
  } else if (type is FunctionType) {
    return '''BridgeTypeRef.genericFunction(BridgeFunctionDef(
      returns: ${bridgeTypeAnnotationFrom(ctx, type.returnType)},
      params: [
        ${parameters(ctx, type.formalParameters.where((p) => p.isPositional).toList())}
      ],
      namedParams: [
        ${parameters(ctx, type.formalParameters.where((p) => p.isNamed).toList())}
      ],
    ))''';
  } else if (type is ParameterizedType) {
    final typeArgs = type.typeArguments
        .map((e) => bridgeTypeRefFromType(ctx, e))
        .join(', ');
    return 'BridgeTypeRef(${bridgeTypeSpecFrom(ctx, type)}, [$typeArgs])';
  } 
  return 'BridgeTypeRef(${bridgeTypeSpecFrom(ctx, type)})';
}

String bridgeTypeAnnotationFrom(BindgenContext ctx, DartType type) {
  final nullabilityString = type.nullabilitySuffix == NullabilitySuffix.question
      ? ', nullable: true'
      : '';
  return 'BridgeTypeAnnotation(${bridgeTypeRefFromType(ctx, type)}$nullabilityString)';
}

String bridgeTypeSpecFrom(BindgenContext ctx, DartType type) {
  final builtin = builtinTypeFrom(type);
  if (builtin != null) {
    return builtin;
  }
  final element = type.element3!;
  final lib = element.library2!;
  final uri = ctx.libOverrides[element.name3] ?? lib.uri.toString();
  return 'BridgeTypeSpec(\'${uri}\', \'${element.name3!.replaceAll(r'$', r'\$')}\')';
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
    return 'CoreTypes.dynamic';
  }
  if (type is FunctionType) {
    return 'CoreTypes.function';
  }

  final element = type.element3!;
  final lib = element.library2!;
  final name = element.name3 ?? ' ';
  final lowerCamelCaseName = name.toCamelCase();

  if (!lib.isInSdk) {
    return null;
  }

  final uri = lib.uri.toString();

  if (uri == 'dart:async') {
    if (name == 'Future' || name == 'Stream') {
      return 'CoreTypes.$lowerCamelCaseName';
    }
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
    {bool func = false,
    bool wrapList = false,
    List<ElementAnnotation>? metadata}) {
  if (type is VoidType) {
    if (func) {
      return '\$null()';
    }
    return 'null';
  }

  if (type.isDartCoreNull) {
    return '\$null()';
  }

  var wrapped =
      wrapType(ctx, type, expr, metadata: metadata, wrapList: wrapList);

  if (wrapped == null) {
    if (ctx.unknownTypes.add(type.element3!.name3!)) {
      print('Warning: type ${type.element3!.name3} is not bound, '
          'falling back to wrapAlways()');
    }
    wrapped = 'runtime.wrapAlways($expr)';
  }

  if (type.nullabilitySuffix == NullabilitySuffix.question) {
    return '$expr == null ? \$null() : $wrapped';
  }

  return wrapped;
}

String? wrapType(BindgenContext ctx, DartType type, String expr,
    {bool wrapList = false, List<ElementAnnotation>? metadata}) {
  final union =
      metadata?.firstWhereOrNull((e) => e.element2?.displayName == 'UnionOf');
  String unionStr = '';
  if (union != null) {
    final types =
        union.computeConstantValue()?.getField('types')?.toListValue();
    if (types != null && types.isNotEmpty) {
      for (final type in types) {
        final _type = type.toTypeValue();
        if (_type == null) {
          continue;
        }
        ctx.imports.add(_type.element3!.library2!.uri.toString());
        final wrapper = wrapVar(ctx, _type, expr);

        unionStr +=
            '$expr is ${_type.element3!.name3} ? $wrapper : ';
      }
    }
  }
  if (type is VoidType) {
    return '${unionStr}null';
  }

  if (type.isDartCoreNull) {
    return '${unionStr}\$null()';
  }

  if (type is DynamicType) {
    return '${unionStr}\$Object($expr)';
  }

  if (type is FunctionType) {
    return unionStr + wrapFunctionType(ctx, type, expr);
  }

  if (type.isDartCoreFunction) {
    return '${unionStr}\$Function((runtime, target, args) => $expr())';
  }

  final element = type.element3 ??
      (throw BindingGenerationError('Type $type has no element'));
  final lib = element.library2!;
  final name = element.name3 ?? ' ';

  final defaultCstr = {'int', 'num', 'double', 'bool', 'String', 'Object'};

  if (lib.isInSdk) {
    final dartUri = lib.uri.toString();
    final which = dartUri.substring(5);
    ctx.imports.add('package:dart_eval/stdlib/$which.dart');
    if (defaultCstr.contains(name)) {
      return '${unionStr}\$$name($expr)';
    }
    if (name == 'List') {
      if (wrapList) {
        return '${unionStr}\$List.wrap($expr)';
      }
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '${unionStr}\$List.view($expr, (e) => ${wrapVar(ctx, arg, 'e')})';
    }
    if (name == 'Stream') {
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '${unionStr}\$Stream.wrap($expr.map((e) => ${wrapVar(ctx, arg, 'e')}))';
    }
    if (name == 'Future') {
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '${unionStr}\$Future.wrap($expr.then((e) => ${wrapVar(ctx, arg, 'e')}))';
    }
    return '${unionStr}\$$name.wrap($expr)';
  }

  final typeEl = type.element3!;
  if (typeEl is ClassElement2 &&
      typeEl.metadata2.annotations.any((e) => e.element2?.displayName == 'Bind')) {
    ctx.imports.add(
        typeEl.library2.uri.toString().replaceAll('.dart', '.eval.dart'));
    return '${unionStr}\$$name.wrap($expr)';
  }

  if (type is TypeParameterType) {
    final bound = type.bound;
    if (bound is! DynamicType) {
      final b = wrapVar(ctx, bound, expr);
      if (b != null) {
        return '${unionStr}\$$b';
      }
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

  if (type.optionalParameterTypes.isNotEmpty) {
    for (var j = i; j < type.optionalParameterTypes.length + i; j++) {
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
      if (j < type.optionalParameterTypes.length + i - 1) {
        buffer.write(', ');
      }
    }
  }

  if (type.namedParameterTypes.isNotEmpty) {
    if (type.normalParameterTypes.isNotEmpty ||
        type.optionalParameterTypes.isNotEmpty) {
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
      '); return ${wrapVar(ctx, type.returnType, 'funcResult', func: true)}; })');
  return buffer.toString();
}
