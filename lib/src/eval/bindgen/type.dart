import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:change_case/change_case.dart';
import 'package:collection/collection.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:dart_eval/src/eval/bindgen/context.dart';
import 'package:dart_eval/src/eval/bindgen/errors.dart';
import 'package:dart_eval/src/eval/bindgen/parameters.dart';
import 'package:path/path.dart' as path;

String bridgeTypeRefFromType(BindgenContext ctx, DartType type) {
  if (type is TypeParameterType) {
    return 'BridgeTypeRef.ref(\'${type.element.name}\')';
  } else if (type is FunctionType) {
    return '''BridgeTypeRef.genericFunction(BridgeFunctionDef(
      returns: ${bridgeTypeAnnotationFrom(ctx, type.returnType)},
      params: [
        ${parameters(ctx, type.formalParameters.where((p) => p.isPositional).toList())}
      ],
      namedParams: [
        ${parameters(ctx, type.formalParameters.where((p) => p.isNamed).toList())}
      ],
    ))''';
  } else if (type is ParameterizedType) {
    final typeArgs = type.typeArguments
        .map((e) => bridgeTypeAnnotationFrom(ctx, e))
        .join(', ');
    return 'BridgeTypeRef(${bridgeTypeSpecFrom(ctx, type)}, [$typeArgs])';
  }
  return 'BridgeTypeRef(${bridgeTypeSpecFrom(ctx, type)})';
}

String bridgeTypeAnnotationFrom(BindgenContext ctx, DartType type) {
  final nullabilityString = type.nullabilitySuffix == NullabilitySuffix.question
      ? ', nullable: true'
      : '';
  return 'BridgeTypeAnnotation(${bridgeTypeRefFromType(ctx, type)}$nullabilityString)';
}

String bridgeTypeSpecFrom(BindgenContext ctx, DartType type) {
  final builtin = builtinTypeFrom(ctx, type);
  if (builtin != null) {
    return builtin;
  }
  final element = type.element;
  if (element == null ||
      element.library == null ||
      element.name == null) {
    print(
      'Warning: type ${type.getDisplayString()} ($type, element: '
      '${element?.runtimeType} ${element?.name}) is not spec-able; '
      'falling back to dynamic spec',
    );
    return 'CoreTypes.dynamic';
  }
  final lib = element.library!;
  final uri = ctx.libOverrides[element.name] ?? lib.uri.toString();
  return 'BridgeTypeSpec(\'$uri\', \'${element.name!.replaceAll(r'$', r'\$')}\')';
}

/// Registry field names that diverge from the automatic camel-case
/// conversion, either because the type has no class name (`void`) or because
/// the camel-case name is a reserved word (`null`, `enum`).
const _divergentSpecFields = {
  'void': 'voidType',
  'Null': 'nullType',
  'Enum': 'enumType',
};

/// The `*Types` registry field name for a bound type.
String registryFieldName(String name) =>
    _divergentSpecFields[name] ?? name.toCamelCase();

/// The registry class name for a configured library
/// (`dart:typed_data` → `TypedDataTypes`).
String registryClassName(BindgenLibraryConfig lib) =>
    lib.registry?.className ??
    '${lib.uri.split(':').last.toPascalCase()}Types';

/// Return `RegistryClass.field` for a type declared in [libUri], or null when
/// the type is not part of any configured registry (the caller then emits a
/// raw `BridgeTypeSpec`). Registry membership mirrors what the generator
/// emits: every class listed in the sidecar config contributes a spec to the
/// registry of the library matching its effective spec URI
/// (`overrideLibrary` or the declaring library).
String? _registrySpec(BindgenContext ctx, String libUri, String name) {
  final config = ctx.config;
  if (config == null) return _legacyRegistrySpec(libUri, name);
  final lib = config.libraries.firstWhereOrNull((l) => l.uri == libUri);
  if (lib == null) return null;
  final cc = lib.classes[name];
  if (cc == null) return null;
  final specUri = cc.libOverride ?? lib.uri;
  final regLib = config.libraries.firstWhereOrNull(
    (l) => l.uri == specUri && l.registry != null,
  );
  if (regLib == null) return null;
  return '${registryClassName(regLib)}.${registryFieldName(name)}';
}

/// Annotation-mode fallback: emit `*Types` constants for every SDK type by
/// URI, matching the historical behavior.
String? _legacyRegistrySpec(String libUri, String name) {
  final camel = name.toCamelCase();
  return switch (libUri) {
    'dart:async' => name == 'Future' || name == 'Stream'
        ? 'CoreTypes.$camel'
        : 'AsyncTypes.$camel',
    'dart:collection' => 'CollectionTypes.$camel',
    'dart:convert' => 'ConvertTypes.$camel',
    'dart:core' => 'CoreTypes.$camel',
    'dart:io' => 'IoTypes.$camel',
    'dart:math' => 'MathTypes.$camel',
    'dart:typed_data' => 'TypedDataTypes.$camel',
    _ => null,
  };
}

String? builtinTypeFrom(BindgenContext ctx, DartType type) {
  if (type.isDartCoreNull) {
    return 'CoreTypes.nullType';
  }
  if (type.isDartCoreEnum) {
    return 'CoreTypes.enumType';
  }
  if (type is VoidType) {
    return 'CoreTypes.voidType';
  }
  if (type is DynamicType) {
    return 'CoreTypes.dynamic';
  }
  if (type is FunctionType) {
    return 'CoreTypes.function';
  }
  if (type is RecordType) {
    return 'CoreTypes.record';
  }
  if (type.element?.name == 'Never') {
    return 'CoreTypes.never';
  }

  final element = type.element;
  final lib = element?.library;
  if (element == null || lib == null) return null;
  final name = element.name ?? ' ';

  if (!lib.isInSdk) {
    return null;
  }

  if (ctx.configMode && element is InterfaceElement) {
    // SDK-private types resolve to their nearest bound public supertype.
    final bound = _boundSdkClass(ctx, element);
    if (bound == null) return null;
    final e = bound.$1;
    return _registrySpec(ctx, e.library.uri.toString(), e.name!);
  }

  return _registrySpec(ctx, lib.uri.toString(), name);
}

String? wrapVar(
  BindgenContext ctx,
  DartType type,
  String expr, {
  bool func = false,
  bool wrapList = false,
  List<ElementAnnotation>? metadata,
  bool forCollection = false,
  List<String>? unionTypeNames,
}) {
  if (type is VoidType) {
    if (func) {
      return 'const \$null()';
    }
    return 'null';
  }

  if (type.isDartCoreNull) {
    return 'const \$null()';
  }

  var wrapped = wrapType(
    ctx,
    type,
    expr,
    metadata: metadata,
    wrapList: wrapList,
    unionTypeNames: unionTypeNames,
  );

  if (wrapped == null) {
    if (ctx.unknownTypes.add(type.element!.name!)) {
      print(
        'Warning: type ${type.element!.name} is not bound, '
        'falling back to wrapAlways()',
      );
    }
    wrapped = 'runtime.wrapAlways($expr)';
  }

  if (type.nullabilitySuffix == NullabilitySuffix.question) {
    if (forCollection) {
      return 'if ($expr == null) const \$null() else $wrapped';
    }
    return '$expr == null ? const \$null() : $wrapped';
  }

  return wrapped;
}

String? wrapType(
  BindgenContext ctx,
  DartType type,
  String expr, {
  bool wrapList = false,
  List<ElementAnnotation>? metadata,
  List<String>? unionTypeNames,
}) {
  final union = metadata?.firstWhereOrNull(
    (e) => e.element?.displayName == 'UnionOf',
  );
  String unionStr = '';
  if (union != null) {
    final types = union
        .computeConstantValue()
        ?.getField('types')
        ?.toListValue();
    if (types != null && types.isNotEmpty) {
      for (final type in types) {
        final type0 = type.toTypeValue();
        if (type0 == null) {
          continue;
        }
        ctx.imports.add(type0.element!.library!.uri.toString());
        final wrapper = wrapVar(ctx, type0, expr);

        unionStr += '$expr is ${type0.element!.name} ? $wrapper : ';
      }
    }
  }
  if (unionTypeNames != null) {
    for (final typeName in unionTypeNames) {
      final element = _resolveTypeElement(ctx, typeName);
      if (element == null) {
        print('Warning: could not resolve union type $typeName');
        continue;
      }
      ctx.imports.add(element.library!.uri.toString());
      final dartType = _dartTypeFromName(ctx, typeName);
      if (dartType == null) continue;
      final wrapper = wrapVar(ctx, dartType, expr);
      unionStr += '$expr is ${element.name} ? $wrapper : ';
    }
  }
  if (type is VoidType) {
    return '${unionStr}null';
  }

  if (type.isDartCoreNull) {
    return '${unionStr}const \$null()';
  }

  if (type is DynamicType) {
    // `recursive: true` preserves collection type witnesses (e.g. the
    // `Map<String, dynamic>` runtime type produced by `json.decode`), which
    // downstream `AssertType` conversions rely on.
    return '${unionStr}runtime.wrapAlways($expr, recursive: true)';
  }

  // Erased type parameters of the generic wrapper — dispatch on runtime type.
  if (type is TypeParameterType) {
    return '${unionStr}runtime.wrapAlways($expr, recursive: true)';
  }

  if (type is FunctionType) {
    return unionStr + wrapFunctionType(ctx, type, expr);
  }

  if (type.isDartCoreFunction) {
    return '$unionStr\$Function((runtime, target, args) => $expr())';
  }

  // A Never-typed expression never produces a value.
  if (type.element?.name == 'Never' && type.element?.library == null) {
    return '${unionStr}const \$null()';
  }

  // FutureOr<T>: unwrap Futures into $Future, plain values as T.
  if (type.isDartAsyncFutureOr && type is ParameterizedType) {
    ctx.imports.add('dart:async');
    final arg = type.typeArguments.first;
    if (arg is VoidType) {
      return '$unionStr($expr is Future ? \$Future.wrap($expr) '
          ': const \$null())';
    }
    return '$unionStr($expr is Future ? \$Future.wrap(($expr as Future)'
        '.then((e) => ${wrapVar(ctx, arg, 'e')})) : '
        '${wrapVar(ctx, arg, expr)})';
  }

  final element =
      type.element ??
      (throw BindingGenerationError('Type $type has no element'));
  final lib = element.library!;
  final name = element.name ?? ' ';

  // A class included in the sidecar config for the library currently being
  // bound gets a generated wrapper — prefer it over the stdlib fallback.
  final configuredClass = ctx.configMode &&
          element.library?.uri.toString() == ctx.uri
      ? ctx.libraryConfig?.classes[element.name]
      : null;
  if (configuredClass != null &&
      configuredClass.include &&
      !configuredClass.handMaintained) {
    final targetFile = configuredClass.file ?? '${element.name}.dart';
    if (ctx.outputFile != null && targetFile != ctx.outputFile) {
      ctx.imports.add(targetFile);
    }
    final wName = configuredClass.wrapperName ?? name;
    if (configuredClass.unnamedValueConstructor) {
      return '$unionStr\$$wName($expr)';
    }
    return '$unionStr\$$wName.wrap($expr)';
  }

  final defaultCstr = {'int', 'num', 'double', 'bool', 'String', 'Object'};

  if (lib.isInSdk) {
    var boundName = name;
    String? wrapperName;
    var unnamedValueConstructor = false;
    if (ctx.configMode) {
      // Only emit `$X.wrap` for wrappers known to exist (generated `include`
      // classes or `handMaintained` ones). SDK-private types such as
      // `_StringStackTrace` resolve to their nearest bound public supertype.
      final bound = _boundSdkClass(ctx, element);
      if (bound == null) {
        return null;
      }
      boundName = bound.$1.name!;
      wrapperName = bound.$2.wrapperName;
      unnamedValueConstructor = bound.$2.unnamedValueConstructor;
      final boundUri = bound.$1.library.uri.toString();
      if (boundUri == ctx.uri && bound.$2.include && !bound.$2.handMaintained) {
        // Generated in this run: import the sibling file directly.
        final targetFile = bound.$2.file ?? '$boundName.dart';
        if (ctx.outputFile != targetFile) {
          ctx.imports.add(targetFile);
        }
      } else if (bound.$2.handMaintained && bound.$2.file != null) {
        // `file` on a handMaintained class gives the import exposing its
        // wrapper (e.g. a wrapper living under a different stdlib directory).
        // For generated classes, `file` is an output filename — not a valid
        // cross-directory import — so use the umbrella instead.
        ctx.imports.add(bound.$2.file!);
      } else {
        ctx.imports.add(
          'package:dart_eval/stdlib/${boundUri.substring(5)}.dart',
        );
      }
    } else {
      final which = lib.uri.toString().substring(5);
      ctx.imports.add('package:dart_eval/stdlib/$which.dart');
    }
    if (defaultCstr.contains(boundName)) {
      return '$unionStr\$$boundName($expr)';
    }
    if (boundName == 'List') {
      if (wrapList) {
        return '$unionStr\$List.wrap($expr)';
      }
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '$unionStr\$List.view($expr, (e) => ${wrapVar(ctx, arg, 'e')})';
    }
    if (boundName == 'Iterable' && type is ParameterizedType) {
      final arg = type.typeArguments.first;
      return '$unionStr\$Iterable.wrap('
          '($expr).map((e) => ${wrapVar(ctx, arg, 'e')}))';
    }
    if (boundName == 'Set' && type is ParameterizedType) {
      final arg = type.typeArguments.first;
      return '$unionStr\$Set.wrap('
          '($expr).map((e) => ${wrapVar(ctx, arg, 'e')}).toSet())';
    }
    if (boundName == 'Map' && type is ParameterizedType) {
      ctx.imports.add('package:dart_eval/src/eval/utils/wrap_helper.dart');
      final key = type.typeArguments[0];
      final value = type.typeArguments[1];
      return '${unionStr}wrapMap($expr, (key, value) => MapEntry('
          '${wrapVar(ctx, key, 'key')}, ${wrapVar(ctx, value, 'value')}))';
    }
    if (boundName == 'Stream') {
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '$unionStr\$Stream.wrap($expr.map((e) => ${wrapVar(ctx, arg, 'e')}))';
    }
    if (boundName == 'Future') {
      final generic = type as ParameterizedType;
      final arg = generic.typeArguments.first;
      return '$unionStr\$Future.wrap($expr.then((e) => ${wrapVar(ctx, arg, 'e')}))';
    }
    final wName = wrapperName ?? boundName;
    if (unnamedValueConstructor) {
      return '$unionStr\$$wName($expr)';
    }
    return '$unionStr\$$wName.wrap($expr)';
  }

  final typeEl = type.element!;
  if (typeEl is InterfaceElement) {
    final uri = typeEl.library.uri.toString();
    final hasAnno = typeEl.metadata.annotations.any(
      (e) => e.element?.displayName == 'Bind',
    );
    if (hasAnno) {
      ctx.imports.add(uri.replaceAll('.dart', '.eval.dart'));
      return '$unionStr\$$name.wrap($expr)';
    } else if (ctx.bridgeDeclarations.containsKey(uri)) {
      final parsedUri = Uri.parse(uri);

      String current = parsedUri.path;
      String? mappedUri;
      // walk up the path until we find a match in ctx.exportedLibMappings
      while (current != path.dirname(current)) {
        if (ctx.exportedLibMappings.containsKey(
          '${parsedUri.scheme}:$current',
        )) {
          mappedUri = ctx.exportedLibMappings['${parsedUri.scheme}:$current']!;
          break;
        }
        current = path.dirname(current);
      }

      if (mappedUri != null) {
        ctx.imports.add(mappedUri);
        return '$unionStr\$$name.wrap($expr)';
      }
    }
  }

  if (type is TypeParameterType) {
    final bound = type.bound;
    if (bound is! DynamicType) {
      final b = wrapVar(ctx, bound, expr);
      if (b != null) {
        return '$unionStr\$$b';
      }
    }
  }

  return null;
}

/// Emit a `BridgeTypeAnnotation` for a YAML type name such as `int`,
/// `List<int>` or `String?`.
///
/// Names are resolved against the bound library's export namespace, falling
/// back to dart:core. Names matching an in-scope type parameter emit
/// `BridgeTypeRef.ref`.
String bridgeTypeAnnotationFromName(BindgenContext ctx, String typeName) {
  final parsed = _TypeName.parse(typeName);
  return 'BridgeTypeAnnotation(${_bridgeTypeRefFromName(ctx, parsed)}'
      '${parsed.nullable ? ', nullable: true' : ''})';
}

/// Emit a `BridgeTypeRef` for a YAML type name (no nullability).
String bridgeTypeRefFromName(BindgenContext ctx, String typeName) =>
    _bridgeTypeRefFromName(ctx, _TypeName.parse(typeName));

String _bridgeTypeRefFromName(BindgenContext ctx, _TypeName name) {
  if (ctx.typeParamNames.contains(name.name)) {
    return 'BridgeTypeRef.ref(\'${name.name}\')';
  }
  if (name.name == 'void') return 'BridgeTypeRef(CoreTypes.voidType)';
  if (name.name == 'dynamic') return 'BridgeTypeRef(CoreTypes.dynamic)';
  if (name.name == 'Null') return 'BridgeTypeRef(CoreTypes.nullType)';
  if (name.name == 'Never') return 'BridgeTypeRef(CoreTypes.never)';
  if (name.name == 'Function') return 'BridgeTypeRef(CoreTypes.function)';
  if (name.name == 'Record') return 'BridgeTypeRef(CoreTypes.record)';
  if (name.name == 'Enum') return 'BridgeTypeRef(CoreTypes.enumType)';

  final element = _resolveTypeElement(ctx, name.name);
  if (element == null) {
    print('Warning: could not resolve type name ${name.name}; '
        'falling back to dynamic');
    return 'BridgeTypeRef(CoreTypes.dynamic)';
  }
  final libUri = element.library!.uri.toString();
  final spec = builtinSpecFromName(ctx, libUri, element.name ?? name.name) ??
      'BridgeTypeSpec(\'$libUri\', '
          '\'${(element.name ?? name.name).replaceAll(r'$', r'\$')}\')';
  if (name.args.isEmpty) {
    return 'BridgeTypeRef($spec)';
  }
  final args = name.args
      .map((e) => _bridgeTypeAnnotationFromParsed(ctx, e))
      .join(', ');
  return 'BridgeTypeRef($spec, [$args])';
}

String _bridgeTypeAnnotationFromParsed(BindgenContext ctx, _TypeName parsed) =>
    'BridgeTypeAnnotation(${_bridgeTypeRefFromName(ctx, parsed)}'
    '${parsed.nullable ? ', nullable: true' : ''})';

/// Public accessor for [_boundSdkClass] — used by the declaration emitter to
/// decide whether a supertype is expressible in the bound-type namespace.
(InterfaceElement, BindgenClassConfig)? boundSdkClassFor(
  BindgenContext ctx,
  Element element,
) => _boundSdkClass(ctx, element);

/// Find the nearest bound public class for [element] by walking up the
/// supertype chain. Returns `(element, classConfig)` or null when neither the
/// type nor any supertype is configured as bound (`include` or
/// `handMaintained`).
(InterfaceElement, BindgenClassConfig)? _boundSdkClass(
  BindgenContext ctx,
  Element element,
) {
  var e = element is InterfaceElement ? element : null;
  while (e != null) {
    final name = e.name;
    if (name != null && !name.startsWith('_')) {
      final uri = e.library.uri.toString();
      final cc = ctx.config?.libraries
          .firstWhereOrNull((l) => l.uri == uri)
          ?.classes[name];
      if (cc != null && (cc.include || cc.handMaintained)) {
        return (e, cc);
      }
    }
    e = e.supertype?.element;
  }
  return null;
}

Element? _resolveTypeElement(BindgenContext ctx, String name) {
  final lib = ctx.libraryElement;
  Element? element = lib?.exportNamespace.get2(name);
  if (element == null && lib != null) {
    for (final fragment in lib.fragments) {
      for (final import in fragment.libraryImports) {
        element ??= import.importedLibrary?.exportNamespace.get2(name);
      }
      if (element != null) break;
    }
  }
  element ??= ctx.dartCoreLibrary?.exportNamespace.get2(name);
  return element;
}

/// Resolve a YAML type name to a [DartType] (generic args become `dynamic`).
DartType? _dartTypeFromName(BindgenContext ctx, String typeName) {
  final parsed = _TypeName.parse(typeName);
  final element = _resolveTypeElement(ctx, parsed.name);
  if (element is InterfaceElement) {
    final dynamicType = element.library.typeProvider.dynamicType;
    return element.instantiate(
      typeArguments: List.filled(element.typeParameters.length, dynamicType),
      nullabilitySuffix: parsed.nullable
          ? NullabilitySuffix.question
          : NullabilitySuffix.none,
    );
  }
  return null;
}

/// Name-based equivalent of [builtinTypeFrom] for YAML-declared types.
/// Returns null for non-SDK libraries. `void`/`Null`/`Enum`/`Function`/
/// `Record`/`dynamic`/`Never` are handled by the caller since their `*Types`
/// constant names diverge from the camel-case convention.
String? builtinSpecFromName(BindgenContext ctx, String libUri, String name) =>
    _registrySpec(ctx, libUri, name);

/// Emit the `*Types` registry class source for [lib], containing a
/// `static const` spec per configured class resolving to this library's URI
/// (including `handMaintained`/`include: false` entries and `overrideLibrary`
/// redirections) plus `registry.extra` entries. Returns null when the library
/// has no `registry:` config.
String? emitRegistrySource(BindgenConfig config, BindgenLibraryConfig lib) {
  final registry = lib.registry;
  if (registry == null) return null;
  final entries = <String, String>{};
  for (final l in config.libraries) {
    for (final cls in l.classes.values) {
      final specUri = cls.libOverride ?? l.uri;
      if (specUri != lib.uri) continue;
      entries[registryFieldName(cls.name)] = cls.name;
    }
  }
  entries.addAll(registry.extra);
  final buf = StringBuffer()
    ..writeln('/// Bridge type specs for `${lib.uri}`.')
    ..writeln('class ${registryClassName(lib)} {');
  for (final field in entries.keys.toList()..sort()) {
    buf
      ..writeln('  /// Bridge spec for [${entries[field]}].')
      ..writeln(
        "  static const $field = "
        "BridgeTypeSpec('${lib.uri}', '${entries[field]}');",
      );
  }
  buf.writeln('}');
  return buf.toString();
}

/// Parsed YAML type name: `List<int>?` → name `List`, args `[int]`,
/// nullable.
class _TypeName {
  _TypeName(this.name, this.args, this.nullable);

  final String name;
  final List<_TypeName> args;
  final bool nullable;

  static _TypeName parse(String source) {
    var s = source.trim();
    var nullable = false;
    if (s.endsWith('?')) {
      nullable = true;
      s = s.substring(0, s.length - 1).trim();
    }
    final lt = s.indexOf('<');
    if (lt == -1) {
      return _TypeName(s, const [], nullable);
    }
    if (!s.endsWith('>')) {
      throw FormatException('Malformed type name: $source');
    }
    final base = s.substring(0, lt).trim();
    final inner = s.substring(lt + 1, s.length - 1);
    final args = <_TypeName>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < inner.length; i++) {
      final c = inner[i];
      if (c == '<') {
        depth++;
      } else if (c == '>') {
        depth--;
      } else if (c == ',' && depth == 0) {
        args.add(_TypeName.parse(inner.substring(start, i)));
        start = i + 1;
      }
    }
    final last = inner.substring(start).trim();
    if (last.isNotEmpty) {
      args.add(_TypeName.parse(last));
    }
    return _TypeName(base, args, nullable);
  }
}

String wrapFunctionType(BindgenContext ctx, FunctionType type, String expr) {
  var buffer = StringBuffer('\$Function((runtime, target, args) { ');
  if (type.returnType is! VoidType && !type.returnType.isDartCoreNull) {
    buffer.write('final funcResult = ');
  }
  buffer.write('$expr(');
  var i = 0;
  for (; i < type.normalParameterTypes.length; i++) {
    buffer.write('args[$i]');
    final type0 = type.normalParameterTypes[i];
    if (type0.nullabilitySuffix == NullabilitySuffix.question) {
      buffer.write('?.\$value');
    } else {
      buffer.write('!.\$value');
    }
    if (i < type.normalParameterTypes.length - 1) {
      buffer.write(', ');
    }
  }

  if (type.optionalParameterTypes.isNotEmpty) {
    for (var j = i; j < type.optionalParameterTypes.length + i; j++) {
      if (type.normalParameterTypes.isNotEmpty) {
        buffer.write(', ');
      }
      final type0 = type.optionalParameterTypes[i];
      buffer.write('args[$j]');
      if (type0.nullabilitySuffix == NullabilitySuffix.question) {
        buffer.write('?.\$value');
      } else {
        buffer.write('!.\$value');
      }
      if (j < type.optionalParameterTypes.length + i - 1) {
        buffer.write(', ');
      }
    }
  }

  if (type.namedParameterTypes.isNotEmpty) {
    if (type.normalParameterTypes.isNotEmpty ||
        type.optionalParameterTypes.isNotEmpty) {
      buffer.write(', ');
    }

    var k = i;
    type.namedParameterTypes.forEach((npName, npType) {
      buffer.write(npName);
      buffer.write(': args[$k]');
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        buffer.write('?.\$value');
      } else {
        buffer.write('!.\$value');
      }
      if (k < type.namedParameterTypes.length + i - 1) {
        buffer.write(', ');
      }
    });
  }
  buffer.write(
    '); return ${wrapVar(ctx, type.returnType, 'funcResult', func: true)}; })',
  );
  return buffer.toString();
}
