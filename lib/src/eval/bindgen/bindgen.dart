import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
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

  /// Create (once) and return the analysis session used by the generator.
  Future<AnalysisSession> _session() async {
    if (_contextCollection == null) {
      _contextCollection = AnalysisContextCollection(
        includedPaths: includedPaths,
        resourceProvider: PhysicalResourceProvider.INSTANCE,
      );
      print('Analyzing project source...');
    }
    final filePath = includedPaths.first;
    final analysisContext = _contextCollection!.contextFor(filePath);
    return analysisContext.currentSession;
  }

  /// Populate the dart:core namespace fallback used to resolve YAML type names.
  Future<void> _ensureCoreNamespace(BindgenContext ctx) async {
    if (ctx.dartCoreLibrary != null) return;
    final session = await _session();
    final result = await session.getLibraryByUri('dart:core');
    if (result is LibraryElementResult) {
      ctx.dartCoreLibrary = result.element;
    }
  }

  /// Resolve a `dart:`/`package:` URI to a [LibraryElement] and run the
  /// config-driven emitters over its top-level elements.
  ///
  /// Returns a map from output file name (the `file:` class option or
  /// `<class>.dart`) to generated source.
  Future<Map<String, String>> parseLibrary(
    String uri,
    BindgenConfig config,
    BindgenLibraryConfig libraryConfig,
  ) async {
    final session = await _session();
    final libraryResult = await session.getLibraryByUri(uri);
    if (libraryResult is! LibraryElementResult) {
      throw CompileError('Could not resolve library $uri');
    }
    final library = libraryResult.element;

    // Group elements by output file.
    final files = <String, BindgenContext>{};
    final output = <String, String>{};

    BindgenContext contextFor(String file) => files.putIfAbsent(
      file,
      () =>
          BindgenContext(
              file,
              uri,
              all: false,
              bridgeDeclarations: _bridgeDeclarations,
              exportedLibMappings: _exportedLibMappings,
              config: config,
            )
            ..libraryConfig = libraryConfig
            ..libraryElement = library
            ..outputFile = file,
    );

    Future<void> process(Element element, String file) async {
      final ctx = contextFor(file);
      await _ensureCoreNamespace(ctx);
      final code = switch (element) {
        ClassElement() => _$instance(ctx, element),
        EnumElement() => _$enum(ctx, element),
        TopLevelFunctionElement() => _$function(ctx, element),
        _ => null,
      };
      if (code != null) {
        output.update(file, (v) => '$v\n$code', ifAbsent: () => code);
      }
    }

    for (final element in library.classes) {
      final cc = libraryConfig.classes[element.name];
      if (cc == null || !cc.include || cc.handMaintained) continue;
      await process(element, cc.file ?? '${element.name}.dart');
    }
    for (final element in library.enums) {
      final cc = libraryConfig.classes[element.name];
      if (cc == null || !cc.include || cc.handMaintained) continue;
      await process(element, cc.file ?? '${element.name}.dart');
    }
    for (final element in library.topLevelFunctions) {
      final fc = libraryConfig.functions[element.name];
      if (fc == null || !fc.include) continue;
      await process(element, libraryConfig.functionsFile ?? 'functions.dart');
    }

    // Emit imports into each file's output.
    final result = <String, String>{};
    for (final entry in output.entries) {
      final ctx = files[entry.key]!;
      final imports = {
        // The bound library itself is always needed for the wrapped type.
        if (uri != 'dart:core') uri,
        ...libraryConfig.imports,
        ...ctx.imports.where((e) => e != uri),
      }.map((e) => _importLine(e, ctx)).join('\n');
      final hooks = ctx.hooksImports.entries
          .map((e) => "import '${e.key}' as ${e.value};")
          .join('\n');
      result[entry.key] = '$imports$hooks\n${entry.value}';
    }
    return result;
  }

  Future<String?> parse(
    io.File src,
    String filename,
    String uri,
    bool all, {
    BindgenConfig? config,
    BindgenLibraryConfig? libraryConfig,
  }) async {
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
      config: config,
    );
    if (libraryConfig != null) {
      ctx.libraryConfig = libraryConfig;
      if (analysisResult is ResolvedUnitResult) {
        ctx.libraryElement = analysisResult.libraryElement;
      }
      await _ensureCoreNamespace(ctx);
    }

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
          .map((e) => _importLine(e, ctx))
          .join('\n');
      final hooks = ctx.hooksImports.entries
          .map((e) => "import '${e.key}' as ${e.value};")
          .join('\n');

      return partOf ? "part of '$filename'" : "$imports$hooks\n$result";
    }

    return null;
  }

  /// Emit an `import` line for [uri]. stdlib umbrella imports hide the names
  /// of generated wrappers so they cannot collide with the built-in wrappers
  /// they supersede.
  static String _importLine(String uri, BindgenContext ctx) {
    if (uri.startsWith('package:dart_eval/stdlib/')) {
      final hidden = ctx.libraryConfig?.classes.values
          .where((c) => c.include && !c.handMaintained)
          .map((c) => '\$${c.wrapperName ?? c.name}')
          .toList();
      if (hidden != null && hidden.isNotEmpty) {
        return "import '$uri' hide ${hidden.join(', ')};";
      }
    }
    return "import '$uri';";
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

    if (ctx.configMode) {
      final lc = ctx.libraryConfig!;
      final BindgenMemberConfig? fc;
      final BindgenClassConfig? cc;
      if (element is TopLevelFunctionElement) {
        fc = lc.functions[element.name];
        cc = null;
      } else {
        fc = null;
        cc = lc.classes[element.name];
      }
      ctx.classConfig = cc;
      if (cc != null) {
        ctx.imports.addAll(cc.imports);
      }
      ctx.typeParamNames = element is InterfaceElement
          ? element.typeParameters.map((e) => e.name ?? '').toSet()
          : const {};
      ctx.implicitSupers =
          cc?.implicitSupers ??
          lc.defaults.implicitSupers ||
              (bindAnnoValue?.getField('implicitSupers')?.toBoolValue() ??
                  false);
      if (cc?.libOverride != null) {
        ctx.libOverrides[element.name!] = cc!.libOverride!;
      }
      final override = bindAnnoValue?.getField('overrideLibrary');
      if (override != null && !override.isNull) {
        final overrideUri = override.toStringValue();
        if (overrideUri != null) {
          ctx.libOverrides[element.name!] = overrideUri;
        }
      }

      final include =
          (fc?.include ?? cc?.include ?? false) &&
          !(cc?.handMaintained ?? false);
      if (!include && bindAnnoValue == null && !ctx.all) {
        return (process: false, isBridge: false, alsoWrap: false);
      }
      final mode = cc?.mode ?? lc.defaults.mode;
      final isBridge =
          bindAnnoValue?.getField('bridge')?.toBoolValue() ?? mode != 'wrap';
      final alsoWrap =
          bindAnnoValue?.getField('wrap')?.toBoolValue() ?? mode == 'both';
      return (process: true, isBridge: isBridge, alsoWrap: alsoWrap);
    }

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

  String _wrapperName(BindgenContext ctx, InterfaceElement element) {
    final configured = ctx.classConfig?.wrapperName;
    if (configured != null) {
      return configured.startsWith(r'$') ? configured : '\$$configured';
    }
    return '\$${element.name}';
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

    final wrapperName = _wrapperName(ctx, element);
    final registerName = wrapperName.startsWith(r'$')
        ? wrapperName.substring(1)
        : wrapperName;

    registerClasses.add((
      file: ctx.filename,
      uri: ctx.libOverrides[element.name!] ?? ctx.uri,
      name: '$registerName${isBridge ? '\$bridge' : ''}',
    ));

    if (isBridge) {
      String code =
          '''
/// dart_eval bridge binding for [${element.name}]
class $wrapperName\$bridge extends ${element.name} with \$Bridge<${element.name}> {
${bindForwardedConstructors(ctx, element)}
/// Configure this class for use in a [Runtime]
${bindConfigureForRuntime(ctx, element, isBridge: true)}
/// Compile-time type specification of [$wrapperName\$bridge]
${bindTypeSpec(ctx, element)}
/// Compile-time type declaration of [$wrapperName\$bridge]
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
class $wrapperName implements \$Instance {
/// Compile-time type specification of [$wrapperName]
${bindTypeSpec(ctx, element)}
/// Compile-time type declaration of [$wrapperName]
${bindBridgeType(ctx, element)}
${$wrap(ctx, element)}
${$getRuntimeType(ctx, element)}
${$getProperty(ctx, element)}
${$methods(ctx, element)}
${$setProperty(ctx, element)}
${$equalityMembers(ctx, element)}
}
''';
      }

      return code;
    }

    final typeParams = _typeParams(ctx, element);
    final implementsSdk = ctx.classConfig?.implementsSdk == true;

    return '''
/// dart_eval wrapper binding for [${element.name}]
class $wrapperName$typeParams implements ${implementsSdk ? '${element.name}${_typeArgs(element)}, ' : ''}\$Instance {
/// Configure this class for use in a [Runtime]
${bindConfigureForRuntime(ctx, element)}
/// Compile-time type specification of [$wrapperName]
${bindTypeSpec(ctx, element)}
/// Compile-time type declaration of [$wrapperName]
${bindBridgeType(ctx, element)}
/// Compile-time class declaration of [\$${element.name}]
${bindBridgeDeclaration(ctx, element)}
${$constructors(ctx, element)}
${$staticMethods(ctx, element)}
${$staticGetters(ctx, element)}
${$staticSetters(ctx, element)}
${$wrap(ctx, element)}
${$getRuntimeType(ctx, element)}
${$getProperty(ctx, element)}
${$methods(ctx, element)}
${$setProperty(ctx, element)}
${$equalityMembers(ctx, element)}
${implementsSdk ? $sdkInterfaceMembers(ctx, element) : ''}
}
''';
  }

  /// For `implementsSdk` classes, emit Dart forwarding members for every
  /// non-Object member of the SDK interface so the wrapper genuinely
  /// implements the wrapped type.
  String $sdkInterfaceMembers(BindgenContext ctx, InterfaceElement element) {
    final buf = StringBuffer();
    String argList(List<FormalParameterElement> params) {
      final positional = params
          .where((p) => !p.isNamed)
          .map((p) => p.name ?? '')
          .join(', ');
      final named = params
          .where((p) => p.isNamed)
          .map((p) => '${p.name}: ${p.name}')
          .join(', ');
      return [positional, named].where((s) => s.isNotEmpty).join(', ');
    }

    bool skip(ExecutableElement e) =>
        e.isStatic ||
        e.enclosingElement?.name == 'Object' ||
        (e.name?.startsWith('_') ?? false);

    // `element.getters`/`setters`/`methods` only list declared members —
    // collect the full interface by walking `allSupertypes`, using
    // `InterfaceType` accessors so type parameters are substituted.
    final getters = <String, PropertyAccessorElement>{};
    final setters = <String, PropertyAccessorElement>{};
    final methods = <String, MethodElement>{};
    void collect(InterfaceType t) {
      for (final g in t.getters) {
        getters.putIfAbsent(g.name ?? '', () => g);
      }
      for (final s in t.setters) {
        setters.putIfAbsent(s.name ?? '', () => s);
      }
      for (final m in t.methods) {
        methods.putIfAbsent(m.name ?? '', () => m);
      }
    }

    collect(element.thisType);
    for (final supertype in element.allSupertypes) {
      collect(supertype);
    }

    for (final getter in getters.values) {
      if (skip(getter)) continue;
      buf.writeln('''
  @override
  ${dartTypeErased(getter.returnType)} get ${getter.name} => \$value.${getter.name};
''');
    }
    for (final setter in setters.values) {
      if (skip(setter)) continue;
      final param = setter.formalParameters.first;
      final pName = param.name == null || param.name!.isEmpty
          ? 'value'
          : param.name!;
      buf.writeln('''
  @override
  set ${setter.name}(${dartTypeErased(param.type)} $pName) =>
      \$value.${setter.name} = $pName;
''');
    }
    for (final method in methods.values) {
      if (skip(method)) continue;
      final args = argList(method.formalParameters);
      final call = switch (method.name) {
        '[]' => '\$value[$args]',
        '[]=' =>
          '\$value[${method.formalParameters.first.name}] = '
              '${method.formalParameters.last.name}',
        '-' when method.formalParameters.isEmpty => '-\$value',
        '~' when method.formalParameters.isEmpty => '~\$value',
        _ when method.isOperator => '\$value ${method.name} $args',
        _ => '\$value.${method.name}($args)',
      };
      buf.writeln('''
  @override
  ${dartTypeErased(method.returnType)} ${method.name}(${parameterHeader(method.formalParameters)}) =>
      $call;
''');
    }
    return buf.toString();
  }

  String? _$enum(BindgenContext ctx, EnumElement element) {
    final (:process, :isBridge, :alsoWrap) = _shouldProcess(ctx, element);
    if (!process) {
      return null;
    }

    final wrapperName = _wrapperName(ctx, element);
    final registerName = wrapperName.startsWith(r'$')
        ? wrapperName.substring(1)
        : wrapperName;

    registerEnums.add((
      file: ctx.filename,
      uri: ctx.libOverrides[element.name!] ?? ctx.uri,
      name: registerName,
    ));

    return '''
/// dart_eval enum wrapper binding for [${element.name}]
class $wrapperName implements \$Instance {
  /// Configure this enum for use in a [Runtime]
  ${bindConfigureEnumForRuntime(ctx, element)}
  /// Compile-time type specification of [$wrapperName]
  ${bindTypeSpec(ctx, element)}
  /// Compile-time type declaration of [$wrapperName]
  ${bindBridgeType(ctx, element)}
  /// Compile-time class declaration of [\$${element.name}]
  ${bindBridgeDeclaration(ctx, element)}
  ${$enumValues(ctx, element)}
  ${$staticMethods(ctx, element)}
  ${$staticGetters(ctx, element)}
  ${$staticSetters(ctx, element)}
  ${$wrap(ctx, element)}
  ${$getRuntimeType(ctx, element)}
  ${$getProperty(ctx, element)}
  ${$methods(ctx, element)}
  ${$setProperty(ctx, element)}
  ${$equalityMembers(ctx, element)}
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
class \$${element.name}Fn {
  const \$${element.name}Fn();

  ${bindConfigureFunctionForRuntime(ctx, element)}
  ${bindFunctionDeclaration(ctx, element)}
  ${$function(ctx, element)}
}
''';
  }

  /// Dart type-parameter list for a generic wrapper class
  /// (`<T extends num>`) or empty.
  String _typeParams(BindgenContext ctx, InterfaceElement element) {
    final params = element.typeParameters;
    if (params.isEmpty) return '';
    return '<${params.map((p) {
      final bound = p.bound;
      if (bound == null || bound is DynamicType || bound.isDartCoreObject) {
        return p.name!;
      }
      final boundLib = bound.element?.library;
      if (boundLib != null) {
        ctx.imports.add(boundLib.uri.toString());
      }
      return '${p.name} extends ${bound.getDisplayString()}';
    }).join(', ')}>';
  }

  /// Bare type-argument list (`<T, S>`) for the wrapped type of a generic
  /// wrapper class.
  String _typeArgs(InterfaceElement element) => element.typeParameters.isEmpty
      ? ''
      : '<${element.typeParameters.map((p) => p.name).join(', ')}>';

  String $superclassWrapper(BindgenContext ctx, InterfaceElement element) {
    final superclass = ctx.classConfig?.superclass;
    if (superclass?.expr != null) {
      if (superclass!.import != null) {
        ctx.imports.add(superclass.import!);
      }
      return superclass.expr!;
    }
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

  String $getRuntimeType(BindgenContext ctx, InterfaceElement element) {
    final runtimeType = ctx.classConfig?.runtimeTypeOverride;
    return '''
  @override
  int \$getRuntimeType(Runtime runtime) => runtime.lookupType(${runtimeType ?? '\$spec'});
''';
  }

  /// Emit `==`/`hashCode`/`toString` overrides requested by `equality:`.
  String $equalityMembers(BindgenContext ctx, InterfaceElement element) {
    final equality = ctx.classConfig?.equality;
    if (equality == null) return '';
    final wrapperName = _wrapperName(ctx, element);
    return '''
  ${equality.emitEquals == true ? '''
  @override
  bool operator ==(Object other) =>
      other is $wrapperName && other.\$value == \$value;
''' : ''}
  ${equality.emitHashCode == true ? '''
  @override
  int get hashCode => \$value.hashCode;
''' : ''}
  ${equality.emitToString != null ? '''
  @override
  String toString() => ${equality.emitToString == 'dartString' ? '\$value.toString()' : equality.emitToString};
''' : ''}
''';
  }

  String $wrap(BindgenContext ctx, InterfaceElement element) {
    final cc = ctx.classConfig;
    final reified = cc?.reified;
    final reifiedExpr =
        reified?.expr ??
        (reified?.hook != null
            ? '${ctx.hooksPrefix()}.${reified!.hook}(this)'
            : '\$value');
    final reifiedType = reified?.type ?? element.name!;
    final wrapperName = _wrapperName(ctx, element);
    final superclassExpr = $superclassWrapper(ctx, element);
    final valueType = '${element.name}${_typeArgs(element)}';
    return '''
  final \$Instance _superclass;

  @override
  final $valueType \$value;

  @override
  $reifiedType get \$reified => $reifiedExpr;

  /// Wrap a [${element.name}] in a [$wrapperName]
  $wrapperName.wrap(this.\$value) : _superclass = $superclassExpr;
  ${cc?.unnamedValueConstructor == true ? '''
  /// Wrap a [${element.name}] in a [$wrapperName]
  $wrapperName(this.\$value) : _superclass = $superclassExpr;''' : ''}
    ''';
  }
}
