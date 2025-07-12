import 'package:analyzer/dart/element/element2.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $constructors(BindgenContext ctx, ClassElement2 element, {bool isBridge = false}) {
  return element.constructors2
      .where((cstr) => !cstr.isPrivate && !cstr.isSynthetic && (cstr.isFactory || !element.isAbstract))
      .map((e) => _$constructor(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String _$constructor(
    BindgenContext ctx, ClassElement2 element, ConstructorElement2 constructor, {bool isBridge = false}) {
  final name = constructor.displayName.isEmpty ? 'new' : constructor.displayName;
  final namedConstructor =
      constructor.displayName.isNotEmpty ? '.${constructor.displayName}' : '';
  final fullyQualifiedConstructorId = isBridge ? 
    '\$${element.displayName}\$bridge$namedConstructor' :
    '${element.displayName}$namedConstructor';

  final oConstructor = constructor;

  final paramMapping = <String, String>{};
  for (var i = 0; i < constructor.formalParameters.length; i++) {
    final param = constructor.formalParameters[i];
    paramMapping[param.displayName] = param.displayName;
  }

  while (constructor.redirectedConstructor2 != null) {
    constructor = constructor.redirectedConstructor2!;
    for (var i = 0; i < constructor.formalParameters.length; i++) {
      final param = constructor.formalParameters[i];
      final oParam = oConstructor.formalParameters[i];
      paramMapping[param.displayName] = oParam.displayName;
    }
  }

  return '''
  /// ${isBridge ? 'Proxy' : 'Wrapper'} for the [${element.displayName}.$name] constructor
  static \$Value? \$$name(Runtime runtime, \$Value? thisValue, List<\$Value?> args) {
    return ${!isBridge ? '\$${element.displayName}.wrap(' : ''}
      $fullyQualifiedConstructorId(
        ${argumentAccessors(ctx, constructor.formalParameters)}
      ${!isBridge ? '),' : ''}
    );
  }
''';
}

String $staticMethods(BindgenContext ctx, ClassElement2 element) {
  return element.methods2
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => _$staticMethod(ctx, element, e))
      .join('\n');
}

String _$staticMethod(
    BindgenContext ctx, ClassElement2 element, MethodElement2 method) {
  return '''
  /// Wrapper for the [${element.displayName}.${method.displayName}] method
  static \$Value? \$${method.displayName}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    ${assertMethodPermissions(method)}
    final value = ${element.displayName}.${method.displayName}(
      ${argumentAccessors(ctx, method.formalParameters)}
    );
    return ${wrapVar(ctx, method.returnType, "value")};
  }
''';
}

String $staticGetters(BindgenContext ctx, ClassElement2 element) {
  return element.getters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => _$staticGetter(ctx, element, e))
      .join('\n');
}

String _$staticGetter(
    BindgenContext ctx, ClassElement2 element, PropertyAccessorElement2 getter) {
  return '''
  /// Wrapper for the [${element.displayName}.${getter.displayName}] getter
  static \$Value? \$${getter.displayName}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    final value = ${element.displayName}.${getter.displayName};
    return ${wrapVar(ctx, getter.returnType, "value")};
  }
''';
}

String $staticSetters(BindgenContext ctx, ClassElement2 element) {
  return element.setters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => _$staticSetter(ctx, element, e))
      .join('\n');
}

String _$staticSetter(
    BindgenContext ctx, ClassElement2 element, PropertyAccessorElement2 setter) {
  return '''
  /// Wrapper for the [${element.displayName}.${setter.displayName}] setter
  static \$Value? set\$${setter.displayName}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    ${element.displayName}.${setter.displayName} = args[0]!.\$value;
    return null;
  }
''';
}
