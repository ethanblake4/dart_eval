import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'sdk_language.dart';

SuiteConfig config([String minimum = "min_sdk: '3.0'"]) =>
    SuiteConfig.fromYaml('sdk_commit: fixture\ncore: []\n$minimum\n');

void main() {
  test(
    'minimum version defaults to Dart 3 and compares numeric components',
    () {
      expect(config('').minSdk, (major: 3, minor: 0));
      final minimum = config("min_sdk: '3.9'");
      expect(
        minimum.unsupportedLanguageVersion('// @dart=3.10\nvoid main() {}'),
        isNull,
      );
      expect(
        minimum.unsupportedLanguageVersion('// @dart=3.8\nvoid main() {}'),
        contains('3.8 is below min_sdk 3.9'),
      );
    },
  );

  test('minimum version requires a quoted major.minor value', () {
    for (final value in [
      '3.0',
      "'3'",
      "'3.0.0'",
      "'v3.0'",
      "'-1.0'",
      'null',
      'true',
    ]) {
      expect(
        () => config('min_sdk: $value'),
        throwsFormatException,
        reason: value,
      );
    }
  });

  test('only recognized leading language overrides affect classification', () {
    final minimum = config();
    for (final source in [
      'void main() {}',
      '// @dart=3.0\nvoid main() {}',
      '// @dart=3.8\nvoid main() {}',
      '// @dart=3.9\nvoid main() {}',
      '// @dart=3.10\nvoid main() {}',
      '// Example: @dart=2.17\nvoid main() {}',
      '/// @dart=2.17\nvoid main() {}',
      '/* // @dart=2.17 */\nvoid main() {}',
      "void main() { print('// @dart=2.17'); }",
      'void main() {}\n// @dart=2.17',
      '// @dart=2.17 trailing text\nvoid main() {}',
    ]) {
      expect(
        minimum.unsupportedLanguageVersion(source),
        isNull,
        reason: source,
      );
    }
    for (final version in ['2.17', '2.18']) {
      expect(
        minimum.unsupportedLanguageVersion(
          '// copyright\n// @dart=$version\n'
          'void main() {}',
        ),
        'language version $version is below min_sdk 3.0',
      );
    }
  });

  group('fixture classification', () {
    late Directory checkout;
    late SdkSuite suite;

    void source(String relativePath, String contents) {
      final file = File(p.join(suite.languageRoot, relativePath));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(contents);
    }

    setUp(() {
      checkout = Directory.systemTemp.createTempSync('sdk-language-version-');
      suite = SdkSuite(config(), checkout);
    });

    tearDown(() => checkout.deleteSync(recursive: true));

    test(
      'old roots are unsupported before negative and import classification',
      () {
        source(
          'old.dart',
          '// @dart=2.17\n'
              "import 'helper.dart';\n"
              'void main() {} // [analyzer] COMPILE_TIME_ERROR\n',
        );
        source('helper.dart', 'int value() => 1;');
        final fixture = suite.classify('old.dart');
        expect(fixture.kind, TestKind.unsupported);
        expect(
          fixture.unsupportedReason,
          'language version 2.17 is below min_sdk 3.0',
        );
      },
    );

    test('a root whose main is in a part retains the version skip reason', () {
      source('old_part.dart', '// @dart=2.18\npart "main_part.dart";');
      source('main_part.dart', 'part of "old_part.dart";\nvoid main() {}');
      final fixture = suite.classify('old_part.dart');
      expect(fixture.kind, TestKind.unsupported);
      expect(fixture.unsupportedReason, contains('2.18 is below min_sdk 3.0'));
    });

    test('all selected multitest variants honor their source override', () {
      for (final version in ['2.18', '3.0', '3.10']) {
        source(
          'multi.dart',
          '// @dart=$version\nvoid main() {\n'
              '  print(1); //# ok: ok\n'
              '  throw 2; //# error: runtime error\n}\n',
        );
        final cases = suite.variants(SdkTest('multi.dart', TestKind.runnable));
        expect(cases.map((test) => test.variantKey), ['none', 'ok', 'error']);
        if (version == '2.18') {
          expect(
            cases.every((test) => test.kind == TestKind.unsupported),
            true,
          );
          expect(
            cases.every(
              (test) =>
                  test.unsupportedReason ==
                  'language version 2.18 is below min_sdk 3.0',
            ),
            true,
          );
          expect(suite.classify('multi.dart').kind, TestKind.unsupported);
        } else {
          expect(cases.map((test) => test.kind), [
            TestKind.runnable,
            TestKind.runnable,
            TestKind.runtimeError,
          ]);
        }
      }
    });

    test('materialization determines whether an override is leading', () {
      source(
        'mixed.dart',
        'int value = 1; //# modern: ok\n'
            '// @dart=2.17\nvoid main() {}',
      );
      final fixture = suite.classify('mixed.dart');
      expect(fixture.kind, TestKind.runnable);
      final cases = suite.variants(fixture);
      expect(cases.map((test) => test.variantKey), ['none', 'modern']);
      expect(cases.first.kind, TestKind.unsupported);
      expect(
        cases.first.unsupportedReason,
        'language version 2.17 is below min_sdk 3.0',
      );
      expect(cases.last.kind, TestKind.runnable);
    });

    test('relative old helpers skip modern roots during source collection', () {
      source(
        'modern.dart',
        '// @dart=3.0\n'
            "import 'helper.dart';\nvoid main() { value(); }",
      );
      source('helper.dart', '// @dart=2.17\nint value() => 1;');
      final fixture = suite.classify('modern.dart');
      expect(fixture.kind, TestKind.runnable);
      expect(
        () => suite.collectSources(fixture),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'reason',
            'helper.dart: language version 2.17 is below min_sdk 3.0',
          ),
        ),
      );
      source('helper.dart', 'int value() => 1;');
      expect(suite.collectSources(fixture), hasLength(2));
    });

    test('vendored package helpers retain their existing language handling', () {
      source(
        'modern.dart',
        '// @dart=3.0\n'
            "import 'package:expect/static_type_helper.dart';\nvoid main() {}",
      );
      final helper = File(p.join(suite.expectRoot, 'static_type_helper.dart'));
      helper.parent.createSync(recursive: true);
      helper.writeAsStringSync('// @dart=2.17\nType typeOf<T>() => T;');
      final fixture = suite.classify('modern.dart');
      expect(fixture.kind, TestKind.runnable);
      expect(suite.collectSources(fixture), hasLength(2));
    });
  });
}
