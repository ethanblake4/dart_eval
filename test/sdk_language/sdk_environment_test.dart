import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';

import 'sdk_language.dart';

void main() {
  test(
    'SharedOptions definitions reach const and runtime imported calls',
    () async {
      final test = SdkTest('environment.dart', TestKind.runnable);
      final compiler = Compiler();
      final result = await runSdkTestSources(test, compiler, [
        DartSource(test.uri, '''
// SharedOptions=-Dempty= -Dflag=true -Dcount=0x20 -Dinvalid=maybe -Dfalse=false
import 'environment_helper.dart';
void main() {
  if (!const bool.hasEnvironment('empty')) throw 'empty is defined';
  if (const String.fromEnvironment('empty', defaultValue: 'fallback') != '') {
    throw 'empty string value';
  }
  if (const int.fromEnvironment('count') != 32) throw 'integer value';
  if (!const bool.fromEnvironment('invalid', defaultValue: true)) {
    throw 'invalid boolean default';
  }
  if (const bool.fromEnvironment('false', defaultValue: true)) {
    throw 'false overrides default';
  }
  if (!readFlag()) throw 'imported runtime lookup';
  if (!const bool.fromEnvironment('dart.library.core')) throw 'host core';
}
'''),
        DartSource('package:sdk_language/environment_helper.dart', '''
bool readFlag() => bool.fromEnvironment('flag');
'''),
      ]);
      expect(result, TestOutcome.passed);

      // Reuse the compiler with a fresh runtime: definitions belong to a fixture.
      expect(
        await runSdkTestSources(test, compiler, [
          DartSource(test.uri, '''
void main() {
  if (const bool.hasEnvironment('flag')) throw 'definition leaked';
}
'''),
        ]),
        TestOutcome.passed,
      );
    },
  );

  test(
    'SDK environment fixtures pass with their declared definitions',
    () async {
      final suite = await SdkSuite.load();
      final compiler = Compiler();
      for (final path in [
        'bool/has_environment_test.dart',
        'library/env_test.dart',
        'dot_shorthands/language_defined/bool_from_environment_test.dart',
      ]) {
        expect(
          await runSdkTest(suite, suite.classify(path), compiler),
          TestOutcome.passed,
          reason: path,
        );
      }
    },
  );
}
