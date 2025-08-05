import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindForwardedConstructors(BindgenContext ctx, ClassElement2 element,
    {bool isBridge = false}) {
  return element.constructors2
      .where((cstr) => !cstr.isPrivate)
      .map((e) => _$forwardedConstructor(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String _$forwardedConstructor(
    BindgenContext ctx, ClassElement2 element, ConstructorElement2 constructor,
    {bool isBridge = false}) {
  final name = constructor.name3 ?? '';
  final namedConstructor =
      constructor.name3 != null && constructor.name3 != 'new'
          ? '.${constructor.name3}'
          : '';
  final fullyQualifiedConstructorId =
      '\$${element.name3}\$bridge$namedConstructor';

  return '''
  /// Forwarded constructor for [${element.name3}.$name]
  $fullyQualifiedConstructorId(${parameterHeader(constructor.formalParameters, forConstructor: true)});
''';
}

String bindDecoratorMethods(BindgenContext ctx, ClassElement2 element) {
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
    final q =
        returnType.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';

    return '''
        @override
        $returnType ${e.displayName}(${parameterHeader(e.formalParameters)}) =>
          ${needsCast ? '(' : ''}\$_invoke('${e.displayName}', [
            ${e.formalParameters.map((p) => wrapVar(ctx, p.type, p.name3 ?? '')).join(', ')}
          ])${needsCast ? 'as ${returnType.element3!.name3}$q)$q.cast()' : ''};
        ''';
  }).join('\n');
}

String bindDecoratorProperties(BindgenContext ctx, ClassElement2 element) {
  final properties = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final p in s.element3.fields2) p.name3: p,
    for (final p in element.fields2) p.name3: p
  };

  return properties.values
      .where((property) => !property.isPrivate && !property.isStatic)
      .map((e) {
    final type = e.type;

    return '''
        @override
        $type get ${e.displayName} => \$_get('${e.displayName}');
        ''';
  }).join('\n');
}

String parameterHeader(List<FormalParameterElement> params,
    {bool forConstructor = false}) {
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
    if (param.isRequiredNamed) {
      paramBuffer.write('required ');
    }
    switch (param.type) {
      case FunctionType functionType when !forConstructor:
        paramBuffer.write(functionType.returnType.getDisplayString());
        paramBuffer.write(' Function(');
        paramBuffer.write(parameterHeader(functionType.formalParameters));
        paramBuffer.write(')');
        break;
      default:
        if (forConstructor) {
          paramBuffer.write('super.');
        } else {
          paramBuffer.write('${param.type.getDisplayString()} ');
        }
    }
    paramBuffer.write(
        param.name3 == null || param.name3!.isEmpty ? 'arg$i' : param.name3);
    if (i < params.length - 1) {
      paramBuffer.write(', ');
    }
  }

  if (inNonPositional) {
    paramBuffer.write(params.last.isNamed ? '}' : ']');
  }

  return paramBuffer.toString();
}
