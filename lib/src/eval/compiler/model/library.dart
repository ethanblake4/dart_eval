import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';

class Library {
  Library(this.uri,
      {required this.imports,
      required this.exports,
      required this.declarations,
      this.library});

  /// A `package`, `dart`, or `file` URI
  final Uri uri;

  final String? library;

  final List<ImportDirective> imports;
  final List<ExportDirective> exports;

  final List<DeclarationOrBridge> declarations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Library && runtimeType == other.runtimeType && uri == other.uri;

  @override
  int get hashCode => uri.hashCode;

  Library copyWith({List<DeclarationOrBridge>? declarations}) {
    return Library(uri,
        library: library,
        imports: imports,
        exports: exports,
        declarations: declarations ?? this.declarations);
  }
}
