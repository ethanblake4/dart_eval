import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';

String bindConfigureForRuntime(
  BindgenContext ctx,
  ClassElement element, {
  bool isBridge = false,
}) =>
    '''
/// Configure this class for use in a [Runtime]
static void configureForRuntime(Runtime runtime) {
  ${constructorsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticMethodsForRuntime(ctx, element, isBridge: isBridge)}
  ${staticGettersForRuntime(ctx, element, isBridge: isBridge)}
  ${staticSettersForRuntime(ctx, element, isBridge: isBridge)}
}

/// Configure this class for use during compilation
static void configureForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeClass(\$declaration);
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

/// Configure this enum for use during compilation
static void configureForCompile(BridgeDeclarationRegistry registry) {
  registry.defineBridgeEnum(\$declaration);
}
''';

String bindConfigureFunctionForRuntime(
  BindgenContext ctx,
  TopLevelFunctionElement element,
) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final member = ctx.libraryConfig?.functions[element.name];
  return '''
static void configureForRuntime(Runtime runtime) {
  return runtime.registerBridgeFuncRegisters('$uri', '${(member?.rename ?? element.name!).replaceAll(r'$', r'\$')}', \$${element.name}Fn.callRegisters);
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
  final emitted = element.constructors
      .where(
        (cstr) =>
            (!element.isAbstract || cstr.isFactory) &&
            !cstr.isPrivate &&
            ctx.memberIncluded(cstr.name ?? '', 'constructor'),
      )
      .map((e) => constructorForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
  return emitted + _syntheticConstructorsForRuntime(ctx, element);
}

String _syntheticConstructorsForRuntime(
  BindgenContext ctx,
  ClassElement element,
) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return synthetic
      .where((s) => s.kind == 'constructor')
      .map((s) => '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '${element.name}.${s.name}',
      \$${element.name}.${memberWrapperName(s.name)}
    );
  ''')
      .join('\n');
}

String constructorForRuntime(
  BindgenContext ctx,
  ClassElement element,
  ConstructorElement constructor, {
  bool isBridge = false,
}) {
  final member = ctx.memberConfig(constructor.name ?? '', 'constructor');
  var name = member?.rename ?? constructor.name ?? '';
  if (name == 'new') {
    name = '';
  }
  final fullyQualifiedConstructorId = '${element.name}.$name';

  final staticName = member?.rename ?? constructor.name ?? '';
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final bridgeParam = isBridge ? ', isBridge: true' : '';

  return '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '$fullyQualifiedConstructorId',
      \$${element.name}${isBridge ? '\$bridge' : ''}.${memberWrapperName(staticName)}
      $bridgeParam
    );
  ''';
}

String staticMethodsForRuntime(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final emitted = element.methods
      .where((e) =>
          e.isStatic &&
          !e.isOperator &&
          !e.isPrivate &&
          ctx.memberIncluded(e.name!, 'static'))
      .map((e) => staticMethodForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
  return emitted + _syntheticStaticsForRuntime(ctx, element);
}

String _syntheticStaticsForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return synthetic
      .where((s) => s.kind == 'static')
      .map((s) => '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '${element.name}.${s.name}',
      \$${element.name}.${memberWrapperName(s.name)}
    );
  ''')
      .join('\n');
}

String staticMethodForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
  MethodElement method, {
  bool isBridge = false,
}) {
  final member = ctx.memberConfig(method.name!, 'static');
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final name = member?.rename ?? method.name;
  return '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '${element.name}.$name',
      \$${element.name}${isBridge ? '\$bridge' : ''}.${memberWrapperName(name!)}
    );
  ''';
}

String staticGettersForRuntime(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final emitted = element.getters
      .where(
        (e) =>
            e.isStatic &&
            !e.isPrivate &&
            ctx.memberIncluded(e.name!, 'static') &&
            (e.nonSynthetic is! FieldElement ||
                !(e.nonSynthetic as FieldElement).isEnumConstant),
      )
      .map((e) => staticGetterForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
  return emitted + _syntheticStaticGettersForRuntime(ctx, element);
}

String _syntheticStaticGettersForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return synthetic
      .where((s) => s.kind == 'getter' && s.isStatic)
      .map((s) => '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '${element.name}.${s.name}*g',
      \$${element.name}.${memberWrapperName(s.name)}
    );
  ''')
      .join('\n');
}

String staticGetterForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
  PropertyAccessorElement getter, {
  bool isBridge = false,
}) {
  final member = ctx.memberConfig(getter.name!, 'static');
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final name = member?.rename ?? getter.name;
  return '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '${element.name}.$name*g',
      \$${element.name}${isBridge ? '\$bridge' : ''}.${memberWrapperName(name!)}
    );
  ''';
}

String staticSettersForRuntime(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  return element.setters
      .where((e) =>
          e.isStatic &&
          !e.isPrivate &&
          ctx.memberIncluded(e.name!, 'static'))
      .map((e) => staticSetterForRuntime(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String staticSetterForRuntime(
  BindgenContext ctx,
  InterfaceElement element,
  PropertyAccessorElement setter, {
  bool isBridge = false,
}) {
  final member = ctx.memberConfig(setter.name!, 'static');
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final name = member?.rename ?? setter.name;
  return '''
    runtime.registerBridgeFuncRegisters(
      '$uri',
      '${element.name}.$name*s',
      \$${element.name}${isBridge ? '\$bridge' : ''}.set${memberWrapperName(name!)}
    );
  ''';
}
