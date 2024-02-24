import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/bindgen/bridge_declaration.dart';
import 'package:dart_eval/src/eval/bindgen/configure.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/statics.dart';
import 'package:dart_eval/src/eval/bindgen/type.dart';
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

  Future<String?> parse(io.File src, String uri, bool all) async {
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
    final ctx = BindgenContext(uri, wrap: true, all: all);

    if (analysisResult is ResolvedUnitResult) {
      // Access the resolved unit and analyze it
      final units =
          analysisResult.unit.declarations.whereType<ClassDeclaration>();

      final resolved = units
          .where((declaration) => declaration.declaredElement != null)
          .map((declaration) => _$instance(ctx, declaration.declaredElement!))
          .whereNotNull();

      if (resolved.isEmpty) {
        return null;
      }

      final result = resolved.join('\n');
      final imports = ctx.imports
          .whereNot((e) => e == uri)
          .map((e) => 'import \'$e\';')
          .join('\n');

      return imports + result;
    }

    return null;
  }

  String? _$instance(BindgenContext ctx, ClassElement element) {
    final metadata = element.metadata;
    if (!ctx.all) {
      final bindAnno = metadata.firstWhereOrNull(
          (element) => element.element?.displayName == 'Bind');
      if (bindAnno == null) {
        return null;
      }
    }

    return '''
/// dart_eval wrapper binding for [${element.name}]
class \$${element.name} implements \$Instance {
/// Configure this class for use in a [Runtime]
${bindConfigureForRuntime(ctx, element)}
/// Compile-time type declaration of [\$${element.name}]
${bindBridgeType(ctx, element)}
/// Compile-time class declaration of [\$${element.name}]
${bindBridgeDeclaration(ctx, element)}
${$constructors(element)}
${$staticMethods(ctx, element)}
${$staticGetters(ctx, element)}
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
    return supertype == null
        ? objectWrapper
        : wrapType(ctx, supertype, '\$value') ?? objectWrapper;
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

  String $getProperty(BindgenContext ctx, ClassElement element) {
    return '''
  @override
  \$Value? \$getProperty(Runtime runtime, String identifier) {
    ${propertyGetters(ctx, element)}
    return _superclass.\$getProperty(runtime, identifier);
  }
''';
  }

  String propertyGetters(BindgenContext ctx, ClassElement element) {
    final _getters = element.accessors
        .where((accessor) => accessor.isGetter && !accessor.isStatic);
    final _methods = element.methods.where((method) => !method.isStatic);
    if (_getters.isEmpty && _methods.isEmpty) {
      return '';
    }
    return 'switch (identifier) {\n' + _getters.map((e) => '''
      case '${e.displayName}':
        final _${e.displayName} = \$value.${e.displayName};
        return ${wrapVar(ctx, e.type.returnType, '_${e.displayName}')};
      ''').join('\n') + _methods.map((e) => '''
      case '${e.displayName}':
        return __${e.displayName};
      ''').join('\n') + '\n' + '}';
  }

  String $methods(BindgenContext ctx, ClassElement element) {
    return element.methods.map((e) {
      return '''
        static const \$Function __${e.displayName} = \$Function(_${e.displayName});
        static \$Value? _${e.displayName}(Runtime runtime, \$Value? target, List<\$Value?> args) {
          throw UnimplementedError();
        }''';
    }).join('\n');
  }

  String $getRuntimeType(ClassElement element) {
    return '''
  @override
  int \$getRuntimeType(Runtime runtime) => runtime.lookupType(\$type.spec!);
''';
  }

  String $setProperty(BindgenContext ctx, ClassElement element) {
    return '''
  @override
  void \$setProperty(Runtime runtime, String identifier, \$Value value) {
    ${propertySetters(ctx, element)}
    return _superclass.\$setProperty(runtime, identifier, value);
  }
''';
  }

  String propertySetters(BindgenContext ctx, ClassElement element) {
    final _setters = element.accessors.where((element) => element.isSetter);
    if (_setters.isEmpty) {
      return '';
    }
    return 'switch (identifier) {\n' + _setters.map((e) => '''
        case '${e.displayName}':
          \$value.${e.displayName} = value.\$value;
          return;
        ''').join('\n') + '\n' + '}';
  }
}
