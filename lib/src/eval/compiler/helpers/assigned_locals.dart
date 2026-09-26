import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Local writes that invalidate allocation facts or earlier type promotions.
Set<String> assignedLocalNames(Iterable<AstNode> nodes) {
  final collector = _AssignedLocalNames();
  for (final node in nodes) {
    node.accept(collector);
  }
  return collector.names;
}

/// Collects the names of locals an AST subtree assigns to (assignments,
/// `++`/`--`, `for (x in ...)` on an existing variable). Function bodies are
/// skipped — they assign through capture cells, not the local binding.
class _AssignedLocalNames extends GeneralizingAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.leftHandSide is SimpleIdentifier) {
      names.add((node.leftHandSide as SimpleIdentifier).name);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if ((node.operator.lexeme == '++' || node.operator.lexeme == '--') &&
        node.operand is SimpleIdentifier) {
      names.add((node.operand as SimpleIdentifier).name);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operand is SimpleIdentifier) {
      names.add((node.operand as SimpleIdentifier).name);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    names.add(node.identifier.name);
    super.visitForEachPartsWithIdentifier(node);
  }
}
