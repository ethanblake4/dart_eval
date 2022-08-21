import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';

/// A Bridge declaration declares an element that is transferrable between the
/// Dart and dart_eval VM.
class BridgeDeclaration {
  const BridgeDeclaration();
}

/// Represents a declaration, which my be a standard Dart declaration or a
/// dart_eval bridge declaration.
class DeclarationOrBridge<T extends Declaration, R extends BridgeDeclaration> {
  DeclarationOrBridge(this.sourceLib, {this.declaration, this.bridge}) : assert(declaration != null || bridge != null);

  int sourceLib;
  T? declaration;
  R? bridge;

  bool get isBridge => bridge != null;
}

/// Represents a bridged function declaration.
class BridgeFunctionDeclaration extends BridgeDeclaration {
  const BridgeFunctionDeclaration(this.library, this.name, this.function);

  final BridgeFunctionDef function;
  final String library;
  final String name;
}
