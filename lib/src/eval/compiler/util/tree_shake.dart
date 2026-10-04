import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import '../helpers/captures.dart';

// Keep this pre-lowering scan separate from code generation's capture cache.
final _lexicalReferences = Expando<Set<SimpleIdentifier>>();

bool _isLexicallyBound(SimpleIdentifier node) {
  AstNode root = node;
  while (root.parent != null) {
    root = root.parent!;
  }
  final references = _lexicalReferences[root] ??=
      (CaptureAnalysis()..scan(root)).lexicalReferences;
  return references.contains(node);
}

class TreeShakeVisitor extends RecursiveAstVisitor<TreeShakeContext?> {
  final TreeShakeContext ctx = TreeShakeContext();

  @override
  TreeShakeContext? visitSimpleIdentifier(SimpleIdentifier node) {
    output(node.name);
    if (!node.inDeclarationContext() &&
        node.parent is! Label &&
        node.parent is! ConstructorName &&
        !_isLexicallyBound(node)) {
      ctx.memberReferences.add(node.name);
    }
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
    if (node.parent is ObjectPattern) {
      output(node.effectiveName);
      if (node.effectiveName case final name?) ctx.memberReferences.add(name);
    }
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
  Set<String> memberReferences = {};
}
