import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/declaration_source.dart';
import 'package:dart_eval/src/eval/bindgen/operator.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/static_constants.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

/// Member names that are excluded unless `includeObjectMembers` is set.
const objectMethodNames = {'==', 'toString', 'noSuchMethod'};
const objectGetterNames = {'hashCode', 'runtimeType'};

BridgeTypeRef buildClassTypeRef(BindgenContext ctx, InterfaceElement element) =>
    BridgeTypeRef(
      ctx.runtimeTypeSpec ??
          BridgeTypeSpec(
            ctx.libOverrides[element.name] ?? ctx.uri,
            element.name!,
          ),
    );

String bindTypeSpec(BindgenContext ctx, InterfaceElement element) =>
    'static const \$spec = ${ctx.classConfig?.runtimeTypeOverride ?? bridgeTypeSpecSource(buildClassTypeRef(ctx, element).spec!)};';

String bindBridgeType(BindgenContext ctx, InterfaceElement element) =>
    r'static const $type = BridgeTypeRef($spec);';

String bindFunctionDeclaration(
  BindgenContext ctx,
  TopLevelFunctionElement element,
) =>
    'static const \$declaration = ${typeSource(ctx).declaration(ctx.declaration ?? buildFunctionDeclaration(ctx, element))};';

String? bindBridgeDeclaration(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final declaration =
      ctx.declaration ??
      buildBridgeDeclaration(ctx, element, isBridge: isBridge);
  if (declaration == null) return null;
  final classType = buildClassTypeRef(ctx, element);
  final base = typeSource(ctx);
  final compact = compactStaticConstants(ctx, element);
  final source = BridgeDeclarationSource(
    specSource: base.typeSpec,
    typeRefSource: (ref) =>
        ref.spec?.library == classType.spec!.library &&
            ref.spec?.name == classType.spec!.name &&
            ref.typeArgs.isEmpty
        ? r'$type'
        : null,
    annotationSource: (annotation) => compact?.annotationAlias(annotation),
  );
  return 'static const \$declaration = ${source.declaration(declaration)};';
}

BridgeFunctionDeclaration buildFunctionDeclaration(
  BindgenContext ctx,
  TopLevelFunctionElement element,
) => BridgeFunctionDeclaration(
  ctx.libOverrides[element.name] ?? ctx.uri,
  element.name!,
  buildFunctionDef(
    ctx,
    element,
    member: ctx.libraryConfig?.functions[element.name],
  ),
);

/// Construct compile-time metadata without generating any native wrapper code.
BridgeDeclaration? buildBridgeDeclaration(
  BindgenContext ctx,
  InterfaceElement element, {
  bool isBridge = false,
}) {
  final cc = ctx.classConfig;
  if (element is ClassElement &&
      element.constructors.isEmpty &&
      cc?.opaque != true) {
    return null;
  }
  final type = buildClassTypeRef(ctx, element);
  if (element is MixinElement && cc?.opaque == true) {
    return BridgeClassDef(
      BridgeClassType(
        type,
        isAbstract: true,
        generics: _classGenerics(ctx, element, preserveBounds: true),
        $implements: _uniqueTypes([
          for (final supertype in element.allSupertypes)
            if (!supertype.isDartCoreObject &&
                !(supertype.element.name?.startsWith('_') ?? true))
              buildTypeRef(ctx, supertype),
        ]),
      ),
      constructors: const {},
      wrap: true,
    );
  }
  final methods = _buildMethods(ctx, element)
    ..addAll(_syntheticMethods(ctx, 'method'));
  final getters = _buildAccessors(ctx, element, setter: false)
    ..addAll(_syntheticMethods(ctx, 'getter'));
  final setters = _buildAccessors(ctx, element, setter: true)
    ..addAll(_syntheticMethods(ctx, 'setter'));
  final fields = _buildFields(ctx, element)..addAll(_syntheticFields(ctx));
  if (element is EnumElement) {
    return BridgeEnumDef(
      type,
      values: [for (final constant in element.constants) constant.name!],
      methods: methods,
      getters: getters,
      setters: setters,
      fields: fields,
    );
  }
  final constructors = <String, BridgeConstructorDef>{
    if (element is MixinElement)
      '': BridgeConstructorDef(
        BridgeFunctionDef(returns: BridgeTypeAnnotation(type)),
      ),
    if (element is ClassElement)
      for (final constructor in element.constructors)
        if (!constructor.isPrivate &&
            ctx.memberIncluded(constructor.name ?? '', 'constructor'))
          _constructorName(
            ctx.memberConfig(constructor.name ?? '', 'constructor')?.rename ??
                constructor.name ??
                '',
          ): BridgeConstructorDef(
            BridgeFunctionDef(
              returns: BridgeTypeAnnotation(type),
              params: buildParameters(
                ctx,
                constructor.formalParameters
                    .where((p) => p.isPositional)
                    .toList(),
                member: ctx.memberConfig(constructor.name ?? '', 'constructor'),
              ),
              namedParams: buildParameters(
                ctx,
                constructor.formalParameters.where((p) => p.isNamed).toList(),
                member: ctx.memberConfig(constructor.name ?? '', 'constructor'),
              ),
            ),
            isFactory: constructor.isFactory,
          ),
    for (final member in cc?.synthetic ?? const <BindgenSyntheticMember>[])
      if (member.kind == 'constructor')
        _constructorName(member.name): BridgeConstructorDef(
          _syntheticFunction(ctx, member, returns: BridgeTypeAnnotation(type)),
          isFactory: member.isStatic,
        ),
  };
  final supertype = element is ClassElement ? element.supertype : null;
  final extendsType = cc?.extendsName != null
      ? buildTypeRefFromName(ctx, cc!.extendsName!)
      : supertype != null &&
            !supertype.isDartCoreObject &&
            !(supertype.element.name?.startsWith('_') ?? false) &&
            !ctx.implicitSupers
      ? buildTypeRef(ctx, supertype)
      : const BridgeTypeRef(CoreTypes.object);
  final implementsTypes = cc != null && cc.implementsNames.isNotEmpty
      ? [for (final name in cc.implementsNames) buildTypeRefFromName(ctx, name)]
      : element is ClassElement
      ? _uniqueTypes([
          for (final supertype in element.allSupertypes)
            if (!supertype.isDartCoreObject &&
                !(supertype.element.name?.startsWith('_') ?? true) &&
                boundSdkClassFor(ctx, supertype.element) != null)
              buildTypeRef(ctx, supertype),
        ])
      : <BridgeTypeRef>[];
  return BridgeClassDef(
    BridgeClassType(
      type,
      isAbstract:
          cc?.isAbstract ??
          (element is MixinElement ||
              element is ClassElement && element.isAbstract),
      isMixinClass:
          element is MixinElement ||
          element is ClassElement && element.isMixinClass,
      generics: _classGenerics(ctx, element),
      $extends: extendsType,
      $implements: implementsTypes,
    ),
    constructors: constructors,
    methods: methods,
    getters: getters,
    setters: setters,
    fields: fields,
    wrap: !isBridge,
    bridge: isBridge,
  );
}

String _constructorName(String name) => name == 'new' ? '' : name;

// Type refs deliberately have identity equality, so compare their contents.
List<BridgeTypeRef> _uniqueTypes(List<BridgeTypeRef> types) {
  final unique = <String, BridgeTypeRef>{};
  for (final type in types) {
    unique[jsonEncode(type.toJson())] = type;
  }
  return unique.values.toList();
}

Map<String, BridgeGenericParam> _classGenerics(
  BindgenContext ctx,
  InterfaceElement element, {
  bool preserveBounds = false,
}) => {
  for (final parameter in element.typeParameters)
    parameter.name!: _classGeneric(
      ctx,
      parameter,
      preserveBounds: preserveBounds,
    ),
};

BridgeGenericParam _classGeneric(
  BindgenContext ctx,
  TypeParameterElement parameter, {
  required bool preserveBounds,
}) {
  final cc = ctx.classConfig;
  final hasOverride =
      !preserveBounds && cc?.generics.containsKey(parameter.name) == true;
  final override = cc?.generics[parameter.name];
  final bound = hasOverride
      ? override == null
            ? null
            : buildTypeRefFromName(ctx, override)
      : parameter.bound != null && (preserveBounds || !ctx.implicitSupers)
      ? buildTypeRef(ctx, parameter.bound!)
      : null;
  return BridgeGenericParam(
    $extends: bound,
    boundNullable:
        bound != null &&
        (hasOverride
            ? override?.trim().endsWith('?') == true
            : parameter.bound?.nullabilitySuffix == NullabilitySuffix.question),
  );
}

Map<String, BridgeMethodDef> _buildMethods(
  BindgenContext ctx,
  InterfaceElement element,
) {
  final candidates = [
    if (ctx.implicitSupers)
      for (final supertype in element.allSupertypes.reversed)
        ...supertype.methods.where((m) => !m.isStatic),
    ...element.methods,
  ];
  return {
    for (final method in dedupeMethods(candidates))
      if (!method.isPrivate &&
          ctx.memberIncluded(
            method.name!,
            method.isStatic ? 'static' : 'method',
            isObjectMember: objectMethodNames.contains(method.name),
          ))
        operatorMemberName(
          ctx
                  .memberConfig(
                    method.name!,
                    method.isStatic ? 'static' : 'method',
                  )
                  ?.rename ??
              method.name!,
          method.formalParameters.length,
        ): BridgeMethodDef(
          buildFunctionDef(
            ctx,
            method,
            member: ctx.memberConfig(
              method.name!,
              method.isStatic ? 'static' : 'method',
            ),
          ),
          isStatic: method.isStatic,
          isAbstract: method.isAbstract,
        ),
  };
}

Map<String, BridgeMethodDef> _buildAccessors(
  BindgenContext ctx,
  InterfaceElement element, {
  required bool setter,
}) {
  final candidates = <String?, PropertyAccessorElement>{
    if (ctx.implicitSupers)
      for (final supertype in element.allSupertypes)
        for (final accessor in setter ? supertype.setters : supertype.getters)
          if (!accessor.isStatic) accessor.name: accessor,
    for (final accessor in setter ? element.setters : element.getters)
      accessor.name: accessor,
  };
  return {
    for (final accessor in candidates.values)
      if (!accessor.isPrivate &&
          !accessor.isOriginVariable &&
          ctx.memberIncluded(
            accessor.name!,
            accessor.isStatic
                ? 'static'
                : setter
                ? 'setter'
                : 'getter',
            isObjectMember:
                !setter && objectGetterNames.contains(accessor.name),
          ))
        ctx
                .memberConfig(
                  accessor.name!,
                  accessor.isStatic
                      ? 'static'
                      : setter
                      ? 'setter'
                      : 'getter',
                )
                ?.rename ??
            accessor.name!: BridgeMethodDef(
          buildFunctionDef(
            ctx,
            accessor,
            member: ctx.memberConfig(
              accessor.name!,
              accessor.isStatic
                  ? 'static'
                  : setter
                  ? 'setter'
                  : 'getter',
            ),
          ),
          isStatic: accessor.isStatic,
          isAbstract: accessor.isAbstract,
        ),
  };
}

Map<String, BridgeFieldDef> _buildFields(
  BindgenContext ctx,
  InterfaceElement element,
) {
  final candidates = <String?, FieldElement>{
    if (ctx.implicitSupers)
      for (final supertype in element.allSupertypes)
        if (supertype.element is ClassElement)
          for (final field in (supertype.element as ClassElement).fields)
            if (!field.isStatic) field.name: field,
    for (final field in element.fields) field.name: field,
  };
  return {
    for (final field in candidates.values)
      if (!field.isOriginGetterSetter &&
          !field.isEnumConstant &&
          !field.isPrivate &&
          ctx.memberIncluded(field.name!, 'field'))
        ctx.memberConfig(field.name!, 'field')?.rename ??
            field.name!: BridgeFieldDef(
          _fieldType(ctx, field),
          isStatic:
              ctx.memberConfig(field.name!, 'field')?.isStatic ??
              field.isStatic,
        ),
  };
}

BridgeTypeAnnotation _fieldType(BindgenContext ctx, FieldElement field) {
  final override = ctx.memberConfig(field.name!, 'field')?.type;
  return override == null
      ? buildTypeAnnotation(ctx, field.type)
      : buildTypeAnnotationFromName(ctx, override);
}

BridgeFunctionDef buildFunctionDef(
  BindgenContext ctx,
  ExecutableElement function, {
  BindgenMemberConfig? member,
}) {
  final previous = ctx.typeParamNames;
  ctx.typeParamNames = {
    ...previous,
    for (final parameter in function.typeParameters) parameter.name!,
  };
  try {
    return BridgeFunctionDef(
      returns: _returns(
        ctx,
        member?.returns,
        buildTypeAnnotation(ctx, function.returnType),
      ),
      returnTypeDependency: _returnDependency(ctx, member?.returns),
      generics: {
        for (final parameter in function.typeParameters)
          parameter.name!: BridgeGenericParam(
            $extends: parameter.bound == null
                ? null
                : buildTypeRef(ctx, parameter.bound!),
            boundNullable:
                parameter.bound?.nullabilitySuffix ==
                NullabilitySuffix.question,
          ),
      },
      params: buildParameters(
        ctx,
        function.formalParameters.where((p) => p.isPositional).toList(),
        member: member,
      ),
      namedParams: buildParameters(
        ctx,
        function.formalParameters.where((p) => p.isNamed).toList(),
        member: member,
      ),
    );
  } finally {
    ctx.typeParamNames = previous;
  }
}

BridgeTypeAnnotation _returns(
  BindgenContext ctx,
  BindgenReturnsConfig? returns,
  BridgeTypeAnnotation fallback,
) {
  final name = returns?.type ?? returns?.dependsOn?.fallback;
  return name == null ? fallback : buildTypeAnnotationFromName(ctx, name);
}

BridgeReturnTypeDependency? _returnDependency(
  BindgenContext ctx,
  BindgenReturnsConfig? returns,
) {
  final dependency = returns?.dependsOn;
  if (dependency == null) return null;
  return BridgeReturnTypeDependency(
    paramIndex: dependency.index,
    paramName: dependency.index == null ? dependency.param : null,
    cases: [
      for (final entry in dependency.cases.entries)
        BridgeReturnTypeCase(
          buildTypeRefFromName(ctx, entry.key),
          buildTypeAnnotationFromName(ctx, entry.value),
        ),
    ],
    fallback: dependency.fallback == null
        ? null
        : buildTypeAnnotationFromName(ctx, dependency.fallback!),
  );
}

BridgeFunctionDef _syntheticFunction(
  BindgenContext ctx,
  BindgenSyntheticMember member, {
  BridgeTypeAnnotation? returns,
}) => BridgeFunctionDef(
  returns:
      returns ??
      _returns(
        ctx,
        member.returns,
        const BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
      ),
  returnTypeDependency: _returnDependency(ctx, member.returns),
  params: [
    for (final parameter in member.params)
      if (!parameter.named) _syntheticParameter(ctx, parameter),
  ],
  namedParams: [
    for (final parameter in member.params)
      if (parameter.named) _syntheticParameter(ctx, parameter),
  ],
);

BridgeParameter _syntheticParameter(
  BindgenContext ctx,
  BindgenSyntheticParam parameter,
) => BridgeParameter(
  parameter.name,
  buildTypeAnnotationFromName(ctx, parameter.type),
  parameter.optional || parameter.named,
);

Map<String, BridgeMethodDef> _syntheticMethods(
  BindgenContext ctx,
  String kind,
) => {
  for (final member
      in ctx.classConfig?.synthetic ?? const <BindgenSyntheticMember>[])
    if (member.kind == kind || kind == 'method' && member.kind == 'static')
      (kind == 'method'
          ? operatorMemberName(member.name, member.params.length)
          : member.name): BridgeMethodDef(
        kind == 'setter'
            ? BridgeFunctionDef(
                returns: const BridgeTypeAnnotation(
                  BridgeTypeRef(CoreTypes.voidType),
                ),
                params: [
                  BridgeParameter(
                    'value',
                    member.returns?.type == null
                        ? const BridgeTypeAnnotation(
                            BridgeTypeRef(CoreTypes.dynamic),
                          )
                        : buildTypeAnnotationFromName(
                            ctx,
                            member.returns!.type!,
                          ),
                    false,
                  ),
                ],
              )
            : kind == 'getter'
            ? BridgeFunctionDef(
                returns: _returns(
                  ctx,
                  member.returns,
                  const BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
                ),
                returnTypeDependency: _returnDependency(ctx, member.returns),
              )
            : _syntheticFunction(ctx, member),
        isStatic:
            kind != 'setter' && (member.isStatic || member.kind == 'static'),
      ),
};

Map<String, BridgeFieldDef> _syntheticFields(BindgenContext ctx) => {
  for (final member
      in ctx.classConfig?.synthetic ?? const <BindgenSyntheticMember>[])
    if (member.kind == 'field')
      member.name: BridgeFieldDef(
        member.returns?.type == null
            ? const BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic))
            : buildTypeAnnotationFromName(ctx, member.returns!.type!),
        isStatic: member.isStatic,
      ),
};
