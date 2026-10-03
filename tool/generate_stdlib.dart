import 'package:dart_eval/src/eval/cli/bind.dart';

/// Regenerate the checked-in stdlib wrappers from `.dart_eval/bindgen.yaml`.
Future<void> main(List<String> arguments) async {
  await cliBindFromConfig(
    '.dart_eval/bindgen.yaml',
    outputFiles: arguments.isEmpty ? null : arguments.toSet(),
  );
}
