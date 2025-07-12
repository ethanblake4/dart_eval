import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/bindgen/bridge.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart';
import 'package:dart_eval/src/eval/bindgen/configure.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/methods.dart';
import 'package:dart_eval/src/eval/bindgen/properties.dart';
import 'package:dart_eval/src/eval/bindgen/statics.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'dart:io' as io;

import 'package:package_config/package_config.dart';
import 'package:path/path.dart';

/// Adapted from code by Alex Wallen (@a-wallen)
class Bindgen {
  static final resourceProvider = PhysicalResourceProvider.INSTANCE;
  final includedPaths = [resourceProvider.pathContext.current];

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

  Future<String?> parse(
      io.File src, String filename, String uri, bool all) async {
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
    final ctx = BindgenContext(uri, all: all);

    if (analysisResult is ResolvedUnitResult) {
      // Access the resolved unit and analyze it

      final evalOutput = filename.replaceAll('.dart', '.eval.dart');
      bool partOf = false;

      if (!all &&
          analysisResult.unit.directives.any((element) =>
              element is PartDirective &&
              element.uri.stringValue == evalOutput)) {
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

      final units =
          analysisResult.unit.declarations.whereType<ClassDeclaration>();

      final resolved = units
          .where((declaration) => declaration.declaredElement != null)
          .map((declaration) => _$instance(ctx, declaration.declaredElement!))
          .nonNulls;

      if (resolved.isEmpty) {
        return null;
      }

      final result = resolved.join('\n');
      final imports = ctx.imports
          .whereNot((e) => e == uri)
          .map((e) => 'import \'$e\';')
          .join('\n');

      return partOf ? "part of '$filename'" : "" + imports + result;
    }

    return null;
  }

  String? _$instance(BindgenContext ctx, ClassElement element) {
    final metadata = element.metadata;
    final bindAnno = metadata.firstWhereOrNull(
          (element) => element.element?.displayName == 'Bind');
    final bindAnnoValue = bindAnno?.computeConstantValue();
    if (!ctx.all) {
      if (bindAnnoValue == null) {
        return null;
      }
      final implicitSupers =
          bindAnnoValue.getField('implicitSupers')?.toBoolValue() ?? false;
      ctx.implicitSupers = implicitSupers;
      final override = bindAnnoValue.getField('overrideLibrary');
      if (override != null && !override.isNull) {
        final overrideUri = override.toStringValue();
        if (overrideUri != null) {
          ctx.libOverrides[element.name] = overrideUri;
        }
      }
    }

    final isBridge = bindAnnoValue?.getField('bridge')?.toBoolValue() ?? false;

    if (isBridge) {
      if (element.isSealed) {
        throw CompileError(
          'Cannot bind sealed class ${element.name} as a bridge type. '
          'Please remove the @Bind annotation, use a wrapper, or make the class non-sealed.');
      }

      return '''
/// dart_eval bridge binding for [${element.name}]
class \$${element.name}\$bridge extends ${element.name} with \$Bridge<${element.name}> {
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
${bindDecoratoratorMethods(ctx, element)}
}
''';
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

  String $superclassWrapper(BindgenContext ctx, ClassElement element) {
    final supertype = element.supertype;
    final objectWrapper = '\$Object(\$value)';
    if (supertype == null || ctx.implicitSupers) {
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
      return objectWrapper;
    }
    final narrowWrapper = wrapType(ctx, supertype, '\$value');
    if (narrowWrapper == null) {
      print('Warning: Could not wrap supertype $supertype of ${element.name},'
          ' falling back to \$Object. Add a @Bind annotation to $supertype'
          ' or set `implicitSupers: true`');
      ctx.imports.add('package:dart_eval/stdlib/core.dart');
      return objectWrapper;
    }
    return narrowWrapper;
  }

  String $getRuntimeType(ClassElement element) {
    return '''
  @override
  int \$getRuntimeType(Runtime runtime) => runtime.lookupType(\$spec);
''';
  }

  String $wrap(BindgenContext ctx, ClassElement element) {
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
