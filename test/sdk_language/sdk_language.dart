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

import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'shims.dart';

/// Parsed `suite.yaml`.
class SuiteConfig {
  SuiteConfig._(
    this.sdkCommit,
    this.coreDirs,
    this.negativeMode,
    this.excluded,
    this.expectFail,
  );

  final String sdkCommit;
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
    final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
    return SuiteConfig._(
      yaml['sdk_commit'] as String,
      (yaml['core'] as YamlList).map((e) => e as String).toList(),
      yaml['negative'] as String? ?? 'skip',
      _pathReasonMap(yaml['exclude']),
      _pathReasonMap(yaml['expect_fail']),
    );
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

  /// Can't run under dart_eval (unsupported import, missing file, harness
  /// flags). `unsupportedReason` says why.
  unsupported,
}

class SdkTest {
  SdkTest(this.relPath, this.kind, [this.unsupportedReason]);

  /// Path relative to `tests/language`, e.g. `closure/nested_test.dart`.
  final String relPath;
  final TestKind kind;
  final String? unsupportedReason;

  /// `package:` URI under which the test is compiled.
  String get uri => 'package:sdk_language/$relPath';
}

enum TestOutcome { passed, failed, compileError, skipped }

/// The checked-out SDK tree: `.dart_tool/sdk_language/<sha>`.
class SdkSuite {
  SdkSuite._(this.config, this.checkoutDir);

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
    return SdkSuite._(config, dir);
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
            .map((f) => p.relative(f.path, from: languageRoot))
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
    final exclusion = config.exclusionReason(relPath);
    if (exclusion != null) {
      return SdkTest(relPath, TestKind.unsupported, 'excluded: $exclusion');
    }
    final file = File(p.join(languageRoot, relPath));
    if (!file.existsSync()) {
      return SdkTest(relPath, TestKind.unsupported, 'missing file');
    }
    final source = file.readAsStringSync();
    // Helpers imported by tests (no main) aren't tests themselves.
    if (!RegExp(r'\bmain\s*\(').hasMatch(source)) {
      return SdkTest(relPath, TestKind.unsupported, 'no main()');
    }
    if (_negativePattern.hasMatch(source)) {
      return SdkTest(relPath, TestKind.negative);
    }
    final unsupported = _unsupportedImport(source);
    if (unsupported != null) {
      return SdkTest(relPath, TestKind.unsupported, unsupported);
    }
    return SdkTest(relPath, TestKind.runnable);
  }

  /// Static-error markers used by the SDK test runner, including multitest
  /// `//# NN: compile-time error` annotations.
  static final _negativePattern = RegExp(
    r'//\s*(\[cfe\]|\[analyzer\]|\[error line|\^|#\s*\d+.*compile-time error)',
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
    '''^\\s*(?:import|export|part)\\s+(?:deferred\\s+)?(?:'|")([^'"]+)''',
    multiLine: true,
  );

  /// First unsupported import URI in [source], or null.
  static String? _unsupportedImport(String source) {
    if (_harnessFlag.hasMatch(source)) return 'requires SDK test harness flags';
    for (final m in _directivePattern.allMatches(source)) {
      final uri = m.group(1)!;
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
      final source = file.readAsStringSync();
      sources['sdk_language/$rel'] = DartSource(
        'package:sdk_language/$rel',
        source,
      );
      final base = Uri.parse('package:sdk_language/$rel');
      for (final m in _directivePattern.allMatches(source)) {
        final uri = Uri.parse(m.group(1)!);
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
      for (final m in _directivePattern.allMatches(source)) {
        final uri = base.resolveUri(Uri.parse(m.group(1)!));
        if (uri.scheme == 'package') {
          _collectPackage(uri.toString().substring(8), sources);
        }
      }
      return;
    }
    throw UnsupportedError('unsupported package import package:$packageRel');
  }
}

/// Compiles and runs [test], returning its outcome. A shared [compiler] is
/// reused across calls so shim sources stay cached in its parse cache.
TestOutcome runSdkTest(SdkSuite suite, SdkTest test, Compiler compiler) {
  if (test.kind == TestKind.unsupported) return TestOutcome.skipped;
  final List<DartSource> sources;
  try {
    sources = suite.collectSources(test);
  } on UnsupportedError {
    return TestOutcome.skipped;
  }

  compiler.entrypoints
    ..clear()
    ..add('/${test.relPath}');
  try {
    final program = compiler.compileSources(sources);
    if (test.kind == TestKind.negative) {
      // Compiled but the SDK expected a static error.
      return TestOutcome.failed;
    }
    final runtime = Runtime(program.write().buffer);
    runtime.executeLib(test.uri, 'main');
    return TestOutcome.passed;
  } on CompileError {
    return test.kind == TestKind.negative
        ? TestOutcome.passed
        : TestOutcome.compileError;
  } catch (_) {
    return TestOutcome.failed;
  }
}

/// Registers [tests] as a `dart_test` group under [label].
///
/// Outcome assertions follow the SDK's status-file convention: a test must
/// pass unless `suite.yaml`'s `expect_fail` lists it, in which case any
/// non-passing outcome satisfies the suite. An expected-failure that starts
/// *passing* fails loudly — that's the reminder to remove the stale entry.
void registerSdkSuite(String label, List<SdkTest> tests, SdkSuite suite) {
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
      test(sdkTest.relPath, () {
        if (++sinceReset >= 300) {
          compiler = Compiler();
          sinceReset = 0;
        }
        final outcome = runSdkTest(suite, sdkTest, compiler);
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
          expect(outcome, TestOutcome.passed);
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    }

    tearDownAll(() {
      print(
        '$label: ${results.entries.map((e) => '${e.key.name}=${e.value}').join(' ')}',
      );
    });
  });
}
