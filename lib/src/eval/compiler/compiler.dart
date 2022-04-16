import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_eval/src/eval/bridge/declaration/class.dart';
import 'package:dart_eval/src/eval/bridge/declaration/type.dart';
import 'package:dart_eval/src/eval/compiler/declaration/declaration.dart';
import 'package:dart_eval/src/eval/compiler/source.dart';
import 'package:dart_eval/src/eval/compiler/type.dart';
import 'package:dart_eval/src/eval/compiler/program.dart';
import 'package:dart_eval/src/eval/bridge/declaration.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/stdlib/core.dart';

import 'context.dart';
import 'errors.dart';

import 'builtins.dart';

class Compiler {
  var _bridgeLibraryIdx = 0;
  var _bridgeStaticFunctionIdx = 0;
  final _bridgeLibraryMappings = <String, int>{};
  final _bridgeClasses = <int, Map<String, BridgeClassDeclaration>>{};
  final _bridgeFunctions = <int, Map<String, BridgeFunctionDeclaration>>{};
  final ctx = CompilerContext(0);

  int _libraryIndex(String libraryUri) {
    if (!_bridgeLibraryMappings.containsKey(libraryUri)) {
      _bridgeLibraryMappings[libraryUri] = _bridgeLibraryIdx++;
    }
    final _libraryIdx = _bridgeLibraryMappings[libraryUri]!;
    if (!_bridgeClasses.containsKey(_libraryIdx)) {
      _bridgeClasses[_libraryIdx] = <String, BridgeClassDeclaration>{};
    }
    if (!_bridgeFunctions.containsKey(_libraryIdx)) {
      _bridgeFunctions[_libraryIdx] = <String, BridgeFunctionDeclaration>{};
    }
    return _libraryIdx;
  }

  // Manually define a (unresolved) bridge class
  void defineBridgeClass(BridgeClassDeclaration classDef) {
    final type = classDef.type;
    final unresolved = type.unresolved;

    if (unresolved != null) {
      final lib = _libraryIndex(unresolved.library);
      _bridgeClasses[lib]![unresolved.name] = classDef;

      classDef.constructors.forEach((name, constructor) {
        if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
          ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
        }
        ctx.bridgeStaticFunctionIndices[lib]!['${unresolved.name}.$name'] = _bridgeStaticFunctionIdx++;
      });

      classDef.methods.forEach((name, method) {
        if (!method.isStatic) return;
        if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
          ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
        }
        ctx.bridgeStaticFunctionIndices[lib]!['${unresolved.name}.$name'] = _bridgeStaticFunctionIdx++;
      });

      return;
    }

    throw CompileError('Cannot define a bridge class that\'s already resolved, a ref, or a generic function type');
  }

  void defineBridgeTopLevelFunction(BridgeFunctionDeclaration function) {
    final lib = _libraryIndex(function.library);
    _bridgeFunctions[lib]![function.name] = function;
    if (!ctx.bridgeStaticFunctionIndices.containsKey(lib)) {
      ctx.bridgeStaticFunctionIndices[lib] = <String, int>{};
    }
    ctx.bridgeStaticFunctionIndices[lib]![function.name] = _bridgeStaticFunctionIdx++;
  }

  void defineBridgeClasses(List<BridgeClassDeclaration> classDefs) {
    for (final classDef in classDefs) {
      defineBridgeClass(classDef);
    }
  }

  /// Compile a set of Dart code into a program
  /// TODO: Use graphs to compose imports
  Program compile(Map<String, Map<String, String>> packages) {

    configureCoreForCompile(this);

    final typeResolvedBridgeClasses = <int, Map<String, BridgeClassDeclaration>>{};
    final packageMap = <String, Map<String, int>>{};
    final indexMap = <int, List<String>>{};
    final partMap = <int, List<String>>{};
    final partOfMap = <int, String>{};
    final importMap = <int, List<ImportDirective>>{};
    final topLevelDeclarationsMap = <int, Map<String, DeclarationOrBridge>>{};
    final instanceDeclarationsMap = <int, Map<String, Map<String, Declaration>>>{};
    int? dartCoreFile;

    ctx.libraryMap = <String, int>{..._bridgeLibraryMappings};

    for (final _blm in _bridgeLibraryMappings.entries) {
      final uri = _blm.key;

      if (uri == 'dart:core') {
        dartCoreFile = _blm.value;
      }

      // Skip over 'package:' in the string
      // TODO remove this when processing JSON
      final content = uri == 'dart:core' ? null : uri.substring(8);
      final package = content?.substring(0, content.indexOf('/')) ?? 'dart:core';
      final file = content?.substring(content.indexOf('/') + 1) ?? 'core';
      if (!packageMap.containsKey(package)) {
        packageMap[package] = {};
      }
      packageMap[package]![file] = _blm.value;
      indexMap[_blm.value] = [package, file];
      final _classes = _bridgeClasses[_blm.value]!;
      final _functions = _bridgeFunctions[_blm.value]!;

      /// 1st-pass bridge class resolver: resolve all defined bridge classes to a type, but not their type args or
      /// supers/implementations/mixins. Among other things, this ensures that bridge classes fill a contiguous block
      /// of the lower indices of the compile-time type map, which allows us to map it directly to a runtime type map

      final resolved = {
        for (final _cls in _classes.entries)
          _cls.key: _cls.value.copyWith(
              type: BridgeTypeReference.type(
                  ctx.typeRefIndexMap[TypeRef.cache(ctx, _blm.value, _cls.key, fileRef: _blm.value)]!,
                  _cls.value.type.typeArgs))
      };

      typeResolvedBridgeClasses[_blm.value] = resolved;

      final types =
          Map.fromEntries(resolved.entries.map((e) => MapEntry(e.key, ctx.runtimeTypeList[e.value.type.cacheId!])));

      ctx.visibleTypes[_blm.value] = {...coreDeclarations, ...types};

      topLevelDeclarationsMap[_blm.value] = {
        for (final v in resolved.entries) v.key: DeclarationOrBridge(bridge: v.value),
        for (final v in resolved.entries)
          for (final m in v.value.methods.entries)
            if (m.value.isStatic) '${v.key}.${m.key}': DeclarationOrBridge(bridge: m.value),
        for (final f in _functions.entries) f.key: DeclarationOrBridge(bridge: f.value)
      };
    }

    var fileIndex = 0;

    int? resolveUri(List<String> resolvedUriParts) {
      return packageMap[resolvedUriParts[0]]?[resolvedUriParts[1]];
    }

    List<String> resolvedUriParts(String currentPackage, String currentFile, String uri) {
      String package = currentPackage, file, targetFile;
      if (uri.startsWith('package:')) {
        final content = uri.substring(8);
        package = content.substring(0, content.indexOf('/'));
        file = content.substring(content.indexOf('/') + 1);
        targetFile = file;
      } else {
        file = uri;
        if (!currentFile.contains('/')) {
          targetFile = file;
        } else {
          final currentFileNest = currentFile.split('/');
          targetFile = [...currentFileNest.take(currentFileNest.length - 1), ...file.split('/')].join('/');
        }
      }
      return [package, targetFile];
    }

    packages.forEach((package, libraries) {
      packageMap[package] = {};

      libraries.forEach((filename, source) {
        final unit = _parse(source);

        final imports = <ImportDirective>[];
        var myIndex = ctx.libraryMap['package:$package/$filename'];

        for (final directive in unit.directives) {
          if (directive is PartDirective) {
            final uri = directive.uri.stringValue;
            if (uri == null) {
              throw CompileError('Part URIs cannot use string interpolation');
            }
            if (!uri.startsWith('package:') && uri.contains(':')) {
              throw CompileError('Invalid URI in part directive: starts with ${uri.split(':')[0]}:');
            }
            final uriParts = resolvedUriParts(package, filename, uri);
            final file = resolveUri(uriParts);
            if (file != null) {
              if (partOfMap[file] != "'$filename'") {
                throw CompileError('$package/$filename contains a part directive for $uri, '
                    'but there is no corresponding part of directive');
              }
              myIndex = file;
            } else {
              final idx = myIndex ?? (myIndex = fileIndex++);
              final formattedUri = 'package:${uriParts[0]}/${uriParts[1]}';
              if (!partMap.containsKey(idx)) {
                partMap[idx] = [formattedUri];
              } else {
                partMap[idx]!.add(formattedUri);
              }
            }
            ctx.libraryMap['package:$package/$filename'] = myIndex;
            indexMap[myIndex] = [package, filename];
          } else if (directive is PartOfDirective) {
            if (unit.directives.length > 1) {
              throw CompileError('"part of" when included must be the only directive in a part');
            }
            final uri = directive.uri?.stringValue;
            final library = directive.libraryName;
            if (uri == null && library == null) {
              throw CompileError('Part URIs cannot use string interpolation');
            }
            if (uri != null) {
              if (!uri.startsWith('package:') && uri.contains(':')) {
                throw CompileError('Invalid URI in part of directive: starts with ${uri.split(':')[0]}:');
              }
              final uriParts = resolvedUriParts(package, filename, uri);
              final file = resolveUri(uriParts);
              final formattedUri = 'package:${uriParts[0]}/${uriParts[1]}';
              final myFormattedUri = 'package:$package/$filename';
              if (file != null) {
                if (partMap[file] == null || !partMap[file]!.contains(myFormattedUri)) {
                  throw CompileError('$package/$filename contains a part of directive for $uri, '
                      'but there is no corresponding part directive');
                }
                partMap[file]!.remove(myFormattedUri);
                myIndex = file;
              } else {
                myIndex = ctx.libraryMap['$formattedUri'] ?? fileIndex++;
                ctx.libraryMap['$formattedUri'] = myIndex;
              }
              partOfMap[myIndex] = formattedUri;
            } else {
              throw CompileError('No support for named libraries yet');
            }
          } else if (directive is ImportDirective) {
            imports.add(directive);
          } else {
            throw CompileError('Unknown directive type ${directive.runtimeType}');
          }
        }

        myIndex ??= fileIndex++;
        packageMap[package]![filename] = myIndex;
        indexMap[myIndex] ??= [package, filename];
        importMap[myIndex] = imports;

        ctx.visibleTypes[myIndex] ??= {
          ...coreDeclarations,
          if (dartCoreFile != null) ...ctx.visibleTypes[dartCoreFile]!
        };
        ctx.visibleDeclarations[myIndex] ??= {
          if (dartCoreFile != null) ...topLevelDeclarationsMap[dartCoreFile]!
              .map((key, value) => MapEntry(key, DeclarationOrPrefix(dartCoreFile!, declaration: value)))
        };
        topLevelDeclarationsMap[myIndex] ??= {};
        instanceDeclarationsMap[myIndex] ??= {};

        unit.declarations.forEach((d) {
          if (d is NamedCompilationUnitMember) {
            if (topLevelDeclarationsMap[myIndex]!.containsKey(d.name.name)) {
              throw CompileError('Cannot define "${d.name.name} twice in the same library"');
            }
            topLevelDeclarationsMap[myIndex]![d.name.name] = DeclarationOrBridge(declaration: d);
            if (d is ClassDeclaration) {
              instanceDeclarationsMap[myIndex]![d.name.name] = {};
              ctx.visibleTypes[myIndex]![d.name.name] = TypeRef.cache(ctx, myIndex!, d.name.name, fileRef: myIndex);
              d.members.forEach((member) {
                if (member is MethodDeclaration) {
                  if (member.isStatic) {
                    topLevelDeclarationsMap[myIndex]![d.name.name + '.' + member.name.name] =
                        DeclarationOrBridge(declaration: member);
                  } else {
                    instanceDeclarationsMap[myIndex]![d.name.name]![member.name.name] = member;
                  }
                } else if (member is FieldDeclaration) {
                  member.fields.variables.forEach((field) {
                    instanceDeclarationsMap[myIndex]![d.name.name]![field.name.name] = field;
                  });
                } else if (member is ConstructorDeclaration) {
                  topLevelDeclarationsMap[myIndex]!['${d.name.name}.${member.name?.name ?? ""}'] =
                      DeclarationOrBridge(declaration: member);
                } else {
                  throw CompileError('Not a NamedCompilationUnitMember');
                }
              });
            }
          } else {
            throw CompileError('Not a NamedCompilationUnitMember');
          }
        });

        ctx.visibleDeclarations[myIndex]!.addAll(topLevelDeclarationsMap[myIndex]!
            .map((key, value) => MapEntry(key, DeclarationOrPrefix(myIndex!, declaration: value))));
      });
    });

    importMap.forEach((file, imports) {
      final myUri = indexMap[file]!;
      for (final imp in imports) {
        final uri = imp.uri.stringValue;
        if (uri == null) {
          throw CompileError('Import URI is not a string');
        }
        final resolvedLibrary = resolveUri(resolvedUriParts(myUri[0], myUri[1], uri))!;
        ctx.visibleTypes[file] ??= {
          ...coreDeclarations,
          if (dartCoreFile != null) ...ctx.visibleTypes[dartCoreFile]!
        };
        ctx.visibleDeclarations[file] ??= {
          if (dartCoreFile != null) ...topLevelDeclarationsMap[dartCoreFile]!
              .map((key, value) => MapEntry(key, DeclarationOrPrefix(dartCoreFile!, declaration: value)))
        };
        var prefix = imp.prefix?.name ?? '';
        if (prefix != '') {
          prefix = '$prefix.';
        }
        ctx.visibleTypes[resolvedLibrary]!.forEach((key, value) {
          ctx.visibleTypes[file]!['$prefix$key'] = value;
        });
        if (prefix == '') {
          ctx.visibleDeclarations[file]!.addAll(topLevelDeclarationsMap[resolvedLibrary]!
              .map((key, value) => MapEntry(key, DeclarationOrPrefix(resolvedLibrary, declaration: value))));
        } else {
          ctx.visibleDeclarations[file]![prefix] =
              DeclarationOrPrefix(resolvedLibrary, children: topLevelDeclarationsMap[resolvedLibrary]);
        }
      }
    });

    ctx.topLevelDeclarationsMap = topLevelDeclarationsMap;
    ctx.instanceDeclarationsMap = instanceDeclarationsMap;

    topLevelDeclarationsMap.forEach((key, value) {
      ctx.topLevelDeclarationPositions[key] = {};
      ctx.instanceDeclarationPositions[key] = {};
      value.forEach((lib, _declaration) {
        if (_declaration.isBridge) {
          return;
        }
        final declaration = _declaration.declaration!;
        if (declaration is ConstructorDeclaration || declaration is MethodDeclaration) {
          return;
        }
        ctx.library = key;
        compileDeclaration(declaration, ctx);
        ctx.resetStack();
      });
    });

    for (final type in ctx.runtimeTypeList) {
      ctx.typeTypes.add(type.resolveTypeChain(ctx).getRuntimeIndices(ctx));
    }

    return Program(
        ctx.topLevelDeclarationPositions,
        ctx.instanceDeclarationPositions,
        ctx.typeNames,
        ctx.typeTypes,
        ctx.offsetTracker.apply(ctx.out),
        _bridgeLibraryMappings,
        ctx.bridgeStaticFunctionIndices,
        ctx.constantPool.pool,
        ctx.runtimeTypes.pool);
  }

  Runtime compileWriteAndLoad(Map<String, Map<String, String>> packages) {
    final program = compile(packages);

    final ob = program.write();

    return Runtime(ob.buffer.asByteData())..setup();
  }

  CompilationUnit _parse(String source) {
    final d = parseString(content: source, throwIfDiagnostics: false);
    if (d.errors.isNotEmpty) {
      for (final error in d.errors) {
        stderr.addError(error);
      }

      throw CompileError('Parsing error(s): ${d.errors}');
    }
    return d.unit;
  }
}
