import 'package:analyzer/dart/element/element2.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String bindConfigureForRuntime(BindgenContext ctx, ClassElement2 element, {bool isBridge = false}) => '''
static void configureForRuntime(Runtime runtime) {
  ${constructorsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticMethodsForRuntime(ctx, element)}
  ${staticGettersForRuntime(ctx, element)}
  ${staticSettersForRuntime(ctx, element)}
}
''';

String constructorsForRuntime(BindgenContext ctx, ClassElement2 element, {bool isBridge = false}) {
  return element.constructors2
      .where(
          (cstr) => (!element.isAbstract || cstr.isFactory) && !cstr.isPrivate)
      .map((e) => constructorForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String constructorForRuntime(
    BindgenContext ctx, ClassElement2 element, ConstructorElement2 constructor, {bool isBridge = false}) {
  final name = constructor.displayName.isEmpty ? '' : constructor.displayName;
  final fullyQualifiedConstructorId = '${element.displayName}.$name';

  final staticName = constructor.displayName.isEmpty ? 'new' : constructor.displayName;
  final uri = ctx.libOverrides[element.displayName] ?? ctx.uri;
  final bridgeParam = isBridge ? ',bridge: true' : '';

  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '$fullyQualifiedConstructorId',
      \$${element.displayName}.\$$staticName
      $bridgeParam
    );
  ''';
}

String staticMethodsForRuntime(BindgenContext ctx, ClassElement2 element) {
  return element.methods2
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => staticMethodForRuntime(ctx, element, e))
      .join('\n');
}

String staticMethodForRuntime(
    BindgenContext ctx, ClassElement2 element, MethodElement2 method) {
  final uri = ctx.libOverrides[element.displayName] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.displayName}.${method.displayName}',
      \$${element.displayName}.\$${method.displayName}
    );
  ''';
}

String staticGettersForRuntime(BindgenContext ctx, ClassElement2 element) {
  return element.getters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => staticGetterForRuntime(ctx, element, e))
      .join('\n');
}

String staticGetterForRuntime(
    BindgenContext ctx, ClassElement2 element, PropertyAccessorElement2 getter) {
  final uri = ctx.libOverrides[element.displayName] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.displayName}.${getter.displayName}*g',
      \$${element.displayName}.\$${getter.displayName}
    );
  ''';
}

String staticSettersForRuntime(BindgenContext ctx, ClassElement2 element) {
  return element.setters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => staticSetterForRuntime(ctx, element, e))
      .join('\n');
}

String staticSetterForRuntime(
    BindgenContext ctx, ClassElement2 element, PropertyAccessorElement2 setter) {
  final uri = ctx.libOverrides[element.displayName] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.displayName}.${setter.displayName}*s',
      \$${element.displayName}.set\$${setter.displayName}
    );
  ''';
}
