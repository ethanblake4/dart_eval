import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindBridgeType(BindgenContext ctx, ClassElement element) {
  return '''
  static const \$type = BridgeTypeRef(
    BridgeTypeSpec(
      '${ctx.uri}',
      '${element.name}',
    ),
  );
''';
}

String? bindBridgeDeclaration(BindgenContext ctx, ClassElement element) {
  if (element.constructors.isEmpty) {
    return null;
  }

  return '''
  static const \$declaration = BridgeClassDef(
    BridgeClassType(
      \$type,
      isAbstract: ${element.isAbstract},
    ),
    constructors: {
${constructors(element)}
    },
    methods: {
${methods(element)}
    },
    getters: {
${getters(element)}
    },
    setters: {
${setters(element)}
    },
    fields: {
${fields(element)}
    },
    wrap: ${ctx.wrap},
  );
    ''';
}

String constructors(ClassElement element) {
  return element.constructors
      .map((e) => bridgeConstructorDef(constructor: e))
      .join('\n');
}

String methods(ClassElement element) {
  return element.methods.map((e) => bridgeMethodDef(method: e)).join('\n');
}

String getters(ClassElement element) {
  var getters = element.accessors
      .where((element) => element.isGetter && !element.isSynthetic)
      .map((element) => element.displayName)
      .toList();

  return getters
      .map((e) => bridgeGetterDef(getter: element.getGetter(e)!))
      .join('\n');
}

String setters(ClassElement element) {
  var setters = element.accessors
      .where((element) => element.isSetter && !element.isSynthetic)
      .map((element) => element.displayName)
      .toList();

  return setters
      .map((e) => bridgeSetterDef(setter: element.getSetter(e)!))
      .join('\n');
}

String fields(ClassElement element) {
  var fields = element.fields
      .where((element) => !element.isSynthetic)
      .map((element) => element.displayName)
      .toList();

  return fields
      .map(
        (e) => bridgeFieldDef(field: element.getField(e)!),
      )
      .join('\n');
}

String bridgeConstructorDef({required ConstructorElement constructor}) {
  return '''
      '${constructor.name}': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(\$type),
            namedParams: [${namedParameters(element: constructor)}],
            params: [${positionalParameters(element: constructor)}],
          ),
      ),
      ''';
}

String bridgeMethodDef({required MethodElement method}) {
  return '''
      '${method.name}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(${bridgeTypeRefFromType(method.returnType)}),
          namedParams: [${namedParameters(element: method)}],
          params: [${positionalParameters(element: method)}],
        ),
        ${method.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeGetterDef({required PropertyAccessorElement getter}) {
  return '''
      '${getter.name}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(${bridgeTypeRefFromType(getter.returnType)}),
          namedParams: [${namedParameters(element: getter)}],
          params: [${positionalParameters(element: getter)}],
        ),
        ${getter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeSetterDef({required PropertyAccessorElement setter}) {
  return '''
      '${setter.name}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(${bridgeTypeRefFromType(setter.returnType)}),
          namedParams: [${namedParameters(element: setter)}],
          params: [${positionalParameters(element: setter)}],
        ),
        ${setter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeFieldDef({required FieldElement field}) {
  return '''
      '${field.name}': BridgeFieldDef(
        BridgeTypeAnnotation(${bridgeTypeRefFromType(field.type)}),
        isStatic: ${field.isStatic},
      ),
''';
}
