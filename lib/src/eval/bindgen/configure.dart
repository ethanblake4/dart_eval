import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';

String bindConfigureForRuntime(BindgenContext ctx, ClassElement element, {bool isBridge = false}) => '''
static void configureForRuntime(Runtime runtime) {
  ${constructorsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticMethodsForRuntime(ctx, element)}
  ${staticGettersForRuntime(ctx, element)}
  ${staticSettersForRuntime(ctx, element)}
}
''';

String constructorsForRuntime(BindgenContext ctx, ClassElement element, {bool isBridge = false}) {
  return element.constructors
      .where(
          (cstr) => (!element.isAbstract || cstr.isFactory) && !cstr.isPrivate)
      .map((e) => constructorForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String constructorForRuntime(
    BindgenContext ctx, ClassElement element, ConstructorElement constructor, {bool isBridge = false}) {
  final name = constructor.name.isEmpty ? '' : constructor.name;
  final fullyQualifiedConstructorId = '${element.name}.$name';

  final staticName = constructor.name.isEmpty ? 'new' : constructor.name;
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final bridgeParam = isBridge ? ',bridge: true' : '';

  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '$fullyQualifiedConstructorId',
      \$${element.name}.\$$staticName
      $bridgeParam
    );
  ''';
}

String staticMethodsForRuntime(BindgenContext ctx, ClassElement element) {
  return element.methods
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => staticMethodForRuntime(ctx, element, e))
      .join('\n');
}

String staticMethodForRuntime(
    BindgenContext ctx, ClassElement element, MethodElement method) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.name}.${method.name}',
      \$${element.name}.\$${method.name}
    );
  ''';
}

String staticGettersForRuntime(BindgenContext ctx, ClassElement element) {
  return element.accessors
      .where((e) => e.isStatic && e.isGetter && !e.isPrivate)
      .map((e) => staticGetterForRuntime(ctx, element, e))
      .join('\n');
}

String staticGetterForRuntime(
    BindgenContext ctx, ClassElement element, PropertyAccessorElement getter) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.name}.${getter.name}*g',
      \$${element.name}.\$${getter.name}
    );
  ''';
}

String staticSettersForRuntime(BindgenContext ctx, ClassElement element) {
  return element.accessors
      .where((e) => e.isStatic && e.isSetter && !e.isPrivate)
      .map((e) => staticSetterForRuntime(ctx, element, e))
      .join('\n');
}

String staticSetterForRuntime(
    BindgenContext ctx, ClassElement element, PropertyAccessorElement setter) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
    runtime.registerBridgeFunc(
      '${uri}',
      '${element.name}.${setter.name}*s',
      \$${element.name}.set\$${setter.name}
    );
  ''';
}
