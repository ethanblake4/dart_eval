import 'package:test/test.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'sdk_multitest.dart';
import 'sdk_language.dart';

void main() {
  test('selects independent forwarding constructor cases and baseline', () {
    const source = '''class Base {
  Base(
    {x} //# 01: ok
    {x} //# 02: ok
    {x} //# 03: ok
  );
}
class C extends Base {
  C(); //# 02: continued
  C() : super(); //# 03: continued
}
void main() { C(); }
''';
    final variants = splitSdkMultitest(source);
    expect(variants.map((variant) => variant.key), ['none', '01', '02', '03']);
    for (final variant in variants) {
      expect(variant.source.split('\n').length, source.split('\n').length);
      expect(variant.isNegative, false);
      expect(variant.isRuntimeError, false);
      expect(
        '{x}'.allMatches(variant.source).length,
        variant.key == 'none' ? 0 : 1,
      );
    }
    expect(variants[1].source.contains('C(); //#'), false);
    expect(variants[2].source.contains('C(); //#'), true);
    expect(variants[2].source.contains('C() : super();'), false);
    expect(variants[3].source.contains('C() : super();'), true);
  });

  test(
    'keeps marker outcomes separate and preserves CRLF source locations',
    () {
      final source = [
        "import 'helper.dart';",
        'void main() {',
        '  throw StateError("expected"); //# fail: runtime error',
        '  undefined(); //# static: compile-time error, runtime error',
        '  print(1); //# good: ok',
        '}',
        '',
      ].join('\r\n');
      final variants = splitSdkMultitest(source);
      expect(variants.map((variant) => variant.key), [
        'none',
        'fail',
        'static',
        'good',
      ]);
      expect(variants[1].isRuntimeError, true);
      expect(variants[2].isNegative, true);
      expect(variants[2].isRuntimeError, false);
      for (final variant in variants) {
        expect(variant.source.startsWith("import 'helper.dart';\r\n"), true);
        expect(
          variant.source.split('\r\n').length,
          source.split('\r\n').length,
        );
      }
    },
  );

  test('untagged sources and continued-only variants follow SDK rules', () {
    const ordinary = 'void main() {}\n';
    expect(splitSdkMultitest(ordinary).single.source, ordinary);
    expect(splitSdkMultitest(ordinary).single.key, null);
    final variants = splitSdkMultitest(
      'void main() {} //# missing: continued\n',
    );
    expect(variants.map((variant) => variant.key), ['none']);
  });

  test(
    'runs all cases and preserves fixture identity and negative mode',
    () async {
      final fixture = SdkTest('mixed_test.dart', TestKind.runnable);
      const source = '''void main() {
  throw StateError('expected'); //# runtime: runtime error
  unknownFunction(); //# negative: compile-time error
  print(1); //# positive: ok
}
''';
      final variants = materializeSdkTests(fixture, source);
      for (final variant in variants) {
        expect(variant.relPath, fixture.relPath);
        expect(variant.uri, fixture.uri);
      }
      final executed = <String?>[];
      Future<TestOutcome> run(SdkTest variant) async {
        executed.add(variant.variantKey);
        return runSdkTestSources(variant, Compiler(), [
          DartSource(variant.uri, variant.source!),
        ]);
      }

      final skipped = await runSdkTestCases(
        variants,
        run,
        negativeMode: 'skip',
      );
      expect(skipped.outcome, TestOutcome.passed);
      expect(executed, ['none', 'runtime', 'positive']);
      expect(skipped.cases['negative'], TestOutcome.skipped);
      executed.clear();
      final checked = await runSdkTestCases(
        variants,
        run,
        negativeMode: 'expect_compile_error',
      );
      expect(checked.outcome, TestOutcome.passed);
      expect(executed, ['none', 'runtime', 'negative', 'positive']);
    },
  );

  test(
    'partial success cannot report a stale fixture and runs later cases',
    () async {
      final variants = materializeSdkTests(
        SdkTest('aggregate_test.dart', TestKind.runnable),
        '''void main() {
  print(1); //# first: ok
  print(2); //# later: ok
}
''',
      );
      final executed = <String?>[];
      final result = await runSdkTestCases(variants, (variant) async {
        executed.add(variant.variantKey);
        return variant.variantKey == 'first'
            ? TestOutcome.compileError
            : TestOutcome.passed;
      }, negativeMode: 'skip');
      expect(result.outcome, TestOutcome.compileError);
      expect(executed, ['none', 'first', 'later']);
      final unsupported = await runSdkTestCases(
        variants,
        (variant) async => variant.variantKey == 'first'
            ? TestOutcome.skipped
            : TestOutcome.passed,
        negativeMode: 'skip',
      );
      expect(unsupported.outcome, TestOutcome.skipped);
    },
  );

  test(
    'runtime-error cases require execution and retain late async errors',
    () async {
      final fixture = SdkTest('runtime_test.dart', TestKind.runnable);
      const source = '''void main() {
  Future<void>.delayed(const Duration(milliseconds: 1), () {
    throw StateError('later'); //# late: runtime error
  });
  missing(); //# compile: runtime error
  print(1); //# normal: runtime error
}
''';
      final variants = materializeSdkTests(fixture, source);
      final result = await runSdkTestCases(
        variants,
        (variant) => runSdkTestSourcesIsolated(variant, [
          DartSource(variant.uri, variant.source!),
        ]),
        negativeMode: 'skip',
      );
      expect(result.cases['none'], TestOutcome.passed);
      expect(result.cases['late'], TestOutcome.passed);
      expect(result.cases['compile'], TestOutcome.compileError);
      expect(result.cases['normal'], TestOutcome.failed);
      expect(result.outcome, TestOutcome.compileError);
    },
  );

  test('missing entrypoints follow each SDK fixture contract', () async {
    for (final isolated in [false, true]) {
      for (final kind in [
        TestKind.runnable,
        TestKind.runtimeError,
        TestKind.negative,
      ]) {
        final fixture = SdkTest('no_entrypoint.dart', kind);
        final sources = [DartSource(fixture.uri, '/* void main() {} */')];
        final outcome = isolated
            ? await runSdkTestSourcesIsolated(fixture, sources)
            : await runSdkTestSources(fixture, Compiler(), sources);
        expect(
          outcome,
          kind == TestKind.runtimeError
              ? TestOutcome.passed
              : kind == TestKind.negative
              ? TestOutcome.failed
              : TestOutcome.compileError,
        );
      }
      final fixture = SdkTest('throws.dart', TestKind.runtimeError);
      final sources = [
        DartSource(fixture.uri, "void main() { throw StateError('runtime'); }"),
      ];
      final outcome = isolated
          ? await runSdkTestSourcesIsolated(fixture, sources)
          : await runSdkTestSources(fixture, Compiler(), sources);
      expect(outcome, TestOutcome.passed);
    }
  });

  test('pinned forwarding constructor cases compile independently', () async {
    final suite = await SdkSuite.load();
    final fixture = suite.classify('mixin/forwarding_constructor4_test.dart');
    expect(fixture.kind, TestKind.runnable);
    expect(
      () => suite.collectSources(fixture),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('suite.variants(test)'),
        ),
      ),
    );
    final variants = suite.variants(fixture);
    expect(variants.map((variant) => variant.variantKey), [
      'none',
      '01',
      '02',
      '03',
    ]);
    final compiler = Compiler();
    for (final variant in variants) {
      final sources = suite.collectSources(variant);
      setSdkEntrypoints(compiler, variant, sources);
      final program = compiler.compileSources(sources);
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        await executeSdkMain(runtime, variant, sources);
      }
    }
  });

  test('discarded tagged imports are not collected for the baseline', () async {
    final suite = await SdkSuite.load();
    final fixture = suite.classify('library/library_test.dart');
    final variants = suite.variants(fixture);
    expect(variants.map((variant) => variant.variantKey), ['none', '01']);
    final sources = suite.collectSources(variants.first);
    expect(sources, hasLength(1));
    expect(sources.single.uri.toString(), fixture.uri);
    expect(
      sources.single.toString().contains('nonexistent_library.dart'),
      false,
    );
  });

  test('selected sources retain relative imports and part URIs', () async {
    final fixture = SdkTest('directory/import_test.dart', TestKind.runnable);
    const source = '''import 'helper.dart';
part 'part.dart';
void main() {
  if (helper() + partValue() != 3) throw StateError('imports');
  print(1); //# case: ok
}
''';
    final result = await runSdkTestCases(
      materializeSdkTests(fixture, source),
      (variant) => runSdkTestSources(variant, Compiler(), [
        DartSource(variant.uri, variant.source!),
        DartSource(
          'package:sdk_language/directory/helper.dart',
          'int helper() => 1;',
        ),
        DartSource(
          'package:sdk_language/directory/part.dart',
          "part of 'import_test.dart'; int partValue() => 2;",
        ),
      ]),
      negativeMode: 'skip',
    );
    expect(result.outcome, TestOutcome.passed);
  });
}
