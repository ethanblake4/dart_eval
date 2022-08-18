import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/enum.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/model/library.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/program.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
import 'package:dart_eval/src/eval/compiler/util/graph.dart';
import 'package:dart_eval/src/eval/compiler/util/library_graph.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core.dart';
import 'package:directed_graph/directed_graph.dart';

import 'context.dart';
import 'errors.dart';

import 'model/source.dart';

class Compiler {
  var _bridgeStaticFunctionIdx = 0;
  final _bridgeDeclarations = <String, List<BridgeDeclaration>>{};

  final _topLevelDeclarationsMap = <int, Map<String, DeclarationOrBridge>>{};
  final _topLevelGlobalIndices = <int, Map<String, int>>{};
  final _instanceDeclarationsMap = <int, Map<String, Map<String, Declaration>>>{};

  final ctx = CompilerContext(0);

  final additionalSources = <DartSource>[];

  // Manually define a (unresolved) bridge class
  void defineBridgeClass(BridgeClassDef classDef) {
    if (!classDef.bridge && !classDef.wrap) {
      throw CompileError('Cannot define a bridge class that\'s not either bridge or wrap');
    }
    final type = classDef.type;
    final spec = type.type.spec;

    if (spec == null) {
      throw CompileError('Cannot define a bridge class that\'s already resolved, a ref, or a generic function type');
    }

    final libraryDeclarations = _bridgeDeclarations[spec.library];
    if (libraryDeclarations == null) {
      _bridgeDeclarations[spec.library] = [classDef];
    } else {
      libraryDeclarations.add(classDef);
    }
  }

  void defineBridgeEnum(BridgeEnumDef enumDef) {
    final spec = enumDef.type.spec;
    if (spec == null) {
      throw CompileError('Cannot define a bridge enum that\'s already resolved, a ref, or a generic function type');
    }

    final libraryDeclarations = _bridgeDeclarations[spec.library];
    if (libraryDeclarations == null) {
      _bridgeDeclarations[spec.library] = [enumDef];
    } else {
      libraryDeclarations.add(enumDef);
    }
  }

  void addSource(DartSource source) => additionalSources.add(source);

  void defineBridgeTopLevelFunction(BridgeFunctionDeclaration function) {
    final libraryDeclarations = _bridgeDeclarations[function.library];
    if (libraryDeclarations == null) {
      _bridgeDeclarations[function.library] = [function];
    } else {
      libraryDeclarations.add(function);
    }
  }

  void defineBridgeClasses(List<BridgeClassDef> classDefs) {
    for (final classDef in classDefs) {
      defineBridgeClass(classDef);
    }
  }

  /// Compile a set of Dart code into a program
  Program compile(Map<String, Map<String, String>> packages) {
    final sources = packages.entries.expand((packageEntry) => packageEntry.value.entries
        .map((library) => DartSource('package:${packageEntry.key}/${library.key}', library.value)));

    return compileSources(sources);
  }

  Program compileSources([Iterable<DartSource> sources = const []]) {
    configureCoreForCompile(this);
    configureAsyncForCompile(this);

    final units = sources.followedBy(additionalSources).map((source) => source.load());

    final unitLibraries = {
      ..._buildLibraries(units),
    };

    final unitLibraryUriMap = {for (final library in unitLibraries) library.uri: library};
    final libraries = <Library>{};
    final mergedLibraryUris = <Uri>{};

    for (final bridgeLibrary in _bridgeDeclarations.keys) {
      final bridgeLibDeclarations = [
        for (final bridgeDeclaration in _bridgeDeclarations[bridgeLibrary]!)
          DeclarationOrBridge(-1, bridge: bridgeDeclaration)
      ];

      final uri = Uri.parse(bridgeLibrary);
      final unitLibrary = unitLibraryUriMap[uri];
      if (unitLibrary != null) {
        libraries.add(unitLibrary.copyWith(declarations: [...unitLibrary.declarations, ...bridgeLibDeclarations]));
        mergedLibraryUris.add(uri);
      } else {
        libraries.add(Library(Uri.parse(bridgeLibrary), imports: [], exports: [], declarations: [
          for (final bridgeDeclaration in _bridgeDeclarations[bridgeLibrary]!)
            DeclarationOrBridge(-1, bridge: bridgeDeclaration)
        ]));
      }
    }

    unitLibraryUriMap.forEach((uri, library) {
      if (!mergedLibraryUris.contains(uri)) {
        libraries.add(library);
      }
    });

    var i = 0;
    final libraryIndexMap = <Library, int>{};
    final visibleDeclarations =
        _resolveImportsAndExports(libraries, (library) => libraryIndexMap[library] ?? (libraryIndexMap[library] = i++));

    for (final library in libraries) {
      final libraryIndex = libraryIndexMap[library] ?? (libraryIndexMap[library] = i++);
      for (final declarationOrBridge in library.declarations) {
        _populateLookupTablesForDeclaration(libraryIndex, declarationOrBridge);
      }
    }

    final libraryMapString = {for (final entry in libraryIndexMap.entries) entry.key.uri.toString(): entry.value};
    ctx.libraryMap = libraryMapString;

    final visibleDeclarationsByIndex = {
      for (final lib in libraries) libraryIndexMap[lib]!: {...visibleDeclarations[lib]!}
    };

    final declarationTypes = <DeclarationOrBridge, TypeRef>{};

    for (final library in libraries) {
      final libraryIndex = libraryIndexMap[library]!;
      for (final declaration in library.declarations) {
        final type = _cacheTypeRef(libraryIndex, declaration);
        if (type != null) {
          declarationTypes[declaration] = type;
        }
      }
    }

    final visibleTypesByIndex = <int, Map<String, TypeRef>>{};
    for (final library in libraries) {
      final libraryIndex = libraryIndexMap[library]!;
      final declarations = visibleDeclarations[library]!;

      for (final entry in declarations.entries) {
        final name = entry.key;
        final dop = entry.value;
        if (dop.children != null) {
          final res = <String, TypeRef>{};
          for (final childName in dop.children!.keys) {
            final child = dop.children![childName]!;
            final _cached = declarationTypes[child];
            if (_cached == null) continue;
            res['$name.$childName'] = _cached;
            if (child.isBridge) {
              final bridge = child.bridge!;
              if (bridge is BridgeClassDef) {
                child.bridge =
                    bridge.copyWith(type: bridge.type.copyWith(type: BridgeTypeRef.type(ctx.typeRefIndexMap[_cached])));
              } else if (bridge is BridgeEnumDef) {
                child.bridge = bridge.copyWith(type: BridgeTypeRef.type(ctx.typeRefIndexMap[_cached]));
              } else {
                assert(false);
              }
            }
          }
          visibleTypesByIndex[libraryIndex] ??= {...coreDeclarations};
          visibleTypesByIndex[libraryIndex] = res;
          continue;
        }
        visibleTypesByIndex[libraryIndex] ??= {...coreDeclarations};
        final declarationOrBridge = dop.declaration!;
        final type = declarationTypes[declarationOrBridge];
        if (type == null) continue;
        if (declarationOrBridge.isBridge) {
          final bridge = declarationOrBridge.bridge!;
          if (bridge is BridgeClassDef) {
            declarationOrBridge.bridge =
                bridge.copyWith(type: bridge.type.copyWith(type: BridgeTypeRef.type(ctx.typeRefIndexMap[type])));
          } else if (bridge is BridgeEnumDef) {
            declarationOrBridge.bridge = bridge.copyWith(type: BridgeTypeRef.type(ctx.typeRefIndexMap[type]));
          } else {
            assert(false);
          }
        }
        visibleTypesByIndex[libraryIndex]![name] = type;
      }
    }

    ctx.topLevelDeclarationsMap = _topLevelDeclarationsMap;
    ctx.instanceDeclarationsMap = _instanceDeclarationsMap;
    ctx.visibleDeclarations = visibleDeclarationsByIndex;
    ctx.visibleTypes = visibleTypesByIndex;

    for (final library in libraries) {
      final libraryIndex = libraryIndexMap[library]!;
      for (final dec in library.declarations) {
        if (dec.isBridge) {
          final bridge = dec.bridge;
          if (bridge is BridgeClassDef) {
            _assignBridgeStaticFunctionIndicesForClass(bridge);
          } else if (bridge is BridgeEnumDef) {
            _assignBridgeGlobalValueIndicesForEnum(bridge);
          } else if (bridge is BridgeFunctionDeclaration) {
            _assignBridgeStaticFunctionIndicesForFunction(libraryIndex, bridge);
          }
        }
      }
    }

    ctx.topLevelGlobalIndices = _topLevelGlobalIndices;

    /// Compile statics first so we can infer their type
    _topLevelDeclarationsMap.forEach((key, value) {
      value.forEach((lib, _declaration) {
        if (_declaration.isBridge) {
          return;
        }
        final declaration = _declaration.declaration!;
        ctx.library = key;
        if (declaration is VariableDeclaration && declaration.parent!.parent is TopLevelVariableDeclaration) {
          compileDeclaration(declaration, ctx);
          ctx.resetStack();
        } else if (declaration is ClassDeclaration) {
          ctx.currentClass = declaration;
          for (final d in declaration.members.whereType<FieldDeclaration>().where((e) => e.isStatic)) {
            compileFieldDeclaration(-1, d, ctx, declaration);
            ctx.resetStack();
          }
          ctx.currentClass = null;
        }
      });
    });

    /// Compile the rest of the declarations
    _topLevelDeclarationsMap.forEach((key, value) {
      ctx.topLevelDeclarationPositions[key] = {};
      ctx.instanceDeclarationPositions[key] = {};
      value.forEach((lib, _declaration) {
        if (_declaration.isBridge) {
          return;
        }
        final declaration = _declaration.declaration!;
        if (declaration is ConstructorDeclaration ||
            declaration is MethodDeclaration ||
            declaration is VariableDeclaration) {
          return;
        }
        ctx.library = key;
        compileDeclaration(declaration, ctx);
        ctx.resetStack();
      });
    });

    for (final library in libraries) {
      for (final dec in library.declarations) {
        if (dec.isBridge) {
          final bridge = dec.bridge;
          if (bridge is BridgeClassDef && bridge.bridge) {
            _reassignBridgeStaticFunctionIndicesForClass(bridge);
          }
        }
      }
    }

    for (final type in ctx.runtimeTypeList) {
      ctx.typeTypes.add(type.resolveTypeChain(ctx).getRuntimeIndices(ctx));
    }

    final globalInitializers = List<int>.filled(ctx.globalIndex, 0);

    for (final gi in ctx.runtimeGlobalInitializerMap.entries) {
      globalInitializers[gi.key] = gi.value;
    }

    return Program(
        ctx.topLevelDeclarationPositions,
        ctx.instanceDeclarationPositions,
        ctx.typeNames,
        ctx.typeTypes,
        ctx.offsetTracker.apply(ctx.out),
        libraryMapString,
        ctx.bridgeStaticFunctionIndices,
        ctx.constantPool.pool,
        ctx.runtimeTypes.pool,
        globalInitializers,
        ctx.enumValueIndices);
  }

  Runtime compileWriteAndLoad(Map<String, Map<String, String>> packages) {
    final program = compile(packages);

    final ob = program.write();

    return Runtime(ob.buffer.asByteData())..setup();
  }

  void _populateLookupTablesForDeclaration(int libraryIndex, DeclarationOrBridge declarationOrBridge) {
    if (!_topLevelDeclarationsMap.containsKey(libraryIndex)) {
      _topLevelDeclarationsMap[libraryIndex] = {};
    }

    if (!_instanceDeclarationsMap.containsKey(libraryIndex)) {
      _instanceDeclarationsMap[libraryIndex] = {};
    }

    if (declarationOrBridge.isBridge) {
      final bridge = declarationOrBridge.bridge!;
      if (bridge is BridgeClassDef) {
        final spec = bridge.type.type.spec!;
        _topLevelDeclarationsMap[libraryIndex]![spec.name] = DeclarationOrBridge(libraryIndex, bridge: bridge);
        for (final method in bridge.methods.entries) {
          if (method.value.isStatic) {
            _topLevelDeclarationsMap[libraryIndex]!['${spec.name}.${method.key}'] =
                DeclarationOrBridge(libraryIndex, bridge: method.value);
          }
        }
      } else if (bridge is BridgeEnumDef) {
        final spec = bridge.type.spec!;
        _topLevelDeclarationsMap[libraryIndex]![spec.name] = DeclarationOrBridge(libraryIndex, bridge: bridge);
      } else if (bridge is BridgeFunctionDeclaration) {
        _topLevelDeclarationsMap[libraryIndex]![bridge.name] = DeclarationOrBridge(libraryIndex, bridge: bridge);
      }
      return;
    }

    final declaration = declarationOrBridge.declaration!;

    if (declaration is TopLevelVariableDeclaration) {
      final vlist = declaration.variables;

      if (!_topLevelGlobalIndices.containsKey(libraryIndex)) {
        _topLevelGlobalIndices[libraryIndex] = {};
        ctx.topLevelGlobalInitializers[libraryIndex] = {};
        ctx.topLevelVariableInferredTypes[libraryIndex] = {};
      }

      for (final variable in vlist.variables) {
        final name = variable.name.name;

        if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
          throw CompileError('Cannot define "$name twice in the same library"');
        }

        _topLevelDeclarationsMap[libraryIndex]![name] = DeclarationOrBridge(libraryIndex, declaration: variable);
        _topLevelGlobalIndices[libraryIndex]![name] = ctx.globalIndex++;
      }
    } else {
      declaration as NamedCompilationUnitMember;
      final name = declaration.name.name;

      if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
        throw CompileError('Cannot define "$name twice in the same library"');
      }

      _topLevelDeclarationsMap[libraryIndex]![name] = DeclarationOrBridge(libraryIndex, declaration: declaration);

      if (declaration is ClassDeclaration) {
        _instanceDeclarationsMap[libraryIndex]![name] = {};

        declaration.members.forEach((member) {
          if (member is MethodDeclaration) {
            if (member.isStatic) {
              _topLevelDeclarationsMap[libraryIndex]![name + '.' + member.name.name] =
                  DeclarationOrBridge(libraryIndex, declaration: member);
            } else {
              _instanceDeclarationsMap[libraryIndex]![name]![member.name.name] = member;
            }
          } else if (member is FieldDeclaration) {
            if (member.isStatic) {
              if (!_topLevelGlobalIndices.containsKey(libraryIndex)) {
                _topLevelGlobalIndices[libraryIndex] = {};
                ctx.topLevelGlobalInitializers[libraryIndex] = {};
                ctx.topLevelVariableInferredTypes[libraryIndex] = {};
              }

              for (final field in member.fields.variables) {
                final name = declaration.name.name + '.' + field.name.name;

                if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
                  throw CompileError('Cannot define "$name twice in the same library"');
                }

                _topLevelDeclarationsMap[libraryIndex]![name] = DeclarationOrBridge(libraryIndex, declaration: field);
                _topLevelGlobalIndices[libraryIndex]![name] = ctx.globalIndex++;
              }
            } else {
              for (final field in member.fields.variables) {
                _instanceDeclarationsMap[libraryIndex]![name]![field.name.name] = field;
              }
            }
          } else if (member is ConstructorDeclaration) {
            _topLevelDeclarationsMap[libraryIndex]!['$name.${member.name?.name ?? ""}'] =
                DeclarationOrBridge(libraryIndex, declaration: member);
          } else {
            throw CompileError('Not a NamedCompilationUnitMember');
          }
        });
      }
    }
  }

  TypeRef? _cacheTypeRef(int libraryIndex, DeclarationOrBridge declarationOrBridge) {
    if (declarationOrBridge.isBridge) {
      final bridge = declarationOrBridge.bridge;
      if (bridge is! BridgeClassDef && bridge is! BridgeEnumDef) {
        return null;
      }
      final type = bridge is BridgeClassDef ? bridge.type.type : (bridge as BridgeEnumDef).type;
      if (type.cacheId != null) {
        return TypeRef.fromBridgeTypeRef(ctx, type);
      }
      final spec = type.spec!;
      return TypeRef.cache(ctx, libraryIndex, spec.name, fileRef: libraryIndex);
    } else {
      final declaration = declarationOrBridge.declaration!;
      if (declaration is! ClassDeclaration) {
        return null;
      }
      return TypeRef.cache(ctx, libraryIndex, declaration.name.name, fileRef: libraryIndex);
    }
  }

  void _assignBridgeStaticFunctionIndicesForClass(BridgeClassDef classDef) {
    final type = TypeRef.fromBridgeTypeRef(ctx, classDef.type.type);
    final lib = type.file;
    if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
      ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
    }
    classDef.constructors.forEach((name, constructor) {
      if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name'] = _bridgeStaticFunctionIdx++;
    });

    classDef.methods.forEach((name, method) {
      if (!method.isStatic) return;
      if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name'] = _bridgeStaticFunctionIdx++;
    });
  }

  void _reassignBridgeStaticFunctionIndicesForClass(BridgeClassDef classDef) {
    final type = TypeRef.fromBridgeTypeRef(ctx, classDef.type.type);
    final lib = type.file;

    classDef.constructors.forEach((name, constructor) {
      final idc = ctx.bridgeStaticFunctionIndices[lib]!;
      final id = '${type.name}.$name';
      final prev = classDef.wrap ? idc[id]! : idc.remove(id)!;
      ctx.bridgeStaticFunctionIndices[lib]!['#${type.name}.$name'] = prev;
    });
  }

  void _assignBridgeGlobalValueIndicesForEnum(BridgeEnumDef enumDef) {
    final type = TypeRef.fromBridgeTypeRef(ctx, enumDef.type);
    final lib = type.file;
    if (!ctx.enumValueIndices.containsKey(lib)) {
      ctx.enumValueIndices[lib] = {};
    }
    ctx.enumValueIndices[lib]![type.name] = {for (final value in enumDef.values) value: ctx.globalIndex++};
  }

  void _assignBridgeStaticFunctionIndicesForFunction(int libraryIndex, BridgeFunctionDeclaration functionDef) {
    if (!ctx.bridgeStaticFunctionIndices.containsKey(libraryIndex)) {
      ctx.bridgeStaticFunctionIndices[libraryIndex] = <String, int>{};
    }
    ctx.bridgeStaticFunctionIndices[libraryIndex]![functionDef.name] = _bridgeStaticFunctionIdx++;
  }
}

List<Library> _buildLibraries(Iterable<DartCompilationUnit> units) {
  var i = 0;
  final compilationUnitMap = <int, DartCompilationUnit>{};
  final uriMap = <Uri, int>{};
  final libraryIdMap = <String, int>{};

  for (final unit in units) {
    compilationUnitMap[i] = unit;
    uriMap[unit.uri] = i;
    if (unit.library != null) {
      libraryIdMap[unit.library!.name.name] = i;
    }
    i++;
  }

  final cuGraph = CompilationUnitGraph(compilationUnitMap, uriMap, libraryIdMap);
  final libGroups = computeStrongComponents(cuGraph);

  final libraries = <Library>[];
  for (final group in libGroups) {
    final primaryId = group.length == 1 ? group[0] : group.firstWhere((e) => compilationUnitMap[e]!.partOf == null);
    final primary = compilationUnitMap[primaryId]!;
    final library = Library(primary.uri,
        library: primary.library?.name.name,
        imports: primary.imports,
        exports: primary.exports,
        declarations: group.map((e) => compilationUnitMap[e]!).fold(
            [], (pv, element) => pv..addAll(element.declarations.map((d) => DeclarationOrBridge(-1, declaration: d)))));
    libraries.add(library);
  }

  return libraries;
}

Map<Library, Map<String, DeclarationOrPrefix>> _resolveImportsAndExports(
    Iterable<Library> libraries, int Function(Library) resolveLibraryId) {
  final uriMap = {for (final l in libraries) l.uri: l};

  final exportGraph = DirectedGraph<Uri>({
    for (final l in libraries) l.uri: {for (final export in l.exports) Uri.parse(export.uri.stringValue!)}
  });

  final result = <Library, Map<String, DeclarationOrPrefix>>{};

  for (final l in libraries) {
    final _visibleDeclarations = <String, DeclarationOrPrefix>{
      for (final d in _expandDeclarations(l.declarations))
        d.first: DeclarationOrPrefix(declaration: d.second..sourceLib = resolveLibraryId(l)),
    };

    final dartCoreUri = Uri.parse('dart:core');
    final isDartCore = l.uri == dartCoreUri;

    for (final import in [
      ...l.imports.map((e) => _Import(Uri.parse(e.uri.stringValue!), e.prefix?.name, e.combinators)),
      if (!isDartCore) _Import(dartCoreUri, null)
    ]) {
      final tree = exportGraph.crawler.tree(import.uri);
      final importedLibs = [...tree.expand((e) => e), import.uri].map((e) => uriMap[e]!).toSet();
      final importedExports = importedLibs.map((e) => e.exports).expand((e) => e);

      final exportsPerUri = <Uri, List<ExportDirective>>{};
      for (final export in importedExports) {
        final uriList = exportsPerUri[export.uri.stringValue!];
        if (uriList != null) {
          uriList.add(export);
        } else {
          exportsPerUri[Uri.parse(export.uri.stringValue!)] = [export];
        }
      }

      final validImport = (String name) {
        if (name.startsWith('_')) return false;
        if (import.combinators.isEmpty) {
          return true;
        }
        for (final combinator in import.combinators) {
          if (combinator is ShowCombinator) {
            if ({for (final n in combinator.shownNames) n.name}.contains(name)) {
              return true;
            }
            return false;
          } else if (combinator is HideCombinator) {
            if ({for (final n in combinator.hiddenNames) n.name}.contains(name)) {
              return false;
            }
            return true;
          }
          throw CompileError('Unsupported import combinator ${combinator.runtimeType}');
        }
        return false;
      };

      final visibleDeclarations = {
        for (final lib in importedLibs)
          for (final declaration in _expandDeclarations(lib.declarations).where((e) => validImport(e.first))) ...{
            if (lib.uri == import.uri) declaration,
            for (final export in exportsPerUri[lib.uri] ?? [])
              if (export.combinators.isEmpty)
                declaration
              else
                for (final combinator in export.combinators)
                  if (combinator is ShowCombinator) ...{
                    if ({for (final n in combinator.shownNames) n.name}.contains(declaration.first)) declaration
                  } else if (combinator is HideCombinator) ...{
                    if (!({for (final n in (combinator).hiddenNames) n.name}.contains(declaration.first))) declaration
                  }
          }
      };

      final mappedVisibleDeclarations = {
        if (import.prefix != null)
          import.prefix!: DeclarationOrPrefix(children: {for (final d in visibleDeclarations) d.first: d.second})
        else
          for (final d in visibleDeclarations) d.first: DeclarationOrPrefix(declaration: d.second)
      };

      _visibleDeclarations.addAll(mappedVisibleDeclarations);
    }

    result[l] = _visibleDeclarations;
  }

  return result;
}

Iterable<Pair<String, DeclarationOrBridge>> _expandDeclarations(List<DeclarationOrBridge> declarations) sync* {
  for (final d in declarations) {
    if (d.isBridge) {
      final bridge = d.bridge as BridgeDeclaration;
      if (bridge is BridgeClassDef) {
        final name = bridge.type.type.spec!.name;
        yield Pair(name, d);
      } else if (bridge is BridgeEnumDef) {
        final name = bridge.type.spec!.name;
        yield Pair(name, d);
      } else if (bridge is BridgeFunctionDeclaration) {
        yield Pair(bridge.name, d);
      }
    } else {
      final declaration = d.declaration!;
      if (declaration is NamedCompilationUnitMember) {
        yield Pair(declaration.name.name, d);
        if (declaration is ClassDeclaration) {
          for (final member in declaration.members) {
            if (member is ConstructorDeclaration) {
              yield Pair(
                  '${declaration.name.name}.${member.name?.name ?? ""}', DeclarationOrBridge(-1, declaration: member));
            } else if (member is MethodDeclaration && member.isStatic) {
              yield Pair('${declaration.name.name}.${member.name.name}', DeclarationOrBridge(-1, declaration: member));
            } else if (member is MethodDeclaration && member.isStatic) {
              yield Pair('${declaration.name.name}.${member.name.name}', DeclarationOrBridge(-1, declaration: member));
            }
          }
        }
      } else if (declaration is TopLevelVariableDeclaration) {
        for (final v in declaration.variables.variables) {
          yield Pair(v.name.name, DeclarationOrBridge(-1, declaration: v));
        }
      }
    }
  }
}

class _Import {
  final Uri uri;
  final String? prefix;
  final List<Combinator> combinators;

  _Import(this.uri, this.prefix, [this.combinators = const []]);
}
