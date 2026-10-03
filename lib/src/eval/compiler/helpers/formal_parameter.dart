import 'package:analyzer/dart/ast/ast.dart';

/// The argument name can differ from an initializing formal's field name.
String formalParameterName(FormalParameter parameter) {
  final name = parameter.name?.lexeme ?? '';
  return parameter.isNamed &&
          parameter is FieldFormalParameter &&
          name.startsWith('_')
      ? name.substring(1)
      : name;
}
