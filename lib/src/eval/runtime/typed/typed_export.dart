/// Public declaration metadata used to bind host arguments by source name.
final class TypedExport {
  TypedExport(
    this.library,
    this.name,
    this.functionId, {
    required List<TypedExportParameter> parameters,
    this.generativeConstructorRuntimeTypeId = -1,
  }) : parameters = List.unmodifiable(parameters);

  final String library;
  final String name;
  final int functionId;
  final List<TypedExportParameter> parameters;

  /// The hidden runtime-type argument appended to a generative constructor.
  /// A negative value means this export has no hidden constructor argument.
  final int generativeConstructorRuntimeTypeId;
}

/// The declared type is separate from its machine argument representation.
final class TypedExportParameter {
  const TypedExportParameter(
    this.name, {
    required this.isRequired,
    required this.nullable,
    required this.typeName,
    required this.typeLibrary,
    this.runtimeTypeId = -1,
    this.defaultValue,
  });

  final String name;
  final bool isRequired;
  final bool nullable;
  final String typeName;
  final String typeLibrary;
  final int runtimeTypeId;
  final Object? defaultValue;
}
