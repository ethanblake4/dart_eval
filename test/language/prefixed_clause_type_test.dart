import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test(
    'prefixed generic superclass participates in extension applicability',
    () {
      final program = Compiler().compile({
        'prefixed_clause': {
          'base.dart': '''
abstract class Value<T> { T get value; }
class Base<T> implements Value<T> {
  final T value;
  Base(this.value);
}
''',
          'leaf.dart': '''
import 'base.dart' hide Base;
import 'base.dart' as p;
class Leaf<T> extends p.Base<T> {
  Leaf(T value) : super(value);
}
''',
          'main.dart': '''
import 'base.dart' show Value;
import 'leaf.dart';
extension Read<T> on Value<T> { T read() => value; }
int main() => Leaf<int>(7).read();
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:prefixed_clause/main.dart', 'main'),
          7,
        );
      }
    },
  );

  test('separate show imports retain both inherited interfaces', () {
    final program = Compiler().compile({
      'prefixed_clause': {
        'base.dart': '''
abstract class A { int get a; }
abstract class B { int get b; }
''',
        'leaf.dart': '''
import 'base.dart' show A;
import 'base.dart' show B;
class Leaf implements A, B {
  int get a => 3;
  int get b => 4;
}
int read() {
  B value = Leaf();
  return Leaf().a + value.b;
}
''',
        'main.dart': '''
import 'leaf.dart';
int main() => read();
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:prefixed_clause/main.dart', 'main'),
        7,
      );
    }
  });

  for (final import in [
    "import 'base.dart' as p hide Base;",
    "import 'base.dart' as other;",
  ]) {
    test('unresolved prefixed superclass remains rejected: $import', () {
      expect(
        () => Compiler().compile({
          'prefixed_clause': {
            'base.dart': 'class Base {}',
            'leaf.dart': '$import class Leaf extends p.Base {}',
            'main.dart': "import 'leaf.dart'; Object main() => Leaf();",
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
