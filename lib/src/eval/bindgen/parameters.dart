import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String namedParameters(BindgenContext ctx,
    {required FormalParameterElement element}) {
  final params = element.formalParameters.where((e) => e.isNamed);
  if (params.isEmpty) {
    return '';
  }

  return parameters(ctx, params.toList());
}

String positionalParameters(BindgenContext ctx,
    {required FormalParameterElement element}) {
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

String argumentAccessors(BindgenContext ctx, List<FormalParameterElement> params,
    {Map<String, String> paramMapping = const {}}) {
  final paramBuffer = StringBuffer();
  for (var i = 0; i < params.length; i++) {
    final param = params[i];
    if (param.isNamed) {
      paramBuffer.write('${paramMapping[param.name3] ?? param.name3}: ');
    }
    final type = param.type;
    if (type.isDartCoreFunction || type is FunctionType) {
      paramBuffer.write('(');
      if (type is FunctionType) {
        final normalParams = type.formalParameters.where((p) => p.isRequiredPositional).toList();
        for (var j = 0; j < normalParams.length; j++) {
          var _name = normalParams[j].name3;
          if (_name == null) {
            _name = 'v$j';
          }
          paramBuffer.write(_name);
          if (j < normalParams.length - 1) {
            paramBuffer.write(', ');
          }
        }

        final optionalParams = type.formalParameters.where((p) => p.isOptionalPositional).toList();
        if (optionalParams.isNotEmpty) {
          if (normalParams.isNotEmpty) {
            paramBuffer.write(', ');
          }
          paramBuffer.write('[');

          for (var j = 0; j < optionalParams.length; j++) {
            final _name = optionalParams[j].name3;
            paramBuffer.write(_name);
            if (j < optionalParams.length - 1) {
              paramBuffer.write(', ');
            }
          }
          paramBuffer.write(']');
        }

        final namedParams = type.formalParameters.where((p) => p.isNamed).toList();
        if (namedParams.isNotEmpty) {
          if (normalParams.isNotEmpty || optionalParams.isNotEmpty) {
            paramBuffer.write(', ');
          }
          paramBuffer.write('{');

          for (var k = 0; k < namedParams.length; k++) {
            final _name = namedParams[k].name3;
            paramBuffer.write(_name);
            if (k < namedParams.length - 1) {
              paramBuffer.write(', ');
            }
          }
          paramBuffer.write('}');
        }
      }
      paramBuffer.write(') {\n');
      paramBuffer.write('return (args[$i] as EvalCallable)(runtime, null, [');
      if (type is FunctionType) {
        final normalParams = type.formalParameters.where((p) => p.isRequiredPositional).toList();
        for (var j = 0; j < normalParams.length; j++) {
          var _name = normalParams[j].name3;
          if (_name == null) {
            _name = 'v$j';
          }
          paramBuffer.write(wrapVar(ctx, normalParams[j].type, _name));
          if (j < normalParams.length - 1) {
            paramBuffer.write(', ');
          }
        }

        final optionalParams = type.formalParameters.where((p) => p.isOptionalPositional).toList();
        if (optionalParams.isNotEmpty) {
          if (normalParams.isNotEmpty) {
            paramBuffer.write(', ');
          }

          for (var j = 0; j < optionalParams.length; j++) {
            final _name = optionalParams[j].displayName;
            paramBuffer.write(wrapVar(ctx, optionalParams[j].type, _name));
            if (j < optionalParams.length - 1) {
              paramBuffer.write(', ');
            }
          }
        }

        final namedParams = type.formalParameters.where((p) => p.isNamed).toList();
        if (namedParams.isNotEmpty) {
          if (normalParams.isNotEmpty || optionalParams.isNotEmpty) {
            paramBuffer.write(', ');
          }

          for (var k = 0; k < namedParams.length; k++) {
            final _name = namedParams[k].displayName;
            paramBuffer.write(wrapVar(ctx, namedParams[k].type, _name));
            if (k < namedParams.length - 1) {
              paramBuffer.write(', ');
            }
          }
        }
      }
      paramBuffer.write('])?.\$value;\n}');
    } else {
      final needsCast =
          type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet;
      if (needsCast) {
        paramBuffer.write('(');
      }
      paramBuffer.write('args[$i]');
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
