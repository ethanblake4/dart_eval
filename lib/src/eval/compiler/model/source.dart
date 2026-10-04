import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';
import 'package:dart_eval/src/eval/compiler/model/diagnostic_mode.dart';
import 'package:pub_semver/pub_semver.dart';

/// A unit of Dart source code, from a file or String.
class DartSource {
  DartSource(String uri, String source, {this.languageVersion})
    : uri = Uri.parse(uri),
      stringSource = source,
      fileSource = null;

  DartSource.file(String uri, File file, {this.languageVersion})
    : uri = Uri.parse(uri),
      fileSource = file,
      stringSource = null;

  /// A `package`, `dart`, or `file` URI
  final Uri uri;
  final String? stringSource;
  final File? fileSource;

  /// The package's language version. Omitted sources use analyzer defaults.
  /// A source-level `// @dart` override is handled by the analyzer scanner.
  final Version? languageVersion;

  /// Load the source code from the filesystem or a String and parse it
  /// (internally using [parseString] from the Dart analyzer) into an AST
  DartCompilationUnit load(DiagnosticMode diagnosticMode) => parseDartSource(
    uri,
    toString(),
    diagnosticMode,
    languageVersion: languageVersion,
  );

  @override
  bool operator ==(Object other) {
    if (other is DartSource) {
      return uri == other.uri &&
          stringSource == other.stringSource &&
          fileSource == other.fileSource &&
          languageVersion == other.languageVersion;
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(uri, stringSource, fileSource, languageVersion);

  @override
  String toString() {
    final String source;
    if (stringSource != null) {
      source = stringSource!;
    } else {
      source = fileSource!.readAsStringSync();
    }
    return source;
  }
}

/// Parses source text already loaded by the compiler.
DartCompilationUnit parseDartSource(
  Uri uri,
  String contents,
  DiagnosticMode diagnosticMode, {
  Version? languageVersion,
}) {
  LibraryDirective? libraryDirective;
  PartOfDirective? partOfDirective;

  final imports = <ImportDirective>[];
  final exports = <ExportDirective>[];
  final parts = <PartDirective>[];

  final unit = _parse(uri, contents, diagnosticMode, languageVersion);
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
          'Library $uri must not contain multiple "part of" directives',
        );
      }
      partOfDirective = directive;
    } else if (directive is LibraryDirective) {
      if (libraryDirective != null) {
        throw CompileError(
          'Library $uri must not contain multiple "library" directives',
        );
      }
      libraryDirective = directive;
    }
  }

  if (partOfDirective != null && imports.isNotEmpty) {
    throw CompileError(
      "Library $uri is a part, so it can't have 'import' directives",
    );
  }

  if (partOfDirective != null && exports.isNotEmpty) {
    throw CompileError(
      "Library $uri is a part, so it can't have 'export' directives",
    );
  }

  if (partOfDirective != null && parts.isNotEmpty) {
    throw CompileError(
      "Library $uri is a part, so it can't have 'part' directives",
    );
  }

  return DartCompilationUnit(
    uri,
    imports: imports,
    exports: exports,
    parts: parts,
    declarations: unit.declarations,
    library: libraryDirective,
    partOf: partOfDirective,
  );
}

CompilationUnit _parse(
  Uri uri,
  String source,
  DiagnosticMode diagnosticMode,
  Version? languageVersion,
) {
  const flags = ['variance', 'anonymous-methods'];
  final d = parseString(
    content: source,
    path: uri.toString(),
    throwIfDiagnostics: false,
    // Enable experiments the compiler can parse but doesn't fully implement,
    // so tests exercising the syntax fail on semantics, not on parsing.
    featureSet: languageVersion == null
        ? FeatureSet.latestLanguageVersion(flags: flags)
        : FeatureSet.fromEnableFlags2(
            sdkLanguageVersion: languageVersion,
            flags: flags,
          ),
  );
  if (d.errors.isNotEmpty) {
    for (final error in d.errors) {
      final location = d.lineInfo.getLocation(error.offset);
      final message =
          '${error.message} at $uri:${location.lineNumber}:${location.columnNumber}';
      if (error.severity == Severity.error &&
          (diagnosticMode == DiagnosticMode.throwIfError ||
              diagnosticMode == DiagnosticMode.throwIfErrorOrWarning ||
              diagnosticMode == DiagnosticMode.throwErrorPrintWarnings ||
              diagnosticMode == DiagnosticMode.throwErrorPrintAll)) {
        throw CompileError('Parsing error: $message');
      }
      if (error.severity == Severity.warning &&
          diagnosticMode == DiagnosticMode.throwIfErrorOrWarning) {
        throw CompileError('Parsing warning: $message');
      }
      if (error.severity == Severity.error &&
          diagnosticMode != DiagnosticMode.ignore) {
        print('Parsing error: $message');
      }
      if (error.severity == Severity.warning &&
          (diagnosticMode == DiagnosticMode.printAll ||
              diagnosticMode == DiagnosticMode.printErrorsAndWarnings ||
              diagnosticMode == DiagnosticMode.throwErrorPrintWarnings ||
              diagnosticMode == DiagnosticMode.throwErrorPrintAll)) {
        print('Parsing warning: $message');
      }
      if (error.severity == Severity.info &&
          (diagnosticMode == DiagnosticMode.printAll ||
              diagnosticMode == DiagnosticMode.printErrorsAndWarnings ||
              diagnosticMode == DiagnosticMode.throwErrorPrintWarnings ||
              diagnosticMode == DiagnosticMode.throwErrorPrintAll)) {
        print('Parsing info: $message');
      }
    }
  }
  return d.unit;
}
