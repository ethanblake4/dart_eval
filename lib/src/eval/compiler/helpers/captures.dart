import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'pattern_bindings.dart';
import 'primary_constructor.dart';

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
  /// Constant references can be rematerialized outside their declaring graph,
  /// including optional defaults, without capturing an enclosing SSA value.
  final lexicalConstants = <SimpleIdentifier, VariableDeclaration>{};
  int _defaultDepth = 0;
  final captured = <AstNode>{};
  final declaringFunctions = <AstNode, AstNode>{};
  final assignedDeclarations = <AstNode>{};
  final capturedCaseBodies = <SwitchMember, Set<String>>{};
  final _patternBindings = <AstNode, List<DeclaredVariablePattern>>{};

  /// Names written inside each closure, keyed by the closure node — a
  /// write takes flow-analysis effect at the point the closure is
  /// created (or, for a closure that is an invocation argument, after
  /// the invocation completes).
  final writes = <AstNode, Set<String>>{};
  final free = <AstNode, Set<String>>{};
  final unresolved = <AstNode, Set<String>>{};
  final _scopes = <Map<String, (AstNode, AstNode)>>[];
  final _functions = <AstNode>[];
  final _members = <Set<String>>[];
  final _primaryInitializers = <Expression>{};
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
      declaringFunctions[declaration] = _functions.last;
    }
  }

  void _use(String name, {bool setter = false, SimpleIdentifier? source}) {
    (AstNode, AstNode)? binding;
    for (final scope in _scopes.reversed) {
      binding = scope[name];
      if (binding != null) break;
    }
    if (source != null) {
      if (binding?.$1 case VariableDeclaration declaration
          when declaration.isConst) {
        lexicalConstants[source] = declaration;
      }
    }
    if (_defaultDepth != 0) return;
    if (binding == null &&
        name != '#this' &&
        _members.isNotEmpty &&
        _members.last.contains(name)) {
      _use('#this');
      return;
    }
    if (binding == null) {
      for (final function in _functions.where(
        (node) => node is FunctionExpression || node is VariableDeclaration,
      )) {
        unresolved.putIfAbsent(function, () => {}).add(name);
      }
      return;
    }
    final owner = _functions.indexOf(binding.$2);
    if (setter) {
      assignedDeclarations.addAll(_patternBindings[binding.$1] ?? [binding.$1]);
    }
    if (owner == _functions.length - 1) return;
    final declaration = binding.$1;
    if (declaration is SwitchMember) {
      capturedCaseBodies.putIfAbsent(declaration, () => {}).add(name);
    } else {
      captured.addAll(_patternBindings[declaration] ?? [declaration]);
    }
    for (final function in _functions.skip(owner + 1)) {
      if (function is FunctionExpression || function is VariableDeclaration) {
        free.putIfAbsent(function, () => {}).add(name);
        if (setter) {
          writes.putIfAbsent(function, () => {}).add(name);
        }
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
    // Defaults resolve in the enclosing lexical scope, before formal names
    // become visible. Their constant references do not require captures.
    _defaultDepth++;
    try {
      for (final parameter in parameters?.parameters ?? <FormalParameter>[]) {
        parameter.defaultClause?.value.accept(this);
      }
    } finally {
      _defaultDepth--;
    }
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
      // Initializing formals bind names only in the initializer list. In
      // the body those names refer to fields and closures must capture this.
      if (node is ConstructorDeclaration) {
        for (final parameter in node.parameters.parameters) {
          if (parameter is FieldFormalParameter ||
              parameter is SuperFormalParameter) {
            _scopes.last.remove(parameter.name!.lexeme);
          }
        }
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
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final declarationInitializers = <Expression>[];
    if (isLoweredPrimaryConstructor(node)) {
      final owner = node.parent!.parent as ClassDeclaration;
      for (final field in owner.body.members.whereType<FieldDeclaration>()) {
        if (field.isStatic || field.fields.isLate) continue;
        for (final variable in field.fields.variables) {
          final initializer = variable.initializer;
          if (initializer != null) declarationInitializers.add(initializer);
        }
      }
      _primaryInitializers.addAll(declarationInitializers);
    }
    _function(
      node,
      node.parameters,
      node.body,
      instance: true,
      initializers: [...declarationInitializers, ...node.initializers],
    );
  }

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
  void visitForElement(ForElement node) =>
      _scope(() => super.visitForElement(node));
  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    node.iterable.accept(this);
    _declare(node.loopVariable.name.lexeme, node.loopVariable);
  }

  void _pattern(DartPattern pattern) {
    final declarations = <String, List<DeclaredVariablePattern>>{};
    for (final declaration in patternDeclarations(pattern)) {
      declarations
          .putIfAbsent(declaration.name.lexeme, () => [])
          .add(declaration);
    }
    for (final entries in declarations.values) {
      for (final declaration in entries) {
        _patternBindings[declaration] = entries;
      }
    }
    pattern.accept(this);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) =>
      _declare(node.name.lexeme, node);

  @override
  void visitAssignedVariablePattern(AssignedVariablePattern node) =>
      _use(node.name.lexeme, setter: true);

  @override
  void visitGuardedPattern(GuardedPattern node) {
    _pattern(node.pattern);
    node.whenClause?.expression.accept(this);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    _pattern(node.pattern);
    node.expression.accept(this);
  }

  @override
  void visitForEachPartsWithPattern(ForEachPartsWithPattern node) {
    node.iterable.accept(this);
    _pattern(node.pattern);
  }

  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);
    _scope(() {
      node.caseClause?.guardedPattern.accept(this);
      node.thenStatement.accept(this);
    });
    node.elseStatement?.accept(this);
  }

  @override
  void visitIfElement(IfElement node) {
    node.expression.accept(this);
    _scope(() {
      node.caseClause?.guardedPattern.accept(this);
      node.thenElement.accept(this);
    });
    node.elseElement?.accept(this);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) => _scope(() {
    node.guardedPattern.accept(this);
    node.expression.accept(this);
  });

  @override
  void visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);
    var start = 0;
    while (start < node.members.length) {
      var end = start;
      while (end + 1 < node.members.length &&
          node.members[end].statements.isEmpty) {
        end++;
      }
      final body = node.members[end];
      if (start == end) {
        _scope(() {
          if (body is SwitchPatternCase) body.guardedPattern.accept(this);
          if (body is SwitchCase) body.expression.accept(this);
          for (final statement in body.statements) {
            statement.accept(this);
          }
        });
      } else {
        final names = <String>{};
        for (var i = start; i <= end; i++) {
          final member = node.members[i];
          _scope(() {
            if (member is SwitchPatternCase) {
              member.guardedPattern.accept(this);
              names.addAll(
                patternDeclarations(
                  member.guardedPattern.pattern,
                ).map((declaration) => declaration.name.lexeme),
              );
            } else if (member is SwitchCase) {
              member.expression.accept(this);
            }
          });
        }
        _scope(() {
          for (final name in names) {
            _declare(name, body);
          }
          for (final statement in body.statements) {
            statement.accept(this);
          }
        });
      }
      start = end + 1;
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _declare(node.name.lexeme, node);
    final initializer = node.initializer;
    // Primary declaration initializers were visited in constructor scope.
    if (initializer != null && !_primaryInitializers.contains(initializer)) {
      final parent = node.parent;
      final deferred =
          parent is VariableDeclarationList &&
          parent.lateKeyword != null &&
          _functions.isNotEmpty;
      if (deferred) _functions.add(node);
      initializer.accept(this);
      if (deferred) _functions.removeLast();
    }
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
    final setter = node.inSetterContext();
    final parent = node.parent;
    if (parent is PropertyAccess && identical(parent.propertyName, node) ||
        parent is PrefixedIdentifier && identical(parent.identifier, node) ||
        parent is MethodInvocation &&
            parent.target != null &&
            identical(parent.methodName, node) ||
        parent is Label) {
      return;
    }
    _use(node.name, setter: setter, source: node);
  }
}
