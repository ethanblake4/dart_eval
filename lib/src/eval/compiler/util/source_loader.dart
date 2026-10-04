import 'package:analyzer/dart/ast/ast.dart';

import '../helpers/conditional_import.dart';
import '../model/compilation_unit.dart';
import '../model/diagnostic_mode.dart';
import '../model/source.dart';

/// Loads roots and selected dependencies, caching text and parsed units.
class SourceLoader {
  final _sources = <DartSource, _CachedSource>{};

  List<DartCompilationUnit> load(
    Iterable<DartSource> sources, {
    required Set<Uri> roots,
    required Iterable<String> entrypoints,
    required DiagnosticMode diagnosticMode,
  }) {
    final ordered = sources.toList();
    final current = ordered.toSet();
    _sources.removeWhere((source, _) => !current.contains(source));
    final byUri = <Uri, List<_CachedSource>>{};
    for (final source in ordered) {
      final cached = _sources.putIfAbsent(source, () => _CachedSource(source));
      (byUri[source.uri] ??= []).add(cached);
    }

    final active = <Uri>{};
    final pending = <Uri>[];
    void activate(Uri uri) {
      if (byUri.containsKey(uri) && active.add(uri)) pending.add(uri);
    }

    for (final uri in roots) {
      activate(uri);
    }
    for (final entry in byUri.entries) {
      if (entrypoints.any((suffix) => entry.key.toString().endsWith(suffix))) {
        activate(entry.key);
      }
      for (final source in entry.value) {
        // Unimported override functions are roots too. The text hint avoids
        // constructing ASTs for ordinary inactive dependencies.
        // Custom loaders retain their eager loading contract.
        if (source.contents == null ||
            source.hasOverrideHint &&
                _load(
                  source,
                  diagnosticMode,
                ).declarations.any(hasRuntimeOverride)) {
          activate(entry.key);
        }
      }
    }

    while (pending.isNotEmpty) {
      for (final source in byUri[pending.removeLast()]!) {
        final unit = _load(source, diagnosticMode);
        for (final directive in [...unit.imports, ...unit.exports]) {
          final uri = unit.uri.resolve(selectedDirectiveUri(directive));
          if (!uri.toString().startsWith('package:eval_annotation')) {
            activate(uri);
          }
        }
        for (final part in unit.parts) {
          activate(unit.uri.resolve(part.uri.stringValue!));
        }
        if (unit.partOf?.uri?.stringValue case final uri?) {
          activate(unit.uri.resolve(uri));
        }
      }
    }

    final units = [
      for (final source in ordered)
        if (active.contains(source.uri))
          _load(_sources[source]!, diagnosticMode),
    ];
    for (final unit in units) {
      final name = unit.partOf?.libraryName?.toString();
      if (name == null) continue;
      final hasOwner = units.any(
        (owner) =>
            owner.library?.name?.toString() == name &&
            owner.parts.any(
              (part) => owner.uri.resolve(part.uri.stringValue!) == unit.uri,
            ),
      );
      if (!hasOwner) {
        // A root can itself be a named part, notably an unimported override.
        // Preserve legacy owner discovery when no selected parent lists it.
        return [
          for (final source in ordered)
            _load(_sources[source]!, diagnosticMode),
        ];
      }
    }
    return units;
  }

  DartCompilationUnit _load(_CachedSource source, DiagnosticMode mode) {
    try {
      return source.load(mode);
    } catch (_) {
      // A retry must reread files whose text never became a parsed cache entry.
      _sources.removeWhere((_, cached) => cached._unit == null);
      rethrow;
    }
  }
}

bool hasRuntimeOverride(AstNode declaration) =>
    declaration is FunctionDeclaration &&
    declaration.metadata.any(
      (annotation) => annotation.name.name == 'RuntimeOverride',
    );

class _CachedSource {
  _CachedSource(this.source)
    : contents = source.runtimeType == DartSource ? source.toString() : null;

  final DartSource source;
  final String? contents;
  late final bool hasOverrideHint =
      contents?.contains('RuntimeOverride') ?? true;
  DartCompilationUnit? _unit;

  DartCompilationUnit load(DiagnosticMode mode) => _unit ??= switch (contents) {
    null => source.load(mode),
    final text => parseDartSource(
      source.uri,
      text,
      mode,
      languageVersion: source.languageVersion,
    ),
  };
}
