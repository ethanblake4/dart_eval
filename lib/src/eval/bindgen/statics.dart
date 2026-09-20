import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

/// Reconstruct a `List<$Value?>` of [count] arguments from the register ABI.
String registerArgsList(int count) => switch (count) {
      0 => 'const <\$Value?>[]',
      1 => '[r as \$Value?]',
      2 => '[r as \$Value?, s as \$Value?]',
      3 => '[r as \$Value?, s as \$Value?, c as \$Value?]',
      _ => '[r as \$Value?, s as \$Value?, '
          '...(c is List ? (c as List).cast<\$Value?>().take(${count - 2}) '
          ': const <\$Value?>[])]',
    };

String $constructors(
  BindgenContext ctx,
  ClassElement element, {
  bool isBridge = false,
}) {
  final emitted = element.constructors
      .where(
        (cstr) =>
            !cstr.isPrivate &&
            (cstr.isFactory || !element.isAbstract) &&
            ctx.memberIncluded(cstr.name ?? '', 'constructor'),
      )
      .map((e) => _$constructor(ctx, element, e, isBridge: isBridge))
      .join('\n');
  return emitted + _syntheticConstructors(ctx, element);
}

String _$constructor(
  BindgenContext ctx,
  ClassElement element,
  ConstructorElement constructor, {
  bool isBridge = false,
}) {
  final member = ctx.memberConfig(constructor.name ?? '', 'constructor');
  final name = member?.rename ?? constructor.name ?? '';
  final sdkNamedConstructor =
      constructor.name != null && constructor.name != 'new'
          ? '.${constructor.name}'
          : '';
  final fullyQualifiedConstructorId = isBridge
      ? '\$${element.name}\$bridge$sdkNamedConstructor'
      : '${element.name}$sdkNamedConstructor';

  final String body;
  if (member?.hook != null) {
    final prefix = ctx.hooksPrefix();
    final argsExpr = registerArgsList(constructor.formalParameters.length);
    body =
        'return ${prefix != null ? '$prefix.' : ''}${member!.hook}(runtime, '
        'null, $argsExpr);';
  } else {
    body = '''
    ${registerArgumentPreamble(constructor.formalParameters)}
    ${assertConfigPermissions(ctx, member, constructor.formalParameters.map((p) => p.name ?? '').toList(), registers: true, paramCount: constructor.formalParameters.length)}
    return ${!isBridge ? '\$${element.name}.wrap(' : ''}
      $fullyQualifiedConstructorId(
        ${argumentAccessors(ctx, constructor.formalParameters, registers: true, member: member).join(', ')}
      ${!isBridge ? '),' : ''}
    );''';
  }

  return '''
  /// ${isBridge ? 'Proxy' : 'Wrapper'} for the [${element.name}.$name] constructor
  static \$Value? ${memberWrapperName(name)}($_signature) {
    $body
  }
''';
}

/// Emit static bodies for `synthetic:` constructor members.
String _syntheticConstructors(BindgenContext ctx, ClassElement element) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  return synthetic
      .where((s) => s.kind == 'constructor')
      .map((s) {
        final name = s.name;
        final prefix = ctx.hooksPrefix();
        String bodyExpr() {
          if (s.hook != null) {
            return 'return ${prefix != null ? '$prefix.' : ''}${s.hook}'
                '(runtime, null, ${registerArgsList(s.params.length)});';
          }
          return 'return ${s.expr ?? 'null'};';
        }

        return '''
  /// Wrapper for the synthetic [${element.name}.$name] constructor
  static \$Value? ${memberWrapperName(name)}($_signature) {
    ${bodyExpr()}
  }
''';
      })
      .join('\n');
}

String $staticMethods(BindgenContext ctx, InterfaceElement element) {
  final emitted = element.methods
      .where((e) =>
          e.isStatic &&
          !e.isOperator &&
          !e.isPrivate &&
          ctx.memberIncluded(e.name!, 'static'))
      .map((e) => _$staticMethod(ctx, element, e))
      .join('\n');
  return emitted + _syntheticStatics(ctx, element);
}

String _$staticMethod(
  BindgenContext ctx,
  InterfaceElement element,
  MethodElement method,
) {
  final member = ctx.memberConfig(method.name!, 'static');
  final name = member?.rename ?? method.name!;
  final String body;
  if (member?.hook != null) {
    final prefix = ctx.hooksPrefix();
    final argsExpr = registerArgsList(method.formalParameters.length);
    body = 'return ${prefix != null ? '$prefix.' : ''}${member!.hook}'
        '(runtime, null, $argsExpr);';
  } else if (member?.expr != null) {
    body = 'return ${member!.expr};';
  } else {
    body = '''
    ${registerArgumentPreamble(method.formalParameters)}
    ${assertMethodPermissions(method, registers: true)}
    ${assertConfigPermissions(ctx, member, method.formalParameters.map((p) => p.name ?? '').toList(), registers: true, paramCount: method.formalParameters.length)}
    ${method.returnType is VoidType ? '' : 'final value = '}${element.name}.${method.name}(
      ${argumentAccessors(ctx, method.formalParameters, registers: true, member: member).join(', ')}
    );
    return ${wrapVar(ctx, method.returnType, "value", unionTypeNames: member?.returns?.union)};''';
  }

  return '''
  /// Wrapper for the [${element.name}.${method.name}] method
  static \$Value? ${memberWrapperName(name)}($_signature) {
    $body
  }
''';
}

/// Emit static bodies for `synthetic:` members of kind `static`.
String _syntheticStatics(BindgenContext ctx, InterfaceElement element) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  return synthetic
      .where((s) => s.kind == 'static')
      .map((s) {
        final prefix = ctx.hooksPrefix();
        String bodyExpr() {
          if (s.hook != null) {
            return 'return ${prefix != null ? '$prefix.' : ''}${s.hook}'
                '(runtime, null, ${registerArgsList(s.params.length)});';
          }
          return 'return ${s.expr ?? 'null'};';
        }

        return '''
  /// Wrapper for the synthetic static [${element.name}.${s.name}]
  static \$Value? ${memberWrapperName(s.name)}($_signature) {
    ${bodyExpr()}
  }
''';
      })
      .join('\n');
}

String $staticGetters(BindgenContext ctx, InterfaceElement element) {
  final emitted = element.getters
      .where(
        (e) =>
            e.isStatic &&
            !e.isPrivate &&
            ctx.memberIncluded(e.name!, 'static') &&
            (e.nonSynthetic is! FieldElement ||
                !(e.nonSynthetic as FieldElement).isEnumConstant),
      )
      .map((e) => _$staticGetter(ctx, element, e))
      .join('\n');
  return emitted + _syntheticStaticGetters(ctx, element);
}

String _$staticGetter(
  BindgenContext ctx,
  InterfaceElement element,
  PropertyAccessorElement getter,
) {
  final member = ctx.memberConfig(getter.name!, 'static');
  final name = member?.rename ?? getter.name!;
  final String body;
  if (member?.hook != null) {
    final prefix = ctx.hooksPrefix();
    body = 'return ${prefix != null ? '$prefix.' : ''}${member!.hook}'
        '(runtime, null, const <\$Value?>[]);';
  } else if (member?.expr != null) {
    body = 'return ${member!.expr};';
  } else {
    body = '''
    final value = ${element.name}.${getter.name};
    return ${wrapVar(ctx, getter.returnType, "value", unionTypeNames: member?.returns?.union)};''';
  }
  return '''
  /// Wrapper for the [${element.name}.${getter.name}] getter
  static \$Value? ${memberWrapperName(name)}($_signature) {
    $body
  }
''';
}

/// Emit static getter bodies for `synthetic:` members of kind `getter` with
/// `static: true`.
String _syntheticStaticGetters(BindgenContext ctx, InterfaceElement element) {
  final synthetic = ctx.classConfig?.synthetic ?? const [];
  return synthetic
      .where((s) => s.kind == 'getter' && s.isStatic)
      .map((s) {
        final prefix = ctx.hooksPrefix();
        String bodyExpr() {
          if (s.hook != null) {
            return 'return ${prefix != null ? '$prefix.' : ''}${s.hook}'
                '(runtime, null, args);';
          }
          return 'return ${s.expr ?? 'null'};';
        }

        return '''
  /// Wrapper for the synthetic static getter [${element.name}.${s.name}]
  static \$Value? ${memberWrapperName(s.name)}($_signature) {
    ${bodyExpr()}
  }
''';
      })
      .join('\n');
}

String $staticSetters(BindgenContext ctx, InterfaceElement element) {
  return element.setters
      .where((e) =>
          e.isStatic &&
          !e.isPrivate &&
          ctx.memberIncluded(e.name!, 'static'))
      .map((e) => _$staticSetter(ctx, element, e))
      .join('\n');
}

String _$staticSetter(
  BindgenContext ctx,
  InterfaceElement element,
  PropertyAccessorElement setter,
) {
  final member = ctx.memberConfig(setter.name!, 'static');
  final name = member?.rename ?? setter.name!;
  return '''
  /// Wrapper for the [${element.name}.${setter.name}] setter
  static \$Value? set${memberWrapperName(name)}($_signature) {
    ${element.name}.${setter.name} = ${argumentAccessors(ctx, setter.formalParameters, registers: true, member: member).single};
    return null;
  }
''';
}

const _signature = r'Runtime runtime, Object? r, Object? s, Object? c';
