import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';

import 'sdk_language.dart';
import 'shims.dart';

final _asyncHelperSource = DartSource(
  'package:expect/async_helper.dart',
  asyncHelperShim,
);

void main() {
  test('waits for an async SDK main to finish', () async {
    final test = SdkTest('async_main_test.dart', TestKind.runnable);
    final source = DartSource(test.uri, '''
Future<void> main() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  throw StateError('async main failure');
}
''');

    final outcome = await runSdkTestSources(test, Compiler(), [source]);

    expect(outcome, TestOutcome.failed);
  });

  test('waits for asyncTest launched by a synchronous main', () async {
    final sdkTest = SdkTest('async_test.dart', TestKind.runnable);
    final source = DartSource(sdkTest.uri, '''
import 'package:expect/async_helper.dart';
void main() {
  asyncTest(() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    throw StateError('async test failure');
  });
}
''');

    final outcome = await runSdkTestSources(
      sdkTest,
      Compiler(),
      [source, _asyncHelperSource],
    );

    expect(outcome, TestOutcome.failed);

    final sources = [source, _asyncHelperSource];
    final compiler = Compiler();
    setSdkEntrypoints(compiler, sdkTest, sources);
    final runtime = Runtime.ofProgram(compiler.compileSources(sources));
    await expectLater(
      executeSdkMain(runtime, sdkTest, sources),
      throwsA(
        predicate<Object>((e) => e.toString().contains('async test failure')),
      ),
    );
  });

  test('waits for manual asyncStart and asyncEnd', () async {
    final sdkTest = SdkTest('manual_async_test.dart', TestKind.runnable);
    final source = DartSource(sdkTest.uri, '''
import 'package:expect/async_helper.dart';
int completed = 0;
void main() {
  asyncStart(2);
  Future<void>.delayed(const Duration(milliseconds: 1)).then((_) {
    completed++;
    asyncEnd();
  });
  Future<void>.delayed(const Duration(milliseconds: 2)).then((_) {
    completed++;
    asyncEnd();
  });
}
int check() => completed;
''');
    final sources = [source, _asyncHelperSource];
    final compiler = Compiler();
    setSdkEntrypoints(compiler, sdkTest, sources);
    final runtime = Runtime.ofProgram(compiler.compileSources(sources));

    await executeSdkMain(runtime, sdkTest, sources);

    expect(runtime.executeLib(sdkTest.uri, 'check'), 2);
  });

  test('waits for unawaited asyncExpectThrows', () async {
    final sdkTest = SdkTest('async_throws_test.dart', TestKind.runnable);
    final source = DartSource(sdkTest.uri, '''
import 'package:expect/async_helper.dart';
void main() {
  asyncExpectThrows<StateError>(
    Future<void>.delayed(const Duration(milliseconds: 1)),
  );
}
''');

    final outcome = await runSdkTestSources(
      sdkTest,
      Compiler(),
      [source, _asyncHelperSource],
    );

    expect(outcome, TestOutcome.failed);
  });
}
