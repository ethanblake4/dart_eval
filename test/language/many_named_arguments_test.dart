import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';
import '../sdk_language/sdk_language.dart';

void main() {
  test('Function.apply preserves named arguments of bound methods', () {
    final program = Compiler().compile({
      'bound_apply': {
        'main.dart': '''
          class C {
            final int offset;
            C(this.offset);
            int method(int first, {int last = 3, int middle = 2}) =>
                offset + first * 100 + middle * 10 + last;
          }
          int main() {
            final method = C(1000).method;
            return Function.apply(method, [4], {#last: 6, #middle: 5}) +
                Function.apply(method, [7]);
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:bound_apply/main.dart', 'main'), 3179);
    }
  });
  test('pinned many_named_arguments runs fresh and serialized', () async {
    final suite = await SdkSuite.load();
    final fixture = suite.classify('unsorted/many_named_arguments_test.dart');
    final sources = suite.collectSources(fixture);
    final compiler = Compiler();
    setSdkEntrypoints(compiler, fixture, sources);
    final program = compiler.compileSources(sources);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      await executeSdkMain(runtime, fixture, sources);
    }
  });
}
