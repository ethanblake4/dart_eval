import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $methods(BindgenContext ctx, ClassElement element) {
  return element.methods.where((method) => !method.isPrivate).map((e) {
    final params = e.parameters;
    final paramBuffer = StringBuffer();
    for (var i = 0; i < params.length; i++) {
      final param = params[i];
      if (param.isNamed) {
        paramBuffer.write('${param.name}: ');
      }
      final type = param.type;
      if (type.isDartCoreFunction || type is FunctionType) {
        paramBuffer.write('(');
        if (type is FunctionType) {
          for (var j = 0; j < type.normalParameterTypes.length; j++) {
            var _name = type.normalParameterNames[j];
            if (_name.isEmpty) {
              _name = 'v$j';
            }
            paramBuffer.write(_name);
            if (j < type.normalParameterTypes.length - 1) {
              paramBuffer.write(', ');
            }
          }

          if (type.optionalParameterNames.isNotEmpty) {
            if (type.normalParameterTypes.isNotEmpty) {
              paramBuffer.write(', ');
            }
            paramBuffer.write('[');

            for (var j = 0; j < type.optionalParameterNames.length; j++) {
              final _name = type.optionalParameterNames[i];
              paramBuffer.write(_name);
              if (j < type.optionalParameterNames.length - 1) {
                paramBuffer.write(', ');
              }
            }
            paramBuffer.write(']');
          }

          if (type.namedParameterTypes.isNotEmpty) {
            if (type.normalParameterTypes.isNotEmpty ||
                type.optionalParameterNames.isNotEmpty) {
              paramBuffer.write(', ');
            }
            paramBuffer.write('{');

            var k = 0;
            type.namedParameterTypes.forEach((_name, _type) {
              paramBuffer.write(_name);
              if (k < type.namedParameterTypes.length - 1) {
                paramBuffer.write(', ');
              }
            });
            paramBuffer.write('}');
          }
        }
        paramBuffer.write(') {\n');
        paramBuffer.write('return (args[$i] as EvalCallable)(runtime, null, [');
        if (type is FunctionType) {
          for (var j = 0; j < type.normalParameterTypes.length; j++) {
            var _name = type.normalParameterNames[j];
            if (_name.isEmpty) {
              _name = 'v$j';
            }
            paramBuffer
                .write(wrapVar(ctx, type.normalParameterTypes[i], _name));
            if (j < type.normalParameterTypes.length - 1) {
              paramBuffer.write(', ');
            }
          }

          if (type.optionalParameterNames.isNotEmpty) {
            if (type.normalParameterTypes.isNotEmpty) {
              paramBuffer.write(', ');
            }

            for (var j = 0; j < type.optionalParameterNames.length; j++) {
              final _name = type.optionalParameterNames[i];
              paramBuffer
                  .write(wrapVar(ctx, type.optionalParameterTypes[i], _name));
              if (j < type.optionalParameterNames.length - 1) {
                paramBuffer.write(', ');
              }
            }
          }

          if (type.namedParameterTypes.isNotEmpty) {
            if (type.normalParameterTypes.isNotEmpty ||
                type.optionalParameterNames.isNotEmpty) {
              paramBuffer.write(', ');
            }

            var k = 0;
            type.namedParameterTypes.forEach((_name, _type) {
              paramBuffer.write(wrapVar(ctx, _type, _name));
              if (k < type.namedParameterTypes.length - 1) {
                paramBuffer.write(', ');
              }
            });
          }
        }
        paramBuffer.write('])?.\$value;\n}');
      } else {
        paramBuffer.write('args[$i]');
        if (param.isRequired) {
          paramBuffer.write('!.\$value');
        } else {
          paramBuffer.write('?.\$value');
          if (param.hasDefaultValue) {
            paramBuffer.write(' ?? ${param.defaultValueCode}');
          }
        }
      }

      if (i < params.length - 1) {
        paramBuffer.write(', ');
      }
    }

    final returnsValue =
        e.returnType is! VoidType && !e.returnType.isDartCoreNull;
    return '''
        static const \$Function __${e.displayName} = \$Function(_${e.displayName});
        static \$Value? _${e.displayName}(Runtime runtime, \$Value? target, List<\$Value?> args) {
          final self = target as \$${element.name};
          ${returnsValue ? 'final result = ' : ''}self.\$value.${e.displayName}(${paramBuffer.toString()});
          return ${wrapVar(ctx, e.returnType, 'result')};
        }''';
  }).join('\n');
}
