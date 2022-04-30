import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';
import 'package:dart_eval/src/eval/compiler/model/library.dart';
import 'package:dart_eval/src/eval/compiler/util/graph.dart';

/// A [Graph] where strongly-connected components representing libraries can be formed from part/part of relationships
class CompilationUnitGraph implements Graph<int> {
  final Map<int, DartCompilationUnit> compilationUnits;
  final Map<Uri, int> uriMap;
  final Map<String, int> libraryIdMap;

  CompilationUnitGraph(this.compilationUnits, this.uriMap, this.libraryIdMap);

  @override
  Iterable<int> get vertices => compilationUnits.keys;

  @override
  Iterable<int> neighborsOf(int vertex) sync* {
    final cu = compilationUnits[vertex];
    if (cu == null) {
      throw 'Compilation unit not found: $vertex';
    }

    for (final part in cu.parts) {
      final uri = Uri.parse(part.uri.stringValue!);
      final id = uriMap[uri];
      if (id != null && compilationUnits.containsKey(id)) {
        yield id;
      }
    }

    final partOf = cu.partOf;
    if (partOf != null) {
      final uriStr = partOf.uri?.stringValue, libId = partOf.libraryName?.name;
      if (uriStr != null) {
        final uri = Uri.parse(uriStr);
        final id = uriMap[uri];
        if (id != null && compilationUnits.containsKey(id)) {
          yield id;
        }
      } else {
        final id = libraryIdMap[libId];
        if (id != null && compilationUnits.containsKey(id)) {
          yield id;
        }
      }
    }
  }
}

class ExportGraph implements Graph<Uri> {
  final Map<Uri, Library> libraries;

  ExportGraph(this.libraries);

  @override
  Iterable<Uri> get vertices => libraries.keys;

  @override
  Iterable<Uri> neighborsOf(Uri vertex) sync* {
    final library = libraries[vertex];
    if (library == null) {
      throw 'Library not found: $vertex';
    }

    for (final export in library.exports) {
      final lib = Uri.parse(export.uri.stringValue!);
      if (libraries.containsKey(lib)) {
        yield lib;
      }
    }
  }
}
