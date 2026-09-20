import 'package:yaml/yaml.dart';

/// Root model for a `bindgen.yaml` sidecar configuration file consumed by
/// `dart_eval bind --config <yaml>`.
class BindgenConfig {
  const BindgenConfig({required this.defaults, required this.libraries});

  final BindgenDefaults defaults;
  final List<BindgenLibraryConfig> libraries;

  factory BindgenConfig.parse(String source) {
    final doc = loadYaml(source);
    if (doc is! YamlMap) {
      throw const FormatException(
        'bindgen config must be a YAML map',
      );
    }
    final version = doc['version'];
    if (version != null && version != 1) {
      throw FormatException(
        'Unsupported bindgen config version: $version (expected 1)',
      );
    }
    return BindgenConfig.fromYaml(doc);
  }

  factory BindgenConfig.fromYaml(YamlMap yaml) {
    final defaultsYaml = yaml['defaults'];
    final librariesYaml = yaml['libraries'];
    return BindgenConfig(
      defaults: defaultsYaml is YamlMap
          ? BindgenDefaults.fromYaml(defaultsYaml)
          : const BindgenDefaults(),
      libraries: [
        if (librariesYaml is YamlList)
          for (final entry in librariesYaml)
            if (entry is YamlMap) BindgenLibraryConfig.fromYaml(entry),
      ],
    );
  }

  /// Apply the root [defaults] to every library so each library carries its
  /// fully-resolved default options.
  void resolveDefaults() {
    for (final library in libraries) {
      library.inheritDefaults(defaults);
    }
  }
}

/// Options that apply to every bound library/class unless overridden.
class BindgenDefaults {
  const BindgenDefaults({
    this.mode = 'wrap',
    this.implicitSupers = false,
    this.includeObjectMembers = false,
    this.excludeMembers = const [],
  });

  /// `wrap` | `bridge` | `both` (equivalent to @Bind `wrap`/`bridge`).
  final String mode;

  /// Equivalent to @Bind `implicitSupers`.
  final bool implicitSupers;

  /// When true, `==`, `toString`, `noSuchMethod`, `hashCode` and `runtimeType`
  /// are generated like ordinary members.
  final bool includeObjectMembers;

  /// Member names excluded everywhere.
  final List<String> excludeMembers;

  factory BindgenDefaults.fromYaml(YamlMap yaml) => BindgenDefaults(
        mode: _str(yaml['mode']) ?? 'wrap',
        implicitSupers: _bool(yaml['implicitSupers']) ?? false,
        includeObjectMembers: _bool(yaml['includeObjectMembers']) ?? false,
        excludeMembers: _strList(yaml['excludeMembers']),
      );

  BindgenDefaults merge(BindgenDefaults? overrides) => BindgenDefaults(
        mode: overrides?.mode ?? mode,
        implicitSupers: overrides?.implicitSupers ?? implicitSupers,
        includeObjectMembers:
            overrides?.includeObjectMembers ?? includeObjectMembers,
        excludeMembers: [
          ...excludeMembers,
          ...overrides?.excludeMembers ?? const [],
        ],
      );
}

/// A single `libraries:` entry.
class BindgenLibraryConfig {
  BindgenLibraryConfig({
    required this.uri,
    this.outDir,
    this.imports = const [],
    this.plugin,
    this.classes = const {},
    this.functions = const {},
    this.functionsFile,
    this.hooks,
    this.registry,
    BindgenDefaults? overrides,
  }) : _overrides = overrides;

  final BindgenDefaults? _overrides;

  /// Top-level function configs keyed by function name.
  final Map<String, BindgenMemberConfig> functions;

  /// Output file for generated top-level function wrappers
  /// (default `functions.dart`).
  final String? functionsFile;

  /// Hooks file used by library-level `functions:` entries.
  final String? hooks;

  /// `dart:*`, `package:*`, or a relative file path.
  final String uri;

  /// Output directory for generated wrapper files.
  final String? outDir;

  /// Extra import lines for every generated file.
  final List<String> imports;

  /// Plugin generation options.
  final BindgenPluginConfig? plugin;

  /// `*Types` spec-registry emission options (`registry:` block).
  final BindgenRegistryConfig? registry;

  /// Class allowlist: only classes listed here (with `include != false`) are
  /// processed in config mode.
  final Map<String, BindgenClassConfig> classes;

  /// Fully-resolved defaults (root defaults merged with library overrides).
  BindgenDefaults defaults = const BindgenDefaults();

  factory BindgenLibraryConfig.fromYaml(YamlMap yaml) {
    final classesYaml = yaml['classes'];
    final classes = <String, BindgenClassConfig>{};
    if (classesYaml is YamlMap) {
      for (final entry in classesYaml.entries) {
        // A bare `Null:` key parses as YAML null; it can only mean dart:core's
        // Null type here.
        final name = entry.key?.toString() ?? 'Null';
        final value = entry.value;
        classes[name] = value is YamlMap
            ? BindgenClassConfig.fromYaml(name, value)
            : BindgenClassConfig(name: name);
      }
    } else if (classesYaml is YamlList) {
      for (final entry in classesYaml) {
        final name = entry?.toString() ?? 'Null';
        classes[name] = BindgenClassConfig(name: name);
      }
    }

    final defaultsYaml = yaml['defaults'];
    final pluginYaml = yaml['plugin'];
    final registryYaml = yaml['registry'];
    return BindgenLibraryConfig(
      uri: _str(yaml['uri']) ??
          (throw const FormatException('library entry requires `uri`')),
      outDir: _str(yaml['outDir']),
      imports: _strList(yaml['imports']),
      plugin:
          pluginYaml is YamlMap ? BindgenPluginConfig.fromYaml(pluginYaml) : null,
      registry: registryYaml is YamlMap
          ? BindgenRegistryConfig.fromYaml(registryYaml)
          : null,
      classes: classes,
      functions: _memberMap(yaml['functions']),
      functionsFile: _str(yaml['functionsFile']),
      hooks: _str(yaml['hooks']),
      overrides:
          defaultsYaml is YamlMap ? BindgenDefaults.fromYaml(defaultsYaml) : null,
    );
  }

  void inheritDefaults(BindgenDefaults root) {
    defaults = root.merge(_overrides);
  }
}

/// Plugin file generation options for a library (`plugin:` block).
class BindgenPluginConfig {
  const BindgenPluginConfig({
    required this.out,
    required this.className,
    required this.identifier,
    this.evalSources = const [],
    this.extraDeclarations = const [],
    this.extraSources = const [],
    this.imports = const [],
  });

  /// Output path for the plugin file (relative to the library `outDir`).
  final String out;

  /// Plugin class name.
  final String className;

  /// `EvalPlugin.identifier` value.
  final String identifier;

  /// Eval-side `DartSource` entries.
  final List<BindgenSourceRef> evalSources;

  /// Extra declarations registered in `configureForCompile`
  /// (expressions evaluating to a `BridgeDeclaration`, e.g. `$dynamicCls`).
  final List<String> extraDeclarations;

  /// Additional `addSource`/`configure*` expressions added verbatim to
  /// `configureForCompile`/`configureForRuntime`.
  final List<BindgenSourceRef> extraSources;

  /// Imports needed by the plugin file.
  final List<String> imports;

  factory BindgenPluginConfig.fromYaml(YamlMap yaml) => BindgenPluginConfig(
        out: _str(yaml['out']) ??
            (throw const FormatException('plugin requires `out`')),
        className: _str(yaml['class']) ??
            (throw const FormatException('plugin requires `class`')),
        identifier: _str(yaml['identifier']) ?? '',
        evalSources: _sourceList(yaml['evalSources']),
        extraDeclarations: _strList(yaml['extraDeclarations']),
        extraSources: _sourceList(yaml['extraSources']),
        imports: _strList(yaml['imports']),
      );
}

/// Emission options for a `*Types` spec-registry class (`registry:` block on a
/// library). The generator emits a `static const` [BridgeTypeSpec] field for
/// every class configured for the library's URI (including `handMaintained`
/// and `include: false` entries) plus any `extra` entries.
class BindgenRegistryConfig {
  const BindgenRegistryConfig({
    required this.file,
    this.className,
    this.extra = const {},
  });

  /// Output path for the registry file (project-relative). Multiple
  /// libraries may share a file; their registry classes are emitted together.
  final String file;

  /// Registry class name (default: `<Which>Types` derived from the URI, e.g.
  /// `dart:typed_data` → `TypedDataTypes`).
  final String? className;

  /// Additional registry entries (`fieldName: TypeName`) for non-class spec
  /// names such as `void`/`dynamic`/`Never`.
  final Map<String, String> extra;

  factory BindgenRegistryConfig.fromYaml(YamlMap yaml) => BindgenRegistryConfig(
        file: _str(yaml['file']) ??
            (throw const FormatException('registry requires `file`')),
        className: _str(yaml['class']),
        extra: _strMap(yaml['extra']),
      );
}

/// A reference used by `evalSources`/`extraSources`: either embed a file's
/// text under a `uri`, or reference an existing expression with an import.
class BindgenSourceRef {
  const BindgenSourceRef({
    this.uri,
    this.file,
    this.import,
    this.expression,
    this.target = 'compile',
  });

  /// `DartSource` uri (for `file`-style entries).
  final String? uri;

  /// Path to a file whose text is embedded (for `uri`-style entries).
  final String? file;

  /// Import line for `expression`-style entries.
  final String? import;

  /// Expression evaluating to the `DartSource` (for `import`-style entries),
  /// or a verbatim statement for `extraSources` entries.
  final String? expression;

  /// Where `extraSources` expressions are emitted: `compile` (default),
  /// `runtime`, or `both`.
  final String target;

  factory BindgenSourceRef.fromYaml(YamlMap yaml) => BindgenSourceRef(
        uri: _str(yaml['uri']),
        file: _str(yaml['file']),
        import: _str(yaml['import']),
        expression: _str(yaml['expression']),
        target: _str(yaml['target']) ?? 'compile',
      );
}

/// Per-class configuration (`classes: <name>:` block).
class BindgenClassConfig {
  const BindgenClassConfig({
    required this.name,
    this.include = true,
    this.handMaintained = false,
    this.file,
    this.mode,
    this.isAbstract,
    this.extendsName,
    this.implementsNames = const [],
    this.generics = const {},
    this.wrapperName,
    this.unnamedValueConstructor = false,
    this.implementsSdk = false,
    this.superclass,
    this.reified,
    this.runtimeTypeOverride,
    this.equality,
    this.excludeMembers = const [],
    this.hooks,
    this.constructors = const {},
    this.statics = const {},
    this.methods = const {},
    this.getters = const {},
    this.setters = const {},
    this.fields = const {},
    this.synthetic = const [],
    this.implicitSupers,
    this.libOverride,
    this.imports = const [],
  });

  final String name;
  final bool include;

  /// When true, no wrapper is generated but the class still contributes a
  /// `*Types` spec entry and `$X.wrap` is assumed to exist (e.g. a
  /// hand-maintained stdlib wrapper such as `$List` or `$String`).
  final bool handMaintained;

  /// Group classes into output files (default `<class>.dart` snake-case).
  final String? file;

  /// `wrap` | `bridge` | `both`.
  final String? mode;
  final bool? isAbstract;

  /// Overrides for `BridgeClassType.$extends` / `$implements`.
  final String? extendsName;
  final List<String> implementsNames;

  /// Generic bound overrides: `{T: num}` or `{T: null}` (unbounded).
  final Map<String, String?> generics;
  final String? wrapperName;

  /// When true, also emit `$X(this.$value)` in addition to `.wrap`.
  final bool unnamedValueConstructor;

  /// When true, the generated wrapper is bimodal: `class $X implements X,
  /// $Instance`, and forwarding members are emitted for every non-Object SDK
  /// interface member so the interface is satisfied. Use for types whose
  /// wrapped instances must satisfy host `is` checks (e.g. errors/exceptions
  /// that are thrown and caught by host code).
  final bool implementsSdk;

  /// `_superclass` initializer override.
  final BindgenSuperclassConfig? superclass;

  /// `$reified` override (`'$value'` or `{expr: ...}`/`{hook: name}`).
  final BindgenExprRef? reified;

  /// `$getRuntimeType`/`$spec` override expression (e.g. `CoreTypes.string`).
  final String? runtimeTypeOverride;

  /// Emit/override `==`, `hashCode`, `toString` implementations.
  final BindgenEqualityConfig? equality;

  /// Per-class member exclusions.
  final List<String> excludeMembers;

  /// Default hooks file for this class.
  final String? hooks;

  final Map<String, BindgenMemberConfig> constructors;
  final Map<String, BindgenMemberConfig> statics;
  final Map<String, BindgenMemberConfig> methods;
  final Map<String, BindgenMemberConfig> getters;
  final Map<String, BindgenMemberConfig> setters;
  final Map<String, BindgenMemberConfig> fields;

  /// Members absent from the SDK element.
  final List<BindgenSyntheticMember> synthetic;

  final bool? implicitSupers;

  /// Overrides the library URI recorded in generated `$spec`s.
  final String? libOverride;

  /// Extra imports for this class's output file (e.g. for SDK constants
  /// referenced by default-value code).
  final List<String> imports;

  /// Look up member config by kind + name. [kind] is one of `method`,
  /// `getter`, `setter`, `field`, `constructor`, `static`.
  BindgenMemberConfig? memberConfig(String kind, String name) =>
      switch (kind) {
        'method' => methods[name],
        'getter' => getters[name],
        'setter' => setters[name],
        'field' => fields[name],
        'constructor' => constructors[name] ?? statics[name],
        'static' => statics[name],
        _ => null,
      };

  factory BindgenClassConfig.fromYaml(String name, YamlMap yaml) =>
      BindgenClassConfig(
        name: name,
        include: _bool(yaml['include']) ?? true,
        handMaintained: _bool(yaml['handMaintained']) ?? false,
        file: _str(yaml['file']),
        mode: _str(yaml['mode']),
        isAbstract: _bool(yaml['abstract']),
        extendsName: _str(yaml['extends']),
        implementsNames: _strList(yaml['implements']),
        generics: _nullableStrMap(yaml['generics']),
        wrapperName: _str(yaml['wrapperName']),
        unnamedValueConstructor:
            _bool(yaml['unnamedValueConstructor']) ?? false,
        implementsSdk: _bool(yaml['implementsSdk']) ?? false,
        superclass: yaml['superclass'] is YamlMap
            ? BindgenSuperclassConfig.fromYaml(yaml['superclass'] as YamlMap)
            : null,
        reified: BindgenExprRef.fromYamlValue(yaml['reified']),
        runtimeTypeOverride: _str(yaml['runtimeType']),
        equality: yaml['equality'] is YamlMap
            ? BindgenEqualityConfig.fromYaml(yaml['equality'] as YamlMap)
            : null,
        excludeMembers: _strList(yaml['excludeMembers']),
        hooks: _str(yaml['hooks']),
        constructors: _memberMap(yaml['constructors']),
        statics: _memberMap(yaml['statics']),
        methods: _memberMap(yaml['methods']),
        getters: _memberMap(yaml['getters']),
        setters: _memberMap(yaml['setters']),
        fields: _memberMap(yaml['fields']),
        synthetic: [
          if (yaml['synthetic'] is YamlList)
            for (final entry in yaml['synthetic'] as YamlList)
              if (entry is YamlMap) BindgenSyntheticMember.fromYaml(entry),
        ],
        implicitSupers: _bool(yaml['implicitSupers']),
        libOverride: _str(yaml['overrideLibrary']),
        imports: _strList(yaml['imports']),
      );
}

/// An expression body or hook reference: `'<expr>'` or `{expr|hook|type}`.
class BindgenExprRef {
  const BindgenExprRef({this.expr, this.hook, this.type});

  final String? expr;
  final String? hook;

  /// Type override (e.g. `$reified` return type).
  final String? type;

  static BindgenExprRef? fromYamlValue(Object? value) {
    if (value is String) return BindgenExprRef(expr: value);
    if (value is YamlMap) {
      return BindgenExprRef(
        expr: _str(value['expr']),
        hook: _str(value['hook']),
        type: _str(value['type']),
      );
    }
    return null;
  }
}

/// `_superclass` initializer override: `{expr, import}`.
class BindgenSuperclassConfig {
  const BindgenSuperclassConfig({this.expr, this.import});

  final String? expr;
  final String? import;

  factory BindgenSuperclassConfig.fromYaml(YamlMap yaml) =>
      BindgenSuperclassConfig(
        expr: _str(yaml['expr']),
        import: _str(yaml['import']),
      );
}

/// Equality/toString emission overrides.
class BindgenEqualityConfig {
  const BindgenEqualityConfig({
    this.emitEquals,
    this.emitHashCode,
    this.emitToString,
  });

  /// `true` emits `operator ==` delegating to `$value`.
  final bool? emitEquals;

  /// `true` emits `hashCode` delegating to `$value`.
  final bool? emitHashCode;

  /// `dartString` delegates to `$value.toString()`; any other string is used
  /// verbatim as the method body expression.
  final String? emitToString;

  factory BindgenEqualityConfig.fromYaml(YamlMap yaml) => BindgenEqualityConfig(
        emitEquals: _bool(yaml['equals']),
        emitHashCode: _bool(yaml['hashCode']),
        emitToString: _str(yaml['toString']),
      );
}

/// Per-member configuration (methods/getters/setters/fields/constructors/
/// statics blocks).
class BindgenMemberConfig {
  const BindgenMemberConfig({
    this.include = true,
    this.rename,
    this.returns,
    this.params = const {},
    this.hook,
    this.permissions = const [],
    this.expr,
    this.isStatic,
    this.type,
  });

  final bool include;

  /// Rename the bound member (emitted name differs from the SDK member name).
  final String? rename;

  /// Return type override.
  final BindgenReturnsConfig? returns;

  /// Parameter overrides keyed by parameter name.
  final Map<String, BindgenParamConfig> params;

  /// Name of a top-level hook function in the class's `hooks:` file that the
  /// generated member delegates to.
  final String? hook;

  /// Permission assertions emitted at the top of the generated body.
  final List<BindgenPermissionConfig> permissions;

  /// Inline expression used as the member body (getters and synthetic members).
  final String? expr;

  /// `isStatic` override for fields.
  final bool? isStatic;

  /// Type override for fields/getters.
  final String? type;

  factory BindgenMemberConfig.fromYaml(YamlMap yaml) => BindgenMemberConfig(
        include: _bool(yaml['include']) ?? true,
        rename: _str(yaml['rename']),
        returns: yaml['returns'] != null
            ? BindgenReturnsConfig.fromYamlValue(yaml['returns'])
            : null,
        params: _paramMap(yaml['params']),
        hook: _str(yaml['hook']),
        permissions: [
          if (yaml['permissions'] is YamlList)
            for (final entry in yaml['permissions'] as YamlList)
              if (entry is YamlMap) BindgenPermissionConfig.fromYaml(entry),
        ],
        expr: _str(yaml['expr']),
        isStatic: _bool(yaml['isStatic']),
        type: _str(yaml['type']),
      );
}

/// `returns:` override: a plain type, a parameter-dependent type, or a union.
class BindgenReturnsConfig {
  const BindgenReturnsConfig({this.type, this.dependsOn, this.union});

  /// Simple type name, e.g. `int`, `String?`, `List<int>`.
  final String? type;

  /// Parameter-type-dependent return.
  final BindgenDependsOnConfig? dependsOn;

  /// `@UnionOf`-equivalent wrap chain.
  final List<String>? union;

  factory BindgenReturnsConfig.fromYamlValue(Object? value) {
    if (value is String) {
      return BindgenReturnsConfig(type: value);
    }
    if (value is YamlMap) {
      final dependsOn = value['dependsOn'];
      return BindgenReturnsConfig(
        type: _str(value['type']),
        dependsOn: dependsOn is YamlMap
            ? BindgenDependsOnConfig.fromYaml(dependsOn)
            : null,
        union: _strList(value['union']).isEmpty
            ? null
            : _strList(value['union']),
      );
    }
    return const BindgenReturnsConfig();
  }
}

/// Parameter-type-dependent return type (`{dependsOn: ...}`).
class BindgenDependsOnConfig {
  const BindgenDependsOnConfig({
    this.param,
    this.index,
    this.cases = const {},
    this.fallback,
  });

  /// Named parameter to switch on.
  final String? param;

  /// Positional parameter index to switch on.
  final int? index;

  /// `{argumentType: returnType}` map.
  final Map<String, String> cases;

  /// Fallback return type (defaults to the member's `returns` type).
  final String? fallback;

  factory BindgenDependsOnConfig.fromYaml(YamlMap yaml) {
    final casesYaml = yaml['cases'];
    final cases = <String, String>{};
    if (casesYaml is YamlMap) {
      for (final entry in casesYaml.entries) {
        cases[entry.key.toString()] = entry.value.toString();
      }
    }
    return BindgenDependsOnConfig(
      param: _str(yaml['param']),
      index: yaml['index'] is int ? yaml['index'] as int : null,
      cases: cases,
      fallback: _str(yaml['fallback']),
    );
  }
}

/// `permissions:` entry — `runtime.assertPermission(...)` emitted at the top
/// of the generated body.
class BindgenPermissionConfig {
  const BindgenPermissionConfig({required this.name, this.constData, this.paramData});

  final String name;
  final String? constData;

  /// Parameter whose `$value` supplies the permission data.
  final String? paramData;

  factory BindgenPermissionConfig.fromYaml(YamlMap yaml) =>
      BindgenPermissionConfig(
        name: _str(yaml['name']) ?? '',
        constData: _str(yaml['constData']),
        paramData: _str(yaml['paramData']),
      );
}

/// Parameter override within a member config.
class BindgenParamConfig {
  const BindgenParamConfig({this.type, this.optional, this.defaultValue});

  final String? type;
  final bool? optional;
  final String? defaultValue;

  factory BindgenParamConfig.fromYaml(YamlMap yaml) => BindgenParamConfig(
        type: _str(yaml['type']),
        optional: _bool(yaml['optional']),
        defaultValue: _str(yaml['default']),
      );
}

/// A member absent from the SDK element, declared via `synthetic:`.
class BindgenSyntheticMember {
  const BindgenSyntheticMember({
    required this.kind,
    required this.name,
    this.params = const [],
    this.returns,
    this.hook,
    this.expr,
    this.isStatic = false,
  });

  /// `method` | `getter` | `setter` | `field` | `static` | `constructor`.
  final String kind;
  final String name;
  final List<BindgenSyntheticParam> params;
  final BindgenReturnsConfig? returns;
  final String? hook;
  final String? expr;
  final bool isStatic;

  factory BindgenSyntheticMember.fromYaml(YamlMap yaml) =>
      BindgenSyntheticMember(
        kind: _str(yaml['kind']) ?? 'method',
        name: _str(yaml['name']) ?? '',
        params: [
          if (yaml['params'] is YamlList)
            for (final entry in yaml['params'] as YamlList)
              if (entry is YamlMap) BindgenSyntheticParam.fromYaml(entry),
        ],
        returns: yaml['returns'] != null
            ? BindgenReturnsConfig.fromYamlValue(yaml['returns'])
            : null,
        hook: _str(yaml['hook']),
        expr: _str(yaml['expr']),
        isStatic: _bool(yaml['static']) ?? _bool(yaml['isStatic']) ?? false,
      );
}

/// Parameter declaration for a synthetic member.
class BindgenSyntheticParam {
  const BindgenSyntheticParam({
    required this.name,
    required this.type,
    this.optional = false,
    this.named = false,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool optional;
  final bool named;
  final String? defaultValue;

  factory BindgenSyntheticParam.fromYaml(YamlMap yaml) => BindgenSyntheticParam(
        name: _str(yaml['name']) ?? '',
        type: _str(yaml['type']) ?? 'dynamic',
        optional: _bool(yaml['optional']) ?? false,
        named: _bool(yaml['named']) ?? false,
        defaultValue: _str(yaml['default']),
      );
}

Map<String, BindgenMemberConfig> _memberMap(Object? value) {
  final result = <String, BindgenMemberConfig>{};
  if (value is YamlMap) {
    for (final entry in value.entries) {
      final name = entry.key.toString();
      final v = entry.value;
      result[name] = v is YamlMap
          ? BindgenMemberConfig.fromYaml(v)
          : const BindgenMemberConfig();
    }
  } else if (value is YamlList) {
    for (final entry in value) {
      result[entry.toString()] = const BindgenMemberConfig();
    }
  }
  return result;
}

Map<String, BindgenParamConfig> _paramMap(Object? value) {
  final result = <String, BindgenParamConfig>{};
  if (value is YamlMap) {
    for (final entry in value.entries) {
      final v = entry.value;
      result[entry.key.toString()] =
          v is YamlMap ? BindgenParamConfig.fromYaml(v) : const BindgenParamConfig();
    }
  } else if (value is YamlList) {
    for (final entry in value) {
      result[entry.toString()] = const BindgenParamConfig();
    }
  }
  return result;
}

List<BindgenSourceRef> _sourceList(Object? value) => [
      if (value is YamlList)
        for (final entry in value)
          if (entry is YamlMap) BindgenSourceRef.fromYaml(entry),
    ];

Map<String, String?> _nullableStrMap(Object? value) {
  final result = <String, String?>{};
  if (value is YamlMap) {
    for (final entry in value.entries) {
      result[entry.key.toString()] = entry.value?.toString();
    }
  }
  return result;
}

String? _str(Object? value) => value?.toString();

Map<String, String> _strMap(Object? value) {
  final result = <String, String>{};
  if (value is YamlMap) {
    for (final entry in value.entries) {
      result[entry.key.toString()] = entry.value.toString();
    }
  }
  return result;
}

bool? _bool(Object? value) => value is bool ? value : null;

List<String> _strList(Object? value) => [
      if (value is YamlList)
        for (final entry in value) entry.toString(),
    ];
