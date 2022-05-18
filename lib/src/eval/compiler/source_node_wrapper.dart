import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';

/// A source node wrapper allows you to, at compile time, 'listen' for constructor invocations of classes
/// conforming to a certain bridge type, and surround them with invocations of another class, using a
/// child parameter as well as parameters derived from the original invocation's [AstNode]
class SourceNodeWrapper {
  SourceNodeWrapper(
      {required this.listenType, required this.wrapperType, required this.constructor, required this.buildArguments});

  final BridgeTypeRef listenType;
  final BridgeTypeRef wrapperType;
  final String constructor;
  /// Return a list of (positional only) arguments. Use null to indicate the child.
  final List<BuiltinValue> Function(AstNode node) buildArguments;
}
