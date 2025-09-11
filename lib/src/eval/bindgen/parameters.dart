import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/bridge.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String namedParameters(BindgenContext ctx,
    {required ExecutableElement2 element}) {
  final params = element.formalParameters.where((e) => e.isNamed);
  if (params.isEmpty) {
    return '';
  }

  return parameters(ctx, params.toList());
}

String positionalParameters(BindgenContext ctx,
    {required ExecutableElement2 element}) {
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
      '${parameter.name3}',
      ${bridgeTypeAnnotationFrom(ctx, parameter.type)},
      ${parameter.isOptional ? 'true' : 'false'},
    ),
  ''';
}

String argumentAccessors(
    BindgenContext ctx, List<FormalParameterElement> params,
    {Map<String, String> paramMapping = const {},
    bool isBridgeMethod = false}) {
  final paramBuffer = StringBuffer();
  for (var i = 0; i < params.length; i++) {
    final idx = i + (isBridgeMethod ? 1 : 0);
    final param = params[i];
    if (param.isNamed) {
      paramBuffer.write('${paramMapping[param.name3] ?? param.name3}: ');
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
      paramBuffer
          .write('(args[$idx]! as EvalCallable$q)$call(runtime, null, [');
      if (type is FunctionType) {
        for (var j = 0; j < type.formalParameters.length; j++) {
          final ftParam = type.formalParameters[j];
          final name = ftParam.name3 == null || ftParam.name3!.isEmpty
              ? 'arg$j'
              : ftParam.name3!;
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
        paramBuffer.write(' as ${type.element3!.name3}$q');
        paramBuffer.write(')$q.cast()');
      }
    }

    if (i < params.length - 1) {
      paramBuffer.write(', ');
    }
  }
  return paramBuffer.toString();
}
