import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:control_flow_graph/control_flow_graph.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/backend/typed_backend.dart';
import 'package:dart_eval/src/eval/ir/representation.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_program.dart';
import 'package:dart_eval/src/eval/compiler/optimizer/validate.dart';
import 'package:dart_eval/src/eval/compiler/optimizer/ssa.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/model/diagnostic_mode.dart';
import 'package:dart_eval/src/eval/compiler/model/override_spec.dart';
import 'package:dart_eval/src/eval/compiler/model/library.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/program.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';

import 'package:dart_eval/src/eval/compiler/util/custom_crawler.dart';
import 'package:dart_eval/src/eval/compiler/util/graph.dart';
import 'package:dart_eval/src/eval/compiler/util/library_graph.dart';
import 'package:dart_eval/src/eval/compiler/util/tree_shake.dart';
import 'package:dart_eval/src/eval/shared/stdlib/async.dart';
import 'package:dart_eval/src/eval/shared/stdlib/collection.dart';
import 'package:dart_eval/src/eval/shared/stdlib/convert.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io.dart';
import 'package:dart_eval/src/eval/shared/stdlib/math.dart';
import 'package:dart_eval/src/eval/shared/stdlib/typed_data.dart';
import 'package:directed_graph/directed_graph.dart';

import 'context.dart';
import 'errors.dart';

/// Compiles Dart source code into EVC bytecode, outputting a [Program].
///
/// To use, call [compile] or [compileSources].
///
/// You may define bridge libraries using a combination of [defineBridgeClass],
/// [defineBridgeTopLevelFunction], and [defineBridgeEnum].
///
/// Additional sources can be added with [addSource].
class Compiler implements BridgeDeclarationRegistry, EvalPluginRegistry {
  Set<String> _entrypointLibraries = {};
  var _bridgeStaticFunctionIdx = 0;
  final _bridgeDeclarations = <String, List<BridgeDeclaration>>{};

  /// A map of library IDs / indexes to a map of String declaration names to
  /// [DeclarationOrBridge]s. Populated in [_populateLookupTablesForDeclaration]
  /// and copied to [CompilerContext.topLevelDeclarationsMap].
  var _topLevelDeclarationsMap = <int, Map<String, DeclarationOrBridge>>{};
  var _topLevelGlobalIndices = <int, Map<String, int>>{};
  var _instanceDeclarationsMap = <int, Map<String, Map<String, Declaration>>>{};

  /// The semantic version of the compiled code, for runtime overrides
  String? version;

  var _ctx = CompilerContext();

  /// Typed control-flow graphs from the last compilation, keyed by function ID.
  /// These precede SSA conversion, register allocation, and bytecode lowering.
  Map<int, ControlFlowGraph> get functionGraphs =>
      Map.unmodifiable(_ctx.functionGraphs);

  Map<int, String> get functionNames => Map.unmodifiable(_ctx.functionNames);

  Map<int, MachineFunctionSignature> get functionSignatures =>
      Map.unmodifiable(_ctx.functionSignatures);

  /// Per-function SSA graphs prepared for instruction selection.
  Map<int, ControlFlowGraph> get ssaFunctionGraphs =>
      Map.unmodifiable(_ctx.ssaFunctionGraphs);

  /// List of additional [DartSource] files to be compiled when [compile] is run
  final additionalSources = <DartSource>[];
  final _cachedParsedSources = <DartSource, DartCompilationUnit>{};

  /// [EvalPlugin]s that will be applied to the compiler
  final _plugins = <EvalPlugin>[
    DartAsyncPlugin(),
    DartCollectionPlugin(),
    DartConvertPlugin(),
    DartCorePlugin(),
    DartIoPlugin(),
    DartMathPlugin(),
    DartTypedDataPlugin(),
  ];
  final _appliedPlugins = <String>[];

  /// List of files whose functions should be used as entrypoints. These can be
  /// full URIs (e.g. `package:foo/main.dart`) or just filenames (e.g.
  /// `main.dart`). Adding a file to this list prevents it from being dead-code
  /// eliminated.
  final entrypoints = ['/main.dart'];

  /// The diagnostic mode to use when parsing.
  var diagnosticMode = DiagnosticMode.throwIfError;

  // Add a plugin, which will only be run once.
  @override
  void addPlugin(EvalPlugin plugin) {
    _plugins.add(plugin);
  }

  // Manually define a (unresolved) bridge class
  @override
  void defineBridgeClass(BridgeClassDef classDef) {
    if (!classDef.bridge && !classDef.wrap) {
      throw CompileError(
        'Cannot define a bridge class that\'s not either bridge or wrap',
      );
    }
    final type = classDef.type;
    final spec = type.type.spec;

    if (spec == null) {
      throw CompileError(
        'Cannot define a bridge class that\'s already resolved, a ref, or a generic function type',
      );
    }

    final libraryDeclarations = _bridgeDeclarations[spec.library];
    if (libraryDeclarations == null) {
      _bridgeDeclarations[spec.library] = [classDef];
    } else {
      libraryDeclarations.add(classDef);
    }
  }

  /// Define a bridged enum definition to be used when compiling.
  @override
  void defineBridgeEnum(BridgeEnumDef enumDef) {
    final spec = enumDef.type.spec;
    if (spec == null) {
      throw CompileError(
        'Cannot define a bridge enum that\'s already resolved, a ref, or a generic function type',
      );
    }

    final libraryDeclarations = _bridgeDeclarations[spec.library];
    if (libraryDeclarations == null) {
      _bridgeDeclarations[spec.library] = [enumDef];
    } else {
      libraryDeclarations.add(enumDef);
    }
  }

  /// Add a unit source to the list of additional sources which will be compiled
  /// alongside the packages specified in [compile].
  @override
  void addSource(DartSource source) => additionalSources.add(source);

  /// Define a bridged top-level function declaration.
  @override
  void defineBridgeTopLevelFunction(BridgeFunctionDeclaration function) {
    final libraryDeclarations = _bridgeDeclarations[function.library];
    if (libraryDeclarations == null) {
      _bridgeDeclarations[function.library] = [function];
    } else {
      libraryDeclarations.add(function);
    }
  }

  /// Define a set of unresolved bridge classes
  void defineBridgeClasses(List<BridgeClassDef> classDefs) {
    for (final classDef in classDefs) {
      defineBridgeClass(classDef);
    }
  }

  /// A list of libraries that have been bridged
  List<String> get bridgedLibraries => _bridgeDeclarations.keys.toList();

  /// Compile a set of Dart code into a program. Shorthand for
  /// [compileSources]. Code should be specified in a map as such:
  /// ```
  /// {
  ///   'package_name': {
  ///     'file_name1.dart': '''code''',
  ///     'file_name2.dart': '''code'''
  ///   }
  /// }
  ///```
  Program compile(Map<String, Map<String, String>> packages) {
    final sources = packages.entries.expand(
      (packageEntry) => packageEntry.value.entries.map(
        (library) => DartSource(
          'package:${packageEntry.key}/${library.key}',
          library.value,
        ),
      ),
    );

    return compileSources(sources);
  }

  /// Compile a unit set of Dart code into a program
  Program compileSources([
    Iterable<DartSource> sources = const [],
    bool debugPerf = true,
  ]) => _compileSources(sources, debugPerf, _emitProgram);

  /// Compile an entrypoint directly to a typed bytecode payload.
  /// Unsupported language operations fail explicitly during lowering.
  TypedProgram compileTyped(
    Map<String, Map<String, String>> packages, {
    required String entrypoint,
    String function = 'main',
  }) => _compileSources(
    packages.entries.expand(
      (package) => package.value.entries.map(
        (file) => DartSource('package:${package.key}/${file.key}', file.value),
      ),
    ),
    false,
    () => TypedBackend(_ctx).compile(entrypoint, function),
    extraEntrypoints: {entrypoint},
  );

  T _compileSources<T>(
    Iterable<DartSource> sources,
    bool debugPerf,
    T Function() emit, {
    Set<String> extraEntrypoints = const {},
  }) {
    _topLevelDeclarationsMap = <int, Map<String, DeclarationOrBridge>>{};
    _topLevelGlobalIndices = <int, Map<String, int>>{};
    _instanceDeclarationsMap = <int, Map<String, Map<String, Declaration>>>{};
    _bridgeStaticFunctionIdx = 0;

    // Create a compilation context
    _ctx = CompilerContext(version: version);

    for (final plugin in _plugins) {
      if (!_appliedPlugins.contains(plugin.identifier)) {
        plugin.configureForCompile(this);
        _appliedPlugins.add(plugin.identifier);
      }
    }

    final cleanupList = _cachedParsedSources.keys.toSet();

    // Generate the parsed AST for all sources. [units] will be a List of
    // [DartCompilationUnit]s. Avoids re-parsing a source if it has already been
    // parsed and is stored in [cachedParsedSources].
    final units = sources.followedBy(additionalSources).map((source) {
      cleanupList.remove(source);
      final cached = _cachedParsedSources[source];
      if (cached != null) {
        return cached;
      }

      // Load the source code from the filesystem or a String and parse it
      // (internally using the Dart analyzer) into an AST
      final parsed = _cachedParsedSources[source] = source.load(diagnosticMode);
      return parsed;
    }).toList();

    for (final source in cleanupList) {
      _cachedParsedSources.remove(source);
    }

    // Map unit sources into a Set of [Library]s using [_buildLibraries].
    final unitLibraries = {..._buildLibraries(units)};

    // Establish a mapping relationship from URI to Library
    final unitLibraryUriMap = {
      for (final library in unitLibraries) library.uri: library,
    };

    // Merge bridge libraries with unit libraries that share an identical URI
    final libraries = <Library>{};
    final mergedLibraryUris = <Uri>{};

    // Iterate over bridge libraries
    for (final bridgeLibrary in _bridgeDeclarations.keys) {
      // Wrap bridge declarations in this library as [DeclarationOrBridge]s
      final bridgeLibDeclarations = [
        for (final bridgeDeclaration in _bridgeDeclarations[bridgeLibrary]!)
          DeclarationOrBridge(-1, bridge: bridgeDeclaration),
      ];

      final uri = Uri.parse(bridgeLibrary);

      // See if there is already a unit library with an identical URI
      // If the two overlap, perform a merge operation
      final unitLibrary = unitLibraryUriMap[uri];
      if (unitLibrary != null) {
        /// Merge source code declarations from the unit library with the bridge
        libraries.add(
          unitLibrary.copyWith(
            declarations: [
              ...unitLibrary.declarations,
              ...bridgeLibDeclarations,
            ],
          ),
        );

        /// Document this is a merged library
        mergedLibraryUris.add(uri);
      } else {
        // If there is no existing unit library with an identical URI, create
        // a new [Library] with the bridge declarations
        libraries.add(
          Library(
            Uri.parse(bridgeLibrary),
            imports: [],
            exports: [],
            declarations: [
              for (final bridgeDeclaration
                  in _bridgeDeclarations[bridgeLibrary]!)
                DeclarationOrBridge(-1, bridge: bridgeDeclaration),
            ],
          ),
        );
      }
    }

    // At this point bridge libraries and merged libraries are already in the
    // [libraries] Set. Add the rest of the unit libraries that were not merged.
    unitLibraryUriMap.forEach((uri, library) {
      if (!mergedLibraryUris.contains(uri)) {
        libraries.add(library);
      }
    });

    var i = 0;
    final libraryIndexMap = <Library, int>{};
    final inverseIndexMap = <int, Library>{};
    final computedEntrypoints = <Uri>{};

    for (final library in libraries) {
      if (libraryIndexMap[library] == null) {
        libraryIndexMap[library] = i++;
      }

      inverseIndexMap[libraryIndexMap[library]!] = library;

      var isEntrypoint = extraEntrypoints.contains(library.uri.toString());
      if (isEntrypoint) computedEntrypoints.add(library.uri);
      for (final entrypoint in entrypoints) {
        if (library.uri.toString().endsWith(entrypoint)) {
          computedEntrypoints.add(library.uri);
          isEntrypoint = true;
        }
      }

      if (!isEntrypoint) {
        /// Discover entrypoints
        for (final declaration in library.declarations) {
          if (declaration.isBridge) {
            computedEntrypoints.add(library.uri);
            continue;
          }
          final d = declaration.declaration!;
          if (d is FunctionDeclaration) {
            final overrideAnno = d.metadata.firstWhereOrNull(
              (element) => element.name.name == 'RuntimeOverride',
            );
            if (overrideAnno != null) {
              computedEntrypoints.add(library.uri);
            }
          }
        }
      }
    }

    final reachableLibraries = _discoverReachableLibraries(
      libraries,
      computedEntrypoints,
    ).toSet();
    _entrypointLibraries = {
      for (final library in libraries)
        if (extraEntrypoints.contains(library.uri.toString()) ||
            entrypoints.any(
              (suffix) => library.uri.toString().endsWith(suffix),
            ))
          library.uri.toString(),
    };

    final discoveredIdentifiers = <Library, Map<String, Set<String>>>{};

    for (final lib in reachableLibraries) {
      final treeShaker = TreeShakeVisitor();
      discoveredIdentifiers[lib] = {};
      for (final decl in lib.declarations) {
        final d = decl.declaration;
        final names = DeclarationOrBridge.nameOf(decl);
        if (d != null) {
          d.visitChildren(treeShaker);
        }
        for (final name in names) {
          discoveredIdentifiers[lib]![name] = treeShaker.ctx.identifiers;
        }
        treeShaker.ctx.identifiers = {};
      }
    }

    // Resolve the export and import relationship of the libraries
    final visibleDeclarations = _resolveImportsAndExports(
      reachableLibraries,
      discoveredIdentifiers,
      computedEntrypoints,
      libraryIndexMap,
    );

    // Populate lookup tables [_topLevelDeclarationsMap],
    // [_instanceDeclarationsMap], and [_topLevelGlobalIndices], and generate
    // remaining library IDs
    for (final library in reachableLibraries) {
      final libraryIndex = libraryIndexMap[library]!;
      for (final declarationOrBridge in library.declarations) {
        _populateLookupTablesForDeclaration(libraryIndex, declarationOrBridge);
      }
    }

    // Pass a mapping of library URI to integer index into the context
    final libraryMapString = {
      for (final lib in reachableLibraries)
        lib.uri.toString(): libraryIndexMap[lib]!,
    };
    _ctx.libraryMap = libraryMapString;

    final visibleDeclarationsByIndex = {
      for (final lib in reachableLibraries)
        libraryIndexMap[lib]!: {...visibleDeclarations[lib]!},
    };

    final declarationTypes = <DeclarationOrBridge, TypeRef>{};

    for (final library in reachableLibraries) {
      final libraryIndex = libraryIndexMap[library]!;
      for (final declaration in library.declarations) {
        final type = _cacheTypeRef(libraryIndex, declaration);
        if (type != null) {
          declarationTypes[declaration] = type;
        }
      }
    }

    final visibleTypesByIndex = <int, Map<String, TypeRef>>{};
    for (final library in reachableLibraries) {
      final libraryIndex = libraryIndexMap[library]!;
      final declarations = visibleDeclarations[library]!;

      for (final entry in declarations.entries) {
        final name = entry.key;
        final dop = entry.value;
        if (dop.children != null) {
          final res = <String, TypeRef>{};
          for (final childName in dop.children!.keys) {
            final child = dop.children![childName]!;
            final cached = declarationTypes[child];
            if (cached == null) continue;
            res['$name.$childName'] = cached;
            if (child.isBridge) {
              final bridge = child.bridge!;
              final type0 = BridgeTypeRef.type(_ctx.typeRefIndexMap[cached]);
              if (bridge is BridgeClassDef) {
                child.bridge = bridge.copyWith(
                  type: bridge.type.copyWith(type: type0),
                );
              } else if (bridge is BridgeEnumDef) {
                child.bridge = bridge.copyWith(type: type0);
              } else {
                assert(false);
              }
            }
          }
          visibleTypesByIndex[libraryIndex] ??= {};
          visibleTypesByIndex[libraryIndex]!.addAll(res);
          continue;
        }
        visibleTypesByIndex[libraryIndex] ??= {};
        final declarationOrBridge = dop.declaration!;
        if (!declarationOrBridge.isBridge &&
            declarationOrBridge.declaration is TypeAlias &&
            declarationOrBridge.declaration is! ClassTypeAlias) {
          final alias = declarationOrBridge.declaration! as TypeAlias;
          _ctx.typeAliases.putIfAbsent(libraryIndex, () => {})[name] = alias;
          _ctx.typeAliasFiles[alias] = libraryIndex;
          continue;
        }
        final type = declarationTypes[declarationOrBridge];
        if (type == null) continue;
        if (declarationOrBridge.isBridge) {
          final bridge = declarationOrBridge.bridge!;
          final type0 = BridgeTypeRef.type(_ctx.typeRefIndexMap[type]);
          if (bridge is BridgeClassDef) {
            declarationOrBridge.bridge = bridge.copyWith(
              type: bridge.type.copyWith(type: type0),
            );
          } else if (bridge is BridgeEnumDef) {
            declarationOrBridge.bridge = bridge.copyWith(type: type0);
          } else {
            assert(false);
          }
        }
        visibleTypesByIndex[libraryIndex]![name] = type;
      }
    }

    _ctx.topLevelDeclarationsMap = _topLevelDeclarationsMap;
    _ctx.instanceDeclarationsMap = _instanceDeclarationsMap;
    _ctx.visibleDeclarations = visibleDeclarationsByIndex;
    _ctx.visibleTypes = visibleTypesByIndex;

    // Fold `with`-clause mixin members into each applying class's instance
    // map (own members win; a later mixin shadows an earlier one), and give a
    // class type alias an entry for each superclass constructor so `C.name`
    // calls bind against `S.name`'s parameter layout.
    for (final library in reachableLibraries) {
      final libraryIndex = libraryIndexMap[library]!;
      _ctx.library = libraryIndex;
      for (final dop in library.declarations) {
        final dec = dop.declaration;
        if (dec is! ClassDeclaration &&
            dec is! ClassTypeAlias &&
            dec is! EnumDeclaration) {
          continue;
        }
        final (superclass, mixins, _, _) = classLikeClauses(dec!);
        final clsName = declarationName(dec);
        final classMembers = _instanceDeclarationsMap[libraryIndex]![clsName];
        for (final mixinType in mixins.reversed) {
          // Only the mixin's member names matter here, so resolve the bare
          // name — generic arguments (e.g. `M<T>`) may reference type
          // parameters that don't resolve during the prepass.
          final prefix = mixinType.importPrefix;
          final mixinName = prefix == null
              ? mixinType.name.lexeme
              : '${prefix.name.lexeme}.${mixinType.name.lexeme}';
          final ref = _ctx.visibleTypes[libraryIndex]![mixinName];
          if (ref == null) {
            continue;
          }
          _instanceDeclarationsMap[ref.file]?[ref.name]?.forEach(
            (mName, member) =>
                classMembers?.putIfAbsent(mName, () => member),
          );
          // Seed the mixin's type parameters with the application's type
          // arguments so `T`-annotated signatures in the folded members
          // resolve to concrete types (or the class's own parameters).
          _seedMixinTypeParams(_ctx, libraryIndex, clsName, dec, mixinType, ref);
        }
        if (dec is ClassTypeAlias && superclass != null) {
          final prefix = superclass.importPrefix;
          final superName = prefix == null
              ? superclass.name.lexeme
              : '${prefix.name.lexeme}.${superclass.name.lexeme}';
          final superRef = _ctx.visibleTypes[libraryIndex]![superName];
          if (superRef != null) {
            final superCtors = [
              for (final entry
                  in _topLevelDeclarationsMap[superRef.file]!.entries)
                if (entry.key.startsWith('${superRef.name}.') &&
                    entry.value.declaration is ConstructorDeclaration &&
                    (entry.value.declaration! as ConstructorDeclaration)
                            .factoryKeyword ==
                        null)
                  entry,
            ];
            for (final entry in superCtors) {
              final ctorName = entry.key.substring(
                superRef.name.length + 1,
              );
              _topLevelDeclarationsMap[libraryIndex]!.putIfAbsent(
                '$clsName.$ctorName',
                () => entry.value,
              );
            }
          }
        }
      }
    }

    unboxedAcrossFunctionBoundaries = {
      CoreTypes.int.ref(_ctx),
      CoreTypes.double.ref(_ctx),
      CoreTypes.bool.ref(_ctx),
    };

    for (final library in reachableLibraries) {
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

    _ctx.topLevelGlobalIndices = _topLevelGlobalIndices;

    // Index which types are named in a superinterface position so member
    // calls on them are not devirtualized by the direct-call fast path.
    _topLevelDeclarationsMap.forEach((libraryIndex, declarations) {
      _ctx.library = libraryIndex;
      for (final tlDeclaration in declarations.values) {
        if (tlDeclaration.isBridge) continue;
        final declaration = tlDeclaration.declaration;
        final (name, typeParameters) = switch (declaration) {
          ClassDeclaration(:final namePart) => (
            namePart.typeName.lexeme,
            namePart.typeParameters,
          ),
          MixinDeclaration(:final name, :final typeParameters) => (
            name.lexeme,
            typeParameters,
          ),
          EnumDeclaration(:final namePart) => (
            namePart.typeName.lexeme,
            namePart.typeParameters,
          ),
          ClassTypeAlias(:final name, :final typeParameters) => (
            name.lexeme,
            typeParameters,
          ),
          _ => ('', null),
        };
        final ownParams = classTypeParameterRefs(
          libraryIndex,
          name,
          typeParameters,
        );
        for (final namedType in superinterfacesOf(declaration)) {
          TypeRef? resolved;
          try {
            resolved = TypeRef.fromAnnotation(
              _ctx,
              libraryIndex,
              namedType,
              typeParameters: ownParams,
            );
          } on CompileError {
            // Unresolvable clause types (e.g. mixins that aren't registered
            // as types yet) — leave the class eligible for devirtualization;
            // the missing name would fail compilation anyway elsewhere.
            continue;
          }
          _ctx.subclassedTypes.add('${resolved.file}:${resolved.name}');
        }
      }
    });

    try {
      /// Compile statics first so we can infer their type
      _topLevelDeclarationsMap.forEach((key, value) {
        final visibleInLibrary = visibleDeclarationsByIndex[key];
        if (visibleInLibrary == null) {
          return;
        }
        value.forEach((name, tlDeclaration) {
          if (tlDeclaration.isBridge || !visibleInLibrary.containsKey(name)) {
            return;
          }
          final declaration = tlDeclaration.declaration!;
          _ctx.library = key;
          if (declaration is VariableDeclaration &&
              declaration.parent!.parent is TopLevelVariableDeclaration) {
            compileDeclaration(declaration, _ctx);
          } else if (declaration is ClassDeclaration) {
            _ctx.currentClass = declaration;
            for (final d
                in declaration.body.members.whereType<FieldDeclaration>().where(
                  (e) => e.isStatic,
                )) {
              compileFieldDeclaration(-1, d, _ctx, declaration);
            }
            _ctx.currentClass = null;
          } else if (declaration is MixinDeclaration) {
            _ctx.currentClass = declaration;
            for (final d
                in declaration.body.members.whereType<FieldDeclaration>().where(
                  (e) => e.isStatic,
                )) {
              compileFieldDeclaration(-1, d, _ctx, declaration);
            }
            _ctx.currentClass = null;
          } else if (declaration is EnumDeclaration) {
            _ctx.currentClass = declaration;
            for (final d
                in declaration.body.members.whereType<FieldDeclaration>().where(
                  (e) => e.isStatic,
                )) {
              compileFieldDeclaration(-1, d, _ctx, declaration);
            }
            _ctx.currentClass = null;
          }
        });
      });

      /// Compile the rest of the declarations
      _topLevelDeclarationsMap.forEach((key, value) {
        _ctx.topLevelDeclarationPositions[key] = {};
        _ctx.instanceDeclarationPositions[key] = {};
        _ctx.instanceGetterIndices[key] = {};
        final visibleInLibrary = visibleDeclarationsByIndex[key];
        if (visibleInLibrary == null) {
          return;
        }
        value.forEach((name, tlDeclaration) {
          if (tlDeclaration.isBridge || !visibleInLibrary.containsKey(name)) {
            return;
          }
          final declaration = tlDeclaration.declaration!;
          if (declaration is ConstructorDeclaration ||
              declaration is MethodDeclaration ||
              declaration is VariableDeclaration) {
            return;
          }
          _ctx.library = key;
          compileDeclaration(declaration, _ctx);

          _ctx.finishMethod();
        });
      });
    } on CompileError catch (e, stk) {
      Error.throwWithStackTrace(e.copyWithContext(_ctx), stk);
    }

    _ctx.finishMethod();

    for (final entry in _ctx.functionGraphs.entries) {
      final graph = entry.value;
      graph.removeUnreachableBlocks();
      validateControlFlowGraph(graph);
      _ctx.ssaFunctionGraphs[entry.key] = buildSSA(graph);
    }

    // Optimization and lowering are separate stages. Keep the typed graphs
    // available for inspection while the register VM backend is being built.

    for (final library in reachableLibraries) {
      for (final dec in library.declarations) {
        if (dec.isBridge) {
          final bridge = dec.bridge;
          if (bridge is BridgeClassDef && bridge.bridge) {
            _reassignBridgeStaticFunctionIndicesForClass(bridge);
          }
        }
      }
    }

    return emit();
  }

  Program _emitProgram() {
    final typeIds = <int, Map<String, int>>{};

    for (final t in _ctx.typeRefIndexMap.entries) {
      final type = t.key;
      typeIds.putIfAbsent(type.file, () => {})[type.name] = t.value;
    }
    final backend = TypedBackend(_ctx);
    final typed = backend.compileEntrypoints([
      for (final library in _entrypointLibraries)
        for (final name
            in _ctx
                    .topLevelDeclarationPositions[_ctx.libraryMap[library]]
                    ?.keys ??
                const <String>[])
          (library, name),
    ]);
    // Backend metadata can introduce instantiated parameter and collection
    // types. Build both tables in an index loop: resolving one descriptor can
    // discover its type arguments or supertypes and append more descriptors.
    _ctx.typeTypes.clear();
    _ctx.runtimeTypeDescriptors.clear();
    for (var i = 0; i < _ctx.runtimeTypeList.length; i++) {
      final type = _ctx.runtimeTypeList[i];
      _ctx.typeTypes.add(type.resolveTypeChain(_ctx).getRuntimeIndices(_ctx));
      _ctx.runtimeTypeDescriptors.add(type.runtimeDescriptor(_ctx));
    }
    int relocate(int id) =>
        backend.functionIndices[id] ??
        (throw StateError('No bytecode for function $id'));
    return Program(
      typeIds,
      _ctx.typeTypes,
      typed,
      _ctx.libraryMap,
      _ctx.bridgeStaticFunctionIndices,
      _ctx.constantPool.pool,
      _ctx.enumValueIndices,
      {
        for (final entry in _ctx.runtimeOverrideMap.entries)
          if (backend.functionIndices.containsKey(entry.value.offset))
            entry.key: OverrideSpec(
              relocate(entry.value.offset),
              entry.value.versionConstraint,
            ),
      },
      typeDescriptors: _ctx.runtimeTypeDescriptors,
    );
  }

  /// For testing purposes. Compile code, write it to a byte stream, load it,
  /// and run it.
  Runtime compileWriteAndLoad(Map<String, Map<String, String>> packages) {
    final program = compile(packages);

    final ob = program.write();

    return Runtime(ob.buffer);
  }

  /// Registers [name] in the library's top-level declaration map, failing on
  /// duplicate definitions.
  void _declareTopLevel(
    int libraryIndex,
    String name,
    DeclarationOrBridge value,
    AstNode source,
  ) {
    final map = _topLevelDeclarationsMap[libraryIndex]!;
    if (map.containsKey(name)) {
      throw CompileError(
        'Cannot define "$name" twice in the same library',
        source,
        libraryIndex,
      );
    }
    map[name] = value;
  }

  /// Declares a top-level binding and allocates it a global slot.
  void _declareGlobal(
    int libraryIndex,
    String name,
    DeclarationOrBridge value,
    AstNode source,
  ) {
    _declareTopLevel(libraryIndex, name, value, source);
    _topLevelGlobalIndices.putIfAbsent(libraryIndex, () => {})[name] =
        _ctx.globalIndex++;
    _ctx.topLevelVariableInferredTypes.putIfAbsent(libraryIndex, () => {});
  }

  void _populateLookupTablesForDeclaration(
    int libraryIndex,
    DeclarationOrBridge declarationOrBridge,
  ) {
    _topLevelDeclarationsMap.putIfAbsent(libraryIndex, () => {});
    _instanceDeclarationsMap.putIfAbsent(libraryIndex, () => {});

    if (declarationOrBridge.isBridge) {
      final bridge = declarationOrBridge.bridge!;
      if (bridge is BridgeClassDef) {
        final spec = bridge.type.type.spec!;
        _topLevelDeclarationsMap[libraryIndex]![spec.name] =
            DeclarationOrBridge(libraryIndex, bridge: bridge);
        for (final constructor in bridge.constructors.entries) {
          _topLevelDeclarationsMap[libraryIndex]!['${spec.name}.${constructor.key}'] =
              DeclarationOrBridge(libraryIndex, bridge: constructor.value);
        }
        for (final method in bridge.methods.entries) {
          if (method.value.isStatic) {
            _topLevelDeclarationsMap[libraryIndex]!['${spec.name}.${method.key}'] =
                DeclarationOrBridge(libraryIndex, bridge: method.value);
          }
        }
      } else if (bridge is BridgeEnumDef) {
        final spec = bridge.type.spec!;
        _topLevelDeclarationsMap[libraryIndex]![spec.name] =
            DeclarationOrBridge(libraryIndex, bridge: bridge);
      } else if (bridge is BridgeFunctionDeclaration) {
        _topLevelDeclarationsMap[libraryIndex]![bridge.name] =
            DeclarationOrBridge(libraryIndex, bridge: bridge);
      }
      return;
    }

    final declaration = declarationOrBridge.declaration!;

    if (declaration is TopLevelVariableDeclaration) {
      for (final variable in declaration.variables.variables) {
        _declareGlobal(
          libraryIndex,
          variable.name.lexeme,
          DeclarationOrBridge(libraryIndex, declaration: variable),
          variable,
        );
      }
      return;
    }

    final name = declarationName(declaration);
    _declareTopLevel(
      libraryIndex,
      name,
      DeclarationOrBridge(libraryIndex, declaration: declaration),
      declaration,
    );

    final members = switch (declaration) {
      ClassDeclaration d => d.body.members,
      EnumDeclaration d => d.body.members,
      MixinDeclaration d => d.body.members,
      _ => null,
    };
    if (declaration is ClassTypeAlias) {
      // No own members, but the mixin fold pass writes into this map.
      _instanceDeclarationsMap[libraryIndex]![name] = {};
    }
    if (members == null) return;

    _instanceDeclarationsMap[libraryIndex]![name] = {};
    final instanceDeclarations = _instanceDeclarationsMap[libraryIndex]![name]!;

    if (declaration is EnumDeclaration) {
      _ctx.enumValueIndices.putIfAbsent(libraryIndex, () => {})[name] = {};
      for (final constant in declaration.body.constants) {
        final cname = '$name.${constant.name.lexeme}';
        _declareGlobal(
          libraryIndex,
          cname,
          DeclarationOrBridge(libraryIndex, declaration: constant),
          constant,
        );
        _ctx.enumValueIndices[libraryIndex]![name]![constant.name.lexeme] =
            _topLevelGlobalIndices[libraryIndex]![cname]!;
      }
    }

    for (final member in members) {
      if (member is MethodDeclaration) {
        var mName = member.name.lexeme;
        if (member.isStatic) {
          _topLevelDeclarationsMap[libraryIndex]!['$name.$mName'] =
              DeclarationOrBridge(libraryIndex, declaration: member);
        } else {
          if (member.isGetter) {
            mName += '*g';
          } else if (member.isSetter) {
            mName += '*s';
          }
          instanceDeclarations[mName] = member;
        }
      } else if (member is FieldDeclaration) {
        for (final field in member.fields.variables) {
          if (member.isStatic) {
            _declareGlobal(
              libraryIndex,
              '$name.${field.name.lexeme}',
              DeclarationOrBridge(libraryIndex, declaration: field),
              field,
            );
          } else {
            instanceDeclarations[field.name.lexeme] = field;
          }
        }
      } else if (member is ConstructorDeclaration) {
        final mName = ctorNameOf(member.name?.lexeme);
        _topLevelDeclarationsMap[libraryIndex]!['$name.$mName'] =
            DeclarationOrBridge(libraryIndex, declaration: member);
      } else {
        throw CompileError(
          'Not a NamedCompilationUnitMember',
          member,
          libraryIndex,
        );
      }
    }
  }

  TypeRef? _cacheTypeRef(
    int libraryIndex,
    DeclarationOrBridge declarationOrBridge,
  ) {
    if (declarationOrBridge.isBridge) {
      final bridge = declarationOrBridge.bridge;
      if (bridge is! BridgeClassDef && bridge is! BridgeEnumDef) {
        return null;
      }
      final type = bridge is BridgeClassDef
          ? bridge.type.type
          : (bridge as BridgeEnumDef).type;
      if (type.cacheId != null) {
        return TypeRef.fromBridgeTypeRef(_ctx, type);
      }
      final spec = type.spec!;
      return TypeRef.cache(
        _ctx,
        libraryIndex,
        spec.name,
        fileRef: libraryIndex,
      );
    } else {
      final declaration = declarationOrBridge.declaration!;
      if (declaration is! ClassDeclaration &&
          declaration is! EnumDeclaration &&
          declaration is! MixinDeclaration &&
          declaration is! ClassTypeAlias) {
        return null;
      }
      final name = declarationName(declaration);
      return TypeRef.cache(_ctx, libraryIndex, name, fileRef: libraryIndex);
    }
  }

  /// Allocates a bridge static function index to a member key of the form
  /// `ClassName.member` (with `*g`/`*s` suffixes for accessors).
  void _assignBridgeIndex(int library, String key) {
    _ctx.bridgeStaticFunctionIndices.putIfAbsent(library, () => {})[key] =
        _bridgeStaticFunctionIdx++;
  }

  void _assignBridgeStaticFunctionIndicesForClass(BridgeClassDef classDef) {
    final type = TypeRef.fromBridgeTypeRef(_ctx, classDef.type.type);
    final lib = type.file;
    classDef.constructors.forEach(
      (name, _) => _assignBridgeIndex(lib, '${type.name}.$name'),
    );
    classDef.methods.forEach((name, method) {
      if (method.isStatic) _assignBridgeIndex(lib, '${type.name}.$name');
    });
    classDef.getters.forEach((name, getter) {
      if (getter.isStatic) _assignBridgeIndex(lib, '${type.name}.$name*g');
    });
    classDef.setters.forEach((name, setter) {
      if (setter.isStatic) _assignBridgeIndex(lib, '${type.name}.$name*s');
    });
    classDef.fields.forEach((name, field) {
      if (field.isStatic) {
        _assignBridgeIndex(lib, '${type.name}.$name*g');
        _assignBridgeIndex(lib, '${type.name}.$name*s');
      }
    });
  }

  void _reassignBridgeStaticFunctionIndicesForClass(BridgeClassDef classDef) {
    final type = TypeRef.fromBridgeTypeRef(_ctx, classDef.type.type);
    final lib = type.file;

    classDef.constructors.forEach((name, constructor) {
      final idc = _ctx.bridgeStaticFunctionIndices[lib]!;
      final id = '${type.name}.$name';
      final prev = classDef.wrap ? idc[id]! : idc.remove(id)!;
      _ctx.bridgeStaticFunctionIndices[lib]!['#${type.name}.$name'] = prev;
    });
  }

  void _assignBridgeGlobalValueIndicesForEnum(BridgeEnumDef enumDef) {
    final type = TypeRef.fromBridgeTypeRef(_ctx, enumDef.type);
    _ctx.enumValueIndices.putIfAbsent(type.file, () => {})[type.name] = {
      for (final value in enumDef.values) value: _ctx.globalIndex++,
    };
  }

  void _assignBridgeStaticFunctionIndicesForFunction(
    int libraryIndex,
    BridgeFunctionDeclaration functionDef,
  ) {
    _ctx.bridgeStaticFunctionIndices.putIfAbsent(
      libraryIndex,
      () => {},
    )[functionDef.name] = _bridgeStaticFunctionIdx++;
  }

  @override
  void addExportedLibraryMapping(String libraryUri, String exportUri) {
    // does nothing in compiler context
  }
}

List<Library> _buildLibraries(Iterable<DartCompilationUnit> units) {
  /// Self-incrementing ID generator, each [DartCompilationUnit] has a unique
  /// integer ID that identifies it. These IDs are local to this function, since
  /// they are only used to build the [Library]s which will be later associated
  /// with their own IDs.
  var i = 0;

  /// ID to [DartCompilationUnit] mapping
  final compilationUnitMap = <int, DartCompilationUnit>{};

  /// URI to ID mapping
  final uriMap = <String, int>{};

  /// Library name to ID mapping
  final libraryIdMap = <String, int>{};

  for (final unit in units) {
    /// Establish a mapping relationship
    compilationUnitMap[i] = unit;
    uriMap[unit.uri.toString()] = i;
    if (unit.library != null && unit.library!.name != null) {
      /// Library instruction for source files that start with "library *****"
      libraryIdMap[unit.library!.name!.toString()] = i;
    }
    i++;
  }

  /// CompilationUnit graph structure
  final cuGraph = CompilationUnitGraph(
    compilationUnitMap,
    uriMap,
    libraryIdMap,
  );

  // Calculate strong link components using the Dijkstra path-based strong
  // component algorithm.
  // Accounting for `library` directives and `part` / `part of` relationships,
  // the algorithm will group source files into libraries.
  // Return type is List<List<int>> where each inner list is a list of source
  // file IDs that should be joined into a single library
  final libGroups = computeStrongComponents(cuGraph);

  final libraries = <Library>[];
  for (final group in libGroups) {
    final primaryId = group.length == 1
        ? group[0]
        : group.firstWhere((e) => compilationUnitMap[e]!.partOf == null);
    final primary = compilationUnitMap[primaryId]!;
    final library = Library(
      primary.uri,
      library: primary.library?.name?.toString(),
      imports: primary.imports,
      exports: primary.exports,
      declarations: group
          .map((e) => compilationUnitMap[e]!)
          .fold(
            [],
            (pv, element) => pv
              ..addAll(
                element.declarations.map(
                  (d) => DeclarationOrBridge(-1, declaration: d),
                ),
              ),
          ),
    );
    libraries.add(library);
  }

  return libraries;
}

/// Analyze the import and export relationships of the library, and return a
/// mapping of library to its visible declarations.
/// The visible declarations of a library are the declarations of the library
/// itself, as well as the declarations of the libraries it imports, including
/// declarations exported by another imported library. A graph is used to
/// resolve long export chains.
Map<Library, Map<String, DeclarationOrPrefix>> _resolveImportsAndExports(
  Iterable<Library> libraries,
  Map<Library, Map<String, Set<String>>> usedIdentifiers,
  Set<Uri> entrypoints,
  Map<Library, int> libraryIds,
) {
  /// URI-Library mapping
  final uriMap = {for (final l in libraries) l.uri: l};

  /// A directed graph based on library exports, allowing the resolution of
  /// export chains.
  /// See test/lib_composition_test.dart "Export chains" for an example of how
  /// this is used.
  final exportGraph = DirectedGraph<Uri>({
    // Pass in a Map representing edges in the graph.
    // Each edge represents a library, with the key being the library's URI
    // and the value being a set of its exports.
    for (final l in libraries)
      l.uri: {
        for (final export in l.exports) l.uri.resolve(export.uri.stringValue!),
      },
  });

  final crawler = CachedFastCrawler(exportGraph.edges);

  final result = <Library, Map<String, DeclarationOrPrefix>>{};
  final usedDeclarationsForLibrary = <int, Set<String>>{};

  final worklist = <Library>[];
  final importMap = <Library, List<_Import>>{};
  final importedDeclarationsMap =
      <Library, Map<Library, Iterable<(String, DeclarationOrBridge)>>>{};

  // Traversing libraries
  for (final l in libraries) {
    // All visible declarations under this Library
    final visibleDeclarationsLib = <String, DeclarationOrPrefix>{
      for (final d in DeclarationOrBridge.expand(l.declarations))
        // Key: the expanded name of the declaration (see [_expandDeclarations])
        // Value: DeclarationOrPrefix (declaration content, and store the ID
        // of the containing library)
        d.$1: DeclarationOrPrefix(
          declaration: d.$2..sourceLib = libraryIds[l]!,
        ),
    };

    final dartCoreUri = Uri.parse('dart:core');
    final isDartCore = l.uri == dartCoreUri;

    final isEntrypoint = entrypoints.contains(l.uri);
    final ids = isEntrypoint
        ? usedIdentifiers[l]?.values.expand((e) => e).toSet()
        : null;

    final imports = [
      ...l.imports
          .map((e) => _Import.resolve(e, l.uri, e.prefix?.name, e.combinators))
          .whereNot(
            (import) =>
                import.uri.toString().startsWith('package:eval_annotation'),
          ),
      if (!isDartCore) _Import(dartCoreUri, null),
    ];

    importMap[l] = imports;
    importedDeclarationsMap[l] = {
      l: DeclarationOrBridge.expand(l.declarations),
    };

    /// Iterate over the library's imports including the implicit import of
    /// dart:core.
    for (final import in imports) {
      /// Use the export graph to find all declarations that become visible
      /// through this import.
      /// directed_graph returns a tree structure with import.uri as the root
      /// and exported libraries as leaves.
      final tree = crawler.tree(import.uri);

      /// Flatten and deduplicate the tree to get a list of all libraries that
      /// are visible through this import.
      final importedLibs = [...tree.map((e) => e.last), import.uri]
          .map(
            (e) =>
                uriMap[e] ??
                (throw CompileError(
                  "Cannot find import '$e' (while parsing '${l.uri}')",
                )),
          )
          .toSet();

      /// Get all the [ExportDirective]s of the imported library tree. While
      /// we've already found all of the libraries that are visible through
      /// this import, we still need access to the raw [ExportDirective]s to
      /// identify which declarations are visible (since some exports may use
      /// `show` or `hide`).
      final exportsPerUri = <Uri, List<ExportDirective>>{};
      for (final lib in importedLibs) {
        for (final export in lib.exports) {
          final uri = lib.uri.resolve(export.uri.stringValue!);
          final uriList = exportsPerUri[uri];
          if (uriList != null) {
            uriList.add(export);
          } else {
            exportsPerUri[uri] = [export];
          }
        }
      }

      final visibleDeclarations = <(String, DeclarationOrBridge)>{};

      for (final lib in importedLibs) {
        final libId = libraryIds[lib]!;
        final expandedDeclarations = DeclarationOrBridge.expand(
          lib.declarations,
        );
        final importedDeclarations = expandedDeclarations
            .where(
              (element) =>
                  _combinatorListAccepts(import.combinators, element.$1, true),
            )
            .toList();
        importedDeclarationsMap[l]![lib] = importedDeclarations;

        final result = <(String, DeclarationOrBridge)>{};

        for (final declaration in importedDeclarations) {
          if (lib.uri == import.uri) {
            result.add(declaration..$2.sourceLib = libId);
          }
          final exports = exportsPerUri[lib.uri] ?? <ExportDirective>[];
          for (final export in exports) {
            final combinators = export.combinators;
            if (_combinatorListAccepts(combinators, declaration.$1, false)) {
              result.add(declaration..$2.sourceLib = libId);
            }
          }
          if (isEntrypoint && ids!.contains(declaration.$1)) {
            usedDeclarationsForLibrary[libId] ??= {'main'};
            usedDeclarationsForLibrary[libId]!.add(declaration.$1);
            if (!worklist.contains(lib)) {
              worklist.add(lib);
            }
          }
        }

        visibleDeclarations.addAll(result);
      }

      if (import.prefix != null) {
        // Multiple imports may share one prefix (`import a as p; import b as
        // p;`) — merge their members instead of overwriting.
        final dop = visibleDeclarationsLib[import.prefix!] ??=
            DeclarationOrPrefix(children: {});
        (dop.children ??= {}).addAll({
          for (final d in visibleDeclarations) d.$1: d.$2,
        });
      } else {
        visibleDeclarationsLib.addAll({
          for (final d in visibleDeclarations)
            d.$1: DeclarationOrPrefix(declaration: d.$2),
        });
      }
    }

    result[l] = visibleDeclarationsLib;
  }

  final processedImports = <String>{};

  /// Run tree-shaking
  while (worklist.isNotEmpty) {
    final library = worklist.removeLast();
    Map<int, Set<String>> applyUsedDeclarations = {};
    for (final dec in (usedDeclarationsForLibrary[libraryIds[library]] ?? {})) {
      final ids = usedIdentifiers[library]?[dec];
      if (ids == null) continue;
      final importsWithImplicitSelf = [
        ...importMap[library]!,
        _Import(library.uri, null),
      ];

      final usedSelf = <String>{};
      final selfList = result[library]?.entries.toList() ?? [];
      while (selfList.isNotEmpty) {
        final declaration = selfList.removeLast();
        if (usedSelf.contains(declaration.key) ||
            !ids.contains(declaration.key)) {
          continue;
        }
        final s = usedIdentifiers[library]![declaration.key];
        for (final id in s ?? {}) {
          ids.add(id);
          final selfDec = result[library]?[id];
          if (usedSelf.contains(id) || selfDec == null) continue;
          selfList.add(MapEntry(id, selfDec));
        }
        usedSelf.add(declaration.key);
      }

      for (final import in importsWithImplicitSelf) {
        // The scan of this import's declarations is specific to [dec]: each
      // used declaration contributes its own identifier set, so dedupe per
      // (library, import, dec) rather than per (library, import).
      final iid = '${library.uri}:${import.uri}:$dec';
        if (processedImports.contains(iid)) {
          continue;
        }
        processedImports.add(iid);
        final lib = uriMap[import.uri]!;
        final decs = result[library]?.entries.toList();
        if (decs == null) continue;
        for (final declaration in decs) {
          if (ids.contains(declaration.key)) {
            final applyLib =
                declaration.value.declaration?.sourceLib ?? libraryIds[lib]!;
            applyUsedDeclarations[applyLib] ??= {'main'};
            applyUsedDeclarations[applyLib]!.add(declaration.key);
            if (!worklist.contains(lib)) {
              worklist.add(lib);
            }
          }
        }
      }
    }
    for (final libId in applyUsedDeclarations.keys) {
      usedDeclarationsForLibrary[libId] ??= {};
      usedDeclarationsForLibrary[libId]!.addAll(applyUsedDeclarations[libId]!);
    }
  }

  for (final l in libraries) {
    if (entrypoints.contains(l.uri)) {
      continue;
    }
    l.declarations = l.declarations
        .where(
          (declaration) =>
              declaration.isBridge ||
              DeclarationOrBridge.nameOf(declaration).any(
                (name) => {
                  ...?usedDeclarationsForLibrary[libraryIds[l]],
                }.contains(name),
              ),
        )
        .toList();
    /*result[l]!.removeWhere((key, d) {
      final dec = d.declaration;
      if (dec == null || !dec.isBridge) {
        return !(usedDeclarationsForLibrary[libraryIds[l]]?.contains(key) ?? true);
      }
      return false; // Bridges are always visible
    });*/
  }

  return result;
}

bool _combinatorListAccepts(
  Iterable<Combinator> combinators,
  String name,
  bool rejectInvalid,
) {
  if (name.startsWith('_')) return false;
  if (combinators.isEmpty) {
    return true;
  }
  for (final combinator in combinators) {
    if (combinator is ShowCombinator) {
      final shown = {for (final n in combinator.shownNames) n.name};
      if (shown.contains(name)) {
        return true;
      }
      if (rejectInvalid) return false;
    } else if (combinator is HideCombinator) {
      final hidden = {for (final n in combinator.hiddenNames) n.name};
      if (!hidden.contains(name)) {
        return true;
      }
      if (rejectInvalid) return false;
    } else {
      throw CompileError(
        'Unsupported import combinator ${combinator.runtimeType}',
      );
    }
  }
  return false;
}

/// Given the list of entrypoint libraries, recursively find all library IDs
/// that are reachable through imports and exports using a graph.
Iterable<Library> _discoverReachableLibraries(
  Iterable<Library> libraries,
  Iterable<Uri> entrypoints,
) sync* {
  final uriMap = {for (final l in libraries) l.uri: l};
  final libraryGraph = DirectedGraph<Uri>({
    for (final l in libraries)
      l.uri: {
        for (final import in l.imports) l.uri.resolve(import.uri.stringValue!),
        for (final export in l.exports) l.uri.resolve(export.uri.stringValue!),
      },
  });

  yield uriMap[Uri.parse('dart:core')]!;
  yield uriMap[Uri.parse('dart:async')]!;
  yield uriMap[Uri.parse('dart:io')]!;

  for (final entrypoint in entrypoints) {
    yield uriMap[entrypoint]!;
    final tree = FastCrawler(libraryGraph.edges).tree(entrypoint);
    yield* tree
        .map((branch) => branch.last)
        .whereNot((e) => e.toString().startsWith('package:eval_annotation'))
        .where((e) => uriMap.containsKey(e))
        .map((e) => uriMap[e]!);
  }
}

class _Import {
  final Uri uri;
  final String? prefix;
  final List<Combinator> combinators;

  _Import(this.uri, this.prefix, [this.combinators = const []]);

  factory _Import.resolve(
    ImportDirective import,
    Uri base,
    String? prefix, [
    List<Combinator> combinators = const [],
  ]) {
    final uri = Uri.parse(import.uri.stringValue!);
    return _Import(
      base.resolveUri(uri),
      import.prefix?.name,
      import.combinators,
    );
  }
}

/// The named types a class-like declaration places in superinterface position
/// (`extends`, `with`, `implements`, `on`), used to suppress unsound
/// devirtualization of member calls on the named types.
Iterable<NamedType> superinterfacesOf(AstNode? declaration) sync* {
  switch (declaration) {
    case ClassDeclaration(
      :final extendsClause,
      :final withClause,
      :final implementsClause,
    ):
      if (extendsClause != null) yield extendsClause.superclass;
      yield* withClause?.mixinTypes ?? const Iterable.empty();
      yield* implementsClause?.interfaces ?? const Iterable.empty();
    case MixinDeclaration(:final onClause, :final implementsClause):
      yield* onClause?.superclassConstraints ?? const Iterable.empty();
      yield* implementsClause?.interfaces ?? const Iterable.empty();
    case ClassTypeAlias(
      :final superclass,
      :final withClause,
      :final implementsClause,
    ):
      yield superclass;
      yield* withClause.mixinTypes;
      yield* implementsClause?.interfaces ?? const Iterable.empty();
    case EnumDeclaration(:final withClause, :final implementsClause):
      yield* withClause?.mixinTypes ?? const Iterable.empty();
      yield* implementsClause?.interfaces ?? const Iterable.empty();
  }
}


/// Seeds the mixin's type parameters into [ctx.temporaryTypes] so signatures
/// of its folded members resolve `T`-style annotations to the application's
/// type arguments — a concrete type for `M<int>`, or the class's own type
/// parameter for `M<T>`. Entries resolve in the mixin's library, where the
/// member signatures are interpreted.
void _seedMixinTypeParams(
  CompilerContext ctx,
  int libraryIndex,
  String clsName,
  Declaration dec,
  NamedType mixinType,
  TypeRef ref,
) {
  final mixinDecl =
      ctx.topLevelDeclarationsMap[ref.file]?[ref.name]?.declaration;
  final mixinParams = switch (mixinDecl) {
    MixinDeclaration m => m.typeParameters?.typeParameters,
    ClassDeclaration c => c.namePart.typeParameters?.typeParameters,
    _ => null,
  };
  if (mixinParams == null || mixinParams.isEmpty) {
    return;
  }
  final classParams = classLikeClauses(dec).$4?.typeParameters;
  final mixinArgs = mixinType.typeArguments?.arguments;
  final temps = ctx.temporaryTypes[ref.file] ??= {};
  for (var i = 0; i < mixinParams.length; i++) {
    TypeRef? argRef;
    if (mixinArgs != null && i < mixinArgs.length) {
      argRef = resolveAppliedTypeArgument(
        ctx,
        libraryIndex,
        clsName,
        classParams,
        mixinArgs[i],
      );
    }
    final bound = mixinParams[i].bound;
    temps.putIfAbsent(
      mixinParams[i].name.lexeme,
      () =>
          argRef ??
          (bound == null
              ? CoreTypes.dynamic.ref(ctx)
              : TypeRef.fromAnnotation(ctx, ref.file, bound)),
    );
  }
}
