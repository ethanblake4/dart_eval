/// Runs the entire dart-lang/sdk `tests/language` suite under dart_eval.
/// Tagged `sdk-full` and excluded by `dart_test.yaml`, so plain `dart test`
/// stays fast; run explicitly with:
///
///   dart test -P sdk-full test/sdk_language/full_test.dart
@Tags(['sdk-full'])
library;

import 'package:test/test.dart';

import 'sdk_language.dart';

void main() async {
  final suite = await SdkSuite.load();
  registerSdkSuite('sdk_language full', suite.allTests(), suite);
}
