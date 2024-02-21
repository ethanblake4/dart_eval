import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String $constructors(ClassElement element) {
  return element.constructors.map((e) => _$constructor(element, e)).join('\n');
}

String _$constructor(ClassElement element, ConstructorElement constructor) {
  final name = constructor.name.isEmpty ? 'new' : constructor.name;
  final namedConstructor =
      constructor.name.isNotEmpty ? '.${constructor.name}' : '';
  final fullyQualifiedConstructorId = '${element.name}$namedConstructor';

  return '''
  /// Wrapper for the [${element.name}.$name] constructor
  static \$Value? \$$name(Runtime runtime, \$Value? thisValue, List<\$Value?> args) {
    return \$${element.name}.wrap(
      $fullyQualifiedConstructorId(
        ${argumentAccessors(constructor.parameters)}
      ),
    );
  }
''';
}

String $staticMethods(BindgenContext ctx, ClassElement element) {
  return element.methods
      .where((e) => e.isStatic)
      .map((e) => _$staticMethod(ctx, element, e))
      .join('\n');
}

String _$staticMethod(
    BindgenContext ctx, ClassElement element, MethodElement method) {
  return '''
  /// Wrapper for the [${element.name}.${method.name}] method
  static \$Value? \$${method.name}(Runtime runtime, \$Value? target, List<\$Value?> args) {
    final value = ${element.name}.${method.name}(
      ${argumentAccessors(method.parameters)}
    );
    return ${wrapVar(ctx, method.returnType, "value")};
  }
''';
}

String $staticGetters(BindgenContext ctx, ClassElement element) {
  return element.accessors
      .where((e) => e.isStatic && e.isGetter)
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
