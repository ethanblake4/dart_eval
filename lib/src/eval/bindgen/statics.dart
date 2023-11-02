import 'package:analyzer/dart/element/element.dart';

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
        ${constructor.parameters.asMap().entries.map((e) {
    final index = e.key;
    final parameter = e.value;
    final nullCheck = parameter.isRequired ? '!' : '?';
    final defaultValue =
        parameter.hasDefaultValue ? ' ?? ${parameter.defaultValueCode}' : '';
    final paramName = parameter.isNamed ? '${parameter.name}: ' : '';
    return '${paramName}args[$index]$nullCheck.\$value$defaultValue';
  }).join(',\n')}
      ),
    );
  }
''';
}
