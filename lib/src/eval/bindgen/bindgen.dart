import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart';
import 'package:dart_eval/src/eval/bindgen/configure.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/enum.dart';
import 'package:dart_eval/src/eval/bindgen/function.dart';
import 'package:dart_eval/src/eval/bindgen/methods.dart';
import 'package:dart_eval/src/eval/bindgen/properties.dart';
import 'package:dart_eval/src/eval/bindgen/statics.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'dart:io' as io;

import 'package:package_config/package_config.dart';
import 'package:path/path.dart';

/// Adapted from code by Alex Wallen (@a-wallen)
class Bindgen implements BridgeDeclarationRegistry {
  static final resourceProvider = PhysicalResourceProvider.INSTANCE;
  final includedPaths = [resourceProvider.pathContext.current];

  final _bridgeDeclarations = <String, List<BridgeDeclaration>>{};
  final _exportedLibMappings = <String, String>{};
  final List<({String file, String uri, String name})> registerClasses = [];
  final List<({String file, String uri, String name})> registerEnums = [];
  final List<({String file, String uri, String name})> registerFunctions = [];

  AnalysisContextCollection? _contextCollection;

  void inject({required Package package}) {
    String filepath;
    try {
      filepath = package.packageUriRoot.toFilePath();
    } catch (e) {
      filepath = package.packageUriRoot.toString();
    }
    includedPaths.add(normalize(filepath));
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

  /// Define a bridged enum definition to be used when binding.
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

  @override
  void addSource(DartSource source) {
    // Has no effect in binding generator
  }

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

  @override
  void addExportedLibraryMapping(String libraryUri, String exportUri) {
    _exportedLibMappings[libraryUri] = exportUri;
  }

  Future<String?> parse(
    io.File src,
    String filename,
    String uri,
    bool all,
  ) async {
    final resourceProvider = PhysicalResourceProvider.INSTANCE;
    if (_contextCollection == null) {
      _contextCollection = AnalysisContextCollection(
        includedPaths: includedPaths,
        resourceProvider: resourceProvider,
      );
      print('Analyzing project source...');
    }

    final filePath = src.path;
    final analysisContext = _contextCollection!.contextFor(filePath);
    final session = analysisContext.currentSession;
    final analysisResult = await session.getResolvedUnit(filePath);
    final ctx = BindgenContext(
      filename,
      uri,
      all: all,
      bridgeDeclarations: _bridgeDeclarations,
      exportedLibMappings: _exportedLibMappings,
    );

    if (analysisResult is ResolvedUnitResult) {
      // Access the resolved unit and analyze it

      final evalOutput = filename.replaceAll('.dart', '.eval.dart');
      bool partOf = false;

      if (!all &&
          analysisResult.unit.directives.any(
            (element) =>
                element is PartDirective &&
                element.uri.stringValue == evalOutput,
          )) {
        partOf = true;
      } else {
        for (final directive in analysisResult.unit.directives) {
          if (directive is ImportDirective) {
            final uri = directive.uri.stringValue;
            if (uri == null || uri.startsWith('package:eval_annotation')) {
              continue;
            }
            ctx.imports.add(uri);
          }
        }
      }

      final units = analysisResult.unit.declarations;

      final Iterable<String> resolved;
      try {
        resolved = units
            .where((declaration) => declaration.declaredFragment != null)
            .map((declaration) {
              if (declaration is ClassDeclaration) {
                return _$instance(ctx, declaration.declaredFragment!.element);
              } else if (declaration is EnumDeclaration) {
                return _$enum(ctx, declaration.declaredFragment!.element);
              } else if (declaration is FunctionDeclaration) {
                return _$function(ctx, declaration.declaredFragment!.element);
              }
              return null;
            })
            .toList()
            .nonNulls;
      } on Error {
        print('Failed to resolve $filePath:');
        rethrow;
      }

      if (resolved.isEmpty) {
        return null;
      }

      final result = resolved.join('\n');
      final imports = ctx.imports
          .whereNot((e) => e == uri)
          .map((e) => 'import \'$e\';')
          .join('\n');

      return partOf ? "part of '$filename'" : "$imports$result";
    }

    return null;
  }

  ({bool process, bool isBridge, bool alsoWrap}) _shouldProcess(
    BindgenContext ctx,
    Element element,
  ) {
    final metadata = element.metadata;
    final bindAnno = metadata.annotations.firstWhereOrNull(
      (element) => element.element?.displayName == 'Bind',
    );
    final bindAnnoValue = bindAnno?.computeConstantValue();

    if (bindAnnoValue == null && !ctx.all) {
      return (process: false, isBridge: false, alsoWrap: false);
    }
    final implicitSupers =
        bindAnnoValue?.getField('implicitSupers')?.toBoolValue() ?? false;
    ctx.implicitSupers = implicitSupers;
    final override = bindAnnoValue?.getField('overrideLibrary');
    if (override != null && !override.isNull) {
      final overrideUri = override.toStringValue();
      if (overrideUri != null) {
        ctx.libOverrides[element.name!] = overrideUri;
      }
    }

    final isBridge = bindAnnoValue?.getField('bridge')?.toBoolValue() ?? false;
    final alsoWrap = bindAnnoValue?.getField('wrap')?.toBoolValue() ?? false;

    return (
      process: ctx.all || bindAnnoValue != null,
      isBridge: isBridge,
      alsoWrap: alsoWrap,
    );
  }

  String? _$instance(BindgenContext ctx, ClassElement element) {
    final (:process, :isBridge, :alsoWrap) = _shouldProcess(ctx, element);
    if (!process) {
      return null;
    }

    if (isBridge && element.isSealed) {
      throw CompileError(
        'Cannot bind sealed class ${element.name} as a bridge type. '
        'Please remove the @Bind annotation, use a wrapper, or make the class non-sealed.',
      );
    }

    registerClasses.add((
      file: ctx.filename,
      uri: ctx.libOverrides[element.name!] ?? ctx.uri,
      name: '${element.name!}${isBridge ? '\$bridge' : ''}',
    ));

    if (isBridge) {
      String code =
          '''
/// dart_eval bridge binding for [${element.name}]
class \$${element.name}\$bridge extends ${element.name} with \$Bridge<${element.name}> {
${bindForwardedConstructors(ctx, element)}
/// Configure this class for use in a [Runtime]
${bindConfigureForRuntime(ctx, element, isBridge: true)}
/// Compile-time type specification of [\$${element.name}\$bridge]
${bindTypeSpec(ctx, element)}
/// Compile-time type declaration of [\$${element.name}\$bridge]
${bindBridgeType(ctx, element)}
/// Compile-time class declaration of [\$${element.name}]
${bindBridgeDeclaration(ctx, element, isBridge: true)}
${$constructors(ctx, element, isBridge: true)}
${$staticMethods(ctx, element)}
${$staticGetters(ctx, element)}
${$staticSetters(ctx, element)}
${$bridgeGet(ctx, element)}
${$bridgeSet(ctx, element)}
${bindDecoratorProperties(ctx, element)}
${bindDecoratorMethods(ctx, element)}
}
''';

      if (alsoWrap) {
        // Add a rudimentary wrapper, because you cannot wrap things in a bridge.
        code +=
            '''
/// dart_eval lightweight wrapper binding for [${element.name}]
class \$${element.name} implements \$Instance {
/// Compile-time type specification of [\$${element.name}]
${bindTypeSpec(ctx, element)}
/// Compile-time type declaration of [\$${element.name}]
${bindBridgeType(ctx, element)}
${$wrap(ctx, element)}
${$getRuntimeType(element)}
${$getProperty(ctx, element)}
${$methods(ctx, element)}
${$setProperty(ctx, element)}
}
''';
      }

      return code;
    }

    return '''
/// dart_eval wrapper binding for [${element.name}]
class \$${element.name} implements \$Instance {
/// Configure this class for use in a [Runtime]
${bindConfigureForRuntime(ctx, element)}
/// Compile-time type specification of [\$${element.name}]
${bindTypeSpec(ctx, element)}
/// Compile-time type declaration of [\$${element.name}]
${bindBridgeType(ctx, element)}
/// Compile-time class declaration of [\$${element.name}]
${bindBridgeDeclaration(ctx, element)}
${$constructors(ctx, element)}
${$staticMethods(ctx, element)}
${$staticGetters(ctx, element)}
${$staticSetters(ctx, element)}
${$wrap(ctx, element)}
${$getRuntimeType(element)}
${$getProperty(ctx, element)}
${$methods(ctx, element)}
${$setProperty(ctx, element)}
}
''';
  }

  String? _$enum(BindgenContext ctx, EnumElement element) {
    final (:process, :isBridge, :alsoWrap) = _shouldProcess(ctx, element);
    if (!process) {
      return null;
    }

    registerEnums.add((
      file: ctx.filename,
      uri: ctx.libOverrides[element.name!] ?? ctx.uri,
      name: element.name!,
    ));

    return '''
/// dart_eval enum wrapper binding for [${element.name}]
class \$${element.name} implements \$Instance {
  /// Configure this enum for use in a [Runtime]
  ${bindConfigureEnumForRuntime(ctx, element)}
  /// Compile-time type specification of [\$${element.name}]
  ${bindTypeSpec(ctx, element)}
  /// Compile-time type declaration of [\$${element.name}]
  ${bindBridgeType(ctx, element)}
  /// Compile-time class declaration of [\$${element.name}]
  ${bindBridgeDeclaration(ctx, element)}
  ${$enumValues(ctx, element)}
  ${$staticMethods(ctx, element)}
  ${$staticGetters(ctx, element)}
  ${$staticSetters(ctx, element)}
  ${$wrap(ctx, element)}
  ${$getRuntimeType(element)}
  ${$getProperty(ctx, element)}
  ${$methods(ctx, element)}
  ${$setProperty(ctx, element)}
}
''';
  }

  String? _$function(BindgenContext ctx, ExecutableElement element) {
    if (element is! TopLevelFunctionElement) return null;
    final (:process, :isBridge, :alsoWrap) = _shouldProcess(ctx, element);
    if (!process) {
      return null;
    }

    registerFunctions.add((
      file: ctx.filename,
      uri: ctx.libOverrides[element.name!] ?? ctx.uri,
      name: element.name!,
    ));

    return '''
/// dart_eval function wrapper binding for [${element.name}]
class \$${element.name}Fn implements EvalCallable {
  const \$${element.name}Fn();

  ${bindConfigureFunctionForRuntime(ctx, element)}
  ${bindFunctionDeclaration(ctx, element)}
  ${$function(ctx, element)}
}
''';
  }

  String $superclassWrapper(BindgenContext ctx, InterfaceElement element) {
    final supertype = element.supertype;
    final objectWrapper = '\$Object(\$value)';
    if (supertype == null || ctx.implicitSupers || element is EnumElement) {
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
      return objectWrapper;
    }
    final narrowWrapper = wrapType(ctx, supertype, '\$value');
    if (narrowWrapper == null) {
      print(
        'Warning: Could not wrap supertype $supertype of ${element.name},'
        ' falling back to \$Object. Add a @Bind annotation to $supertype'
        ' or set `implicitSupers: true`',
      );
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
      return objectWrapper;
    }
    return narrowWrapper;
  }

  String $getRuntimeType(InterfaceElement element) {
    return '''
  @override
  int \$getRuntimeType(Runtime runtime) => runtime.lookupType(\$spec);
''';
  }

  String $wrap(BindgenContext ctx, InterfaceElement element) {
    return '''
  final \$Instance _superclass;

  @override
  final ${element.name} \$value;

  @override
  ${element.name} get \$reified => \$value;

  /// Wrap a [${element.name}] in a [\$${element.name}]
  \$${element.name}.wrap(this.\$value) : _superclass = ${$superclassWrapper(ctx, element)};
    ''';
  }
}
