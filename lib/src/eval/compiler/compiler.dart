import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
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
import 'package:dart_eval/src/eval/shared/stdlib/convert.dart';
import 'package:dart_eval/src/eval/shared/stdlib/core.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io.dart';
import 'package:dart_eval/src/eval/shared/stdlib/math.dart';
import 'package:dart_eval/src/eval/shared/types.dart';
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

  var ctx = CompilerContext(0);

  final additionalSources = <DartSource>[];
  final cachedParsedSources = <DartSource, DartCompilationUnit>{};
  final plugins = <EvalPlugin>[
    DartAsyncPlugin(),
    DartCorePlugin(),
    DartConvertPlugin(),
    DartIoPlugin(),
    DartMathPlugin(),
  ];
  final appliedPlugins = <String>[];

  // Add a plugin, which will only be run once.
  @override
  void addPlugin(EvalPlugin plugin) {
    plugins.add(plugin);
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
    ctx = CompilerContext(0, version: version);

    for (final plugin in plugins) {
      if (!appliedPlugins.contains(plugin.identifier)) {
        plugin.configureForCompile(this);
        appliedPlugins.add(plugin.identifier);
      }
    }

    final cleanupList = cachedParsedSources.keys.toSet();

    // Generate the parsed AST for all sources. [units] will be a List of
    // [DartCompilationUnit]s. Avoids re-parsing a source if it has already been
    // parsed and is stored in [cachedParsedSources].
    final units = sources.followedBy(additionalSources).map((source) {
      cleanupList.remove(source);
      final cached = cachedParsedSources[source];
      if (cached != null) {
        return cached;
      }

      // Load the source code from the filesystem or a String and parse it
      // (internally using the Dart analyzer) into an AST
      final parsed = cachedParsedSources[source] = source.load();
      return parsed;
    }).toList();

    for (final source in cleanupList) {
      cachedParsedSources.remove(source);
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

    // Resolve the export and import relationship of the libraries, while
    // generating library IDs
    final visibleDeclarations = _resolveImportsAndExports(
        libraries,
        (library) =>
            libraryIndexMap[library] ?? (libraryIndexMap[library] = i++));

    // Populate lookup tables [_topLevelDeclarationsMap],
    // [_instanceDeclarationsMap], and [_topLevelGlobalIndices], and generate
    // remaining library IDs
    for (final library in libraries) {
      final libraryIndex =
          libraryIndexMap[library] ?? (libraryIndexMap[library] = i++);
      for (final declarationOrBridge in library.declarations) {
        _populateLookupTablesForDeclaration(libraryIndex, declarationOrBridge);
      }
    }

    // Pass a mapping of library URI to integer index into the context
    final libraryMapString = {
      for (final entry in libraryIndexMap.entries)
        entry.key.uri.toString(): entry.value
    };
    ctx.libraryMap = libraryMapString;

    final visibleDeclarationsByIndex = {
      for (final lib in libraries)
        libraryIndexMap[lib]!: {...visibleDeclarations[lib]!}
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
                child.bridge = bridge.copyWith(
                    type: bridge.type.copyWith(
                        type:
                            BridgeTypeRef.type(ctx.typeRefIndexMap[_cached])));
              } else if (bridge is BridgeEnumDef) {
                child.bridge = bridge.copyWith(
                    type: BridgeTypeRef.type(ctx.typeRefIndexMap[_cached]));
              } else {
                assert(false);
              }
            }
          }
          visibleTypesByIndex[libraryIndex] ??= {...coreDeclarations};
          visibleTypesByIndex[libraryIndex]!.addAll(res);
          continue;
        }
        visibleTypesByIndex[libraryIndex] ??= {...coreDeclarations};
        final declarationOrBridge = dop.declaration!;
        final type = declarationTypes[declarationOrBridge];
        if (type == null) continue;
        if (declarationOrBridge.isBridge) {
          final bridge = declarationOrBridge.bridge!;
          if (bridge is BridgeClassDef) {
            declarationOrBridge.bridge = bridge.copyWith(
                type: bridge.type.copyWith(
                    type: BridgeTypeRef.type(ctx.typeRefIndexMap[type])));
          } else if (bridge is BridgeEnumDef) {
            declarationOrBridge.bridge = bridge.copyWith(
                type: BridgeTypeRef.type(ctx.typeRefIndexMap[type]));
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

    unboxedAcrossFunctionBoundaries = {
      EvalTypes.intType,
      EvalTypes.doubleType,
      EvalTypes.boolType,
      EvalTypes.getListType(ctx)
    };

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

    try {
      /// Compile statics first so we can infer their type
      _topLevelDeclarationsMap.forEach((key, value) {
        value.forEach((lib, _declaration) {
          if (_declaration.isBridge) {
            return;
          }
          final declaration = _declaration.declaration!;
          ctx.library = key;
          if (declaration is VariableDeclaration &&
              declaration.parent!.parent is TopLevelVariableDeclaration) {
            compileDeclaration(declaration, ctx);
            ctx.resetStack();
          } else if (declaration is ClassDeclaration) {
            ctx.currentClass = declaration;
            for (final d in declaration.members
                .whereType<FieldDeclaration>()
                .where((e) => e.isStatic)) {
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
    } on CompileError catch (e) {
      throw e.copyWithContext(ctx);
    }

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

    final typeIds = <int, Map<String, int>>{};

    for (final t in {...runtimeTypeMap, ...ctx.typeRefIndexMap}.entries) {
      final type = t.key;
      typeIds.putIfAbsent(type.file, () => {})[type.name] = t.value;
    }

    return Program(
        ctx.topLevelDeclarationPositions,
        ctx.instanceDeclarationPositions,
        typeIds,
        //ctx.typeNames,
        ctx.typeTypes,
        ctx.offsetTracker.apply(ctx.out),
        libraryMapString,
        ctx.bridgeStaticFunctionIndices,
        ctx.constantPool.pool,
        ctx.runtimeTypes.pool,
        globalInitializers,
        ctx.enumValueIndices,
        ctx.runtimeOverrideMap);
  }

  /// For testing purposes. Compile code, write it to a byte stream, load it,
  /// and run it.
  Runtime compileWriteAndLoad(Map<String, Map<String, String>> packages) {
    final program = compile(packages);

    final ob = program.write();

    return Runtime(ob.buffer.asByteData())..setup();
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
        ctx.topLevelGlobalInitializers[libraryIndex] = {};
        ctx.topLevelVariableInferredTypes[libraryIndex] = {};
      }

      for (final variable in vlist.variables) {
        final name = variable.name.value() as String;

        if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
          throw CompileError('Cannot define "$name" twice in the same library',
              variable, libraryIndex);
        }

        _topLevelDeclarationsMap[libraryIndex]![name] =
            DeclarationOrBridge(libraryIndex, declaration: variable);
        _topLevelGlobalIndices[libraryIndex]![name] = ctx.globalIndex++;
      }
    } else {
      declaration as NamedCompilationUnitMember;
      final name = declaration.name.value() as String;

      if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
        throw CompileError('Cannot define "$name" twice in the same library',
            declaration, libraryIndex);
      }

      _topLevelDeclarationsMap[libraryIndex]![name] =
          DeclarationOrBridge(libraryIndex, declaration: declaration);

      if (declaration is ClassDeclaration) {
        _instanceDeclarationsMap[libraryIndex]![name] = {};

        declaration.members.forEach((member) {
          if (member is MethodDeclaration) {
            var mName = member.name.value() as String;
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
                ctx.topLevelGlobalInitializers[libraryIndex] = {};
                ctx.topLevelVariableInferredTypes[libraryIndex] = {};
              }

              for (final field in member.fields.variables) {
                final name =
                    '${declaration.name.value() as String}.${field.name.value()}';

                if (_topLevelDeclarationsMap[libraryIndex]!.containsKey(name)) {
                  throw CompileError(
                      'Cannot define "$name" twice in the same library',
                      field,
                      libraryIndex);
                }

                _topLevelDeclarationsMap[libraryIndex]![name] =
                    DeclarationOrBridge(libraryIndex, declaration: field);
                _topLevelGlobalIndices[libraryIndex]![name] = ctx.globalIndex++;
              }
            } else {
              for (final field in member.fields.variables) {
                final fName = field.name.value() as String;
                _instanceDeclarationsMap[libraryIndex]![name]![fName] = field;
              }
            }
          } else if (member is ConstructorDeclaration) {
            final mName = (member.name?.value() as String?) ?? "";
            _topLevelDeclarationsMap[libraryIndex]!['$name.$mName'] =
                DeclarationOrBridge(libraryIndex, declaration: member);
          } else {
            throw CompileError(
                'Not a NamedCompilationUnitMember', member, libraryIndex);
          }
        });
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
        return TypeRef.fromBridgeTypeRef(ctx, type);
      }
      final spec = type.spec!;
      return TypeRef.cache(ctx, libraryIndex, spec.name, fileRef: libraryIndex);
    } else {
      final declaration = declarationOrBridge.declaration!;
      if (declaration is! ClassDeclaration) {
        return null;
      }
      return TypeRef.cache(
          ctx, libraryIndex, declaration.name.value() as String,
          fileRef: libraryIndex);
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
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.methods.forEach((name, method) {
      if (!method.isStatic) return;
      if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.getters.forEach((name, getter) {
      if (!getter.isStatic) return;
      if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*g'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.setters.forEach((name, setter) {
      if (!setter.isStatic) return;
      if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*s'] =
          _bridgeStaticFunctionIdx++;
    });

    classDef.fields.forEach((name, field) {
      if (!field.isStatic) return;
      if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
        ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
      }
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*g'] =
          _bridgeStaticFunctionIdx++;
      ctx.bridgeStaticFunctionIndices[lib]!['${type.name}.$name*s'] =
          _bridgeStaticFunctionIdx++;
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
    ctx.enumValueIndices[lib]![type.name] = {
      for (final value in enumDef.values) value: ctx.globalIndex++
    };
  }

  void _assignBridgeStaticFunctionIndicesForFunction(
      int libraryIndex, BridgeFunctionDeclaration functionDef) {
    if (!ctx.bridgeStaticFunctionIndices.containsKey(libraryIndex)) {
      ctx.bridgeStaticFunctionIndices[libraryIndex] = <String, int>{};
    }
    ctx.bridgeStaticFunctionIndices[libraryIndex]![functionDef.name] =
        _bridgeStaticFunctionIdx++;
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
    Iterable<Library> libraries, int Function(Library) resolveLibraryId) {
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

  final result = <Library, Map<String, DeclarationOrPrefix>>{};

  // Traversing libraries
  for (final l in libraries) {
    // All visible declarations under this Library
    final _visibleDeclarations = <String, DeclarationOrPrefix>{
      for (final d in _expandDeclarations(l.declarations))
        // Key: the expanded name of the declaration (see [_expandDeclarations])
        // Value: DeclarationOrPrefix (declaration content, and store the ID of the containing library)
        d.first: DeclarationOrPrefix(
            declaration: d.second..sourceLib = resolveLibraryId(l)),
    };

    final dartCoreUri = Uri.parse('dart:core');
    final isDartCore = l.uri == dartCoreUri;

    for (final import in [
      /// Iterate over the library's imports including the implicit import of
      /// dart:core.
      ...l.imports
          .map((e) => _Import.resolve(e, l.uri, e.prefix?.name, e.combinators)),
      if (!isDartCore) _Import(dartCoreUri, null)
    ]) {
      /// Skip eval_annotation imports if present
      if (import.uri.toString().startsWith('package:eval_annotation')) {
        continue;
      }

      /// Use the export graph to find all declarations that become visible
      /// through this import.
      /// directed_graph returns a tree structure with import.uri as the root
      /// and exported libraries as leaves.
      final tree = exportGraph.crawler.tree(import.uri);

      /// Flatten and deduplicate the tree to get a list of all libraries that
      /// are visible through this import.
      final importedLibs = [...tree.expand((e) => e), import.uri]
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
          final _uri = lib.uri.resolve(export.uri.stringValue!);
          final uriList = exportsPerUri[_uri];
          if (uriList != null) {
            uriList.add(export);
          } else {
            exportsPerUri[_uri] = [export];
          }
        }
      }

      final validImport = (String name) {
        if (name.startsWith('_')) return false;
        if (import.combinators.isEmpty) {
          return true;
        }
        for (final combinator in import.combinators) {
          if (combinator is ShowCombinator) {
            if ({for (final n in combinator.shownNames) n.name}
                .contains(name)) {
              return true;
            }
            return false;
          } else if (combinator is HideCombinator) {
            if ({for (final n in combinator.hiddenNames) n.name}
                .contains(name)) {
              return false;
            }
            return true;
          }
          throw CompileError(
              'Unsupported import combinator ${combinator.runtimeType} (while parsing ${l.uri})');
        }
        return false;
      };

      final visibleDeclarations = {
        for (final lib in importedLibs)
          for (final declaration in _expandDeclarations(lib.declarations)
              .where((e) => validImport(e.first))) ...{
            if (lib.uri == import.uri)
              declaration..second.sourceLib = resolveLibraryId(lib),
            for (final export in exportsPerUri[lib.uri] ?? [])
              if (export.combinators.isEmpty)
                declaration..second.sourceLib = resolveLibraryId(lib)
              else
                for (final combinator in export.combinators)
                  if (combinator is ShowCombinator) ...{
                    if ({for (final n in combinator.shownNames) n.name}
                        .contains(declaration.first))
                      declaration..second.sourceLib = resolveLibraryId(lib)
                  } else if (combinator is HideCombinator) ...{
                    if (!({for (final n in (combinator).hiddenNames) n.name}
                        .contains(declaration.first)))
                      declaration..second.sourceLib = resolveLibraryId(lib)
                  }
          }
      };

      final mappedVisibleDeclarations = {
        if (import.prefix != null)
          import.prefix!: DeclarationOrPrefix(children: {
            for (final d in visibleDeclarations) d.first: d.second
          })
        else
          for (final d in visibleDeclarations)
            d.first: DeclarationOrPrefix(declaration: d.second)
      };

      _visibleDeclarations.addAll(mappedVisibleDeclarations);
    }

    result[l] = _visibleDeclarations;
  }

  return result;
}

/// Flatten static nested declarations into an iterable of pairs of compound name to declaration
/// For example, for a class `A` with a static method `foo`, this will return `['A', A]` and `['A.foo', foo]`
Iterable<Pair<String, DeclarationOrBridge>> _expandDeclarations(
    List<DeclarationOrBridge> declarations) sync* {
  /// Traverse declarations
  for (final d in declarations) {
    if (d.isBridge) {
      /// Process bridge declaration
      final bridge = d.bridge as BridgeDeclaration;

      /// Find the declaration name according to its specific type
      if (bridge is BridgeClassDef) {
        /// Bridge class name
        final name = bridge.type.type.spec!.name;
        yield Pair(name, d);
      } else if (bridge is BridgeEnumDef) {
        /// Bridge enumeration name
        final name = bridge.type.spec!.name;
        yield Pair(name, d);
      } else if (bridge is BridgeFunctionDeclaration) {
        /// This is simple, directly yield the function name
        yield Pair(bridge.name, d);
      }
    } else {
      // If it is a source code declaration
      final declaration = d.declaration!;
      if (declaration is NamedCompilationUnitMember) {
        final dName = declaration.name.value() as String;

        /// First yield the declaration itself
        yield Pair(dName, d);

        /// If it is a class declaration
        if (declaration is ClassDeclaration) {
          /// Then also yield the static class members
          for (final member in declaration.members) {
            if (member is ConstructorDeclaration) {
              yield Pair('$dName.${member.name?.value() ?? ""}',
                  DeclarationOrBridge(-1, declaration: member));
            } else if (member is MethodDeclaration && member.isStatic) {
              yield Pair('$dName.${member.name.value()}',
                  DeclarationOrBridge(-1, declaration: member));
            }
          }
        }
      } else if (declaration is TopLevelVariableDeclaration) {
        /// Top-level variable declaration
        for (final v in declaration.variables.variables) {
          yield Pair(v.name.value() as String,
              DeclarationOrBridge(-1, declaration: v));
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

  factory _Import.resolve(ImportDirective import, Uri base, String? prefix,
      [List<Combinator> combinators = const []]) {
    final uri = Uri.parse(import.uri.stringValue!);
    return _Import(
        base.resolveUri(uri), import.prefix?.name, import.combinators);
  }
}
