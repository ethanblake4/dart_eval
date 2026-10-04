import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/static_constants.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

/// Reconstruct a `List<$Value?>` of [count] arguments from the register ABI.
String registerArgsList(int count) => switch (count) {
  0 => 'const <\$Value?>[]',
  1 => '[r as \$Value?]',
  2 => '[r as \$Value?, s as \$Value?]',
  3 => '[r as \$Value?, s as \$Value?, c as \$Value?]',
  _ =>
    '[r as \$Value?, s as \$Value?, '
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
            (isBridge || cstr.isFactory || !element.isAbstract) &&
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
  final bridgeFactory = isBridge && constructor.isFactory;
  isBridge = isBridge && !constructor.isFactory;
  final member = ctx.memberConfig(constructor.name ?? '', 'constructor');
  final name = member?.rename ?? constructor.name ?? '';
  final sdkNamedConstructor =
      constructor.name != null && constructor.name != 'new'
      ? '.${constructor.name}'
      : '';
  final fullyQualifiedConstructorId = isBridge
      ? '${ctx.wrapperName(element)}\$bridge$sdkNamedConstructor'
      : '${element.name}$sdkNamedConstructor';

  final String body;
  if (member?.hook != null) {
    final prefix = ctx.hooksPrefix();
    final argsExpr = registerArgsList(constructor.formalParameters.length);
    body =
        'return ${prefix != null ? '$prefix.' : ''}${member!.hook}(runtime, '
        'null, $argsExpr);';
  } else {
    final parameters = constructor.formalParameters;
    final needsNativeDefaults =
        !isBridge &&
        parameters.any((parameter) {
          final defaultValue = parameter.defaultValueCode;
          return parameter.isOptional &&
              member?.params[parameter.name]?.defaultValue == null &&
              defaultValue != null &&
              _usesPrivateIdentifier(defaultValue);
        });
    final invocation = needsNativeDefaults
        ? _nativeConstructorInvocation(
            ctx,
            element,
            constructor,
            member,
            bridgeFactory,
          )
        : '$fullyQualifiedConstructorId('
              '${argumentAccessors(ctx, parameters, registers: true, exportValues: bridgeFactory, member: member).join(', ')})';
    body = '''
    ${bridgeFactory ? 'final result = $invocation; return ${wrapVar(ctx, element.thisType, 'result')};' : 'return ${isBridge ? invocation : '${ctx.wrapperName(element)}.wrap($invocation)'};'}''';
  }

  return '''
  /// ${isBridge ? 'Proxy' : 'Wrapper'} for the [${element.name}.$name] constructor
  static \$Value? ${memberWrapperName(name)}($_signature) {
    ${registerArgumentPreamble(constructor.formalParameters)}
    ${assertConfigPermissions(ctx, member, constructor.formalParameters, paramCount: constructor.formalParameters.length)}
    $body
  }
''';
}

bool _usesPrivateIdentifier(String expression) {
  final visitor = _PrivateIdentifierVisitor();
  parseString(
    content: 'final defaultValue = $expression;',
    throwIfDiagnostics: false,
  ).unit.accept(visitor);
  return visitor.found;
}

class _PrivateIdentifierVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name.startsWith('_')) found = true;
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme.startsWith('_')) found = true;
    super.visitNamedType(node);
  }
}

String _nativeConstructorInvocation(
  BindgenContext ctx,
  ClassElement element,
  ConstructorElement constructor,
  BindgenMemberConfig? member,
  bool exportValues,
) {
  final parameters = constructor.formalParameters;
  final positional = <String>[];
  final named = <String>[];
  for (final (index, parameter) in parameters.indexed) {
    final source = registerArgumentSource(
      index,
      parameters.length,
      optional: parameter.isOptional,
    );
    final configured = member?.params[parameter.name];
    final value = argumentAccessor(
      ctx,
      index,
      parameter,
      argumentSource: source,
      primitiveSource: registerRawArgumentSource(
        index,
        parameters.length,
        optional: parameter.isOptional,
      ),
      exportValues: exportValues,
      paramConfig: configured,
      includeNamedLabel: false,
      useDefaultValue: configured?.defaultValue != null,
    );
    final guard = parameter.isOptional && configured?.defaultValue == null
        ? 'if ($source != null) '
        : '';
    if (parameter.isNamed) {
      named.add('$guard#${parameter.name}: $value');
    } else {
      positional.add('$guard$value');
    }
  }
  final name = constructor.name;
  final tearoff =
      '${element.name}.${name == null || name == 'new' ? 'new' : name}';
  return 'Function.apply($tearoff, [${positional.join(', ')}], '
      '{${named.join(', ')}}) as ${element.name}';
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
      .where(
        (e) =>
            e.isStatic &&
            !e.isOperator &&
            !e.isPrivate &&
            ctx.memberIncluded(e.name!, 'static'),
      )
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
    body =
        'return ${prefix != null ? '$prefix.' : ''}${member!.hook}'
        '(runtime, null, $argsExpr);';
  } else if (member?.expr != null) {
    body = 'return ${member!.expr};';
  } else {
    body =
        '''
    ${method.returnType is VoidType ? '' : 'final value = '}${element.name}.${method.name}(
      ${argumentAccessors(ctx, method.formalParameters, registers: true, member: member).join(', ')}
    );
    return ${wrapVar(ctx, method.returnType, "value", unionTypeNames: member?.returns?.union)};''';
  }

  return '''
  /// Wrapper for the [${element.name}.${method.name}] method
  static \$Value? ${memberWrapperName(name)}($_signature) {
    ${registerArgumentPreamble(method.formalParameters)}
    ${assertMethodPermissions(method)}
    ${assertConfigPermissions(ctx, member, method.formalParameters, paramCount: method.formalParameters.length)}
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
  final compactNames = compactStaticConstants(ctx, element)?.fieldNames;
  final emitted = element.getters
      .where(
        (e) =>
            e.isStatic &&
            !e.isPrivate &&
            !(compactNames?.contains(e.name) ?? false) &&
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
    body =
        'return ${prefix != null ? '$prefix.' : ''}${member!.hook}'
        '(runtime, null, const <\$Value?>[]);';
  } else if (member?.expr != null) {
    body = 'return ${member!.expr};';
  } else {
    body =
        '''
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
      .where(
        (e) =>
            e.isStatic && !e.isPrivate && ctx.memberIncluded(e.name!, 'static'),
      )
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
