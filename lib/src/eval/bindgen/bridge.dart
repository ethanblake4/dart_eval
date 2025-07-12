import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindDecoratoratorMethods(BindgenContext ctx, ClassElement2 element) {
  final methods = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final m in s.element3.methods2) m.name3: m,
    for (final m in element.methods2) m.name3: m
  };

  return methods.values
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
          (m) => !(const ['==', 'toString', 'noSuchMethod'].contains(m.name3)))
      .map((e) {
        final returnType = e.returnType;
        final needsCast = returnType.isDartCoreList ||
            returnType.isDartCoreMap ||
            returnType.isDartCoreSet;
        final q = returnType.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';

    return '''
        @override
        ${returnType} ${e.name3}(${_parameterHeader(e.formalParameters)}) =>
          ${needsCast ? '(' : ''}\$_invoke('${e.name3}', [
            ${e.formalParameters.map((p) => wrapVar(ctx, p.type, p.displayName)).join(', ')}
          ])${needsCast ? 'as ${returnType..getDisplayString()}$q)$q.cast()' : ''};
        ''';
  }).join('\n');

}

String _parameterHeader(List<FormalParameterElement> params) {
  final paramBuffer = StringBuffer();
  var inNonPositional = false;
  for (var i = 0; i < params.length; i++) {
    final param = params[i];
    if (param.isNamed || param.isOptional) {
      if (!inNonPositional) {
        inNonPositional = true;
        paramBuffer.write(param.isNamed ? '{' : '[');
      }
    } 
    switch (param.type) {
      case FunctionType functionType:
        paramBuffer.write(functionType.returnType.getDisplayString());
        paramBuffer.write(' Function(');
        paramBuffer.write(_parameterHeader(functionType.formalParameters));
        paramBuffer.write(')');
        break;
      default:
        paramBuffer.write('${param.type.getDisplayString()} ${param.name3}');
    }
    if (i < params.length - 1) {
      paramBuffer.write(', ');
    }
  }

  if (inNonPositional) {
    paramBuffer.write(params.last.isNamed ? '}' : ']');
  }

  return paramBuffer.toString();
}