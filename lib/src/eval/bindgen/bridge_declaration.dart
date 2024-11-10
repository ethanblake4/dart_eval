import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindTypeSpec(BindgenContext ctx, ClassElement element) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
  static const \$spec = BridgeTypeSpec(
    '${uri}',
    '${element.name}',
  );
''';
}

String bindBridgeType(BindgenContext ctx, ClassElement element) {
  return '''
  static const \$type = BridgeTypeRef(\$spec);
''';
}

String? bindBridgeDeclaration(BindgenContext ctx, ClassElement element) {
  if (element.constructors.isEmpty) {
    return null;
  }

  var genericsStr = '';
  final typeParams = element.typeParameters;
  if (typeParams.isNotEmpty) {
    genericsStr = '''\ngenerics: {
      ${typeParams.map((e) {
      final boundStr = e.bound != null
          ? '\$extends: ${bridgeTypeRefFromType(ctx, e.bound!)}'
          : '';
      return '\'${e.name}\': BridgeGenericParam($boundStr)';
    }).join(',')}
    },''';
  }

  var extendsStr = '';
  if (element.supertype != null && !element.supertype!.isDartCoreObject) {
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
    wrap: ${ctx.wrap},
  );
    ''';
}

String constructors(BindgenContext ctx, ClassElement element) {
  return element.constructors
      .map((e) => bridgeConstructorDef(ctx, constructor: e))
      .join('\n');
}

String methods(BindgenContext ctx, ClassElement element) {
  return element.methods.map((e) => bridgeMethodDef(ctx, method: e)).join('\n');
}

String getters(BindgenContext ctx, ClassElement element) {
  var getters = element.accessors
      .where((element) => element.isGetter && !element.isSynthetic)
      .map((element) => element.displayName)
      .toList();

  return getters
      .map((e) => bridgeGetterDef(ctx, getter: element.getGetter(e)!))
      .join('\n');
}

String setters(BindgenContext ctx, ClassElement element) {
  var setters = element.accessors
      .where((element) => element.isSetter && !element.isSynthetic)
      .map((element) => element.displayName)
      .toList();

  return setters
      .map((e) => bridgeSetterDef(ctx, setter: element.getSetter(e)!))
      .join('\n');
}

String fields(BindgenContext ctx, ClassElement element) {
  var fields = element.fields
      .where((element) => !element.isSynthetic)
      .map((element) => element.displayName)
      .toList();

  return fields
      .map(
        (e) => bridgeFieldDef(ctx, field: element.getField(e)!),
      )
      .join('\n');
}

String bridgeConstructorDef(BindgenContext ctx,
    {required ConstructorElement constructor}) {
  return '''
      '${constructor.name}': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(\$type),
            namedParams: [${namedParameters(ctx, element: constructor)}],
            params: [${positionalParameters(ctx, element: constructor)}],
          ),
          isFactory: ${constructor.isFactory},
      ),
      ''';
}

String bridgeMethodDef(BindgenContext ctx, {required MethodElement method}) {
  return '''
      '${method.name}': BridgeMethodDef(
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
    {required PropertyAccessorElement getter}) {
  return '''
      '${getter.name}': BridgeMethodDef(
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
    {required PropertyAccessorElement setter}) {
  return '''
      '${setter.name}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: ${bridgeTypeAnnotationFrom(ctx, setter.returnType)},
          namedParams: [${namedParameters(ctx, element: setter)}],
          params: [${positionalParameters(ctx, element: setter)}],
        ),
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
