import 'package:dart_eval/src/eval/compiler/compiler.dart';
import 'package:dart_eval/dart_eval_bridge.dart';

/// A registry of compile-time bridge declarations. Implemented by [Compiler]
/// and [BridgeSerializer].
abstract class BridgeDeclarationRegistry {
  void defineBridgeClass(BridgeClassDef classDef);

  /// Define a bridged enum definition to be used when compiling.
  void defineBridgeEnum(BridgeEnumDef enumDef);

  /// Add a unit source to the list of additional sources which will be compiled
  /// alongside the packages specified in [compile].
  void addSource(DartSource source);

  /// Define a bridged top-level function declaration.
  void defineBridgeTopLevelFunction(BridgeFunctionDeclaration function);

  /// Add a mapping from a library URI to an exported library URI.
  void addExportedLibraryMapping(String libraryUri, String exportUri);
}
