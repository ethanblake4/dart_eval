import 'package:analyzer/dart/element/element2.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/permission.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $constructors(BindgenContext ctx, ClassElement2 element,
    {bool isBridge = false}) {
  return element.constructors2
      .where(
          (cstr) => !cstr.isPrivate && (cstr.isFactory || !element.isAbstract))
      .map((e) => _$constructor(ctx, element, e, isBridge: isBridge))
      .join('\n');
}

String _$constructor(
    BindgenContext ctx, ClassElement2 element, ConstructorElement2 constructor,
    {bool isBridge = false}) {
  final name = constructor.name3 ?? '';
  final namedConstructor =
      constructor.name3 != null && constructor.name3 != 'new'
          ? '.${constructor.name3}'
          : '';
  final fullyQualifiedConstructorId = isBridge
      ? '\$${element.name3}\$bridge$namedConstructor'
      : '${element.name3}$namedConstructor';

  /*final oConstructor = constructor;

  final paramMapping = <String, String>{};
  for (var i = 0; i < constructor.formalParameters.length; i++) {
    final param = constructor.formalParameters[i];
    paramMapping[param.name3!] = param.name3!;
  }

  while (constructor.redirectedConstructor2 != null) {
    constructor = constructor.redirectedConstructor2!;
    for (var i = 0; i < constructor.formalParameters.length; i++) {
      final param = constructor.formalParameters[i];
      final oParam = oConstructor.formalParameters[i];
      paramMapping[param.name3!] = oParam.name3!;
    }
  }*/

  return '''
  /// ${isBridge ? 'Proxy' : 'Wrapper'} for the [${element.name3}.$name] constructor
  static \$Value? \$$name(Runtime runtime, \$Value? thisValue, List<\$Value?> args) {
    return ${!isBridge ? '\$${element.name3}.wrap(' : ''}
      $fullyQualifiedConstructorId(
        ${argumentAccessors(ctx, constructor.formalParameters)}
      ${!isBridge ? '),' : ''}
    );
  }
''';
}

String $staticMethods(BindgenContext ctx, InterfaceElement2 element) {
  return element.methods2
      .where((e) => e.isStatic && !e.isOperator && !e.isPrivate)
      .map((e) => _$staticMethod(ctx, element, e))
      .join('\n');
}

String _$staticMethod(
    BindgenContext ctx, InterfaceElement2 element, MethodElement2 method) {
  return '''
  /// Wrapper for the [${element.name3}.${method.name3}] method
  static \$Value? \$${method.name3}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    ${assertMethodPermissions(method)}
    final value = ${element.name3}.${method.name3}(
      ${argumentAccessors(ctx, method.formalParameters)}
    );
    return ${wrapVar(ctx, method.returnType, "value")};
  }
''';
}

String $staticGetters(BindgenContext ctx, InterfaceElement2 element) {
  return element.getters2
      .where((e) =>
          e.isStatic &&
          !e.isPrivate &&
          (e.nonSynthetic2 is! FieldElement2 ||
              !(e.nonSynthetic2 as FieldElement2).isEnumConstant))
      .map((e) => _$staticGetter(ctx, element, e))
      .join('\n');
}

String _$staticGetter(BindgenContext ctx, InterfaceElement2 element,
    PropertyAccessorElement2 getter) {
  return '''
  /// Wrapper for the [${element.name3}.${getter.name3}] getter
  static \$Value? \$${getter.name3}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    final value = ${element.name3}.${getter.name3};
    return ${wrapVar(ctx, getter.returnType, "value")};
  }
''';
}

String $staticSetters(BindgenContext ctx, InterfaceElement2 element) {
  return element.setters2
      .where((e) => e.isStatic && !e.isPrivate)
      .map((e) => _$staticSetter(ctx, element, e))
      .join('\n');
}

String _$staticSetter(BindgenContext ctx, InterfaceElement2 element,
    PropertyAccessorElement2 setter) {
  return '''
  /// Wrapper for the [${element.name3}.${setter.name3}] setter
  static \$Value? set\$${setter.name3}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    ${element.name3}.${setter.name3} = args[0]!.\$value;
    return null;
  }
''';
}
