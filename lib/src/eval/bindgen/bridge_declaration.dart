import 'package:analyzer/dart/element/element2.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindTypeSpec(BindgenContext ctx, ClassElement2 element) {
  final uri = ctx.libOverrides[element.name3] ?? ctx.uri;
  return '''
  static const \$spec = BridgeTypeSpec(
    '${uri}',
    '${element.name3!.replaceAll(r'$', r'\$')}',
  );
''';
}

String bindBridgeType(BindgenContext ctx, ClassElement2 element) {
  return '''
  static const \$type = BridgeTypeRef(\$spec);
''';
}

String? bindBridgeDeclaration(BindgenContext ctx, ClassElement2 element, {bool isBridge = false}) {
  if (element.constructors2.isEmpty) {
    return null;
  }

  var genericsStr = '';
  final typeParams = element.typeParameters2;
  if (typeParams.isNotEmpty) {
    genericsStr = '''\ngenerics: {
      ${typeParams.map((e) {
      final boundStr = e.bound != null && !ctx.implicitSupers
          ? '\$extends: ${bridgeTypeRefFromType(ctx, e.bound!)}'
          : '';
      return '\'${e.name3}\': BridgeGenericParam($boundStr)';
    }).join(',')}
    },''';
  }

  var extendsStr = '';
  if (element.supertype != null &&
      !element.supertype!.isDartCoreObject &&
      !ctx.implicitSupers) {
    extendsStr =
        '\n\$extends: ${bridgeTypeRefFromType(ctx, element.supertype!)},';
  }

  var implementsStr = '';
  if (element.interfaces.isNotEmpty) {
    implementsStr =
        '\n\$implements: [${element.interfaces.map((e) => bridgeTypeRefFromType(ctx, e)).join(', ')}],';
  }

  return '''
  static const \$declaration = BridgeClassDef(
    BridgeClassType(
      \$type,
      isAbstract: ${element.isAbstract},
      $genericsStr
      $extendsStr
      $implementsStr
    ),
    constructors: {
${constructors(ctx, element)}
    },
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
    wrap: ${!isBridge},
    bridge: $isBridge,
  );
    ''';
}

String constructors(BindgenContext ctx, ClassElement2 element) {
  return element.constructors2
      .map((e) => bridgeConstructorDef(ctx, constructor: e))
      .join('\n');
}

String methods(BindgenContext ctx, ClassElement2 element) {
  final methods = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final m in s.element3.methods2.where((m) => !m.isStatic)) m.name3: m,
    for (final m in element.methods2) m.name3: m
  };
  return methods.values
      .where(
          (m) => !(const ['==', 'toString', 'noSuchMethod'].contains(m.name3)))
      .map((m) => bridgeMethodDef(ctx, method: m))
      .join('\n');
}

String getters(BindgenContext ctx, ClassElement2 element) {
  final getters = [
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.element3.getters2.where((a) => !a.isStatic)) a,
    for (final a in element.getters2) a
  ];

  return getters.map((e) => bridgeGetterDef(ctx, getter: e)).join('\n');
}

String setters(BindgenContext ctx, ClassElement2 element) {
  final setters = [
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.element3.setters2.where((a) => !a.isStatic))
          a,
    for (final a in [...element.getters2, ...element.setters2]) a
  ];

  return setters.map((e) => bridgeSetterDef(ctx, setter: e)).join('\n');
}

String fields(BindgenContext ctx, ClassElement2 element) {
  final allFields = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        if (s is ClassElement2)
          for (final f in s.element3.fields2.where((f) => !f.isStatic))
            f.name3: f,
    for (final f in element.fields2)f.name3: f
  };

  final fields = allFields.values.where((element) => !element.isSynthetic);

  return fields
      .map(
        (e) => bridgeFieldDef(ctx, field: e),
      )
      .join('\n');
}

String bridgeConstructorDef(BindgenContext ctx,
    {required ConstructorElement2 constructor}) {
  return '''
      '${constructor.name3}': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(\$type),
            namedParams: [${namedParameters(ctx, element: constructor)}],
            params: [${positionalParameters(ctx, element: constructor)}],
          ),
          isFactory: ${constructor.isFactory},
      ),
      ''';
}

String bridgeMethodDef(BindgenContext ctx, {required MethodElement2 method}) {
  return '''
      '${method.name3}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: ${bridgeTypeAnnotationFrom(ctx, method.returnType)},
          namedParams: [${namedParameters(ctx, element: method)}],
          params: [${positionalParameters(ctx, element: method)}],
        ),
        ${method.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeGetterDef(BindgenContext ctx,
    {required PropertyAccessorElement2 getter}) {
  return '''
      '${getter.name3}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: ${bridgeTypeAnnotationFrom(ctx, getter.returnType)},
          namedParams: [${namedParameters(ctx, element: getter)}],
          params: [${positionalParameters(ctx, element: getter)}],
        ),
        ${getter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeSetterDef(BindgenContext ctx,
    {required PropertyAccessorElement2 setter}) {
  return '''
      '${setter.name3}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: ${bridgeTypeAnnotationFrom(ctx, setter.returnType)},
          namedParams: [${namedParameters(ctx, element: setter)}],
          params: [${positionalParameters(ctx, element: setter)}],
        ),
        ${setter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeFieldDef(BindgenContext ctx, {required FieldElement2 field}) {
  return '''
      '${field.name3}': BridgeFieldDef(
        ${bridgeTypeAnnotationFrom(ctx, field.type)},
        isStatic: ${field.isStatic},
      ),
''';
}
