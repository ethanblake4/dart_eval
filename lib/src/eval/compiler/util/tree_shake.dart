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
    output(node.name2.lexeme);
    super.visitNamedType(node);
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
