import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $getProperty(BindgenContext ctx, InterfaceElement2 element) {
  return '''
  @override
  \$Value? \$getProperty(Runtime runtime, String identifier) {
    ${propertyGetters(ctx, element)}
    return _superclass.\$getProperty(runtime, identifier);
  }
''';
}

String $bridgeGet(BindgenContext ctx, ClassElement2 element) {
  return '''
  @override
  \$Value? \$bridgeGet(String identifier) {
    ${propertyGetters(ctx, element, isBridge: true)}
    return null;
  }
''';
}

String propertyGetters(BindgenContext ctx, InterfaceElement2 element,
    {bool isBridge = false}) {
  final methods = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final m in s.element3.methods2) m.name3: m,
    for (final m in element.methods2) m.name3: m
  };
  final getters = element.getters2
      .where((accessor) => !accessor.isStatic && !accessor.isPrivate)
      .where((a) => !(const ['hashCode', 'runtimeType'].contains(a.name3)));

  final methods0 = methods.values
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
          (m) => !(const ['==', 'toString', 'noSuchMethod'].contains(m.name3)));
  if (getters.isEmpty && methods0.isEmpty) {
    return '';
  }
  if (isBridge) {
    return 'switch (identifier) {\n${getters.map((e) => '''
      case '${e.displayName}':
        final _${e.displayName} = super.${e.displayName};
        return ${wrapVar(ctx, e.type.returnType, '_${e.displayName}', metadata: e.metadata2.annotations)};
      ''').join('\n')}${methods0.map((e) {
      final returnsValue =
          e.returnType is! VoidType && !e.returnType.isDartCoreNull;
      return '''
        case '${e.displayName}':
          return \$Function((runtime, target, args) {
            ${assertMethodPermissions(e)}
            ${returnsValue ? 'final result = ' : ''}super.${e.displayName}(${argumentAccessors(ctx, e.formalParameters, isBridgeMethod: true)});
            return ${wrapVar(ctx, e.returnType, 'result')};
          });''';
    }).join('\n')}\n}';
  }
  return 'switch (identifier) {\n${getters.map((e) => '''
      case '${e.name3}':
        final _${e.name3} = \$value.${e.name3};
        return ${wrapVar(ctx, e.type.returnType, '_${e.name3}', metadata: e.metadata2.annotations)};
      ''').join('\n')}${methods0.map((e) => '''
      case '${e.name3}':
        return __${e.name3};
      ''').join('\n')}\n}';
}

String $setProperty(BindgenContext ctx, InterfaceElement2 element) {
  return '''
  @override
  void \$setProperty(Runtime runtime, String identifier, \$Value value) {
    ${propertySetters(ctx, element)}
    return _superclass.\$setProperty(runtime, identifier, value);
  }
''';
}

String $bridgeSet(BindgenContext ctx, ClassElement2 element) {
  return '''
  @override
  void \$bridgeSet(String identifier, \$Value value) {
    ${propertySetters(ctx, element, isBridge: true)}
  }
''';
}

String propertySetters(BindgenContext ctx, InterfaceElement2 element,
    {bool isBridge = false}) {
  final setters = element.setters2
      .where((element) => !element.isStatic && !element.isPrivate);
  if (setters.isEmpty) {
    return '';
  }
  if (isBridge) {
    return 'switch (identifier) {\n${setters.map((e) => '''
        case '${e.displayName}':
          super.${e.displayName} = value.${e.displayName};
          return;
        ''').join('\n')}\n}';
  }
  return 'switch (identifier) {\n${setters.map((e) => '''
        case '${e.displayName}':
          \$value.${e.displayName} = value.\$value;
          return;
        ''').join('\n')}\n}';
}
