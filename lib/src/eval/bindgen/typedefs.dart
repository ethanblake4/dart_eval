import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';

/// Copies selected typedef declarations verbatim from SDK compilation units.
/// The caller supplies the units containing the library's type aliases.
String extractTypedefSource(Iterable<String> units, Iterable<String> names) {
  final selected = names.toList();
  if (selected.isEmpty) return '';
  if (selected.toSet().length != selected.length) {
    throw const FormatException('Duplicate typedef name in config');
  }
  final wanted = selected.toSet();
  final declarations = <String, String>{};
  for (final source in units) {
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;
    for (final alias in unit.declarations.whereType<TypeAlias>()) {
      if (!wanted.contains(alias.name.lexeme)) continue;
      if (declarations.containsKey(alias.name.lexeme)) {
        throw FormatException('Duplicate typedef ${alias.name.lexeme}');
      }
      declarations[alias.name.lexeme] = source.substring(
        alias.typedefKeyword.offset,
        alias.semicolon.end,
      );
    }
  }
  for (final name in selected) {
    if (!declarations.containsKey(name)) {
      throw FormatException('Typedef $name not found in SDK source');
    }
  }
  return selected.map((name) => declarations[name]!).join('\n');
}

/// Reads only SDK units that own the selected aliases in [library].
String sdkTypedefSourceForLibrary(
  LibraryElement library,
  Iterable<String> names,
) {
  final selected = names.toSet();
  final paths = <String>{};
  for (final alias in library.typeAliases) {
    if (!selected.contains(alias.name)) continue;
    final source = alias.firstFragment.libraryFragment?.source;
    if (source == null) {
      throw FormatException('No source for typedef ${alias.name}');
    }
    paths.add(source.fullName);
  }
  return extractTypedefSource(
    paths.map((path) => File(path).readAsStringSync()),
    names,
  );
}

/// Source of a generated binding file; the CLI's default imports provide
/// [DartSource] when this file is written beside wrapper files.
String emitTypedefDartSource(String uri, String declarations) {
  if (declarations.contains("'''")) {
    throw const FormatException(
      'Typedef source contains a raw string delimiter',
    );
  }
  return "final sdkTypedefsSource = DartSource('$uri', r'''\n$declarations\n''');";
}
