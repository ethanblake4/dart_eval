import 'package:analyzer/dart/ast/ast.dart';

/// A parsed Dart source file that still hasn't been resolved to a library
class DartCompilationUnit {
  DartCompilationUnit(this.uri,
      {required this.imports,
      required this.exports,
      required this.parts,
      required this.declarations,
      this.library,
      this.partOf});

  /// A `package`, `dart`, or `file` URI
  final Uri uri;

  final LibraryDirective? library;
  final PartOfDirective? partOf;

  final List<ImportDirective> imports;
  final List<ExportDirective> exports;
  final List<PartDirective> parts;

  final List<CompilationUnitMember> declarations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DartCompilationUnit && runtimeType == other.runtimeType && uri == other.uri;

  @override
  int get hashCode => uri.hashCode;
}
