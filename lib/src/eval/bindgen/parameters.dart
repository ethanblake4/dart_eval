import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

String namedParameters({required ExecutableElement element}) {
  final parameters = element.parameters.where((e) => e.isNamed);
  if (parameters.isEmpty) {
    return '';
  }

  return List.generate(parameters.length,
      (index) => _parameterFrom(parameters.elementAt(index))).join('\n');
}

String positionalParameters({required ExecutableElement element}) {
  final parameters = element.parameters.where((e) => e.isPositional);
  if (parameters.isEmpty) {
    return '';
  }

  return List.generate(parameters.length,
      (index) => _parameterFrom(parameters.elementAt(index))).join('\n');
}

String _parameterFrom(ParameterElement parameter) {
  return '''
    BridgeParameter(
      '${parameter.name}',
      BridgeTypeAnnotation(${bridgeTypeRefFromType(parameter.type)}),
      ${parameter.isRequired ? 'true' : 'false'},
    ),
  ''';
}
