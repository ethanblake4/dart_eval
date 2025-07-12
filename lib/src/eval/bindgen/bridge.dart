import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindDecoratoratorMethods(BindgenContext ctx, ClassElement element) {
  final methods = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final m in s.element.methods) m.name: m,
    for (final m in element.methods) m.name: m
  };

  return methods.values
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
          (m) => !(const ['==', 'toString', 'noSuchMethod'].contains(m.name)))
      .map((e) {
        final returnType = e.returnType;
        final needsCast = returnType.isDartCoreList ||
            returnType.isDartCoreMap ||
            returnType.isDartCoreSet;
        final q = returnType.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';

    return '''
        @override
        ${returnType} ${e.displayName}(${_parameterHeader(e.parameters)}) =>
          ${needsCast ? '(' : ''}\$_invoke('${e.displayName}', [
            ${e.parameters.map((p) => wrapVar(ctx, p.type, p.name)).join(', ')}
          ])${needsCast ? 'as ${returnType.getDisplayString(withNullability: false)}$q)$q.cast()' : ''};
        ''';
  }).join('\n');

}

String _parameterHeader(List<ParameterElement> params) {
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
        paramBuffer.write(_parameterHeader(functionType.parameters));
        paramBuffer.write(')');
        break;
      default:
        paramBuffer.write('${param.type.getDisplayString()} ${param.name}');
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