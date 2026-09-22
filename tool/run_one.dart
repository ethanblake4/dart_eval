// Usage: dart run tool/run_one.dart <relpath> -- compile+run one sdk_language
// test (e.g. 'dot_shorthands/simple/call_test.dart'), print PASSED or the
// compile/runtime error with a truncated stack. The test's kind and any
// unsupported reason print to stderr first.
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import '../test/sdk_language/sdk_language.dart';

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
    if (e is TypedInstance) {
      // Eval-land exceptions carry their receiver's field values inline —
      // dump them so a thrown condition (e.g. Expect._fail) shows its state.
      final tp = e.program;
      print('eval class: ${tp.classes[e.classId].name}');
      for (var i = 0; i < e.values.length; i++) {
        print('  value[$i]: ${e.values[i]}');
      }
    }
    print(st.toString().split('\n').take(12).join('\n'));
  }
}
