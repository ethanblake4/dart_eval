import 'package:dart_eval/dart_eval_bridge.dart';

class BindgenContext {
  final String filename;
  final String uri;
  final Set<String> imports = {};
  final Set<String> knownTypes = {};
  final Set<String> unknownTypes = {};
  final bool all;
  final Map<String, String> libOverrides = {};
  bool implicitSupers = false;
  final Map<String, List<BridgeDeclaration>> bridgeDeclarations;
  final Map<String, String> exportedLibMappings;

  BindgenContext(this.filename, this.uri,
      {required this.all,
      required this.bridgeDeclarations,
      required this.exportedLibMappings});
}
