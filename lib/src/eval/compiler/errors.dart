import 'dart:math';

import 'package:analyzer/dart/ast/ast.dart';
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
    final src = node?.toSource();
    return 'CompileError: $message at ${src == null ? "unknown" : '"${src.substring(0, min(20, src.length))}${src.length > 20 ? '..."' : '"'}'}';
  }

  String _toStringWithContext(CompilerContext ctx) {
    String? library;
    for (final entry in ctx.libraryMap.entries) {
      if (entry.value == (library ?? ctx.library)) {
        library = entry.key;
      }
    }
    return '${_toString()} (file $library)';
  }
}

class NotReferencableError extends CompileError {
  const NotReferencableError(super.message);

  @override
  String toString() {
    return 'NotReferencableError: $message';
  }
}

class PrefixError extends CompileError {
  const PrefixError({
    AstNode? node,
    int? library,
    CompilerContext? context,
  }) : super("[internal] unexpected prefix", node, library, context);

  @override
  String toString() {
    return 'PrefixError: $message';
  }
}
