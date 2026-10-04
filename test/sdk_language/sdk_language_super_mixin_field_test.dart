import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/model/source.dart';
import 'package:test/test.dart';

import 'sdk_language.dart';

void main() {
  test(
    'super reads a folded private mixin field fresh and serialized',
    () async {
      final test = SdkTest('mixin_private_field_super.dart', TestKind.runnable);
      final sources = [
        DartSource(test.uri, '''
mixin PrivateFieldMixin {
  int _foo = 40;
}

class PrivateFieldClass with PrivateFieldMixin {
  int get _foo => super._foo + 2;
}

void main() {
  final value = PrivateFieldClass()._foo;
  if (value != 42) {
    throw StateError('expected 42, got \$value');
  }
}
'''),
      ];
      final compiler = Compiler();
      setSdkEntrypoints(compiler, test, sources);
      final program = compiler.compileSources(sources);

      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        await executeSdkMain(runtime, test, sources);
      }
    },
  );
}
