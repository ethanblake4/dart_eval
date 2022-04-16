import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration/function.dart';

class BridgeDeclaration {
  const BridgeDeclaration();
}

class DeclarationOrBridge<T extends Declaration, R extends BridgeDeclaration> {
  DeclarationOrBridge({this.declaration, this.bridge}) : assert(declaration != null || bridge != null);

  T? declaration;
  R? bridge;

  bool get isBridge => bridge != null;
}

class BridgeFunctionDeclaration extends BridgeDeclaration {
  const BridgeFunctionDeclaration(this.library, this.name, this.function);

  final BridgeFunctionDescriptor function;
  final String library;
  final String name;
}