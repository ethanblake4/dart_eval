import 'package:dart_eval/dart_eval_bridge.dart';

/// A [BridgeDeclarationRegistry] which serializes registered declarations to a
/// JSON object. Serialized declarations can be loaded with the dart_eval CLI.
class BridgeSerializer
    implements BridgeDeclarationRegistry, EvalPluginRegistry {
  final List<BridgeClassDef> _classes = [];
  final List<BridgeEnumDef> _enums = [];
  final List<BridgeFunctionDeclaration> _functions = [];
  final List<DartSource> _sources = [];
  final Map<String, String> _exportedLibMappings = {};

  @override
  void addPlugin(EvalPlugin plugin) {
    plugin.configureForCompile(this);
  }

  @override
  void addSource(DartSource source) {
    _sources.add(source);
  }

  @override
  void defineBridgeClass(BridgeClassDef classDef) {
    _classes.add(classDef);
  }

  @override
  void defineBridgeEnum(BridgeEnumDef enumDef) {
    _enums.add(enumDef);
  }

  @override
  void defineBridgeTopLevelFunction(BridgeFunctionDeclaration function) {
    _functions.add(function);
  }

  @override
  void addExportedLibraryMapping(String libraryUri, String exportUri) {
    _exportedLibMappings[libraryUri] = exportUri;
  }

  /// Serialize all declarations to a JSON object.
  Map<String, dynamic> serialize() {
    return {
      'classes': _classes.map((e) => e.toJson()).toList(),
      'enums': _enums.map((e) => e.toJson()).toList(),
      'functions': _functions.map((e) => e.toJson()).toList(),
      'sources': _sources
          .map((e) => {'uri': e.uri.toString(), 'source': e.toString()})
          .toList(),
      'exportedLibMappings': _exportedLibMappings,
    };
  }
}
