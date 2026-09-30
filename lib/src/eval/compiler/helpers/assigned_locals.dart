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

/// Only repeated evaluations can invalidate a loop header's initial state.
/// Initializers and for-in iterable expressions run once before that header.
Set<String> assignedLoopLocalNames(Iterable<AstNode> nodes) {
  final repeated = <AstNode>[];
  final targets = <String>{};
  for (final node in nodes) {
    final (parts, body) = switch (node) {
      ForStatement() => (node.forLoopParts, node.body),
      ForElement() => (node.forLoopParts, node.body),
      _ => (null, node),
    };
    repeated.add(body);
    if (parts is ForParts) {
      if (parts.condition != null) repeated.add(parts.condition!);
      repeated.addAll(parts.updaters);
    } else if (parts is ForEachPartsWithIdentifier) {
      targets.add(parts.identifier.name);
    }
  }
  final collector = _LoopAssignedLocalNames();
  for (final node in repeated) {
    node.accept(collector);
  }
  return collector.names..addAll(targets);
}

/// Writes to locals declared inside the repeated code do not overwrite a
/// binding that already exists at the loop header, even when names coincide.
class _LoopAssignedLocalNames extends _AssignedLocalNames {
  final _scopes = <Set<String>>[{}];

  void _scope(void Function() visit) {
    _scopes.add({});
    visit();
    _scopes.removeLast();
  }

  @override
  void recordWrite(String name) {
    if (!_scopes.any((scope) => scope.contains(name))) super.recordWrite(name);
  }

  @override
  void visitBlock(Block node) => _scope(() => super.visitBlock(node));
  @override
  void visitForStatement(ForStatement node) =>
      _scope(() => super.visitForStatement(node));
  @override
  void visitForElement(ForElement node) =>
      _scope(() => super.visitForElement(node));
  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);
    _scope(() {
      node.caseClause?.accept(this);
      node.thenStatement.accept(this);
    });
    node.elseStatement?.accept(this);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) =>
      _scope(() => super.visitSwitchPatternCase(node));
  @override
  void visitSwitchCase(SwitchCase node) =>
      _scope(() => super.visitSwitchCase(node));
  @override
  void visitSwitchDefault(SwitchDefault node) =>
      _scope(() => super.visitSwitchDefault(node));
  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) =>
      _scope(() => super.visitSwitchExpressionCase(node));
  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _scopes.last.add(node.name.lexeme);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    _scopes.last.add(node.name.lexeme);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.iterable.accept(this);
    _scopes.last.add(node.loopVariable.name.lexeme);
  }

  @override
  void visitCatchClause(CatchClause node) => _scope(() {
    if (node.exceptionParameter != null) {
      _scopes.last.add(node.exceptionParameter!.name.lexeme);
    }
    if (node.stackTraceParameter != null) {
      _scopes.last.add(node.stackTraceParameter!.name.lexeme);
    }
    super.visitCatchClause(node);
  });
}

/// The labels `continue` statements under [nodes] target — a `continue L`
/// back edge re-enters `L:`'s body, so writes along it defeat the entry's
/// promotions and recorded conditions.
Set<String> continueTargetNames(Iterable<AstNode> nodes) {
  final collector = _ContinueTargetNames();
  for (final node in nodes) {
    node.accept(collector);
  }
  return collector.names;
}

class _ContinueTargetNames extends GeneralizingAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitContinueStatement(ContinueStatement node) {
    final label = node.label;
    if (label != null) names.add(label.name.lexeme);
    super.visitContinueStatement(node);
  }
}

/// Collects the names of locals an AST subtree assigns to (assignments,
/// `++`/`--`, `for (x in ...)` on an existing variable). Function bodies are
/// skipped — they assign through capture cells, not the local binding.
class _AssignedLocalNames extends GeneralizingAstVisitor<void> {
  final Set<String> names = {};
  void recordWrite(String name) => names.add(name);

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.leftHandSide is SimpleIdentifier) {
      recordWrite((node.leftHandSide as SimpleIdentifier).name);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if ((node.operator.lexeme == '++' || node.operator.lexeme == '--') &&
        node.operand is SimpleIdentifier) {
      recordWrite((node.operand as SimpleIdentifier).name);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operand is SimpleIdentifier) {
      recordWrite((node.operand as SimpleIdentifier).name);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    recordWrite(node.identifier.name);
    super.visitForEachPartsWithIdentifier(node);
  }
}
