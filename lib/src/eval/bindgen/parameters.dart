import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/bindgen/bridge.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String namedParameters(BindgenContext ctx,
    {required ExecutableElement element}) {
  final params = element.formalParameters.where((e) => e.isNamed);
  if (params.isEmpty) {
    return '';
  }

  return parameters(ctx, params.toList());
}

String positionalParameters(BindgenContext ctx,
    {required ExecutableElement element}) {
  final params = element.formalParameters.where((e) => e.isPositional);
  if (params.isEmpty) {
    return '';
  }

  return parameters(ctx, params.toList());
}

String parameters(BindgenContext ctx, List<FormalParameterElement> params) {
  return List.generate(
      params.length, (index) => _parameterFrom(ctx, params[index])).join('\n');
}

String _parameterFrom(BindgenContext ctx, FormalParameterElement parameter) {
  return '''
    BridgeParameter(
      '${parameter.name}',
      ${bridgeTypeAnnotationFrom(ctx, parameter.type)},
      ${parameter.isOptional ? 'true' : 'false'},
    ),
  ''';
}

String argumentAccessor(
    BindgenContext ctx, int index, FormalParameterElement param,
    {Map<String, String> paramMapping = const {},
    bool isBridgeMethod = false}) {
  final paramBuffer = StringBuffer();
  final idx = index + (isBridgeMethod ? 1 : 0);
  if (param.isNamed) {
    paramBuffer.write('${paramMapping[param.name] ?? param.name}: ');
  }
  final type = param.type;
  if (type.isDartCoreFunction || type is FunctionType) {
    paramBuffer.write('(');
    if (type is FunctionType) {
      paramBuffer.write(parameterHeader(type.formalParameters));
    }
    paramBuffer.write(') {\n');
    if (type is FunctionType) {
      if (type.returnType is! VoidType) {
        paramBuffer.write('return ');
      }
    }
    final q = (param.isRequired ? '' : '?');
    final call = (param.isRequired ? '' : '?.call');
    paramBuffer.write('(args[$idx]! as EvalCallable$q)$call(runtime, null, [');
    if (type is FunctionType) {
      for (var j = 0; j < type.formalParameters.length; j++) {
        final ftParam = type.formalParameters[j];
        final name = ftParam.name == null || ftParam.name!.isEmpty
            ? 'arg$j'
            : ftParam.name!;
        paramBuffer
            .write(wrapVar(ctx, ftParam.type, name, forCollection: true));
        if (j < type.formalParameters.length - 1) {
          paramBuffer.write(', ');
        }
      }
    }
    paramBuffer.write('])');
    if (type is FunctionType) {
      if (type.returnType is! VoidType) {
        paramBuffer.write('?.\$value');
      }
    }
    paramBuffer.write(';\n}');
  } else {
    final needsCast =
        type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet;
    if (needsCast) {
      paramBuffer.write('(');
    }
    paramBuffer.write('args[$idx]');
    final accessor = needsCast ? 'reified' : 'value';
    if (param.isRequired) {
      paramBuffer.write('!.\$$accessor');
    } else {
      paramBuffer.write('?.\$$accessor');
      if (param.hasDefaultValue) {
        paramBuffer.write(' ?? ${param.defaultValueCode}');
      }
    }
    if (needsCast) {
      final q = (param.isRequired ? '' : '?');
      paramBuffer.write(' as ${type.element!.name}$q');
      paramBuffer.write(')$q.cast()');
    }
  }
  return paramBuffer.toString();
}

List<String> argumentAccessors(
    BindgenContext ctx, List<FormalParameterElement> params,
    {Map<String, String> paramMapping = const {},
    bool isBridgeMethod = false}) {
  return params
      .mapIndexed((i, p) => argumentAccessor(ctx, i, p,
          paramMapping: paramMapping, isBridgeMethod: isBridgeMethod))
      .toList();
}
