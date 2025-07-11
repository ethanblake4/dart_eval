import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $constructors(BindgenContext ctx, ClassElement element, {bool isBridge = false}) {
  return element.constructors
      .where((cstr) => !cstr.isPrivate && !cstr.isSynthetic && (cstr.isFactory || !element.isAbstract))
      .map((e) => _$constructor(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String _$constructor(
    BindgenContext ctx, ClassElement element, ConstructorElement constructor, {bool isBridge = false}) {
  final name = constructor.name.isEmpty ? 'new' : constructor.name;
  final namedConstructor =
      constructor.name.isNotEmpty ? '.${constructor.name}' : '';
  final fullyQualifiedConstructorId = isBridge ? 
    '\$${element.name}\$bridge$namedConstructor' :
    '${element.name}$namedConstructor';

  final oConstructor = constructor;

  final paramMapping = <String, String>{};
  for (var i = 0; i < constructor.parameters.length; i++) {
    final param = constructor.parameters[i];
    paramMapping[param.name] = param.name;
  }

  while (constructor.redirectedConstructor != null) {
    constructor = constructor.redirectedConstructor!;
    for (var i = 0; i < constructor.parameters.length; i++) {
      final param = constructor.parameters[i];
      final oParam = oConstructor.parameters[i];
      paramMapping[param.name] = oParam.name;
    }
  }

  return '''
  /// ${isBridge ? 'Proxy' : 'Wrapper'} for the [${element.name}.$name] constructor
  static \$Value? \$$name(Runtime runtime, \$Value? thisValue, List<\$Value?> args) {
    return ${!isBridge ? '\$${element.name}.wrap(' : ''}
      $fullyQualifiedConstructorId(
        ${argumentAccessors(ctx, constructor.parameters)}
      ${!isBridge ? '),' : ''}
    );
  }
''';
}

String $staticMethods(BindgenContext ctx, ClassElement element) {
  return element.methods
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => _$staticMethod(ctx, element, e))
      .join('\n');
}

String _$staticMethod(
    BindgenContext ctx, ClassElement element, MethodElement method) {
  return '''
  /// Wrapper for the [${element.name}.${method.name}] method
  static \$Value? \$${method.name}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    ${assertMethodPermissions(method)}
    final value = ${element.name}.${method.name}(
      ${argumentAccessors(ctx, method.parameters)}
    );
    return ${wrapVar(ctx, method.returnType, "value")};
  }
''';
}

String $staticGetters(BindgenContext ctx, ClassElement element) {
  return element.accessors
      .where((e) => e.isStatic && e.isGetter && !e.isPrivate)
      .map((e) => _$staticGetter(ctx, element, e))
      .join('\n');
}

String _$staticGetter(
    BindgenContext ctx, ClassElement element, PropertyAccessorElement getter) {
  return '''
  /// Wrapper for the [${element.name}.${getter.name}] getter
  static \$Value? \$${getter.name}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    final value = ${element.name}.${getter.name};
    return ${wrapVar(ctx, getter.returnType, "value")};
  }
''';
}

String $staticSetters(BindgenContext ctx, ClassElement element) {
  return element.accessors
      .where((e) => e.isStatic && e.isSetter && !e.isPrivate)
      .map((e) => _$staticSetter(ctx, element, e))
      .join('\n');
}

String _$staticSetter(
    BindgenContext ctx, ClassElement element, PropertyAccessorElement setter) {
  return '''
  /// Wrapper for the [${element.name}.${setter.name}] setter
  static \$Value? set\$${setter.name}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    ${element.name}.${setter.name} = args[0]!.\$value;
    return null;
  }
''';
}
