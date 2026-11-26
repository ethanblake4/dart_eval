import 'dart:convert';

import 'package:dart_eval/dart_eval_bridge.dart';

/// Renders bridge metadata as const-compatible Dart constructor expressions.
///
/// The callbacks can replace known specs, refs, or annotations with aliases
/// already available in the generated library. Returning `null` uses the
/// renderer's inline constructor expression.
class BridgeDeclarationSource {
  const BridgeDeclarationSource({
    this.specSource,
    this.typeRefSource,
    this.annotationSource,
  });

  final String? Function(BridgeTypeSpec spec)? specSource;
  final String? Function(BridgeTypeRef type)? typeRefSource;
  final String? Function(BridgeTypeAnnotation annotation)? annotationSource;

  /// Render a supported top-level bridge declaration.
  String declaration(BridgeDeclaration declaration) => switch (declaration) {
    BridgeClassDef value => _classDeclaration(value),
    BridgeEnumDef value => _enumDeclaration(value),
    BridgeFunctionDeclaration value =>
      'BridgeFunctionDeclaration('
          '${_string(value.library)}, ${_string(value.name)}, '
          '${function(value.function)})',
    _ => throw UnsupportedError(
      'Cannot render bridge declaration ${declaration.runtimeType}',
    ),
  };

  /// Render a type reference, rejecting resolved references that only carry a
  /// runtime cache id.
  String typeRef(BridgeTypeRef type) {
    final replacement = typeRefSource?.call(type);
    if (replacement != null) return replacement;

    if (type.cacheId != null) {
      throw UnsupportedError(
        'Cannot render resolved BridgeTypeRef cacheId ${type.cacheId}',
      );
    }

    final typeArgs = type.typeArgs.isEmpty
        ? ''
        : ', ${_list(type.typeArgs.map(typeAnnotation))}';
    if (type.spec case final spec?) {
      return 'BridgeTypeRef(${typeSpec(spec)}$typeArgs)';
    }
    if (type.gft case final function?) {
      return 'BridgeTypeRef.genericFunction(${this.function(function)})';
    }
    if (type.ref case final ref?) {
      return 'BridgeTypeRef.ref(${_string(ref)}$typeArgs)';
    }
    throw UnsupportedError('Cannot render an empty BridgeTypeRef');
  }

  /// Render a type annotation.
  String typeAnnotation(BridgeTypeAnnotation annotation) {
    final replacement = annotationSource?.call(annotation);
    if (replacement != null) return replacement;
    final nullable = annotation.nullable ? ', nullable: true' : '';
    return 'BridgeTypeAnnotation(${typeRef(annotation.type)}$nullable)';
  }

  /// Render a type spec without referring to a registry constant.
  String typeSpec(BridgeTypeSpec spec) {
    final replacement = specSource?.call(spec);
    if (replacement != null) return replacement;
    return 'BridgeTypeSpec(${_string(spec.library)}, ${_string(spec.name)})';
  }

  /// Render a function definition and all of its signature metadata.
  String function(BridgeFunctionDef function) {
    final arguments = <String>['returns: ${typeAnnotation(function.returns)}'];
    final returnTypeDependency = function.returnTypeDependency;
    if (returnTypeDependency != null) {
      arguments.add(
        'returnTypeDependency: ${_returnTypeDependency(returnTypeDependency)}',
      );
    }
    if (function.generics.isNotEmpty) {
      arguments.add('generics: ${_genericParams(function.generics)}');
    }
    if (function.params.isNotEmpty) {
      arguments.add('params: ${_list(function.params.map(parameter))}');
    }
    if (function.namedParams.isNotEmpty) {
      arguments.add(
        'namedParams: ${_list(function.namedParams.map(parameter))}',
      );
    }
    return 'BridgeFunctionDef(${arguments.join(', ')})';
  }

  /// Render a function parameter.
  String parameter(BridgeParameter parameter) {
    final defaultValueSource = parameter.defaultValueSource;
    final defaultValue = defaultValueSource == null
        ? ''
        : ', defaultValueSource: ${_doubleQuotedString(defaultValueSource)}';
    return 'BridgeParameter('
        '${_string(parameter.name)}, ${typeAnnotation(parameter.type)}, '
        '${parameter.optional}$defaultValue)';
  }

  String _classDeclaration(BridgeClassDef declaration) {
    final arguments = <String>[
      _classType(declaration.type),
      'constructors: ${_map(declaration.constructors, _constructor)}',
    ];
    if (declaration.methods.isNotEmpty) {
      arguments.add('methods: ${_map(declaration.methods, _method)}');
    }
    if (declaration.getters.isNotEmpty) {
      arguments.add('getters: ${_map(declaration.getters, _method)}');
    }
    if (declaration.setters.isNotEmpty) {
      arguments.add('setters: ${_map(declaration.setters, _method)}');
    }
    if (declaration.fields.isNotEmpty) {
      arguments.add('fields: ${_map(declaration.fields, _field)}');
    }
    arguments.add('bridge: ${declaration.bridge}');
    arguments.add('wrap: ${declaration.wrap}');
    return 'BridgeClassDef(${arguments.join(', ')})';
  }

  String _enumDeclaration(BridgeEnumDef declaration) {
    final arguments = <String>[typeRef(declaration.type)];
    if (declaration.values.isNotEmpty) {
      arguments.add('values: ${_list(declaration.values.map(_string))}');
    }
    if (declaration.methods.isNotEmpty) {
      arguments.add('methods: ${_map(declaration.methods, _method)}');
    }
    if (declaration.getters.isNotEmpty) {
      arguments.add('getters: ${_map(declaration.getters, _method)}');
    }
    if (declaration.setters.isNotEmpty) {
      arguments.add('setters: ${_map(declaration.setters, _method)}');
    }
    if (declaration.fields.isNotEmpty) {
      arguments.add('fields: ${_map(declaration.fields, _field)}');
    }
    return 'BridgeEnumDef(${arguments.join(', ')})';
  }

  String _classType(BridgeClassType type) {
    final arguments = <String>[typeRef(type.type)];
    final supertype = type.$extends;
    if (supertype == null) {
      arguments.add('\$extends: null');
    } else if (!_isDefaultObjectType(supertype)) {
      arguments.add('\$extends: ${typeRef(supertype)}');
    }
    if (type.$implements.isNotEmpty) {
      arguments.add('\$implements: ${_list(type.$implements.map(typeRef))}');
    }
    if (type.$with.isNotEmpty) {
      arguments.add('\$with: ${_list(type.$with.map(typeRef))}');
    }
    if (type.isAbstract) arguments.add('isAbstract: true');
    if (type.isMixinClass) arguments.add('isMixinClass: true');
    if (type.generics.isNotEmpty) {
      arguments.add('generics: ${_genericParams(type.generics)}');
    }
    return 'BridgeClassType(${arguments.join(', ')})';
  }

  String _constructor(BridgeConstructorDef definition) {
    final isFactory = definition.isFactory ? ', isFactory: true' : '';
    return 'BridgeConstructorDef(${function(definition.functionDescriptor)}$isFactory)';
  }

  String _method(BridgeMethodDef definition) {
    final options = <String>[];
    if (definition.isStatic) options.add('isStatic: true');
    if (definition.isAbstract) options.add('isAbstract: true');
    final suffix = options.isEmpty ? '' : ', ${options.join(', ')}';
    return 'BridgeMethodDef(${function(definition.functionDescriptor)}$suffix)';
  }

  String _field(BridgeFieldDef definition) {
    final isStatic = definition.isStatic ? ', isStatic: true' : '';
    return 'BridgeFieldDef(${typeAnnotation(definition.type)}$isStatic)';
  }

  String _genericParams(Map<String, BridgeGenericParam> params) =>
      _map(params, _genericParam);

  String _genericParam(BridgeGenericParam parameter) {
    final arguments = <String>[];
    final supertype = parameter.$extends;
    if (supertype != null) arguments.add('\$extends: ${typeRef(supertype)}');
    if (parameter.boundNullable) arguments.add('boundNullable: true');
    return 'BridgeGenericParam(${arguments.join(', ')})';
  }

  String _returnTypeDependency(BridgeReturnTypeDependency? dependency) {
    if (dependency == null) return 'null';
    final arguments = <String>[];
    final cases = _list(
      dependency.cases.map(
        (entry) =>
            'BridgeReturnTypeCase('
            '${typeRef(entry.when)}, ${typeAnnotation(entry.then)})',
      ),
    );
    final paramIndex = dependency.paramIndex;
    if (paramIndex != null) arguments.add('paramIndex: $paramIndex');
    final paramName = dependency.paramName;
    if (paramName != null) {
      arguments.add('paramName: ${_string(paramName)}');
    }
    arguments.add('cases: $cases');
    final fallback = dependency.fallback;
    if (fallback != null) {
      arguments.add('fallback: ${typeAnnotation(fallback)}');
    }
    return 'BridgeReturnTypeDependency(${arguments.join(', ')})';
  }
}

/// Render a supported bridge declaration with the default inline renderer.
String bridgeDeclarationSource(BridgeDeclaration declaration) =>
    const BridgeDeclarationSource().declaration(declaration);

/// Render a bridge type reference with the default inline renderer.
String bridgeTypeRefSource(BridgeTypeRef type) =>
    const BridgeDeclarationSource().typeRef(type);

/// Render a bridge type annotation with the default inline renderer.
String bridgeTypeAnnotationSource(BridgeTypeAnnotation annotation) =>
    const BridgeDeclarationSource().typeAnnotation(annotation);

/// Render a bridge type spec with the default inline renderer.
String bridgeTypeSpecSource(BridgeTypeSpec spec) =>
    const BridgeDeclarationSource().typeSpec(spec);

/// Render a bridge function definition with the default inline renderer.
String bridgeFunctionSource(BridgeFunctionDef function) =>
    const BridgeDeclarationSource().function(function);

/// Render a bridge parameter with the default inline renderer.
String bridgeParameterSource(BridgeParameter parameter) =>
    const BridgeDeclarationSource().parameter(parameter);

String _list(Iterable<String> values) => '[${values.join(', ')}]';

String _map<V>(Map<String, V> values, String Function(V value) source) =>
    '{${values.entries.map((entry) => '${_string(entry.key)}: ${source(entry.value)}').join(', ')}}';

bool _isDefaultObjectType(BridgeTypeRef type) =>
    type.cacheId == null &&
    type.ref == null &&
    type.gft == null &&
    type.spec?.library == 'dart:core' &&
    type.spec?.name == 'Object' &&
    type.typeArgs.isEmpty;

String _string(String value) {
  final result = StringBuffer("'");
  for (final rune in value.runes) {
    switch (rune) {
      case 0x24:
        result.write(r'\$');
      case 0x27:
        result.write(r"\'");
      case 0x5c:
        result.write(r'\\');
      case 0x0a:
        result.write(r'\n');
      case 0x0d:
        result.write(r'\r');
      case 0x09:
        result.write(r'\t');
      case 0x2028:
      case 0x2029:
        result.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
      default:
        if (rune < 0x20 || rune == 0x7f) {
          result.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        } else if (rune > 0xffff) {
          result.write('\\u{${rune.toRadixString(16)}}');
        } else {
          result.writeCharCode(rune);
        }
    }
  }
  result.write("'");
  return result.toString();
}

String _doubleQuotedString(String value) =>
    jsonEncode(value).replaceAll(r'$', r'\$');
