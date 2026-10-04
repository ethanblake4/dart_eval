/// Harness for running the real dart-lang/sdk `tests/language` suite under
/// dart_eval.
///
/// The SDK tests are fetched once into `.dart_tool/sdk_language/<sha>/` via a
/// sparse git checkout pinned to [SuiteConfig.sdkCommit] in `suite.yaml` —
/// no separate mirror repository to maintain.
///
/// Each test file is compiled as `package:sdk_language/<path>` together with
/// the files it pulls in through relative import/part directives and a small
/// set of package shims (`package:expect`, `package:meta`). `package:` imports
/// outside that set or `dart:` libraries dart_eval doesn't implement mark a
/// test as [TestKind.unsupported].
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:dart_eval/src/eval/compiler/helpers/conditional_import.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'shims.dart';
import 'sdk_multitest.dart';
import 'sdk_native_environment.dart';
import 'sdk_environment.dart';

String _normalizeRelPath(String relPath) => relPath.replaceAll('\\', '/');

/// Parsed `suite.yaml`.
class SuiteConfig {
  SuiteConfig._(
    this.sdkCommit,
    this.minSdk,
    this.coreDirs,
    this.negativeMode,
    this.excluded,
    this.expectFail,
  );

  final String sdkCommit;

  /// Explicit fixture language overrides below this version are unsupported.
  final ({int major, int minor}) minSdk;
  final List<String> coreDirs;

  /// How to treat tests carrying static-error markers: `skip` or
  /// `expect_compile_error`.
  final String negativeMode;

  /// Excluded paths (relative to `tests/language`): path → reason.
  final Map<String, String> excluded;

  /// Tests known to fail under dart_eval today: path → reason. An
  /// expected-failure that starts *passing* fails the suite, so the entry
  /// can be removed — the list is always accurate.
  final Map<String, String> expectFail;

  static SuiteConfig load() {
    final file = File('test/sdk_language/suite.yaml');
    return SuiteConfig.fromYaml(file.readAsStringSync());
  }

  factory SuiteConfig.fromYaml(String source) {
    final yaml = loadYaml(source) as YamlMap;
    return SuiteConfig._(
      yaml['sdk_commit'] as String,
      _parseVersion(yaml.containsKey('min_sdk') ? yaml['min_sdk'] : '3.0'),
      (yaml['core'] as YamlList).map((e) => e as String).toList(),
      yaml['negative'] as String? ?? 'skip',
      _pathReasonMap(yaml['exclude']),
      _pathReasonMap(yaml['expect_fail']),
    );
  }

  static ({int major, int minor}) _parseVersion(Object? value) {
    final match = value is String
        ? RegExp(r'^(\d+)\.(\d+)$').firstMatch(value)
        : null;
    if (match == null) {
      throw FormatException(
        'min_sdk must be a quoted major.minor version',
        value,
      );
    }
    return (major: int.parse(match[1]!), minor: int.parse(match[2]!));
  }

  /// The parser recognizes leading language overrides without mistaking
  /// ordinary comments or string contents for a version directive.
  String? unsupportedLanguageVersion(String source) {
    if (!source.contains('@dart')) return null;
    final version = parseString(
      content: source,
      throwIfDiagnostics: false,
    ).unit.languageVersionToken;
    if (version == null ||
        version.major > minSdk.major ||
        (version.major == minSdk.major && version.minor >= minSdk.minor)) {
      return null;
    }
    return 'language version ${version.major}.${version.minor} is below '
        'min_sdk ${minSdk.major}.${minSdk.minor}';
  }

  static Map<String, String> _pathReasonMap(Object? entries) => {
    for (final e in (entries as YamlList?) ?? const [])
      (e as YamlMap)['path'] as String: e['reason'] as String? ?? '',
  };

  /// Whether [relPath] (relative to `tests/language`) is excluded.
  String? exclusionReason(String relPath) =>
      _matchReason(excluded, relPath, 'excluded');

  /// Whether [relPath] is expected to fail; the reason if so, else null.
  String? expectedFailure(String relPath) =>
      _matchReason(expectFail, relPath, 'known failure');

  static String? _matchReason(
    Map<String, String> map,
    String relPath,
    String defaultReason,
  ) {
    for (final entry in map.entries) {
      final pattern = entry.key;
      final matches = pattern.endsWith('/')
          ? relPath.startsWith(pattern)
          : pattern.contains('*')
          ? RegExp(
              '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$',
            ).hasMatch(relPath)
          : relPath == pattern;
      if (matches) return entry.value.isEmpty ? defaultReason : entry.value;
    }
    return null;
  }
}

enum TestKind {
  /// A runtime test: compile and execute `main`.
  runnable,

  /// A negative test: the SDK expects a compile-time error
  /// (`// [cfe]`, `// [analyzer]`, `// [error line N]`, `// ^^^` markers).
  negative,

  /// A runtime test whose expected outcome is an uncaught exception —
  /// the source carries `//# NN: runtime error` multitest markers.
  runtimeError,

  /// Can't run under dart_eval (unsupported import, missing file, harness
  /// flags). `unsupportedReason` says why.
  unsupported,
}

class SdkTest {
  SdkTest(String relPath, this.kind, [this.unsupportedReason])
    : relPath = _normalizeRelPath(relPath),
      variantKey = null,
      source = null;

  SdkTest.variant(
    String relPath,
    this.kind, {
    required this.variantKey,
    required this.source,
    this.unsupportedReason,
  }) : relPath = _normalizeRelPath(relPath);

  /// Path relative to `tests/language`, e.g. `closure/nested_test.dart`.
  final String relPath;
  final TestKind kind;
  final String? unsupportedReason;
  final String? variantKey;
  final String? source;

  /// `package:` URI under which the test is compiled.
  String get uri => 'package:sdk_language/$relPath';
}

/// Selects SDK outcomes per case, including the untagged `none` baseline.
/// Error comments left behind by discarded code do not reclassify a case.
List<SdkTest> materializeSdkTests(SdkTest test, String source) {
  if (test.variantKey != null) return [test];
  return [
    for (final variant in splitSdkMultitest(source))
      if (variant.key == null)
        test
      else
        SdkTest.variant(
          test.relPath,
          variant.isNegative
              ? TestKind.negative
              : variant.isRuntimeError
              ? TestKind.runtimeError
              : variant.hasStaticWarning
              ? TestKind.unsupported
              : TestKind.runnable,
          variantKey: variant.key,
          source: variant.source,
          unsupportedReason:
              variant.hasStaticWarning &&
                  !variant.isNegative &&
                  !variant.isRuntimeError
              ? 'requires static type warning checking'
              : null,
        ),
  ];
}

enum TestOutcome { passed, failed, compileError, skipped, timedOut }

/// The checked-out SDK tree: `.dart_tool/sdk_language/<sha>`.
class SdkSuite {
  SdkSuite(this.config, this.checkoutDir);

  final SuiteConfig config;
  final Directory checkoutDir;

  /// `tests/language` inside the checkout.
  String get languageRoot => p.join(checkoutDir.path, 'tests', 'language');

  /// `pkg/expect/lib` inside the checkout (vendored real package sources).
  String get expectRoot => p.join(checkoutDir.path, 'pkg', 'expect', 'lib');

  static const _sparseDirs = ['tests/language', 'pkg/expect/lib'];

  /// Loads `suite.yaml` and fetches the pinned SDK checkout if missing.
  static Future<SdkSuite> load() async {
    final config = SuiteConfig.load();
    final dir = Directory(
      p.join('.dart_tool', 'sdk_language', config.sdkCommit),
    );
    await _ensureCheckout(dir, config.sdkCommit);
    return SdkSuite(config, dir);
  }

  static Future<void> _ensureCheckout(Directory dir, String sha) async {
    final marker = File(p.join(dir.path, '.complete'));
    if (marker.existsSync()) return;
    if (!dir.existsSync()) dir.createSync(recursive: true);

    Future<void> git(List<String> args) async {
      final result = await Process.run('git', args, workingDirectory: dir.path);
      if (result.exitCode != 0) {
        throw StateError('git ${args.join(' ')} failed: ${result.stderr}');
      }
    }

    if (!File(p.join(dir.path, '.git', 'HEAD')).existsSync()) {
      await git(['init', '-q']);
      await git([
        'remote',
        'add',
        'origin',
        'https://github.com/dart-lang/sdk.git',
      ]);
      await git(['sparse-checkout', 'init', '--cone']);
      await git(['sparse-checkout', 'set', ..._sparseDirs]);
    }
    await git([
      'fetch',
      '-q',
      '--depth',
      '1',
      '--filter=blob:none',
      'origin',
      sha,
    ]);
    await git(['checkout', '-q', 'FETCH_HEAD']);
    marker.writeAsStringSync(sha);
  }

  /// All candidate tests under `tests/language` (recursively), classified.
  List<SdkTest> allTests() {
    final files =
        Directory(languageRoot)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_test.dart'))
            .map(
              (f) => _normalizeRelPath(p.relative(f.path, from: languageRoot)),
            )
            .toList()
          ..sort();
    return [for (final rel in files) classify(rel)];
  }

  /// The "core" subset: tests under the directories listed in `core:`.
  List<SdkTest> coreTests() => [
    for (final test in allTests())
      if (config.coreDirs.any((d) => test.relPath.startsWith('$d/'))) test,
  ];

  SdkTest classify(String relPath) {
    relPath = _normalizeRelPath(relPath);
    final exclusion = config.exclusionReason(relPath);
    if (exclusion != null) {
      return SdkTest(relPath, TestKind.unsupported, 'excluded: $exclusion');
    }
    final file = File(p.join(languageRoot, relPath));
    if (!file.existsSync()) {
      return SdkTest(relPath, TestKind.unsupported, 'missing file');
    }
    final cases = variants(SdkTest(relPath, TestKind.runnable));
    if (cases.length == 1 && cases.single.variantKey == null) {
      return cases.single;
    }
    if (cases.any(
      (test) =>
          test.kind == TestKind.runnable || test.kind == TestKind.runtimeError,
    )) {
      return SdkTest(relPath, TestKind.runnable);
    }
    if (cases.any((test) => test.kind == TestKind.negative)) {
      return SdkTest(relPath, TestKind.negative);
    }
    return SdkTest(
      relPath,
      TestKind.unsupported,
      cases.first.unsupportedReason,
    );
  }

  /// Each variant retains the fixture path and URI for imports and status
  /// matching. Only its root source and expected outcome differ.
  List<SdkTest> variants(SdkTest test) {
    if (test.kind == TestKind.unsupported || test.variantKey != null) {
      return [test];
    }
    final source = File(p.join(languageRoot, test.relPath)).readAsStringSync();
    return [
      for (final candidate in materializeSdkTests(test, source))
        _classifySource(candidate, candidate.source ?? source),
    ];
  }

  SdkTest _classifySource(SdkTest candidate, String source) {
    final relPath = candidate.relPath;
    final file = File(p.join(languageRoot, relPath));
    SdkTest classified(TestKind kind, [String? reason]) =>
        candidate.variantKey == null
        ? SdkTest(relPath, kind, reason)
        : SdkTest.variant(
            relPath,
            kind,
            variantKey: candidate.variantKey,
            source: source,
            unsupportedReason: reason,
          );
    final versionReason = config.unsupportedLanguageVersion(source);
    if (versionReason != null) {
      return classified(TestKind.unsupported, versionReason);
    }
    // Helpers imported by tests (no main) aren't tests themselves. A part
    // file may define main() — scan `part` targets relative to the test.
    var hasMain = RegExp(r'\bmain\s*\(').hasMatch(source);
    if (!hasMain) {
      for (final m in RegExp(
        r'''part\s+['"]([^'"]+)['"]''',
      ).allMatches(source)) {
        final partFile = File(p.join(p.dirname(file.path), m.group(1)!));
        if (partFile.existsSync() &&
            RegExp(r'\bmain\s*\(').hasMatch(partFile.readAsStringSync())) {
          hasMain = true;
          break;
        }
      }
    }
    if (!hasMain) {
      return classified(TestKind.unsupported, 'no main()');
    }
    if (candidate.variantKey != null) {
      if (candidate.kind == TestKind.negative ||
          candidate.kind == TestKind.unsupported) {
        return candidate;
      }
    } else if (_negativePattern.hasMatch(source)) {
      return classified(TestKind.negative);
    }
    if (candidate.variantKey == null && _runtimeErrorPattern.hasMatch(source)) {
      return classified(TestKind.runtimeError);
    }
    final unsupported = _unsupportedImport(source);
    if (unsupported != null) {
      return classified(TestKind.unsupported, unsupported);
    }
    return classified(
      candidate.variantKey == null ? TestKind.runnable : candidate.kind,
    );
  }

  /// Static-error markers used by the SDK test runner, including multitest
  /// `//# NN: compile-time error` annotations.
  static final _negativePattern = RegExp(
    r'//\s*(\[cfe\]|\[analyzer\]|\[error line|\^|#\s*\d+.*compile-time error)',
  );

  /// Legacy runtime-error markers on ordinary, non-materialized sources.
  static final _runtimeErrorPattern = RegExp(
    r'//\s*#\s*\d+\s*:\s*runtime error',
  );

  /// SDK test-harness options dart_eval can't honor.
  static final _harnessFlag = RegExp(
    r'^//\s*(Requirements|SharedObjects|Flags|dart2jsOptions|'
    r'dart2wasmOptions|ddcOptions|VMOptions)=',
    multiLine: true,
  );

  /// `dart:` libraries implemented by dart_eval's stdlib plugins.
  static const _supportedDartLibs = {
    'async',
    'collection',
    'convert',
    'core',
    'io',
    'math',
    'typed_data',
  };

  /// `package:` URIs backed by vendored SDK sources or hand shims.
  static const _packageShims = {
    'expect/expect.dart': expectShim,
    'expect/async_helper.dart': asyncHelperShim,
    'expect/config.dart': expectConfigShim,
    'meta/meta.dart': metaShim,
  };

  /// `package:expect/` files vendored verbatim from `pkg/expect/lib`.
  static const _vendoredExpectLibs = {
    'static_type_helper.dart',
    'variations.dart',
    'minitest.dart',
  };

  static final _directivePattern = RegExp(
    r'''^\s*(?:import|export|part)\s+(?:deferred\s+)?['"][^'"]*['"][^;]*;''',
    multiLine: true,
  );

  static Iterable<String> _directiveUris(String source) sync* {
    for (final match in _directivePattern.allMatches(source)) {
      final unit = parseString(
        content: match.group(0)!,
        throwIfDiagnostics: false,
      ).unit;
      for (final directive in unit.directives.whereType<UriBasedDirective>()) {
        yield selectedDirectiveUri(directive);
      }
    }
  }

  /// First unsupported import URI in [source], or null.
  static String? _unsupportedImport(String source) {
    if (_harnessFlag.hasMatch(source)) return 'requires SDK test harness flags';
    for (final uri in _directiveUris(source)) {
      if (uri.startsWith('dart:')) {
        final lib = uri.substring(5).split('.').first;
        if (!_supportedDartLibs.contains(lib)) return uri;
      } else if (uri.startsWith('package:')) {
        final rel = uri.substring(8);
        if (rel.startsWith('sdk_language/')) continue;
        if (_packageShims.containsKey(rel) ||
            _vendoredExpectLibs.any((f) => rel == 'expect/$f')) {
          continue;
        }
        return uri;
      }
    }
    return null;
  }

  /// Collects the sources needed to compile [test]: the file itself plus
  /// everything reachable through relative import/export/part directives,
  /// mapped to `package:sdk_language/` URIs so relative resolution works.
  ///
  /// Throws [UnsupportedError] when a required import isn't available.
  List<DartSource> collectSources(SdkTest test) {
    final sources = <String, DartSource>{};
    final pending = <String>[test.relPath];

    while (pending.isNotEmpty) {
      final rel = pending.removeLast();
      if (sources.containsKey('sdk_language/$rel')) continue;
      final file = File(p.join(languageRoot, rel));
      if (!file.existsSync()) {
        throw UnsupportedError('missing dependency $rel');
      }
      final source = rel == test.relPath && test.source != null
          ? test.source!
          : file.readAsStringSync();
      if (rel == test.relPath &&
          test.variantKey == null &&
          splitSdkMultitest(source).first.key != null) {
        throw StateError(
          'SDK multitest ${test.relPath} requires '
          'suite.variants(test) before collecting sources',
        );
      }
      final versionReason = config.unsupportedLanguageVersion(source);
      if (versionReason != null) {
        throw UnsupportedError('$rel: $versionReason');
      }
      sources['sdk_language/$rel'] = DartSource(
        'package:sdk_language/$rel',
        source,
      );
      final base = Uri.parse('package:sdk_language/$rel');
      for (final path in _directiveUris(source)) {
        final uri = Uri.parse(path);
        if (uri.scheme == 'dart') {
          final lib = uri.pathSegments.first.split('.').first;
          if (!_supportedDartLibs.contains(lib)) {
            throw UnsupportedError('unsupported $uri');
          }
          continue;
        }
        if (uri.scheme == 'package') {
          final packageRel = uri.toString().substring(8);
          _collectPackage(packageRel, sources);
          continue;
        }
        final resolved = base.resolveUri(uri);
        if (resolved.toString().startsWith('package:sdk_language/')) {
          pending.add(resolved.toString().substring(21));
        }
      }
    }
    return sources.values.toList();
  }

  void _collectPackage(String packageRel, Map<String, DartSource> sources) {
    if (sources.containsKey(packageRel)) return;
    final shim = _packageShims[packageRel];
    if (shim != null) {
      sources[packageRel] = DartSource('package:$packageRel', shim);
      return;
    }
    if (packageRel.startsWith('expect/') &&
        _vendoredExpectLibs.contains(packageRel.substring(7))) {
      final file = File(p.join(expectRoot, packageRel.substring(7)));
      final source = file.readAsStringSync();
      sources[packageRel] = DartSource('package:$packageRel', source);
      // Vendored files may pull in siblings via relative imports
      // (e.g. variations.dart → config.dart).
      final base = Uri.parse('package:$packageRel');
      for (final path in _directiveUris(source)) {
        final uri = base.resolveUri(Uri.parse(path));
        if (uri.scheme == 'package') {
          _collectPackage(uri.toString().substring(8), sources);
        }
      }
      return;
    }
    throw UnsupportedError('unsupported package import package:$packageRel');
  }
}

const _asyncHelperUri = 'package:expect/async_helper.dart';

bool _usesAsyncHelper(List<DartSource> sources) =>
    sources.any((source) => source.uri.toString() == _asyncHelperUri);

/// Keep the shim's drain function available after compilation.
void setSdkEntrypoints(
  Compiler compiler,
  SdkTest test,
  List<DartSource> sources,
) {
  compiler.entrypoints
    ..clear()
    ..add('/${test.relPath}');
  compiler.entrypointFunctions
    ..clear()
    ..['/${test.relPath}'] = {'main'};
  if (_usesAsyncHelper(sources)) {
    compiler.entrypoints.add(_asyncHelperUri);
    compiler.entrypointFunctions[_asyncHelperUri] = {'drainAsyncTests'};
  }
}

/// Whether [error] is the compiler's missing-entrypoint failure for a
/// runtime-error fixture that has no executable `main` in its library.
///
/// The SDK runner reports a missing `main` when it launches a test. dart_eval
/// currently detects that condition while compiling entrypoints, so normalize
/// only this exact failure at the launcher boundary. Parse declarations so a
/// commented-out `main` does not count, and follow parts but not imports.
bool isExpectedMissingSdkMainError(
  Object error,
  SdkTest test,
  List<DartSource> sources,
) {
  if (test.kind != TestKind.runtimeError ||
      error is! ArgumentError ||
      error.message != 'No typed entrypoints were found') {
    return false;
  }

  final byUri = {for (final source in sources) source.uri: source};
  final visited = <Uri>{};

  bool hasMain(Uri uri) {
    if (!visited.add(uri)) return false;
    final source = byUri[uri];
    if (source == null) return false;
    final unit = parseString(
      content: source.toString(),
      throwIfDiagnostics: false,
    ).unit;
    if (unit.declarations.whereType<FunctionDeclaration>().any(
      (declaration) => declaration.name.lexeme == 'main',
    )) {
      return true;
    }
    for (final part in unit.directives.whereType<PartDirective>()) {
      final path = part.uri.stringValue;
      if (path != null && hasMain(uri.resolve(path))) return true;
    }
    return false;
  }

  return !hasMain(Uri.parse(test.uri));
}

Future<void> executeSdkMain(
  Runtime runtime,
  SdkTest test,
  List<DartSource> sources,
) async {
  final rootSource = sources
      .where((source) => source.uri.toString() == test.uri)
      .firstOrNull;
  if (rootSource != null && rootSource.toString().contains('Platform.script')) {
    final checkout = Directory(
      p.join('.dart_tool', 'sdk_language', SuiteConfig.load().sdkCommit),
    );
    final script = File(
      p.join(checkout.path, 'tests', 'language', test.relPath),
    );
    if (script.existsSync()) {
      runtime.addPlugin(SdkNativeEnvironment(script.absolute.uri, checkout));
    }
  }
  final source = sources.firstWhere(
    (source) => source.uri.toString() == test.uri,
  );
  runtime.addPlugin(SdkEnvironmentPlugin(source.toString()));
  await runtime.executeLib(
    test.uri,
    'main',
    arguments: _sdkMainArguments(test, sources),
  );
  if (_usesAsyncHelper(sources)) {
    await runtime.executeLib(_asyncHelperUri, 'drainAsyncTests');
  }
}

/// The VM launcher prefers two positional arguments, then one, then zero.
/// Named parameters keep their defaults; only this library's parts share main.
Map<String, Object?> _sdkMainArguments(SdkTest test, List<DartSource> sources) {
  final byUri = {for (final source in sources) source.uri: source};
  final visited = <Uri>{};
  FormalParameterList? findParameters(Uri uri) {
    if (!visited.add(uri)) return null;
    final source = byUri[uri];
    if (source == null) return null;
    final unit = parseString(
      content: source.toString(),
      throwIfDiagnostics: false,
    ).unit;
    for (final declaration
        in unit.declarations.whereType<FunctionDeclaration>()) {
      if (declaration.name.lexeme == 'main') {
        return declaration.functionExpression.parameters;
      }
    }
    for (final part in unit.directives.whereType<PartDirective>()) {
      final path = part.uri.stringValue;
      if (path == null) continue;
      final parameters = findParameters(uri.resolve(path));
      if (parameters != null) return parameters;
    }
    return null;
  }

  final parameters = findParameters(Uri.parse(test.uri))?.parameters;
  if (parameters == null || parameters.any((p) => p.isRequiredNamed)) return {};
  final positional = parameters.where((p) => p.isPositional).toList();
  final requiredCount = positional.where((p) => p.isRequiredPositional).length;
  final count = requiredCount <= 2 && positional.length >= 2
      ? 2
      : requiredCount <= 1 && positional.isNotEmpty
      ? 1
      : 0;
  return {
    if (count > 0) positional[0].name!.lexeme: <String>[],
    if (count > 1) positional[1].name!.lexeme: null,
  };
}

/// Compiles and runs [test], returning its outcome. A shared [compiler] is
/// reused across calls so shim sources stay cached in its parse cache.
/// Multitests execute every selected variant and aggregate at the fixture path.
Future<TestOutcome> runSdkTest(
  SdkSuite suite,
  SdkTest test,
  Compiler compiler,
) async => (await runSdkTestCases(suite.variants(test), (variant) async {
  try {
    return await runSdkTestSources(
      variant,
      compiler,
      suite.collectSources(variant),
    );
  } on UnsupportedError {
    return TestOutcome.skipped;
  }
}, negativeMode: suite.config.negativeMode)).outcome;

/// Executes every selected case and aggregates under the original fixture.
/// A skipped runnable case prevents a partially checked fixture going stale.
Future<({TestOutcome outcome, Map<String, TestOutcome> cases})> runSdkTestCases(
  List<SdkTest> variants,
  Future<TestOutcome> Function(SdkTest) run, {
  required String negativeMode,
}) async {
  final outcomes = <String, TestOutcome>{};
  final checked = <TestOutcome>[];
  for (final variant in variants) {
    final skipNegative =
        variant.kind == TestKind.negative && negativeMode == 'skip';
    final outcome = skipNegative || variant.kind == TestKind.unsupported
        ? TestOutcome.skipped
        : await run(variant);
    outcomes[variant.variantKey ?? 'main'] = outcome;
    if (!skipNegative) checked.add(outcome);
  }
  final outcome = checked.isEmpty
      ? TestOutcome.skipped
      : [
          TestOutcome.timedOut,
          TestOutcome.compileError,
          TestOutcome.failed,
          TestOutcome.skipped,
          TestOutcome.passed,
        ].firstWhere(checked.contains);
  return (outcome: outcome, cases: outcomes);
}

/// Compiles [sources] for [test] and waits for its `main` result.
///
/// Kept separate from [runSdkTest] so execution outcomes can be tested without
/// loading the SDK checkout.
Future<TestOutcome> runSdkTestSources(
  SdkTest test,
  Compiler compiler,
  List<DartSource> sources,
) async {
  setSdkEntrypoints(compiler, test, sources);
  final Program program;
  try {
    program = compiler.compileSources(sources);
  } on ArgumentError catch (error) {
    return isExpectedMissingSdkMainError(error, test, sources)
        ? TestOutcome.passed
        : test.kind == TestKind.negative
        ? TestOutcome.failed
        : TestOutcome.compileError;
  } on CompileError {
    return test.kind == TestKind.negative
        ? TestOutcome.passed
        : TestOutcome.compileError;
  } catch (_) {
    return test.kind == TestKind.negative
        ? TestOutcome.failed
        : TestOutcome.compileError;
  }
  if (test.kind == TestKind.negative) {
    // Compiled but the SDK expected a static error.
    return TestOutcome.failed;
  }
  final Runtime runtime;
  try {
    runtime = Runtime(program.write().buffer);
  } catch (_) {
    return TestOutcome.compileError;
  }
  try {
    await executeSdkMain(runtime, test, sources);
    return test.kind == TestKind.runtimeError
        ? TestOutcome
              .failed // returned normally but expected to throw
        : TestOutcome.passed;
  } catch (_) {
    return test.kind == TestKind.runtimeError
        ? TestOutcome.passed
        : TestOutcome.failed;
  }
}

void _sdkSourceWorker((SendPort, SdkTest, List<DartSource>) request) async {
  final (port, test, sources) = request;
  port.send(await runSdkTestSources(test, Compiler(), sources));
}

/// Run both compilation and execution in a worker that can be terminated.
/// A Future timeout in the executing isolate cannot interrupt synchronous
/// guest loops or compiler work that never returns to the event loop.
Future<TestOutcome> runSdkTestSourcesIsolated(
  SdkTest test,
  List<DartSource> sources, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final port = ReceivePort();
  final result = Completer<TestOutcome>();
  TestOutcome? reported;
  final subscription = port.listen((message) {
    if (result.isCompleted) return;
    if (message is TestOutcome) {
      reported = message;
    } else {
      // Pending timers can fail after main returns. Accept its outcome only
      // after a clean worker exit; uncaught errors override that outcome.
      result.complete(
        message == null
            ? reported ?? TestOutcome.failed
            : test.kind == TestKind.runtimeError
            ? TestOutcome.passed
            : TestOutcome.failed,
      );
    }
  });
  Isolate? worker;
  try {
    worker = await Isolate.spawn(
      _sdkSourceWorker,
      (port.sendPort, test, sources),
      onError: port.sendPort,
      onExit: port.sendPort,
    );
    return await result.future.timeout(
      timeout,
      onTimeout: () => TestOutcome.timedOut,
    );
  } finally {
    worker?.kill(priority: Isolate.immediate);
    await subscription.cancel();
    port.close();
  }
}

/// Registers [tests] as a `dart_test` group under [label].
///
/// Outcome assertions follow the SDK's status-file convention: a test must
/// pass unless `suite.yaml`'s `expect_fail` lists it, in which case any
/// non-passing outcome satisfies the suite. An expected-failure that starts
/// *passing* fails loudly — that's the reminder to remove the stale entry.
void registerSdkSuite(
  String label,
  List<SdkTest> tests,
  SdkSuite suite, {
  bool isolateTests = false,
}) {
  // One shared Compiler amortizes shim parsing across tests, but its parse
  // cache retains every test file's AST — rebuild it periodically so the
  // full suite doesn't OOM on big runs.
  var compiler = Compiler();
  final results = <TestOutcome, int>{};

  group(label, () {
    var sinceReset = 0;
    for (final sdkTest in tests) {
      if (sdkTest.kind == TestKind.negative &&
          suite.config.negativeMode == 'skip') {
        continue;
      }
      if (sdkTest.kind == TestKind.unsupported) {
        test(sdkTest.relPath, () {}, skip: sdkTest.unsupportedReason);
        continue;
      }
      test(
        sdkTest.relPath,
        () async {
          if (++sinceReset >= 300) {
            compiler = Compiler();
            sinceReset = 0;
          }
          final variants = suite.variants(sdkTest);
          final result = await runSdkTestCases(variants, (variant) async {
            try {
              final sources = suite.collectSources(variant);
              return isolateTests
                  ? await runSdkTestSourcesIsolated(variant, sources)
                  : await runSdkTestSources(variant, compiler, sources);
            } on UnsupportedError {
              return TestOutcome.skipped;
            }
          }, negativeMode: suite.config.negativeMode);
          final outcome = result.outcome;
          if (variants.any((variant) => variant.variantKey != null)) {
            print(
              '${sdkTest.relPath}: ${result.cases.entries.map((entry) => '${entry.key}=${entry.value.name}').join(', ')}',
            );
          }
          results[outcome] = (results[outcome] ?? 0) + 1;
          final expectedFail = suite.config.expectedFailure(sdkTest.relPath);
          if (expectedFail != null) {
            expect(
              outcome,
              isNot(TestOutcome.passed),
              reason:
                  'expected to fail ($expectedFail) but passed — '
                  'remove the expect_fail entry in suite.yaml',
            );
          } else {
            if (outcome == TestOutcome.skipped) {
              markTestSkipped('one or more runnable cases are unsupported');
              return;
            }
            expect(outcome, TestOutcome.passed);
          }
        },
        timeout: Timeout(
          Duration(
            seconds: (isolateTests ? 70 : 30) * suite.variants(sdkTest).length,
          ),
        ),
      );
    }

    tearDownAll(() {
      print(
        '$label: ${results.entries.map((e) => '${e.key.name}=${e.value}').join(' ')}',
      );
    });
  });
}
