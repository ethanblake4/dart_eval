import 'package:analyzer/dart/element/element2.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String bindConfigureForRuntime(BindgenContext ctx, ClassElement2 element,
        {bool isBridge = false}) =>
    '''
static void configureForRuntime(Runtime runtime) {
  ${constructorsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticMethodsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticGettersForRuntime(ctx, element, isBridge: isBridge)}
  ${staticSettersForRuntime(ctx, element, isBridge: isBridge)}
}
''';

String constructorsForRuntime(BindgenContext ctx, ClassElement2 element,
    {bool isBridge = false}) {
  return element.constructors2
      .where(
          (cstr) => (!element.isAbstract || cstr.isFactory) && !cstr.isPrivate)
      .map((e) => constructorForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String constructorForRuntime(
    BindgenContext ctx, ClassElement2 element, ConstructorElement2 constructor,
    {bool isBridge = false}) {
  var name = constructor.name3 == null ? '' : constructor.name3;
  if (name == 'new') {
    name = '';
  }
  final fullyQualifiedConstructorId = '${element.name3}.$name';

  final staticName = constructor.name3 == null ? '' : constructor.name3;
  final uri = ctx.libOverrides[element.name3] ?? ctx.uri;
  final bridgeParam = isBridge ? ', isBridge: true' : '';

  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '$fullyQualifiedConstructorId',
      \$${element.name3}${isBridge ? '\$bridge' : ''}.\$$staticName
      $bridgeParam
    );
  ''';
}

String staticMethodsForRuntime(BindgenContext ctx, ClassElement2 element,
    {bool isBridge = false}) {
  return element.methods2
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => staticMethodForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticMethodForRuntime(
    BindgenContext ctx, ClassElement2 element, MethodElement2 method,
    {bool isBridge = false}) {
  final uri = ctx.libOverrides[element.name3] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.name3}.${method.name3}',
      \$${element.name3}${isBridge ? '\$bridge' : ''}.\$${method.name3}
    );
  ''';
}

String staticGettersForRuntime(BindgenContext ctx, ClassElement2 element,
    {bool isBridge = false}) {
  return element.getters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => staticGetterForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticGetterForRuntime(
    BindgenContext ctx, ClassElement2 element, PropertyAccessorElement2 getter,
    {bool isBridge = false}) {
  final uri = ctx.libOverrides[element.name3] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.name3}.${getter.name3}*g',
      \$${element.name3}${isBridge ? '\$bridge' : ''}.\$${getter.name3}
    );
  ''';
}

String staticSettersForRuntime(BindgenContext ctx, ClassElement2 element,
    {bool isBridge = false}) {
  return element.setters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => staticSetterForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticSetterForRuntime(
    BindgenContext ctx, ClassElement2 element, PropertyAccessorElement2 setter,
    {bool isBridge = false}) {
  final uri = ctx.libOverrides[element.name3] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.name3}.${setter.name3}*s',
      \$${element.name3}${isBridge ? '\$bridge' : ''}.set\$${setter.name3}
    );
  ''';
}
