import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
void main(List<String> args) async {
  final compiler = Compiler();
  compiler.entrypoints.add('package:x/main.dart');
  try {
    final src = File(args[0]).readAsStringSync();
    final program = compiler.compileSources([
      DartSource('package:x/main.dart', src),
    ]);
    final runtime = Runtime(program.write().buffer);
    await runtime.executeLib('package:x/main.dart', 'main');
    print('PASSED');
  } catch (e, st) {
    print('ERROR: $e');
    print(st.toString().split('\n').take(14).join('\n'));
  }
}
