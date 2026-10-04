import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class TreeShakeVisitor extends RecursiveAstVisitor<TreeShakeContext?> {
  final TreeShakeContext ctx = TreeShakeContext();

  @override
  TreeShakeContext? visitSimpleIdentifier(SimpleIdentifier node) {
    output(node.name);
    super.visitSimpleIdentifier(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitNamedType(NamedType node) {
    output(node.name.lexeme);
    // `C.named()` can parse C as an import prefix, whose name is a token
    // rather than a SimpleIdentifier child. Keep both ambiguous segments.
    output(node.importPrefix?.name.lexeme);
    super.visitNamedType(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitPatternField(PatternField node) {
    if (node.parent is ObjectPattern) output(node.effectiveName);
    super.visitPatternField(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitComment(Comment node) {
    // Ignore comments
    return ctx;
  }

  void output(String? s) {
    if (s == null) return;
    ctx.identifiers.add(s);
  }
}

class TreeShakeContext {
  TreeShakeContext();

  Set<String> identifiers = {};
}
