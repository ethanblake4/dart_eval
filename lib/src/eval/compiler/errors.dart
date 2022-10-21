import 'package:dart_eval/source_node_wrapper.dart';
import 'package:dart_eval/src/eval/compiler/context.dart';

class CompileError implements Exception {
  final String message;
  final AstNode? node;
  final int? library;
  final CompilerContext? context;

  const CompileError(this.message, [this.node, this.library, this.context]);

  CompileError copyWithContext(CompilerContext context) {
    return CompileError(message, node, library, context);
  }

  @override
  String toString() {
    if (context != null) {
      return _toStringWithContext(context!);
    }
    return _toString();
  }

  String _toString() {
    return 'CompileError: $message at ${node == null ? "unknown" : '"' + node!.toSource().substring(0, 20) + '..."'}';
  }

  String _toStringWithContext(CompilerContext ctx) {
    String? _library;
    for (final entry in ctx.libraryMap.entries) {
      if (entry.value == (library ?? ctx.library)) {
        _library = entry.key;
      }
    }
    return '${_toString()} (file $_library)';
  }
}

class NotReferencableError extends CompileError {
  const NotReferencableError(String message) : super(message);

  @override
  String toString() {
    return 'NotReferencableError: $message';
  }
}
