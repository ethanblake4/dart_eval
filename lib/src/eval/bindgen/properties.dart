import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/operator.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $getProperty(BindgenContext ctx, InterfaceElement element) {
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

String propertyGetters(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final methods = [
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed) ...s.methods,
    ...element.methods,
  ];
  final allGetters = <String, PropertyAccessorElement>{
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed)
        for (final a in s.getters) a.name!: a,
    for (final a in element.getters) a.name!: a,
  };
  final getters = allGetters.values
      .where((accessor) => !accessor.isStatic && !accessor.isPrivate)
      .where(
        (a) => ctx.memberIncluded(
          a.name!,
          'getter',
          isObjectMember: objectGetterNames.contains(a.name),
        ),
      );

  final methods0 = dedupeMethods(methods)
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
        (m) => ctx.memberIncluded(
          m.name!,
          'method',
          isObjectMember: objectMethodNames.contains(m.name),
        ),
      );

  final synthetic = ctx.classConfig?.synthetic ?? const [];
  final syntheticGetters =
      synthetic.where((s) => s.kind == 'getter' && !s.isStatic).toList();
  final syntheticMethods =
      synthetic.where((s) => s.kind == 'method' && !s.isStatic).toList();

  if (getters.isEmpty &&
      methods0.isEmpty &&
      syntheticGetters.isEmpty &&
      syntheticMethods.isEmpty) {
    return '';
  }
  if (isBridge) {
    return 'switch (identifier) {\n${getters.map((e) => '''
      case '${e.displayName}':
        final _${e.displayName} = super.${e.displayName};
        return ${wrapVar(ctx, e.type.returnType, '_${e.displayName}', metadata: e.metadata.annotations)};
      ''').join('\n')}${methods0.map((e) {
      final member = ctx.memberConfig(e.name!, 'method');
      final returnsValue = e.returnType is! VoidType && !e.returnType.isDartCoreNull;
      final callOp = operatorForArity(
        e.displayName,
        e.formalParameters.length,
      );
      return '''
        case '${member?.rename ?? e.displayName}':
          return \$Function((runtime, target, args) {
            ${assertMethodPermissions(e)}
            ${assertConfigPermissions(ctx, member, e.formalParameters.map((p) => p.name ?? '').toList())}
            ${returnsValue ? 'final result = ' : ''}${callOp.format('super', argumentAccessors(ctx, e.formalParameters, isBridgeMethod: true, member: member))};
            return ${wrapVar(ctx, e.returnType, 'result', unionTypeNames: member?.returns?.union)};
          });''';
    }).join('\n')}\n}';
  }
  final prefix = ctx.hooksPrefix();
  return 'switch (identifier) {\n${getters.map((e) {
      final member = ctx.memberConfig(e.name!, 'getter');
      final name = member?.rename ?? e.name!;
      if (member?.hook != null) {
        return '''
      case '$name':
        return ${prefix != null ? '$prefix.' : ''}${member!.hook}(runtime, this);''';
      }
      if (member?.expr != null) {
        return '''
      case '$name':
        return ${member!.expr};''';
      }
      return '''
      case '$name':
        final _$name = \$value.${e.name};
        return ${wrapVar(ctx, e.type.returnType, '_$name', metadata: e.metadata.annotations, unionTypeNames: member?.returns?.union)};''';
    }).join('\n')}${syntheticGetters.map((s) {
      if (s.hook != null) {
        return '''
      case '${s.name}':
        return ${prefix != null ? '$prefix.' : ''}${s.hook}(runtime, this);''';
      }
      return '''
      case '${s.name}':
        return ${s.expr ?? 'null'};''';
    }).join('\n')}${methods0.map((e) => '''
      case '${ctx.memberConfig(e.name!, 'method')?.rename ?? e.name}':
        return __${operatorForArity(ctx.memberConfig(e.name!, 'method')?.rename ?? e.name!, e.formalParameters.length).name};
      ''').join('\n')}${syntheticMethods.map((s) => '''
      case '${s.name}':
        return __${operatorForArity(s.name, s.params.length).name};
      ''').join('\n')}\n}';
}

String $setProperty(BindgenContext ctx, InterfaceElement element) {
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

String propertySetters(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final allSetters = <String, PropertyAccessorElement>{
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed)
        for (final a in s.setters) a.name!: a,
    for (final a in element.setters) a.name!: a,
  };
  final setters = allSetters.values.where(
    (element) =>
        !element.isStatic &&
        !element.isPrivate &&
        ctx.memberIncluded(element.name!, 'setter'),
  );
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  final syntheticSetters =
      synthetic.where((s) => s.kind == 'setter' && !s.isStatic);
  if (setters.isEmpty && syntheticSetters.isEmpty) {
    return '';
  }
  if (isBridge) {
    return 'switch (identifier) {\n${setters.map((e) => '''
        case '${ctx.memberConfig(e.name!, 'setter')?.rename ?? e.displayName}':
          super.${e.displayName} = value.\$reified;
          return;
        ''').join('\n')}\n}';
  }
  final prefix = ctx.hooksPrefix();
  return 'switch (identifier) {\n${setters.map((e) {
      final member = ctx.memberConfig(e.name!, 'setter');
      if (member?.hook != null) {
        return '''
        case '${member?.rename ?? e.displayName}':
          ${prefix != null ? '$prefix.' : ''}${member!.hook}(runtime, this, value);
          return;''';
      }
      if (member?.expr != null) {
        return '''
        case '${member?.rename ?? e.displayName}':
          ${member!.expr};
          return;''';
      }
      return '''
        case '${member?.rename ?? e.displayName}':
          \$value.${e.displayName} = value.\$reified;
          return;''';
    }).join('\n')}${syntheticSetters.map((s) {
      if (s.hook != null) {
        return '''
        case '${s.name}':
          ${prefix != null ? '$prefix.' : ''}${s.hook}(runtime, this, value);
          return;''';
      }
      return '''
        case '${s.name}':
          ${s.expr ?? ''};
          return;''';
    }).join('\n')}\n}';
}
