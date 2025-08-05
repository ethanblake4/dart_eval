import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/builtins.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/declaration/field.dart';
import 'package:dart_eval/src/eval/compiler/model/diagnostic_mode.dart';
import 'package:dart_eval/src/eval/compiler/model/library.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/program.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/compiler/model/compilation_unit.dart';
import 'package:dart_eval/src/eval/compiler/util.dart';
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

  var _ctx = CompilerContext(0);

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
    DartTypedDataPlugin()
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
          'Cannot define a bridge class that\'s not either bridge or wrap');
    }
    final type = classDef.type;
    final spec = type.type.spec;

    if (spec == null) {
      throw CompileError(
          'Cannot define a bridge class that\'s already resolved, a ref, or a generic function type');
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
          'Cannot define a bridge enum that\'s already resolved, a ref, or a generic function type');
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
    final sources = packages.entries.expand((packageEntry) =>
        packageEntry.value.entries.map((library) => DartSource(
            'package:${packageEntry.key}/${library.key}', library.value)));

    return compileSources(sources);
  }

  /// Compile a unit set of Dart code into a program
  Program compileSources(
      [Iterable<DartSource> sources = const [], bool debugPerf = true]) {
    _topLevelDeclarationsMap = <int, Map<String, DeclarationOrBridge>>{};
    _topLevelGlobalIndices = <int, Map<String, int>>{};
    _instanceDeclarationsMap = <int, Map<String, Map<String, Declaration>>>{};
    _bridgeStaticFunctionIdx = 0;

    // Create a compilation context
    _ctx = CompilerContext(0, version: version);

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
    final unitLibraries = {
      ..._buildLibraries(units),
    };

    // Establish a mapping relationship from URI to Library
    final unitLibraryUriMap = {
      for (final library in unitLibraries) library.uri: library
    };

    // Merge bridge libraries with unit libraries that share an identical URI
    final libraries = <Library>{};
    final mergedLibraryUris = <Uri>{};

    // Iterate over bridge libraries
    for (final bridgeLibrary in _bridgeDeclarations.keys) {
      // Wrap bridge declarations in this library as [DeclarationOrBridge]s
      final bridgeLibDeclarations = [
        for (final bridgeDeclaration in _bridgeDeclarations[bridgeLibrary]!)
          DeclarationOrBridge(-1, bridge: bridgeDeclaration)
      ];

      final uri = Uri.parse(bridgeLibrary);

      // See if there is already a unit library with an identical URI
      // If the two overlap, perform a merge operation
      final unitLibrary = unitLibraryUriMap[uri];
      if (unitLibrary != null) {
        /// Merge source code declarations from the unit library with the bridge
        libraries.add(unitLibrary.copyWith(declarations: [
          ...unitLibrary.declarations,
          ...bridgeLibDeclarations
        ]));

        /// Document this is a merged library
        mergedLibraryUris.add(uri);
      } else {
        // If there is no existing unit library with an identical URI, create
        // a new [Library] with the bridge declarations
        libraries.add(Library(Uri.parse(bridgeLibrary),
            imports: [],
            exports: [],
            declarations: [
              for (final bridgeDeclaration
                  in _bridgeDeclarations[bridgeLibrary]!)
                DeclarationOrBridge(-1, bridge: bridgeDeclaration)
            ]));
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

      var isEntrypoint = false;
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
                (element) => element.name.name == 'RuntimeOverride');
            if (overrideAnno != null) {
              computedEntrypoints.add(library.uri);
            }
          }
        }
      }
    }

    final reachableLibraries =
        _discoverReachableLibraries(libraries, computedEntrypoints).toSet();

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
    final visibleDeclarations = _resolveImportsAndExports(reachableLibraries,
        discoveredIdentifiers, computedEntrypoints, libraryIndexMap);

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
        lib.uri.toString(): libraryIndexMap[lib]!
    };
    _ctx.libraryMap = libraryMapString;

    final visibleDeclarationsByIndex = {
      for (final lib in reachableLibraries)
        libraryIndexMap[lib]!: {...visibleDeclarations[lib]!}
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
                child.bridge =
                    bridge.copyWith(type: bridge.type.copyWith(type: type0));
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
        final type = declarationTypes[declarationOrBridge];
        if (type == null) continue;
        if (declarationOrBridge.isBridge) {
          final bridge = declarationOrBridge.bridge!;
          final type0 = BridgeTypeRef.type(_ctx.typeRefIndexMap[type]);
          if (bridge is BridgeClassDef) {
            declarationOrBridge.bridge =
                bridge.copyWith(type: bridge.type.copyWith(type: type0));
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

    unboxedAcrossFunctionBoundaries = {
      CoreTypes.int.ref(_ctx),
      CoreTypes.double.ref(_ctx),
      CoreTypes.bool.ref(_ctx),
      CoreTypes.list.ref(_ctx)
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
            _ctx.resetStack();
          } else if (declaration is ClassDeclaration) {
            _ctx.currentClass = declaration;
            for (final d in declaration.members
                .whereType<FieldDeclaration>()
                .where((e) => e.isStatic)) {
              compileFieldDeclaration(-1, d, _ctx, declaration);
              _ctx.resetStack();
            }
            _ctx.currentClass = null;
          } else if (declaration is EnumDeclaration) {
            _ctx.currentClass = declaration;
            for (final d in declaration.members
                .whereType<FieldDeclaration>()
                .where((e) => e.isStatic)) {
              compileFieldDeclaration(-1, d, _ctx, declaration);
              _ctx.resetStack();
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
          _ctx.resetStack();
        });
      });
    } on CompileError catch (e, stk) {
      Error.throwWithStackTrace(e.copyWithContext(_ctx), stk);
    }

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

    for (final type in _ctx.runtimeTypeList) {
      _ctx.typeTypes.add(type.resolveTypeChain(_ctx).getRuntimeIndices(_ctx));
    }

    final globalInitializers = List<int>.filled(_ctx.globalIndex, 0);

    for (final gi in _ctx.runtimeGlobalInitializerMap.entries) {
      globalInitializers[gi.key] = gi.value;
    }

    final typeIds = <int, Map<String, int>>{};

    for (final t in _ctx.typeRefIndexMap.entries) {
      final type = t.key;
      typeIds.putIfAbsent(type.file, () => {})[type.name] = t.value;
    }
    return Program(
      _ctx.topLevelDeclarationPositions,
      _ctx.instanceDeclarationPositions,
      typeIds,
      //ctx.typeNames,
      _ctx.typeTypes,
      _ctx.offsetTracker.apply(_ctx.out),
      libraryMapString,
      _ctx.bridgeStaticFunctionIndices,
      _ctx.constantPool.pool,
      _ctx.runtimeTypes.pool,
      globalInitializers,
      _ctx.enumValueIndices,
      _ctx.runtimeOverrideMap,
    );
  }

  /// For testing purposes. Compile code, write it to a byte stream, load it,
  /// and run it.
  Runtime compileWriteAndLoad(Map<String, Map<String, String>> packages) {
    final program = compile(packages);

    final ob = program.write();

    return Runtime(ob.buffer.asByteData());
  }

  void _populateLookupTablesForDeclaration(
      int libraryIndex, DeclarationOrBridge declarationOrBridge) {
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
        _topLevelDeclarationsMap[libraryIndex]![spec.name] =
            DeclarationOrBridge(libraryIndex, bridge: bridge);
        for (final constructor in bridge.constructors.entries) {
          _topLevelDeclarationsMap[libraryIndex]![
                  '${spec.name}.${constructor.key}'] =
              DeclarationOrBridge(libraryIndex, bridge: constructor.value);
        }
        for (final method in bridge.methods.entries) {
          if (method.value.isStatic) {
            _topLevelDeclarationsMap[libraryIndex]![
                    '${spec.name}.${method.key}'] =
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
      final vlist = declaration.variables;

      if (!_topLevelGlobalIndices.containsKey(libraryIndex)) {
        _topLevelGlobalIndices[libraryIndex] = {};
        _ctx.topLevelGlobalInitializers[libraryIndex] = {};
        _ctx.topLevelVariableInferredTypes[libraryIndex] = {};
      }

      for (final variable in vlist.variables) {
        final name = variable.name.lexeme;

        if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
          throw CompileError('Cannot define "$name" twice in the same library',
              variable, libraryIndex);
        }

        _topLevelDeclarationsMap[libraryIndex]![name] =
            DeclarationOrBridge(libraryIndex, declaration: variable);
        _topLevelGlobalIndices[libraryIndex]![name] = _ctx.globalIndex++;
      }
    } else {
      declaration as NamedCompilationUnitMember;
      final name = declaration.name.lexeme;

      if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
        throw CompileError('Cannot define "$name" twice in the same library',
            declaration, libraryIndex);
      }

      _topLevelDeclarationsMap[libraryIndex]![name] =
          DeclarationOrBridge(libraryIndex, declaration: declaration);

      if (declaration is ClassDeclaration || declaration is EnumDeclaration) {
        _instanceDeclarationsMap[libraryIndex]![name] = {};
        final members = declaration is ClassDeclaration
            ? declaration.members
            : (declaration as EnumDeclaration).members;

        if (declaration is EnumDeclaration) {
          _ctx.enumValueIndices[libraryIndex] ??= {};
          _ctx.enumValueIndices[libraryIndex]![declaration.name.lexeme] = {};
          for (final constant in declaration.constants) {
            if (!_topLevelGlobalIndices.containsKey(libraryIndex)) {
              _topLevelGlobalIndices[libraryIndex] = {};
              _ctx.topLevelGlobalInitializers[libraryIndex] = {};
              _ctx.topLevelVariableInferredTypes[libraryIndex] = {};
            }
            final name = '${declaration.name.lexeme}.${constant.name.lexeme}';
            if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
              throw CompileError(
                  'Cannot define "$name" twice in the same library',
                  constant,
                  libraryIndex);
            }

            _topLevelDeclarationsMap[libraryIndex]![name] =
                DeclarationOrBridge(libraryIndex, declaration: constant);
            final globalIndex = _ctx.globalIndex++;
            _topLevelGlobalIndices[libraryIndex]![name] = globalIndex;
            _ctx.enumValueIndices[libraryIndex]![declaration.name.lexeme]![
                constant.name.lexeme] = globalIndex;
          }
        }

        for (var member in members) {
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
              _instanceDeclarationsMap[libraryIndex]![name]![mName] = member;
            }
          } else if (member is FieldDeclaration) {
            if (member.isStatic) {
              if (!_topLevelGlobalIndices.containsKey(libraryIndex)) {
                _topLevelGlobalIndices[libraryIndex] = {};
                _ctx.topLevelGlobalInitializers[libraryIndex] = {};
                _ctx.topLevelVariableInferredTypes[libraryIndex] = {};
              }

              for (final field in member.fields.variables) {
                final name = '${declaration.name.lexeme}.${field.name.lexeme}';

                if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
                  throw CompileError(
                      'Cannot define "$name" twice in the same library',
                      field,
                      libraryIndex);
                }

                _topLevelDeclarationsMap[libraryIndex]![name] =
                    DeclarationOrBridge(libraryIndex, declaration: field);
                _topLevelGlobalIndices[libraryIndex]![name] =
                    _ctx.globalIndex++;
              }
            } else {
              for (final field in member.fields.variables) {
                final fName = field.name.lexeme;
                _instanceDeclarationsMap[libraryIndex]![name]![fName] = field;
              }
            }
          } else if (member is ConstructorDeclaration) {
            final mName = (member.name?.lexeme) ?? "";
            _topLevelDeclarationsMap[libraryIndex]!['$name.$mName'] =
                DeclarationOrBridge(libraryIndex, declaration: member);
          } else {
            throw CompileError(
                'Not a NamedCompilationUnitMember', member, libraryIndex);
          }
        }
      }
    }
  }

  TypeRef? _cacheTypeRef(
      int libraryIndex, DeclarationOrBridge declarationOrBridge) {
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
      return TypeRef.cache(_ctx, libraryIndex, spec.name,
          fileRef: libraryIndex);
    } else {
      final declaration = declarationOrBridge.declaration!;
      if (declaration is! ClassDeclaration && declaration is! EnumDeclaration) {
        return null;
      }
      final name = (declaration as NamedCompilationUnitMember).name.lexeme;
      return TypeRef.cache(_ctx, libraryIndex, name, fileRef: libraryIndex);
    }
  }

  void _assignBridgeStaticFunctionIndicesForClass(BridgeClassDef classDef) {
    final type = TypeRef.fromBridgeTypeRef(_ctx, classDef.type.type);
    final lib = type.file;
    if (!_ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
      _ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
    }
    classDef.constructors.forEach((name, constructor) {
      if (!_ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        _ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      _ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.methods.forEach((name, method) {
      if (!method.isStatic) return;
      if (!_ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        _ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      _ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.getters.forEach((name, getter) {
      if (!getter.isStatic) return;
      if (!_ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        _ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      _ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*g'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.setters.forEach((name, setter) {
      if (!setter.isStatic) return;
      if (!_ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        _ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      _ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*s'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.fields.forEach((name, field) {
      if (!field.isStatic) return;
      if (!_ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        _ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      _ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*g'] =
          _bridgeStaticFunctionIdx++;
      _ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*s'] =
          _bridgeStaticFunctionIdx++;
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
    final lib = type.file;
    if (!_ctx.enumValueIndices.containsKey(lib)) {
      _ctx.enumValueIndices[lib] = {};
    }
    _ctx.enumValueIndices[lib]![type.name] = {
      for (final value in enumDef.values) value: _ctx.globalIndex++
    };
  }

  void _assignBridgeStaticFunctionIndicesForFunction(
      int libraryIndex, BridgeFunctionDeclaration functionDef) {
    if (!_ctx.bridgeStaticFunctionIndices.containsKey(libraryIndex)) {
      _ctx.bridgeStaticFunctionIndices[libraryIndex] = <String, int>{};
    }
    _ctx.bridgeStaticFunctionIndices[libraryIndex]![functionDef.name] =
        _bridgeStaticFunctionIdx++;
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
    if (unit.library != null && unit.library!.name2 != null) {
      /// Library instruction for source files that start with "library *****"
      libraryIdMap[unit.library!.name2!.name] = i;
    }
    i++;
  }

  /// CompilationUnit graph structure
  final cuGraph =
      CompilationUnitGraph(compilationUnitMap, uriMap, libraryIdMap);

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
    final library = Library(primary.uri,
        library: primary.library?.name2?.name,
        imports: primary.imports,
        exports: primary.exports,
        declarations: group.map((e) => compilationUnitMap[e]!).fold(
            [],
            (pv, element) => pv
              ..addAll(element.declarations
                  .map((d) => DeclarationOrBridge(-1, declaration: d)))));
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
    Map<Library, int> libraryIds) {
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
        for (final export in l.exports) l.uri.resolve(export.uri.stringValue!)
      }
  });

  final crawler = CachedFastCrawler(exportGraph.edges);

  final result = <Library, Map<String, DeclarationOrPrefix>>{};
  final usedDeclarationsForLibrary = <int, Set<String>>{};

  final worklist = <Library>[];
  final importMap = <Library, List<_Import>>{};
  final importedDeclarationsMap =
      <Library, Map<Library, Iterable<Pair<String, DeclarationOrBridge>>>>{};

  // Traversing libraries
  for (final l in libraries) {
    // All visible declarations under this Library
    final visibleDeclarationsLib = <String, DeclarationOrPrefix>{
      for (final d in DeclarationOrBridge.expand(l.declarations))
        // Key: the expanded name of the declaration (see [_expandDeclarations])
        // Value: DeclarationOrPrefix (declaration content, and store the ID
        // of the containing library)
        d.first: DeclarationOrPrefix(
            declaration: d.second..sourceLib = libraryIds[l]!),
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
          .whereNot((import) =>
              import.uri.toString().startsWith('package:eval_annotation')),
      if (!isDartCore) _Import(dartCoreUri, null)
    ];

    importMap[l] = imports;
    importedDeclarationsMap[l] = {
      l: DeclarationOrBridge.expand(l.declarations)
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
          .map((e) =>
              uriMap[e] ??
              (throw CompileError(
                  "Cannot find import '$e' (while parsing '${l.uri}')")))
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

      final visibleDeclarations = <Pair<String, DeclarationOrBridge>>{};

      for (final lib in importedLibs) {
        final libId = libraryIds[lib]!;
        final expandedDeclarations =
            DeclarationOrBridge.expand(lib.declarations);
        final importedDeclarations = expandedDeclarations
            .where((element) =>
                _combinatorListAccepts(import.combinators, element.first, true))
            .toList();
        importedDeclarationsMap[l]![lib] = importedDeclarations;

        final result = <Pair<String, DeclarationOrBridge>>{};

        for (final declaration in importedDeclarations) {
          if (lib.uri == import.uri) {
            result.add(declaration..second.sourceLib = libId);
          }
          final exports = exportsPerUri[lib.uri] ?? <ExportDirective>[];
          for (final export in exports) {
            final combinators = export.combinators;
            if (_combinatorListAccepts(combinators, declaration.first, false)) {
              result.add(declaration..second.sourceLib = libId);
            }
          }
          if (isEntrypoint && ids!.contains(declaration.first)) {
            usedDeclarationsForLibrary[libId] ??= {'main'};
            usedDeclarationsForLibrary[libId]!.add(declaration.first);
            if (!worklist.contains(lib)) {
              worklist.add(lib);
            }
          }
        }

        visibleDeclarations.addAll(result);
      }

      final mappedVisibleDeclarations = {
        if (import.prefix != null)
          import.prefix!: DeclarationOrPrefix(children: {
            for (final d in visibleDeclarations) d.first: d.second
          })
        else
          for (final d in visibleDeclarations)
            d.first: DeclarationOrPrefix(declaration: d.second)
      };

      visibleDeclarationsLib.addAll(mappedVisibleDeclarations);
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
        _Import(library.uri, null)
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
        final iid = '${library.uri}:${import.uri}';
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
        .where((declaration) =>
            declaration.isBridge ||
            DeclarationOrBridge.nameOf(declaration).any((name) =>
                {...?usedDeclarationsForLibrary[libraryIds[l]]}.contains(name)))
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
    Iterable<Combinator> combinators, String name, bool rejectInvalid) {
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
          'Unsupported import combinator ${combinator.runtimeType}');
    }
  }
  return false;
}

/// Given the list of entrypoint libraries, recursively find all library IDs
/// that are reachable through imports and exports using a graph.
Iterable<Library> _discoverReachableLibraries(
    Iterable<Library> libraries, Iterable<Uri> entrypoints) sync* {
  final uriMap = {for (final l in libraries) l.uri: l};
  final libraryGraph = DirectedGraph<Uri>({
    for (final l in libraries)
      l.uri: {
        for (final import in l.imports) l.uri.resolve(import.uri.stringValue!),
        for (final export in l.exports) l.uri.resolve(export.uri.stringValue!)
      }
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

  factory _Import.resolve(ImportDirective import, Uri base, String? prefix,
      [List<Combinator> combinators = const []]) {
    final uri = Uri.parse(import.uri.stringValue!);
    return _Import(
        base.resolveUri(uri), import.prefix?.name, import.combinators);
  }
}
