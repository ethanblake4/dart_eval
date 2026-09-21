// Usage: dart run /tmp/run_one.dart <relpath> -- compile+run one sdk test, print the error
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import '/home/ubuntu/repos/dart-eval/test/sdk_language/sdk_language.dart';

void main(List<String> args) async {
  final suite = await SdkSuite.load();
  final t = suite.classify(args[0]);
  stderr.writeln('kind: ${t.kind} ${t.unsupportedReason ?? ''}');
  final sources = suite.collectSources(t);
  final compiler = Compiler();
  compiler.entrypoints.add('/${t.relPath}');
  try {
    final program = compiler.compileSources(sources);
    final runtime = Runtime(program.write().buffer);
    runtime.executeLib(t.uri, 'main');
    print('PASSED');
  } catch (e, st) {
    print('ERROR: $e');
    print(st.toString().split('\n').take(12).join('\n'));
  }
}
