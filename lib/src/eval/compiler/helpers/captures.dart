import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final _analyses = Expando<CaptureAnalysis>();
CaptureAnalysis capturesFor(AstNode node) {
  while (node.parent != null) {
    node = node.parent!;
  }
  return _analyses[node] ??= (CaptureAnalysis()..scan(node));
}

/// Resolves lexical bindings before code generation, so conditional closure
/// creation never controls whether a shared cell exists.
class CaptureAnalysis extends RecursiveAstVisitor<void> {
  final captured = <AstNode>{};
  final free = <FunctionExpression, Set<String>>{};
  final unresolved = <FunctionExpression, Set<String>>{};
  final _scopes = <Map<String, (AstNode, AstNode)>>[];
  final _functions = <AstNode>[];
  final _members = <Set<String>>[];
  void scan(AstNode root) => root.accept(this);
  void _scope(void Function() visit) {
    _scopes.add({});
    visit();
    _scopes.removeLast();
  }

  void _declare(String name, AstNode declaration) {
    // `_` is a wildcard: it never binds, so it is never declared.
    if (_functions.isNotEmpty && name != '_') {
      _scopes.last[name] = (declaration, _functions.last);
    }
  }

  void _use(String name) {
    (AstNode, AstNode)? binding;
    for (final scope in _scopes.reversed) {
      binding = scope[name];
      if (binding != null) break;
    }
    if (binding == null &&
        name != '#this' &&
        _members.isNotEmpty &&
        _members.last.contains(name)) {
      _use('#this');
      return;
    }
    if (binding == null) {
      for (final function in _functions.whereType<FunctionExpression>()) {
        unresolved.putIfAbsent(function, () => {}).add(name);
      }
      return;
    }
    final owner = _functions.indexOf(binding.$2);
    if (owner == _functions.length - 1) return;
    captured.add(binding.$1);
    for (final function in _functions.skip(owner + 1)) {
      if (function is FunctionExpression) {
        free.putIfAbsent(function, () => {}).add(name);
      }
    }
  }

  void _function(
    AstNode node,
    FormalParameterList? parameters,
    FunctionBody body, {
    bool instance = false,
    Iterable<AstNode> initializers = const [],
  }) {
    _functions.add(node);
    _scope(() {
      if (instance) _declare('#this', node);
      for (final parameter in parameters?.parameters ?? <FormalParameter>[]) {
        if (parameter.name != null) {
          _declare(parameter.name!.lexeme, parameter);
        }
      }
      for (final initializer in initializers) {
        initializer.accept(this);
      }
      body.accept(this);
    });
    _functions.removeLast();
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _members.add({
      for (final member in node.body.members)
        if (member is MethodDeclaration && !member.isStatic)
          member.name.lexeme
        else if (member is FieldDeclaration && !member.isStatic)
          ...member.fields.variables.map((v) => v.name.lexeme),
    });
    super.visitClassDeclaration(node);
    _members.removeLast();
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _function(node, node.parameters, node.body, instance: !node.isStatic);
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) => _function(
    node,
    node.parameters,
    node.body,
    instance: true,
    initializers: node.initializers,
  );
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_functions.isNotEmpty) _declare(node.name.lexeme, node);
    node.functionExpression.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) =>
      _function(node, node.parameters, node.body);
  @override
  void visitBlock(Block node) => _scope(() => super.visitBlock(node));
  @override
  void visitForStatement(ForStatement node) =>
      _scope(() => super.visitForStatement(node));
  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.iterable.accept(this);
    _declare(node.loopVariable.name.lexeme, node.loopVariable);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _declare(node.name.lexeme, node);
    node.initializer?.accept(this);
  }

  @override
  void visitThisExpression(ThisExpression node) => _use('#this');
  @override
  void visitSuperExpression(SuperExpression node) => _use('#this');
  @override
  void visitNamedType(NamedType node) {}
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) return;
    final parent = node.parent;
    if (parent is PropertyAccess && identical(parent.propertyName, node) ||
        parent is PrefixedIdentifier && identical(parent.identifier, node) ||
        parent is MethodInvocation &&
            parent.target != null &&
            identical(parent.methodName, node) ||
        parent is Label) {
      return;
    }
    _use(node.name);
  }
}
