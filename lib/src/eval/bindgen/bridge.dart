import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'native_source.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart'
    show objectGetterNames, objectMethodNames;
import 'package:dart_eval/src/eval/bindgen/operator.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String bindForwardedConstructors(
  BindgenContext ctx,
  ClassElement element, {
  bool isBridge = false,
}) {
  return element.constructors
      .where(
        (cstr) =>
            !cstr.isPrivate &&
            !cstr.isFactory &&
            ctx.memberIncluded(cstr.name ?? '', 'constructor'),
      )
      .map(
        (e) => element.isInterface
            ? _interfaceConstructor(ctx, element, e)
            : _$forwardedConstructor(ctx, element, e, isBridge: isBridge),
      )
      .join('\n');
}

String _interfaceConstructor(
  BindgenContext ctx,
  ClassElement element,
  ConstructorElement constructor,
) {
  final namedConstructor = constructor.name == null
      ? ''
      : '.' + constructor.name!;
  final bridgeName = ctx.wrapperName(element) + r'$bridge' + namedConstructor;
  return '  ' +
      bridgeName +
      '(' +
      parameterHeader(constructor.formalParameters, preserveTypes: true) +
      ') {}';
}

String _$forwardedConstructor(
  BindgenContext ctx,
  ClassElement element,
  ConstructorElement constructor, {
  bool isBridge = false,
}) {
  final name = constructor.name ?? '';
  final namedConstructor = constructor.name != null && constructor.name != 'new'
      ? '.${constructor.name}'
      : '';
  final fullyQualifiedConstructorId =
      '${ctx.wrapperName(element)}\$bridge$namedConstructor';

  return '''
  /// Forwarded constructor for [${element.name}.$name]
  $fullyQualifiedConstructorId(${parameterHeader(constructor.formalParameters, forConstructor: true)})${namedConstructor.isEmpty ? '' : ' : super$namedConstructor()'};
''';
}

String bindDecoratorMethods(BindgenContext ctx, ClassElement element) {
  final methods = [
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed) ...s.methods,
    ...element.methods,
  ];

  return dedupeMethods(methods)
      .where((method) => !method.isPrivate && !method.isStatic)
      .where(
        (m) => ctx.memberIncluded(
          m.name!,
          'method',
          isObjectMember: objectMethodNames.contains(m.name),
        ),
      )
      .map((e) {
        final returnType = e.returnType;
        final constructorCall =
            ctx.classConfig?.constructorCalls.contains(e.name) ?? false;
        final nativeSuper =
            ctx.classConfig?.nativeSuper == true &&
            !e.isAbstract &&
            !e.isOperator &&
            e.typeParameters.isEmpty;
        final nativeArguments = e.formalParameters
            .map((p) => '${p.isNamed ? '${p.name}: ' : ''}${p.name}')
            .join(', ');
        final exportIterable =
            returnType.isDartCoreIterable && returnType is InterfaceType;
        if (exportIterable) {
          ctx.imports.add(
            'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
          );
        }
        final needsCast =
            returnType.isDartCoreList ||
            returnType.isDartCoreMap ||
            returnType.isDartCoreSet;
        final q = returnType.nullabilitySuffix == NullabilitySuffix.question
            ? '?'
            : '';

        return '''
        @override
        $returnType ${e.isOperator ? 'operator ' : ''}${e.displayName}${e.typeParameters.isEmpty ? '' : '<${e.typeParameters.join(', ')}>'}(${parameterHeader(e.formalParameters, preserveTypes: true)}) {
          ${nativeSuper || constructorCall ? '''if (${nativeSuper ? 'Runtime.bridgeData[this]?.subclass == null' : 'Runtime.bridgeData[this] == null'}) {
            ${returnType is VoidType ? '' : 'return '}super.${e.displayName}($nativeArguments);
            ${returnType is VoidType ? 'return;' : ''}
          }''' : ''}
          final runtime = \$runtime;
          ${returnType is VoidType
            ? ''
            : exportIterable
            ? 'final result = '
            : 'return '}${needsCast ? '(' : ''}\$_invoke('${e.isOperator ? operatorMemberName(e.name!, e.formalParameters.length) : e.displayName}', [
            ${e.formalParameters.map((p) => _bridgeArgument(ctx, p.type, p.name ?? '')).join(', ')}
          ])${needsCast ? 'as ${returnType.element!.name}$q)$q.cast()' : ''};
          ${exportIterable ? 'return ${q.isEmpty ? '' : 'result == null ? null : '}TypedInterop.exportIterable<${returnType.typeArguments.single}>(result, runtime);' : ''}
        }
        ''';
      })
      .join('\n');
}

String? _bridgeArgument(BindgenContext ctx, DartType type, String expression) {
  final wrapped = wrapBridgeArgument(ctx, type, expression);
  if (wrapped == null ||
      type is! ParameterizedType ||
      type.typeArguments.isEmpty ||
      type.nullabilitySuffix == NullabilitySuffix.question) {
    return wrapped;
  }
  final typeId = runtimeTypeIdFor(ctx, type, 'bridge');
  if (typeId == null) return wrapped;
  ctx.imports.add('package:dart_eval/src/eval/runtime/runtime.dart');
  if (type.isDartCoreList || type.isDartCoreMap || type.isDartCoreSet) {
    ctx.imports.add(
      'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
    );
    return 'TypedInterop.boxExternal($expression, runtime: runtime, '
        'runtimeTypeId: $typeId)!';
  }
  if (type.element?.library?.isInSdk == true) return wrapped;
  ctx.imports.add(
    'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
  );
  return 'TypedInterop.annotateBridgeType($wrapped, runtime, $typeId)';
}

String bindDecoratorProperties(BindgenContext ctx, ClassElement element) {
  final properties = {
    if (ctx.implicitSupers)
      for (var s in element.allSupertypes.reversed)
        for (final p in s.element.fields) p.name: p,
    for (final p in element.fields) p.name: p,
  };

  return properties.values
          .where((property) => !property.isPrivate && !property.isStatic)
          .where(
            (property) => ctx.memberIncluded(
              property.name!,
              'getter',
              isObjectMember: objectGetterNames.contains(property.name),
            ),
          )
          .map((e) {
            final type = e.type;
            final nativeSuper =
                ctx.classConfig?.nativeSuper == true &&
                e.getter?.isAbstract == false;
            final nativeGetter = nativeSuper
                ? 'if (Runtime.bridgeData[this]?.subclass == null) return super.${e.displayName};'
                : '';
            if (type is InterfaceType && type.isDartCoreList) {
              final nullable =
                  type.nullabilitySuffix == NullabilitySuffix.question;
              final elementType = type.typeArguments.single;
              return '''
            @override
            $type get ${e.displayName} {
              $nativeGetter
              final result = \$_get('${e.displayName}') as List?;
              return ${nullable ? 'result?.cast<$elementType>()' : 'result!.cast<$elementType>()'};
            }
            ''';
            }
            if (type is InterfaceType &&
                (type.element.name == 'Iterator' || type.isDartCoreIterable) &&
                type.element.library.uri.toString() == 'dart:core') {
              ctx.imports.add(
                'package:dart_eval/src/eval/runtime/typed/typed_interop.dart',
              );
              if (type.nullabilitySuffix == NullabilitySuffix.question) {
                ctx.imports.add('package:dart_eval/stdlib/core.dart');
                return '''
            @override
            $type get ${e.displayName} {
              $nativeGetter
              final runtime = \$runtime;
              final result = \$getProperty(runtime, '${e.displayName}');
              if (result == null || result is \$null) return null;
              return TypedInterop.export${type.isDartCoreIterable ? 'Iterable' : 'Iterator'}<${type.typeArguments.single}>(result, runtime);
            }
            ''';
              }
              return '''
          @override
          $type get ${e.displayName} => ${nativeSuper ? 'Runtime.bridgeData[this]?.subclass == null ? super.${e.displayName} : ' : ''}TypedInterop.export${type.isDartCoreIterable ? 'Iterable' : 'Iterator'}<${type.typeArguments.single}>(
            \$getProperty(\$runtime, '${e.displayName}'), \$runtime);
          ''';
            }

            return '''
        @override
        $type get ${e.displayName} => ${nativeSuper ? 'Runtime.bridgeData[this]?.subclass == null ? super.${e.displayName} : ' : ''}\$_get('${e.displayName}');
        ''';
          })
          .join('\n') +
      properties.values
          .where((e) => !e.isPrivate && !e.isStatic && e.setter != null)
          .where((e) => ctx.memberIncluded(e.name!, 'setter'))
          .map(
            (e) =>
                '''
            @override
            set ${e.displayName}(${e.type} value) {
              ${ctx.classConfig?.nativeSuper == true && e.setter?.isAbstract == false ? '''if (Runtime.bridgeData[this]?.subclass == null) {
                super.${e.displayName} = value;
                return;
              }''' : ''}
              final runtime = \$runtime;
              \$_set('${e.displayName}', ${wrapVar(ctx, e.type, 'value')});
            }
          ''',
          )
          .join('\n');
}

/// Renders [type] as a Dart type with type parameters erased to their bound
/// (or `dynamic`). Wrapper method bodies are static, so class type parameters
/// are out of scope, and `$value` is always raw — erased types are correct.
String dartTypeErased(
  DartType type, {
  BindgenContext? ctx,
  InterfaceElement? nativeOwner,
  Iterable<TypeParameterElement> localTypeParameters = const [],
}) {
  final suffix = type.nullabilitySuffix == NullabilitySuffix.question
      ? '?'
      : '';
  if (type is TypeParameterType) {
    if (localTypeParameters.any(
          (parameter) => identical(parameter, type.element),
        ) ||
        nativeOwner != null &&
            identical(type.element.enclosingElement, nativeOwner)) {
      return type.getDisplayString();
    }
    final bound = type.bound;
    if (bound.isDartCoreObject) {
      return 'dynamic';
    }
    return dartTypeErased(
      bound,
      ctx: ctx,
      nativeOwner: nativeOwner,
      localTypeParameters: localTypeParameters,
    );
  }
  if (type is FunctionType) {
    final locals = [...localTypeParameters, ...type.typeParameters];
    String native(DartType t) => dartTypeErased(
      t,
      ctx: ctx,
      nativeOwner: nativeOwner,
      localTypeParameters: locals,
    );
    final generics = type.typeParameters.isEmpty
        ? ''
        : '<${type.typeParameters.map((p) {
            final bound = p.bound;
            return bound == null ? p.name : '${p.name} extends ${native(bound)}';
          }).join(', ')}>';
    final required = <String>[];
    final optional = <String>[];
    final named = <String>[];
    for (final p in type.formalParameters) {
      final t = native(p.type);
      if (p.isNamed) {
        named.add('${p.isRequiredNamed ? 'required ' : ''}$t ${p.name}');
      } else if (p.isOptionalPositional) {
        optional.add(t);
      } else {
        required.add(t);
      }
    }
    final parameters = [
      ...required,
      if (optional.isNotEmpty) '[${optional.join(', ')}]',
      if (named.isNotEmpty) '{${named.join(', ')}}',
    ].join(', ');
    return '${native(type.returnType)} Function$generics($parameters)$suffix';
  }
  if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
    final args = type.typeArguments
        .map(
          (argument) => dartTypeErased(
            argument,
            ctx: ctx,
            nativeOwner: nativeOwner,
            localTypeParameters: localTypeParameters,
          ),
        )
        .join(', ');
    return '${ctx == null ? type.element?.name : ctx.nativeName(type.element!)}<$args>$suffix';
  }
  if (ctx != null && type.element != null) {
    return '${ctx.nativeName(type.element!)}$suffix';
  }
  return type.getDisplayString();
}

String parameterHeader(
  List<FormalParameterElement> params, {
  BindgenContext? ctx,
  bool forConstructor = false,
  bool preserveTypes = false,
  Iterable<TypeParameterElement> localTypeParameters = const [],
}) {
  final paramBuffer = StringBuffer();
  var inNonPositional = false;
  for (var i = 0; i < params.length; i++) {
    final param = params[i];
    if (param.isNamed || param.isOptional) {
      if (!inNonPositional) {
        inNonPositional = true;
        paramBuffer.write(param.isNamed ? '{' : '[');
      }
    }
    if (param.isRequiredNamed) {
      paramBuffer.write('required ');
    }
    switch (param.type) {
      case FunctionType functionType when !forConstructor && !preserveTypes:
        paramBuffer.write(dartTypeErased(functionType.returnType, ctx: ctx));
        paramBuffer.write(' Function(');
        paramBuffer.write(
          parameterHeader(functionType.formalParameters, ctx: ctx),
        );
        paramBuffer.write(')');
        if (functionType.nullabilitySuffix == NullabilitySuffix.question) {
          paramBuffer.write('?');
        }
        break;
      default:
        if (forConstructor) {
          paramBuffer.write('super.');
        } else {
          paramBuffer.write(
            '${preserveTypes && ctx == null ? param.type.getDisplayString() : dartTypeErased(param.type, ctx: ctx, localTypeParameters: localTypeParameters)} ',
          );
        }
    }
    paramBuffer.write(
      param.name == null || param.name!.isEmpty ? 'arg$i' : param.name,
    );
    if (!forConstructor && param.defaultValueCode != null) {
      paramBuffer.write(
        ' = ${ctx == null ? param.defaultValueCode : nativeDefaultSource(ctx, param)}',
      );
    } else if (!forConstructor &&
        param.isOptional &&
        param.type.isDartCoreBool &&
        param.type.nullabilitySuffix == NullabilitySuffix.none) {
      // A function typedef may declare an optional non-nullable bool without
      // a default. The generated closure still needs a Dart default value.
      paramBuffer.write(' = false');
    }
    if (i < params.length - 1) {
      paramBuffer.write(', ');
    }
  }

  if (inNonPositional) {
    paramBuffer.write(params.last.isNamed ? '}' : ']');
  }

  return paramBuffer.toString();
}
