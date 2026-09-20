import 'package:dart_eval/src/eval/cli/bind.dart';

/// Regenerate the checked-in stdlib wrappers from `.dart_eval/bindgen.yaml`.
void main() {
  cliBindFromConfig('.dart_eval/bindgen.yaml');
}
