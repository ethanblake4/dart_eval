import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';

import 'sdk_language.dart';

void main() {
  test(
    'runtime-error fixture still reports an unrelated syntax error',
    () async {
      final test = SdkTest.variant(
        'main/no_main_test.dart',
        TestKind.runtimeError,
        variantKey: '01',
        source: 'void broken() { int value = ; }',
      );

      expect(await _run(test), TestOutcome.compileError);
    },
  );

  test(
    'runtime-error fixture with main still reports a syntax error',
    () async {
      final test = SdkTest.variant(
        'main/no_main_test.dart',
        TestKind.runtimeError,
        variantKey: '01',
        source: 'void main() {} int broken = ;',
      );

      expect(await _run(test), TestOutcome.compileError);
    },
  );
}

Future<TestOutcome> _run(SdkTest test, [String? source]) {
  return runSdkTestSources(test, Compiler(), [
    DartSource(test.uri, source ?? test.source!),
  ]);
}
