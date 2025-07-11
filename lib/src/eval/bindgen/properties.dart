import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $getProperty(BindgenContext ctx, ClassElement element) {
  return '''
  @override
  \$Value? \$getProperty(Runtime runtime, String identifier) {
    ${propertyGetters(ctx, element)}
    return _superclass.\$getProperty(runtime, identifier);
  }
''';
}

String $bridgeGet(BindgenContext ctx, ClassElement element) {
  return '''
  @override
  \$Value? \$bridgeGet(String identifier) {
    ${propertyGetters(ctx, element, isBridge: true)}
    return null;
  }
''';
}

String propertyGetters(BindgenContext ctx, ClassElement element,
    {bool isBridge = false}) {
  final accessors = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.element.accessors) a.name: a,
    for (final a in element.accessors) a.name: a
  };
  final methods = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final m in s.element.methods) m.name: m,
    for (final m in element.methods) m.name: m
  };
  final _getters = accessors.values
      .where((accessor) =>
          accessor.isGetter && !accessor.isStatic && !accessor.isPrivate)
      .where((a) => !(const ['hashCode', 'runtimeType'].contains(a.name)));

  final _methods = methods.values
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
          (m) => !(const ['==', 'toString', 'noSuchMethod'].contains(m.name)));
  if (_getters.isEmpty && _methods.isEmpty) {
    return '';
  }
  if (isBridge) {
    return 'switch (identifier) {\n' +
        _getters.map((e) => '''
      case '${e.displayName}':
        final _${e.displayName} = super.${e.displayName};
        return ${wrapVar(ctx, e.type.returnType, '_${e.displayName}', metadata: e.nonSynthetic.metadata)};
      ''').join('\n') +
        _methods.map((e) {
          final returnsValue =
              e.returnType is! VoidType && !e.returnType.isDartCoreNull;
          return '''
        case '${e.displayName}':
          return \$Function((runtime, target, args) {
            ${assertMethodPermissions(e)}
            ${returnsValue ? 'final result = ' : ''}super.${e.displayName}(${argumentAccessors(ctx, e.parameters)});
            return ${wrapVar(ctx, e.returnType, 'result')};
          });''';
        }).join('\n') +
        '\n' +
        '}';
  }
  return 'switch (identifier) {\n' + _getters.map((e) => '''
      case '${e.displayName}':
        final _${e.displayName} = \$value.${e.displayName};
        return ${wrapVar(ctx, e.type.returnType, '_${e.displayName}', metadata: e.nonSynthetic.metadata)};
      ''').join('\n') + _methods.map((e) => '''
      case '${e.displayName}':
        return __${e.displayName};
      ''').join('\n') + '\n' + '}';
}

String $setProperty(BindgenContext ctx, ClassElement element) {
  return '''
  @override
  void \$setProperty(Runtime runtime, String identifier, \$Value value) {
    ${propertySetters(ctx, element)}
    return _superclass.\$setProperty(runtime, identifier, value);
  }
''';
}

String $bridgeSet(BindgenContext ctx, ClassElement element) {
  return '''
  @override
  void \$bridgeSet(String identifier, \$Value value) {
    ${propertySetters(ctx, element, isBridge: true)}
  }
''';
}


String propertySetters(BindgenContext ctx, ClassElement element, {bool isBridge = false}) {
  final accessors = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.element.accessors) a.name: a,
    for (final a in element.accessors) a.name: a
  };
  final _setters = accessors.values.where(
      (element) => element.isSetter && !element.isStatic && !element.isPrivate);
  if (_setters.isEmpty) {
    return '';
  }
  if (isBridge) {
    return 'switch (identifier) {\n' + _setters.map((e) => '''
        case '${e.displayName}':
          super.${e.displayName} = value.${e.displayName};
          return;
        ''').join('\n') + '\n' + '}';
  }
  return 'switch (identifier) {\n' + _setters.map((e) => '''
        case '${e.displayName}':
          \$value.${e.displayName} = value.\$value;
          return;
        ''').join('\n') + '\n' + '}';
}
