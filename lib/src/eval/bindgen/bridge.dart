import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
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
      .map((e) => _$forwardedConstructor(ctx, element, e, isBridge: isBridge))
      .join('\n');
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
      '\$${element.name}\$bridge$namedConstructor';

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
String dartTypeErased(DartType type) {
  final suffix = type.nullabilitySuffix == NullabilitySuffix.question
      ? '?'
      : '';
  if (type is TypeParameterType) {
    final bound = type.bound;
    if (bound.isDartCoreObject) {
      return 'dynamic';
    }
    return dartTypeErased(bound);
  }
  if (type is FunctionType) {
    return '${dartTypeErased(type.returnType)} Function('
        '${type.formalParameters.map((p) {
          final t = dartTypeErased(p.type);
          final prefix = p.isRequiredNamed ? 'required ' : '';
          return p.isNamed ? '$prefix$t ${p.name ?? ''}' : t;
        }).join(', ')})$suffix';
  }
  if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
    final args = type.typeArguments.map(dartTypeErased).join(', ');
    return '${type.element?.name}<$args>$suffix';
  }
  return type.getDisplayString();
}

String parameterHeader(
  List<FormalParameterElement> params, {
  bool forConstructor = false,
  bool preserveTypes = false,
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
        paramBuffer.write(dartTypeErased(functionType.returnType));
        paramBuffer.write(' Function(');
        paramBuffer.write(parameterHeader(functionType.formalParameters));
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
            '${preserveTypes ? param.type.getDisplayString() : dartTypeErased(param.type)} ',
          );
        }
    }
    paramBuffer.write(
      param.name == null || param.name!.isEmpty ? 'arg$i' : param.name,
    );
    if (!forConstructor && param.defaultValueCode != null) {
      paramBuffer.write(' = ${param.defaultValueCode}');
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
