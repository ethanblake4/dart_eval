// Usage: dart run tool/eval_src.dart <file.dart> -- compile+run an arbitrary
// Dart file, print error + stack or PASSED.
import 'dart:io';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';

void main(List<String> args) {
  final compiler = Compiler();
  compiler.entrypoints.add('package:x/main.dart');
  try {
    // The first arg is the entrypoint (always package:x/main.dart); any extra
    // args are auxiliary sources named by basename.
    final sources = [
      for (final file in args)
        DartSource(
          file == args.first ? 'package:x/main.dart' : 'package:x/${file.split('/').last}',
          File(file).readAsStringSync(),
        ),
    ];
    final program = compiler.compileSources(sources);
    final runtime = Runtime(program.write().buffer);
    runtime.executeLib('package:x/main.dart', 'main');
    print('PASSED');
  } catch (e, st) {
    print('ERROR: $e');
    print(st.toString().split('\n').take(14).join('\n'));
  }
}
