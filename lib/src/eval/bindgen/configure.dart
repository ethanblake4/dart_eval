import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String bindConfigureForRuntime(
  BindgenContext ctx,
  ClassElement element, {
  bool isBridge = false,
}) =>
    '''
static void configureForRuntime(Runtime runtime) {
  ${constructorsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticMethodsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticGettersForRuntime(ctx, element, isBridge: isBridge)}
  ${staticSettersForRuntime(ctx, element, isBridge: isBridge)}
}
''';

String bindConfigureEnumForRuntime(BindgenContext ctx, EnumElement element) =>
    '''
static void configureForRuntime(Runtime runtime) {
  ${enumValuesForRuntime(ctx, element)}
  ${staticMethodsForRuntime(ctx, element)}
  ${staticGettersForRuntime(ctx, element)}
  ${staticSettersForRuntime(ctx, element)}
}
''';

String bindConfigureFunctionForRuntime(
  BindgenContext ctx,
  TopLevelFunctionElement element,
) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
static void configureForRuntime(Runtime runtime) {
  return runtime.registerBridgeFunc('$uri', '${element.name!.replaceAll(r'$', r'\$')}', const \$${element.name}Fn().call);
}
''';
}

String enumValuesForRuntime(BindgenContext ctx, EnumElement element) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeEnumValues(
      '$uri',
      '${element.name}',
      \$${element.name}._\$values
    );
  ''';
}

String constructorsForRuntime(
  BindgenContext ctx,
  ClassElement element, {
  bool isBridge = false,
}) {
  return element.constructors
      .where(
        (cstr) => (!element.isAbstract || cstr.isFactory) && !cstr.isPrivate,
      )
      .map((e) => constructorForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String constructorForRuntime(
  BindgenContext ctx,
  ClassElement element,
  ConstructorElement constructor, {
  bool isBridge = false,
}) {
  var name = constructor.name ?? '';
  if (name == 'new') {
    name = '';
  }
  final fullyQualifiedConstructorId = '${element.name}.$name';

  final staticName = constructor.name ?? '';
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final bridgeParam = isBridge ? ', isBridge: true' : '';

  return '''
    runtime.registerBridgeFunc(
      '$uri',
      '$fullyQualifiedConstructorId',
      \$${element.name}${isBridge ? '\$bridge' : ''}.\$$staticName
      $bridgeParam
    );
  ''';
}

String staticMethodsForRuntime(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  return element.methods
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => staticMethodForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticMethodForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
  MethodElement method, {
  bool isBridge = false,
}) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '$uri',
      '${element.name}.${method.name}',
      \$${element.name}${isBridge ? '\$bridge' : ''}.\$${method.name}
    );
  ''';
}

String staticGettersForRuntime(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  return element.getters
      .where(
        (e) =>
            e.isStatic &&
            !e.isPrivate &&
            (e.nonSynthetic is! FieldElement ||
                !(e.nonSynthetic as FieldElement).isEnumConstant),
      )
      .map((e) => staticGetterForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticGetterForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
  PropertyAccessorElement getter, {
  bool isBridge = false,
}) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '$uri',
      '${element.name}.${getter.name}*g',
      \$${element.name}${isBridge ? '\$bridge' : ''}.\$${getter.name}
    );
  ''';
}

String staticSettersForRuntime(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  return element.setters
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => staticSetterForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticSetterForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
  PropertyAccessorElement setter, {
  bool isBridge = false,
}) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '$uri',
      '${element.name}.${setter.name}*s',
      \$${element.name}${isBridge ? '\$bridge' : ''}.set\$${setter.name}
    );
  ''';
}
