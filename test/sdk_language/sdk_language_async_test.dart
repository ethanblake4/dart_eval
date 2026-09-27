import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';

import 'sdk_language.dart';

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
}
