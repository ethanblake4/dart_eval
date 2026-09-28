import 'package:analyzer/dart/ast/ast.dart';

import '../../shared/library_environment.dart';

/// The first matching conditional URI wins; absent names have an empty value.
String selectedDirectiveUri(UriBasedDirective directive) {
  final configurations = switch (directive) {
    ImportDirective(:final configurations) => configurations,
    ExportDirective(:final configurations) => configurations,
    _ => const <Configuration>[],
  };
  for (final configuration in configurations) {
    final value = sdkLibraryEnvironment[configuration.name.toSource()] ?? '';
    if (value == (configuration.value?.stringValue ?? 'true')) {
      return configuration.uri.stringValue!;
    }
  }
  return directive.uri.stringValue!;
}
