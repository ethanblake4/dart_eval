import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class TreeShakeVisitor extends RecursiveAstVisitor<TreeShakeContext?> {
  final TreeShakeContext ctx = TreeShakeContext();

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
  TreeShakeContext? visitFieldDeclaration(FieldDeclaration node) {
    // Capturar o tipo dos campos
    if (node.fields.type != null) {
      node.fields.type!.accept(this);
    }
    super.visitFieldDeclaration(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitFormalParameterList(FormalParameterList node) {
    // Capturar tipos de parâmetros
    for (final parameter in node.parameters) {
      if (parameter is DefaultFormalParameter) {
        final param = parameter.parameter;
        if (param is SimpleFormalParameter && param.type != null) {
          param.type!.accept(this);
        }
      } else if (parameter is SimpleFormalParameter && parameter.type != null) {
        parameter.type!.accept(this);
      }
    }
    super.visitFormalParameterList(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitConstructorDeclaration(ConstructorDeclaration node) {
    // Capturar tipos de parâmetros do construtor
    node.parameters.accept(this);

    super.visitConstructorDeclaration(node);
    return ctx;
  }

  @override
  TreeShakeContext? visitVariableDeclarationList(VariableDeclarationList node) {
    // Capturar tipos de variáveis locais
    if (node.type != null) {
      node.type!.accept(this);
    }
    super.visitVariableDeclarationList(node);
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
  TreeShakeContext? visitSimpleIdentifier(SimpleIdentifier node) {
    output(node.name);
    super.visitSimpleIdentifier(node);
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
