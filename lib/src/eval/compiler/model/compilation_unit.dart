import 'package:analyzer/dart/ast/ast.dart';

/// This class represents a parsed Dart source file (AST), but not yet parsed
/// into a library (library). In Dart, every source file is a part of or an
/// entire library, depending on the existence of `part` directives.
///
/// DartCompilationUnit is an intermediate stage of source code compilation,
/// after the Dart analyzer has parsed the source code into an AST, but before
/// libraries are created from the AST declarations.
class DartCompilationUnit {
  DartCompilationUnit(
    this.uri, {
    required this.imports,
    required this.exports,
    required this.parts,
    required this.declarations,
    this.library,
    this.partOf,
  });

  /// A `package`, `dart`, or `file` URI identifying the source file,
  /// such as 'package:example/main.dart'
  final Uri uri;

  /// Library directive for source code that starts with "library *****"
  final LibraryDirective? library;

  /// Corresponds to 'part of' syntax, only supports one
  final PartOfDirective? partOf;

  /// Package imports
  final List<ImportDirective> imports;

  /// Package exports
  final List<ExportDirective> exports;

  /// `part` syntax
  /// Relationship between `part` and `part of`:
  /// https://stackoverflow.com/questions/67096135/how-to-use-part-or-part-of-in-dart
  final List<PartDirective> parts;

  /// Various specific code declarations for eg. classes and functions
  final List<CompilationUnitMember> declarations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartCompilationUnit &&
          runtimeType == other.runtimeType &&
          uri == other.uri;

  @override
  int get hashCode => uri.hashCode;
}
