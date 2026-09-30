import 'package:analyzer/dart/ast/ast.dart';

/// Includes declarations in both arms of an OR pattern, preserving their nodes
/// so capture analysis can mark every declaration of the same binding.
Iterable<DeclaredVariablePattern> patternDeclarations(AstNode pattern) sync* {
  if (pattern is DeclaredVariablePattern && pattern.name.lexeme != '_') {
    yield pattern;
  }
  for (final child in pattern.childEntities.whereType<AstNode>()) {
    yield* patternDeclarations(child);
  }
}
