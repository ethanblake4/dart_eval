import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';

const _runtimeBridgeTypeSpecLibrary =
    'package:dart_eval/src/eval/bridge/declaration/type.dart';
const _runtimeTypesLibrary = 'package:dart_eval/src/eval/shared/types.dart';

/// Resolves a configured runtime type expression without executing Dart code.
///
/// Supported expressions are direct `BridgeTypeSpec` string literals and
/// simple references to const top-level variables or static fields. Registry
/// entries emitted from bindgen configuration are resolved from that
/// configuration when their generated Dart file is not available to the
/// analyzer yet.
Future<BridgeTypeSpec> resolveRuntimeTypeSpec(
  AnalysisSession session,
  BindgenContext ctx,
  String expression,
) async {
  final source = expression.trim();
  final parsed = _parseExpression(source);
  if (parsed == null) {
    throw _resolutionError(ctx, expression);
  }

  final literal = _directBridgeTypeSpec(parsed);
  if (literal != null) return literal;

  final parts = _simpleReference(parsed);
  if (parts == null) throw _resolutionError(ctx, expression);

  final scopes = await _resolutionScopes(session, ctx);
  // Bindgen configuration is the source of truth for registries it owns. A
  // stale generated file or an imported registry with the same class name
  // must not override the value that generation will emit from this config.
  final configured = _configuredRegistrySpec(ctx.config, parts, scopes);
  if (configured != null) return configured;

  for (final element in _resolveReference(parts, scopes)) {
    final spec = _specFromElement(element);
    if (spec != null) return spec;
  }

  throw _resolutionError(ctx, expression);
}

Expression? _parseExpression(String source) {
  try {
    final unit = parseString(content: 'const _runtimeType = $source;').unit;
    final declaration = unit.declarations
        .whereType<TopLevelVariableDeclaration>();
    if (declaration.length != 1) return null;
    final variables = declaration.single.variables.variables;
    if (variables.length != 1) return null;
    return variables.single.initializer;
  } on FormatException {
    return null;
  }
}

BridgeTypeSpec? _directBridgeTypeSpec(Expression expression) {
  final List<Argument> arguments;
  if (expression is InstanceCreationExpression) {
    final constructor = expression.constructorName;
    if (constructor.type.name.lexeme != 'BridgeTypeSpec' ||
        constructor.type.typeArguments != null ||
        constructor.name != null) {
      return null;
    }
    arguments = expression.argumentList.arguments;
  } else if (expression is MethodInvocation &&
      expression.target == null &&
      expression.methodName.name == 'BridgeTypeSpec') {
    arguments = expression.argumentList.arguments;
  } else {
    return null;
  }
  if (arguments.length != 2 ||
      arguments[0] is! SimpleStringLiteral ||
      arguments[1] is! SimpleStringLiteral) {
    return null;
  }
  final library = (arguments[0] as SimpleStringLiteral).stringValue;
  final name = (arguments[1] as SimpleStringLiteral).stringValue;
  if (library == null || name == null) return null;
  return BridgeTypeSpec(library, name);
}

List<String>? _simpleReference(Expression expression) {
  final source = expression.toSource();
  if (!RegExp(
    r'^[A-Za-z_$][A-Za-z0-9_$]*(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*$',
  ).hasMatch(source)) {
    return null;
  }
  return source.split('.');
}

Future<List<_ImportScope>> _resolutionScopes(
  AnalysisSession session,
  BindgenContext ctx,
) async {
  final scopes = <_ImportScope>[];

  void addScope(Element? Function(String) lookup, String? prefix) {
    scopes.add(_ImportScope(lookup, prefix));
  }

  final currentLibrary = ctx.libraryElement;
  if (currentLibrary != null) {
    addScope(currentLibrary.publicNamespace.get2, null);
    addScope(currentLibrary.exportNamespace.get2, null);
    for (final fragment in currentLibrary.fragments) {
      for (final import in fragment.libraryImports) {
        final library = import.importedLibrary;
        if (library == null) continue;
        addScope(import.namespace.get2, import.prefix?.element.name);
      }
    }
  }

  final importReferences = <String>{
    ...ctx.imports,
    ...?ctx.libraryConfig?.imports,
    ...?ctx.classConfig?.imports,
  };
  for (final reference in importReferences) {
    final import = _parseImport(reference);
    if (import == null) continue;
    final uri = _resolveImportUri(ctx, import.uri);
    if (uri == null) continue;
    final library = await _libraryForUri(session, uri);
    if (library == null) continue;
    addScope(library.exportNamespace.get2, import.prefix);
  }

  final typeRegistry = await _libraryForUri(session, _runtimeTypesLibrary);
  if (typeRegistry != null) {
    addScope(typeRegistry.exportNamespace.get2, null);
  }
  return scopes;
}

({String uri, String? prefix})? _parseImport(String reference) {
  final trimmed = reference.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.startsWith('import ')) {
    return (uri: trimmed, prefix: null);
  }
  try {
    final unit = parseString(content: '$trimmed\n').unit;
    final directives = unit.directives.whereType<ImportDirective>().toList();
    if (directives.isEmpty) return null;
    final directive = directives.first;
    final uri = directive.uri.stringValue;
    if (uri == null) return null;
    return (uri: uri, prefix: directive.prefix?.name);
  } on FormatException {
    return null;
  }
}

String? _resolveImportUri(BindgenContext ctx, String uri) {
  final parsed = Uri.tryParse(uri);
  if (parsed == null) return null;
  if (parsed.hasScheme) return uri;
  final libraryUri = ctx.libraryElement?.uri;
  if (libraryUri == null) return null;
  return libraryUri.resolveUri(parsed).toString();
}

Future<LibraryElement?> _libraryForUri(
  AnalysisSession session,
  String uri,
) async {
  try {
    final parsed = Uri.tryParse(uri);
    if (parsed?.scheme == 'file') {
      final result = await session.getResolvedLibrary(parsed!.toFilePath());
      return result is ResolvedLibraryResult ? result.element : null;
    }
    final result = await session.getLibraryByUri(uri);
    return result is LibraryElementResult ? result.element : null;
  } on Exception {
    return null;
  }
}

Iterable<Element> _resolveReference(
  List<String> parts,
  List<_ImportScope> scopes,
) sync* {
  if (parts.length == 1) {
    final name = parts.single;
    for (final scope in scopes.where((scope) => scope.prefix == null)) {
      final element = scope.lookup(name);
      final variable = _variableFromElement(element);
      if (variable != null) yield variable;
    }
    return;
  }

  if (parts.length == 2) {
    final first = parts[0];
    final second = parts[1];
    for (final scope in scopes.where((scope) => scope.prefix == first)) {
      final element = scope.lookup(second);
      final variable = _variableFromElement(element);
      if (variable != null) yield variable;
    }
    for (final scope in scopes.where((scope) => scope.prefix == null)) {
      final owner = scope.lookup(first);
      if (owner is InterfaceElement) {
        final field = _staticField(owner, second);
        if (field != null) yield field;
      }
    }
    return;
  }

  if (parts.length == 3) {
    final prefix = parts[0];
    final ownerName = parts[1];
    final fieldName = parts[2];
    for (final scope in scopes.where((scope) => scope.prefix == prefix)) {
      final owner = scope.lookup(ownerName);
      if (owner is InterfaceElement) {
        final field = _staticField(owner, fieldName);
        if (field != null) yield field;
      }
    }
  }
}

FieldElement? _staticField(InterfaceElement owner, String name) {
  for (final field in owner.fields) {
    if (field.name == name && field.isStatic) return field;
  }
  return null;
}

BridgeTypeSpec? _specFromElement(Element element) {
  if (element is! VariableElement) return null;
  try {
    final value = element.computeConstantValue();
    if (value == null || !_isBridgeTypeSpec(value)) return null;
    final library = value.getField('library')?.toStringValue();
    final name = value.getField('name')?.toStringValue();
    if (library == null || name == null) return null;
    return BridgeTypeSpec(library, name);
  } on Exception {
    return null;
  }
}

VariableElement? _variableFromElement(Element? element) => switch (element) {
  VariableElement() => element,
  GetterElement(isOriginVariable: true) => element.variable,
  _ => null,
};

bool _isBridgeTypeSpec(DartObject value) {
  final type = value.type;
  if (type is! InterfaceType) return false;
  final element = type.element;
  return element.name == 'BridgeTypeSpec' &&
      element.library.uri.toString() == _runtimeBridgeTypeSpecLibrary;
}

BridgeTypeSpec? _configuredRegistrySpec(
  BindgenConfig? config,
  List<String> parts,
  List<_ImportScope> scopes,
) {
  if (config == null || parts.length < 2 || parts.length > 3) return null;
  final registryName = parts[parts.length - 2];
  final field = parts.last;
  if (parts.length == 3 &&
      !scopes.any((scope) => scope.prefix == parts.first)) {
    return null;
  }

  for (final registryLibrary in config.libraries) {
    final registry = registryLibrary.registry;
    if (registry == null ||
        registryClassName(registryLibrary) != registryName) {
      continue;
    }
    final entries = <String, String>{};
    for (final sourceLibrary in config.libraries) {
      for (final classConfig in sourceLibrary.classes.values) {
        if ((classConfig.libOverride ?? sourceLibrary.uri) !=
            registryLibrary.uri) {
          continue;
        }
        entries[registryFieldName(classConfig.name)] = classConfig.name;
      }
    }
    entries.addAll(registry.extra);
    final specName = entries[field];
    if (specName != null) {
      return BridgeTypeSpec(registryLibrary.uri, specName);
    }
  }
  return null;
}

BindingGenerationError _resolutionError(BindgenContext ctx, String expression) {
  final owner = ctx.classConfig?.name ?? ctx.classElement?.name;
  final context = owner == null ? ctx.uri : '${ctx.uri}::$owner';
  return BindingGenerationError(
    'Could not resolve runtime type expression "$expression" for $context. '
    'Use a BridgeTypeSpec literal or a const BridgeTypeSpec reference.',
  );
}

class _ImportScope {
  const _ImportScope(this.lookup, this.prefix);

  final Element? Function(String) lookup;
  final String? prefix;
}
