import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/operator.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

/// Member names that are excluded unless `includeObjectMembers` is set.
const objectMethodNames = {'==', 'toString', 'noSuchMethod'};
const objectGetterNames = {'hashCode', 'runtimeType'};

String bindTypeSpec(BindgenContext ctx, InterfaceElement element) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  final runtimeType = ctx.classConfig?.runtimeTypeOverride;
  if (runtimeType != null) {
    return '''
  static const \$spec = $runtimeType;
''';
  }
  return '''
  static const \$spec = BridgeTypeSpec(
    '$uri',
    '${element.name!.replaceAll(r'$', r'\$')}',
  );
''';
}

String bindBridgeType(BindgenContext ctx, InterfaceElement element) {
  return '''
  static const \$type = BridgeTypeRef(\$spec);
''';
}

String bindFunctionDeclaration(
  BindgenContext ctx,
  TopLevelFunctionElement element,
) {
  final uri = ctx.libOverrides[element.name] ?? ctx.uri;
  return '''
  static const \$declaration = BridgeFunctionDeclaration(
    '$uri',
    '${element.name!.replaceAll(r'$', r'\$')}',
    ${bridgeFunctionDef(ctx, function: element)}
  );
''';
}

String? bindBridgeDeclaration(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final cc = ctx.classConfig;
  if (element is ClassElement && element.constructors.isEmpty) {
    return null;
  }

  var genericsStr = '';
  final typeParams = element.typeParameters;
  if (typeParams.isNotEmpty && element is ClassElement) {
    genericsStr =
        '''\ngenerics: {
      ${typeParams.map((e) {
          final override = cc?.generics[e.name];
          final hasOverride = cc != null && cc.generics.containsKey(e.name);
          final boundStr = hasOverride
              ? (override == null ? '' : '\$extends: ${bridgeTypeRefFromName(ctx, override)}')
              : e.bound != null && !ctx.implicitSupers
              ? '\$extends: ${bridgeTypeRefFromType(ctx, e.bound!)}'
              : '';
          return '\'${e.name}\': BridgeGenericParam($boundStr)';
        }).join(',')}
    },''';
  }

  var extendsStr = '';
  if (cc?.extendsName != null) {
    extendsStr =
        '\n\$extends: ${bridgeTypeRefFromName(ctx, cc!.extendsName!)},';
  } else if (element is ClassElement &&
      element.supertype != null &&
      !element.supertype!.isDartCoreObject &&
      !ctx.implicitSupers) {
    extendsStr =
        '\n\$extends: ${bridgeTypeRefFromType(ctx, element.supertype!)},';
  }

  var implementsStr = '';
  if (cc != null && cc.implementsNames.isNotEmpty) {
    implementsStr =
        '\n\$implements: [${cc.implementsNames.map((e) => bridgeTypeRefFromName(ctx, e)).join(', ')}],';
  } else if (element is ClassElement) {
    // `element.interfaces` only lists directly-declared interfaces and may
    // reference SDK-private types (e.g. `Uint8List implements _TypedIntList`).
    // Emit every bound public supertype instead so assignability checks like
    // `Uint8List is List<int>` resolve through the generated declaration.
    final implRefs = <String>{};
    for (final st in element.allSupertypes) {
      if (st.isDartCoreObject) continue;
      final el = st.element;
      final elName = el.name;
      if (elName == null || elName.startsWith('_')) continue;
      if (boundSdkClassFor(ctx, el) == null) continue;
      implRefs.add(bridgeTypeRefFromType(ctx, st));
    }
    if (implRefs.isNotEmpty) {
      implementsStr = '\n\$implements: [${implRefs.join(', ')}],';
    }
  }

  var enumValuesStr = '';
  if (element is EnumElement) {
    enumValuesStr =
        '''
    values: [${element.constants.map((e) => "'${e.name}'").join(', ')}],
    ''';
  }

  final isAbstract =
      cc?.isAbstract ?? (element is ClassElement && element.isAbstract);

  return '''
  static const \$declaration = ${element is ClassElement ? 'BridgeClassDef(BridgeClassType(' : 'BridgeEnumDef('}
      \$type,
      ${element is ClassElement && isAbstract ? 'isAbstract: true,' : ''}
      $enumValuesStr
      $genericsStr
      $extendsStr
      $implementsStr
    ${element is ClassElement ? '),' : ''}
    ${element is ClassElement ? '''
    constructors: {
${constructors(ctx, element)}
${syntheticDeclarations(ctx, 'constructor')}
    },
    ''' : ''}
    methods: {
${methods(ctx, element)}
${syntheticDeclarations(ctx, 'method')}
    },
    getters: {
${getters(ctx, element)}
${syntheticDeclarations(ctx, 'getter')}
    },
    setters: {
${setters(ctx, element)}
${syntheticDeclarations(ctx, 'setter')}
    },
    fields: {
${fields(ctx, element)}
${syntheticDeclarations(ctx, 'field')}
    },
    ${element is ClassElement ? '''
    wrap: ${!isBridge},
    bridge: $isBridge,
    ''' : ''}
  );
    ''';
}

String constructors(BindgenContext ctx, InterfaceElement element) {
  return element.constructors
      .where((e) => !e.isPrivate)
      .where((e) => ctx.memberIncluded(e.name ?? '', 'constructor'))
      .map(
        (e) => bridgeConstructorDef(
          ctx,
          constructor: e,
          member: ctx.memberConfig(e.name ?? '', 'constructor'),
        ),
      )
      .join('\n');
}

String methods(BindgenContext ctx, InterfaceElement element) {
  final methods = [
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed)
        // `InterfaceType.methods` includes statics, which are not inherited.
        ...s.methods.where((m) => !m.isStatic),
    ...element.methods,
  ];
  return dedupeMethods(methods)
      .where(
        (m) => ctx.memberIncluded(
          m.name!,
          m.isStatic ? 'static' : 'method',
          isObjectMember: objectMethodNames.contains(m.name),
        ),
      )
      .where((m) => !m.isPrivate)
      .map(
        (m) => bridgeMethodDef(
          ctx,
          method: m,
          member: ctx.memberConfig(m.name!, m.isStatic ? 'static' : 'method'),
        ),
      )
      .join('\n');
}

String getters(BindgenContext ctx, InterfaceElement element) {
  final getters = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.getters.where((a) => !a.isStatic)) a.name: a,
    for (final a in element.getters) a.name: a,
  };

  return getters.values
      .where(
        (m) => ctx.memberIncluded(
          m.name!,
          m.isStatic ? 'static' : 'getter',
          isObjectMember: objectGetterNames.contains(m.name),
        ),
      )
      .where((element) => !element.isPrivate)
      .where(
        (element) =>
            !element.isOriginVariable ||
            (element is EnumElement &&
                element.nonSynthetic is FieldElement &&
                !(element.nonSynthetic as FieldElement).isEnumConstant),
      )
      .map(
        (e) => bridgeGetterDef(
          ctx,
          getter: e,
          member: ctx.memberConfig(e.name!, e.isStatic ? 'static' : 'getter'),
        ),
      )
      .join('\n');
}

String setters(BindgenContext ctx, InterfaceElement element) {
  final setters = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        for (final a in s.setters.where((a) => !a.isStatic)) a.name: a,
    for (final a in element.setters) a.name: a,
  };

  return setters.values
      .where((element) => !element.isOriginVariable && !element.isPrivate)
      .where(
        (m) => ctx.memberIncluded(m.name!, m.isStatic ? 'static' : 'setter'),
      )
      .map(
        (e) => bridgeSetterDef(
          ctx,
          setter: e,
          member: ctx.memberConfig(e.name!, e.isStatic ? 'static' : 'setter'),
        ),
      )
      .join('\n');
}

String fields(BindgenContext ctx, InterfaceElement element) {
  final allFields = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes)
        if (s.element is ClassElement)
          for (final f in (s.element as ClassElement).fields.where(
            (f) => !f.isStatic,
          ))
            f.name: f,
    for (final f in element.fields) f.name: f,
  };

  final fields = allFields.values.where(
    (element) =>
        !element.isOriginGetterSetter &&
        !element.isEnumConstant &&
        !element.isPrivate &&
        ctx.memberIncluded(element.name!, 'field'),
  );

  return fields
      .map(
        (e) => bridgeFieldDef(
          ctx,
          field: e,
          member: ctx.memberConfig(e.name!, 'field'),
        ),
      )
      .join('\n');
}

String bridgeConstructorDef(
  BindgenContext ctx, {
  required ConstructorElement constructor,
  BindgenMemberConfig? member,
}) {
  final name = member?.rename ?? constructor.name;
  return '''
      '${name == 'new' ? '' : name}': BridgeConstructorDef(
          BridgeFunctionDef(
            returns: BridgeTypeAnnotation(\$type),
            namedParams: [${namedParameters(ctx, element: constructor, member: member)}],
            params: [${positionalParameters(ctx, element: constructor, member: member)}],
          ),
          isFactory: ${constructor.isFactory},
      ),
      ''';
}

/// Emits the `returns:`/`returnTypeDependency:` arguments for a
/// [BridgeFunctionDef], honoring member `returns` overrides.
String functionReturnsSource(
  BindgenContext ctx,
  ExecutableElement function,
  BindgenMemberConfig? member,
) {
  final returns = member?.returns;
  if (returns == null) {
    return 'returns: ${bridgeTypeAnnotationFrom(ctx, function.returnType)}';
  }
  final dep = returns.dependsOn;
  final baseName = returns.type ?? dep?.fallback;
  final baseExpr = baseName != null
      ? bridgeTypeAnnotationFromName(ctx, baseName)
      : bridgeTypeAnnotationFrom(ctx, function.returnType);
  if (dep == null) {
    return 'returns: $baseExpr';
  }
  final cases = dep.cases.entries
      .map(
        (e) =>
            'BridgeReturnTypeCase(${bridgeTypeRefFromName(ctx, e.key)}, '
            '${bridgeTypeAnnotationFromName(ctx, e.value)})',
      )
      .join(', ');
  final selector = dep.index != null
      ? 'paramIndex: ${dep.index}'
      : "paramName: '${dep.param}'";
  final fallback = dep.fallback != null
      ? ', fallback: ${bridgeTypeAnnotationFromName(ctx, dep.fallback!)}'
      : '';
  return 'returns: $baseExpr, returnTypeDependency: '
      'BridgeReturnTypeDependency($selector, cases: [$cases]$fallback)';
}

String bridgeFunctionDef(
  BindgenContext ctx, {
  required ExecutableElement function,
  BindgenMemberConfig? member,
}) {
  var genericsStr = '';
  final typeParams = function.typeParameters;
  if (typeParams.isNotEmpty) {
    genericsStr =
        '''\ngenerics: {
      ${typeParams.map((e) {
          final boundStr = e.bound != null ? '\$extends: ${bridgeTypeRefFromType(ctx, e.bound!)}' : '';
          return '\'${e.name}\': BridgeGenericParam($boundStr)';
        }).join(',')}
    },''';
  }

  return '''
        BridgeFunctionDef(
          $genericsStr
          ${functionReturnsSource(ctx, function, member)},
          namedParams: [${namedParameters(ctx, element: function, member: member)}],
          params: [${positionalParameters(ctx, element: function, member: member)}],
        ),
''';
}

String bridgeMethodDef(
  BindgenContext ctx, {
  required MethodElement method,
  BindgenMemberConfig? member,
}) {
  return '''
      '${member?.rename ?? method.name}': BridgeMethodDef(
        ${bridgeFunctionDef(ctx, function: method, member: member)}
        ${method.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeGetterDef(
  BindgenContext ctx, {
  required PropertyAccessorElement getter,
  BindgenMemberConfig? member,
}) {
  return '''
      '${member?.rename ?? getter.name}': BridgeMethodDef(
        ${bridgeFunctionDef(ctx, function: getter, member: member)}
        ${getter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeSetterDef(
  BindgenContext ctx, {
  required PropertyAccessorElement setter,
  BindgenMemberConfig? member,
}) {
  return '''
      '${member?.rename ?? setter.name}': BridgeMethodDef(
        ${bridgeFunctionDef(ctx, function: setter, member: member)}
        ${setter.isStatic ? 'isStatic: true,' : ''}
      ),
''';
}

String bridgeFieldDef(
  BindgenContext ctx, {
  required FieldElement field,
  BindgenMemberConfig? member,
}) {
  final type = member?.type != null
      ? bridgeTypeAnnotationFromName(ctx, member!.type!)
      : bridgeTypeAnnotationFrom(ctx, field.type);
  return '''
      '${member?.rename ?? field.name}': BridgeFieldDef(
        $type,
        isStatic: ${member?.isStatic ?? field.isStatic},
      ),
''';
}

/// Emit `BridgeMethodDef`/`BridgeFieldDef`/`BridgeConstructorDef` entries for
/// `synthetic:` config members of [kind] (`method`, `getter`, `setter`,
/// `field`, `constructor`, `static`).
String syntheticDeclarations(BindgenContext ctx, String kind) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  return synthetic
      .where((s) => _syntheticKindMatches(s, kind))
      .map((s) => _syntheticDeclaration(ctx, s))
      .join('\n');
}

bool _syntheticKindMatches(BindgenSyntheticMember s, String kind) =>
    switch (s.kind) {
      'method' => kind == 'method',
      'static' => kind == 'method',
      'getter' => kind == 'getter',
      'setter' => kind == 'setter',
      'field' => kind == 'field',
      'constructor' => kind == 'constructor',
      _ => false,
    };

String _syntheticParams(BindgenContext ctx, BindgenSyntheticMember s) {
  String paramSource(BindgenSyntheticParam p) =>
      '''
        BridgeParameter(
          '${p.name}',
          ${bridgeTypeAnnotationFromName(ctx, p.type)},
          ${p.optional || p.named},
        ),
  ''';
  final positional = s.params.where((p) => !p.named).map(paramSource).join();
  final named = s.params.where((p) => p.named).map(paramSource).join();
  return 'params: [$positional], namedParams: [$named],';
}

String _syntheticReturns(BindgenContext ctx, BindgenSyntheticMember s) {
  final returns = s.returns;
  if (returns == null) {
    return 'returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic))';
  }
  final dep = returns.dependsOn;
  final baseName = returns.type ?? dep?.fallback ?? 'dynamic';
  final baseExpr = bridgeTypeAnnotationFromName(ctx, baseName);
  if (dep == null) {
    return 'returns: $baseExpr';
  }
  final cases = dep.cases.entries
      .map(
        (e) =>
            'BridgeReturnTypeCase(${bridgeTypeRefFromName(ctx, e.key)}, '
            '${bridgeTypeAnnotationFromName(ctx, e.value)})',
      )
      .join(', ');
  final selector = dep.index != null
      ? 'paramIndex: ${dep.index}'
      : "paramName: '${dep.param}'";
  final fallback = dep.fallback != null
      ? ', fallback: ${bridgeTypeAnnotationFromName(ctx, dep.fallback!)}'
      : '';
  return 'returns: $baseExpr, returnTypeDependency: '
      'BridgeReturnTypeDependency($selector, cases: [$cases]$fallback)';
}

String _syntheticDeclaration(BindgenContext ctx, BindgenSyntheticMember s) {
  final isStatic = s.isStatic || s.kind == 'static';
  return switch (s.kind) {
    'method' || 'static' =>
      '''
      '${s.name}': BridgeMethodDef(
        BridgeFunctionDef(
          ${_syntheticReturns(ctx, s)},
          ${_syntheticParams(ctx, s)}
        ),
        ${isStatic ? 'isStatic: true,' : ''}
      ),''',
    'getter' =>
      '''
      '${s.name}': BridgeMethodDef(
        BridgeFunctionDef(
          ${_syntheticReturns(ctx, s)},
        ),
        ${isStatic ? 'isStatic: true,' : ''}
      ),''',
    'setter' =>
      '''
      '${s.name}': BridgeMethodDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.voidType)),
          params: [
            BridgeParameter(
              'value',
              ${s.returns?.type != null ? bridgeTypeAnnotationFromName(ctx, s.returns!.type!) : 'BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic))'},
              false,
            ),
          ],
        ),
      ),''',
    'field' =>
      '''
      '${s.name}': BridgeFieldDef(
        ${s.returns?.type != null ? bridgeTypeAnnotationFromName(ctx, s.returns!.type!) : 'BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic))'},
        isStatic: $isStatic,
      ),''',
    'constructor' =>
      '''
      '${s.name}': BridgeConstructorDef(
        BridgeFunctionDef(
          returns: BridgeTypeAnnotation(\$type),
          ${_syntheticParams(ctx, s)}
        ),
        isFactory: ${s.isStatic},
      ),''',
    _ => '',
  };
}
