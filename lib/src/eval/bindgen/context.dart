import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';

class BindgenContext {
  final String filename;
  final String uri;
  final Set<String> imports = {};
  bool outputIsPart = false;
  final Map<String, String> nativeImports = {};
  final Map<FormalParameterElement, Expression> nativeDefaults = {};

  String nativeName(Element element) {
    if (outputIsPart) return element.name!;
    final library = element.library;
    if (library == null ||
        library.uri.toString() == 'dart:core' ||
        library.uri.toString() == uri) {
      return element.name!;
    }
    if (library.isInSdk) {
      imports.add(library.uri.toString());
      return element.name!;
    }
    final prefix = nativeImports.putIfAbsent(
      library.uri.toString(),
      () => 'bindgenNative${nativeImports.length}',
    );
    return '$prefix.${element.name}';
  }

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

  /// Class currently being emitted; used to inspect member annotations.
  InterfaceElement? classElement;

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

  /// Dart identifier of the wrapper currently being emitted.
  String wrapperName(InterfaceElement element) {
    final name = classConfig?.wrapperName ?? element.name!;
    return wrapperIdentifier(name);
  }

  /// Per-member config for [name] of [kind] on the current class.
  BindgenMemberConfig? memberConfig(String name, String kind) =>
      classConfig?.memberConfig(kind, name);

  /// Whether [name] (kind: method/getter/setter/field/constructor/static)
  /// should be emitted. Honors `excludeMembers`, per-member `include`,
  /// and `includeObjectMembers` for the Object member set.
  bool memberIncluded(String name, String kind, {bool isObjectMember = false}) {
    if (configMode) {
      final cc = classConfig;
      final mc = cc?.memberConfig(kind, name);
      if (cc?.opaque == true) {
        // Genuine opaque mixins have no adapter or member bodies.
        return classElement is ClassElement && mc?.include == true;
      }
      if (mc != null) return mc.include;
      final excluded = {
        ...libraryConfig?.defaults.excludeMembers ?? const <String>[],
        ...cc?.excludeMembers ?? const <String>[],
      };
      if (excluded.contains(name)) return false;
      if ((cc?.mode ?? libraryConfig?.defaults.mode) == 'wrap' &&
          _isProtectedMember(name, kind)) {
        return false;
      }
      if (isObjectMember &&
          !(libraryConfig?.defaults.includeObjectMembers ?? false)) {
        return false;
      }
      return true;
    }
    return !isObjectMember;
  }

  bool _isProtectedMember(String name, String kind) {
    final element = classElement;
    if (element == null) return false;
    final elements = <InterfaceElement>[
      element,
      if (implicitSupers) ...element.allSupertypes.map((s) => s.element),
    ];
    for (final owner in elements) {
      final members = switch (kind) {
        'constructor' => owner.constructors,
        'method' => owner.methods,
        'getter' => owner.getters,
        'setter' => owner.setters,
        'field' => owner.fields,
        'static' => [
          ...owner.methods.where((m) => m.isStatic),
          ...owner.getters.where((g) => g.isStatic),
          ...owner.setters.where((s) => s.isStatic),
        ],
        _ => <Element>[],
      };
      for (final member in members) {
        if (member.name != name) continue;
        if (member.metadata.annotations.any(
          (annotation) => annotation.element?.displayName == 'protected',
        )) {
          return true;
        }
      }
    }
    return false;
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

/// Normalize a configured wrapper identifier, accepting an optional `$`.
String wrapperIdentifier(String name) =>
    name.startsWith(r'$') ? name : '\$$name';
