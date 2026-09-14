import 'package:dart_eval/src/eval/compiler/backend/representation.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('throwing an unboxed parameter preserves boxed exception ABI', () {
    final compiler = Compiler();
    compiler.compile({
      'example': {
        'main.dart': """
     int main(int log) {
       try { throw log; }
       finally { log += 1; }
     }
   """,
      },
    });
    for (final entry in compiler.ssaFunctionGraphs.entries) {
      analyzeRepresentations(
        entry.value,
        functions: compiler.functionSignatures,
        functionId: entry.key,
      );
    }
  });

  test('return preserves its representation across handler normalization', () {
    expect(
      eval("""
     String value() {
       var log = 'start';
       try { log += ' try'; return log; }
       finally { log += ' finally'; }
     }
     int main() => value().length;
   """),
      9,
    );
  });
  test('throw preserves the local value across handler normalization', () {
    expect(
      eval("""
     String value(String log) {
       try { log += ' try'; throw log; }
       catch (e) { return e.toString(); }
     }
     String main() => value('start');
   """),
      'start try',
    );
  });
}
