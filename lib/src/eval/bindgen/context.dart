import 'package:analyzer/dart/element/element.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';

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

  /// Sidecar configuration (null when running in annotation/`--all` mode).
  final BindgenConfig? config;

  /// The library config currently being processed.
  BindgenLibraryConfig? libraryConfig;

  /// The class config currently being processed.
  BindgenClassConfig? classConfig;

  /// The resolved library element, used to resolve YAML type names.
  LibraryElement? libraryElement;

  /// dart:core library fallback for type-name resolution.
  LibraryElement? dartCoreLibrary;

  /// Names of type parameters in scope (enclosing class + method).
  Set<String> typeParamNames = const {};

  /// The output file the current class is being generated into. Used to make
  /// hooks-file imports relative.
  String? outputFile;

  BindgenContext(
    this.filename,
    this.uri, {
    required this.all,
    required this.bridgeDeclarations,
    required this.exportedLibMappings,
    this.config,
  });

  /// True when running under a sidecar config (`--config`).
  bool get configMode => config != null;

  /// Per-member config for [name] of [kind] on the current class.
  BindgenMemberConfig? memberConfig(String name, String kind) =>
      classConfig?.memberConfig(kind, name);

  /// Whether [name] (kind: method/getter/setter/field/constructor/static)
  /// should be emitted. Honors `excludeMembers`, per-member `include`,
  /// and `includeObjectMembers` for the Object member set.
  bool memberIncluded(
    String name,
    String kind, {
    bool isObjectMember = false,
  }) {
    if (configMode) {
      final cc = classConfig;
      final mc = cc?.memberConfig(kind, name);
      if (mc != null) return mc.include;
      final excluded = {
        ...libraryConfig?.defaults.excludeMembers ?? const <String>[],
        ...cc?.excludeMembers ?? const <String>[],
      };
      if (excluded.contains(name)) return false;
      if (isObjectMember &&
          !(libraryConfig?.defaults.includeObjectMembers ?? false)) {
        return false;
      }
      return true;
    }
    return !isObjectMember;
  }

  /// Hooks files imported by the current output file, mapped to their import
  /// prefix (`hooks`, `hooks1`, ...).
  final Map<String, String> hooksImports = {};

  /// Import prefix for the current class's `hooks:` file, registering the
  /// import on first use. Returns null when the class has no hooks file.
  String? hooksPrefix() {
    final hooks = classConfig?.hooks ?? libraryConfig?.hooks;
    if (hooks == null) return null;
    return hooksImports.putIfAbsent(
      hooks,
      () => hooksImports.isEmpty ? 'hooks' : 'hooks${hooksImports.length}',
    );
  }
}
