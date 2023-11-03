import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';

/// A unit of Dart source code, from a file or String.
class DartSource {
  DartSource(String _uri, String source)
      : uri = Uri.parse(_uri),
        stringSource = source,
        fileSource = null;

  DartSource.file(String _uri, File file)
      : uri = Uri.parse(_uri),
        fileSource = file,
        stringSource = null;

  /// A `package`, `dart`, or `file` URI
  final Uri uri;
  final String? stringSource;
  final File? fileSource;

  /// Load the source code from the filesystem or a String and parse it
  /// (internally using [parseString] from the Dart analyzer) into an AST
  DartCompilationUnit load() {
    LibraryDirective? libraryDirective;
    PartOfDirective? partOfDirective;

    final imports = <ImportDirective>[];
    final exports = <ExportDirective>[];
    final parts = <PartDirective>[];

    final unit = _parse(toString());
    for (final directive in unit.directives) {
      if (directive is ImportDirective) {
        imports.add(directive);
      } else if (directive is ExportDirective) {
        exports.add(directive);
      } else if (directive is PartDirective) {
        parts.add(directive);
      } else if (directive is PartOfDirective) {
        if (partOfDirective != null) {
          throw CompileError(
              'Library $uri must not contain multiple "part of" directives');
        }
        partOfDirective = directive;
      } else if (directive is LibraryDirective) {
        if (libraryDirective != null) {
          throw CompileError(
              'Library $uri must not contain multiple "library" directives');
        }
        libraryDirective = directive;
      }
    }

    if (partOfDirective != null && imports.isNotEmpty) {
      throw CompileError(
          "Library $uri is a part, so it can't have 'import' directives");
    }

    if (partOfDirective != null && exports.isNotEmpty) {
      throw CompileError(
          "Library $uri is a part, so it can't have 'export' directives");
    }

    if (partOfDirective != null && parts.isNotEmpty) {
      throw CompileError(
          "Library $uri is a part, so it can't have 'part' directives");
    }

    return DartCompilationUnit(uri,
        imports: imports,
        exports: exports,
        parts: parts,
        declarations: unit.declarations,
        library: libraryDirective,
        partOf: partOfDirective);
  }

  @override
  bool operator ==(Object other) {
    if (other is DartSource) {
      return uri == other.uri &&
          stringSource == other.stringSource &&
          fileSource == other.fileSource;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(uri, stringSource, fileSource);

  @override
  String toString() {
    final String _source;
    if (stringSource != null) {
      _source = stringSource!;
    } else {
      _source = fileSource!.readAsStringSync();
    }
    return _source;
  }
}

CompilationUnit _parse(String source) {
  final d = parseString(content: source, throwIfDiagnostics: false);
  if (d.errors.isNotEmpty) {
    throw CompileError('Parsing error(s): ${d.errors}');
  }
  return d.unit;
}
