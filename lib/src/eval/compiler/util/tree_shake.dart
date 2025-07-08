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
  TreeShakeContext? visitMethodDeclaration(MethodDeclaration node) {
    if (node.returnType != null) {
      node.returnType!.accept(this);
    }
    super.visitMethodDeclaration(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.returnType != null) {
      node.returnType!.accept(this);
    }
    super.visitFunctionDeclaration(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitGenericFunctionType(GenericFunctionType node) {
    if (node.returnType != null) {
      node.returnType!.accept(this);
    }
    super.visitGenericFunctionType(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitNamedType(NamedType node) {
    final typeName = node.name2.lexeme;
    ctx.identifiers.add(typeName);

    final typeArgs = node.typeArguments;
    if (typeArgs != null) {
      for (final arg in typeArgs.arguments) {
        arg.accept(this);
      }
    }

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
