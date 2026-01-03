import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindTypeSpec(BindgenContext ctx, InterfaceElement element) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
  static const \$spec = BridgeTypeSpec(
    '$uri',
    '${element.name!.replaceAll(r'$', r'\$')}',
  );
''';
}

String bindBridgeType(BindgenContext ctx, InterfaceElement element) {
  return '''
  static const \$type = BridgeTypeRef(\$spec);
''';
}

String bindFunctionDeclaration(
    BindgenContext ctx, TopLevelFunctionElement element) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
  static const \$declaration = BridgeFunctionDeclaration(
    '$uri',
    '${element.name!.replaceAll(r'$', r'\$')}',
    ${bridgeFunctionDef(ctx, function: element)}
  );
''';
}

String? bindBridgeDeclaration(BindgenContext ctx, InterfaceElement element,
    {bool isBridge = false}) {
  if (element is ClassElement && element.constructors.isEmpty) {
    return null;
  }

  var genericsStr = '';
  final typeParams = element.typeParameters;
  if (typeParams.isNotEmpty && element is ClassElement) {
    genericsStr = '''\ngenerics: {
      ${typeParams.map((e) {
      final boundStr = e.bound != null && !ctx.implicitSupers
          ? '\$extends: ${bridgeTypeRefFromType(ctx, e.bound!)}'
          : '';
      return '\'${e.name}\': BridgeGenericParam($boundStr)';
    }).join(',')}
    },''';
  }

  var extendsStr = '';
  if (element is ClassElement &&
      element.supertype != null &&
      !element.supertype!.isDartCoreObject &&
      !ctx.implicitSupers) {
    extendsStr =
        '\n\$extends: ${bridgeTypeRefFromType(ctx, element.supertype!)},';
  }

  var implementsStr = '';
  if (element is ClassElement && element.interfaces.isNotEmpty) {
    implementsStr =
        '\n\$implements: [${element.interfaces.map((e) => bridgeTypeRefFromType(ctx, e)).join(', ')}],';
  }

  var enumValuesStr = '';
  if (element is EnumElement) {
    enumValuesStr = '''
    values: [${element.constants.map((e) => "'${e.name}'").join(', ')}],
    ''';
  }

  return '''
  static const \$declaration = ${element is ClassElement ? 'BridgeClassDef(BridgeClassType(' : 'BridgeEnumDef('}
      \$type,
      ${element is ClassElement && element.isAbstract ? 'isAbstract: true,' : ''}
      $enumValuesStr
      $genericsStr
      $extendsStr
      $implementsStr
    ${element is ClassElement ? '),' : ''}
    ${element is ClassElement ? '''
    constructors: {
${constructors(ctx, element)}
    },
    ''' : ''}
    methods: {
${methods(ctx, element)}
    },
    getters: {
${getters(ctx, element)}
    },
    setters: {
${setters(ctx, element)}
    },
    fields: {
${fields(ctx, element)}
    },
    ${element is ClassElement ? '''
    wrap: ${!isBridge},
    bridge: $isBridge,
    ''' : ''}
  );
    ''';
}

String constructors(BindgenContext ctx, InterfaceElement element) {
  return element.constructors
      .where((e) => !e.isPrivate)
      .map((e) => bridgeConstructorDef(ctx, constructor: e))
      .join('\n');
}

String methods(BindgenContext ctx, InterfaceElement element) {
  final methods = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final m in s.element.methods.where((m) => !m.isStatic)) m.name: m,
    for (final m in element.methods) m.name: m
  };
  return methods.values
      .where(
          (m) => !(const ['==', 'toString', 'noSuchMethod'].contains(m.name)))
      .where((m) => !m.isPrivate)
      .map((m) => bridgeMethodDef(ctx, method: m))
      .join('\n');
}

String getters(BindgenContext ctx, InterfaceElement element) {
  final getters = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.element.getters.where((a) => !a.isStatic)) a.name: a,
    for (final a in element.getters) a.name: a
  };

  return getters.values
      .where((m) => !(const ['hashCode', 'runtimeType'].contains(m.name)))
      .where((element) => !element.isPrivate)
      .where((element) =>
          !element.isSynthetic ||
          (element is EnumElement &&
              element.nonSynthetic is FieldElement &&
              !(element.nonSynthetic as FieldElement).isEnumConstant))
      .map((e) => bridgeGetterDef(ctx, getter: e))
      .join('\n');
}

String setters(BindgenContext ctx, InterfaceElement element) {
  final setters = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.element.setters.where((a) => !a.isStatic)) a.name: a,
    for (final a in element.setters) a.name: a
  };

  return setters.values
      .where((element) => !element.isSynthetic && !element.isPrivate)
      .map((e) => bridgeSetterDef(ctx, setter: e))
      .join('\n');
}

String fields(BindgenContext ctx, InterfaceElement element) {
  final allFields = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        if (s is ClassElement)
          for (final f in (s as ClassElement).fields.where((f) => !f.isStatic))
            f.name: f,
    for (final f in element.fields) f.name: f
  };

  final fields = allFields.values.where((element) =>
      !element.isSynthetic && !element.isEnumConstant && !element.isPrivate);

  return fields
      .map(
        (e) => bridgeFieldDef(ctx, field: e),
      )
      .join('\n');
}

String bridgeConstructorDef(BindgenContext ctx,
    {required ConstructorElement constructor}) {
  return '''
      '${constructor.name == 'new' ? '' : constructor.name}': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(\$type),
            namedParams: [${namedParameters(ctx, element: constructor)}],
            params: [${positionalParameters(ctx, element: constructor)}],
          ),
          isFactory: ${constructor.isFactory},
      ),
      ''';
}

String bridgeFunctionDef(BindgenContext ctx,
    {required ExecutableElement function}) {
  return '''
        BridgeFunctionDef(
          returns: ${bridgeTypeAnnotationFrom(ctx, function.returnType)},
          namedParams: [${namedParameters(ctx, element: function)}],
          params: [${positionalParameters(ctx, element: function)}],
        ),
''';
}

String bridgeMethodDef(BindgenContext ctx, {required MethodElement method}) {
  return '''
      '${method.name}': BridgeMethodDef(
        ${bridgeFunctionDef(ctx, function: method)}
        ${method.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeGetterDef(BindgenContext ctx,
    {required PropertyAccessorElement getter}) {
  return '''
      '${getter.name}': BridgeMethodDef(
        ${bridgeFunctionDef(ctx, function: getter)}
        ${getter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeSetterDef(BindgenContext ctx,
    {required PropertyAccessorElement setter}) {
  return '''
      '${setter.name}': BridgeMethodDef(
        ${bridgeFunctionDef(ctx, function: setter)}
        ${setter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeFieldDef(BindgenContext ctx, {required FieldElement field}) {
  return '''
      '${field.name}': BridgeFieldDef(
        ${bridgeTypeAnnotationFrom(ctx, field.type)},
        isStatic: ${field.isStatic},
      ),
''';
}
