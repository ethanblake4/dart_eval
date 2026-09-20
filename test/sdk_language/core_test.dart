/// Runs the "core" subset of the dart-lang/sdk language tests — the fast
/// set to exercise while developing a feature. The full suite is
/// `full_test.dart` (tagged `sdk-full`, excluded from default `dart test`).
library;

import 'sdk_language.dart';

void main() async {
  final suite = await SdkSuite.load();
  registerSdkSuite('sdk_language core', suite.coreTests(), suite);
}
