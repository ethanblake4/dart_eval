import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_instance.dart';
import '/home/ubuntu/repos/dart-eval/test/sdk_language/sdk_language.dart';

void main(List<String> args) async {
  final suite = await SdkSuite.load();
  final t = suite.classify(args[0]);
  stderr.writeln('kind: ${t.kind}');
  final sources = suite.collectSources(t);
  final compiler = Compiler();
  compiler.entrypoints.add('/${t.relPath}');
  final program = compiler.compileSources(sources);
  final runtime = Runtime(program.write().buffer);
  try {
    runtime.executeLib(t.uri, 'main');
    print('PASSED');
  } catch (e, st) {
    print('CAUGHT: ${e.runtimeType}');
    if (e is TypedInstance) {
      final tp = e.program;
      print('eval class: ${tp.classes[e.classId].name}');
      for (var i = 0; i < e.values.length; i++) {
        print('  value[$i]: ${e.values[i]}');
      }
    }
    print(st.toString().split('\n').take(8).join('\n'));
  }
}
