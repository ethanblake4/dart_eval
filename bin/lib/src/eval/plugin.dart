import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

/// A plugin that can configure compile-time and runtime code / bindings
/// for dart_eval.
///
/// The presence of a unique [identifier] allows dart_eval to cache certain
/// results of applying a plugin, improving performance for subsequent
/// compilations.
abstract class EvalPlugin {
  /// Unique identifier for this plugin. In most cases this should be the
  /// package name.
  String get identifier;

  /// Configure this plugin for use in a dart_eval [Compiler] or
  /// [BridgeSerializer].
  void configureForCompile(BridgeDeclarationRegistry registry);

  /// Configure this plugin for use in a dart_eval [Runtime].
  void configureForRuntime(Runtime runtime);
}

/// A registry of [EvalPlugin]s.
abstract class EvalPluginRegistry {
  /// Register a plugin with this registry.
  void addPlugin(EvalPlugin plugin);
}
