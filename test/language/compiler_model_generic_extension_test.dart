import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('generic extension methods keep their type parameter in scope', () {
    // The padding puts `score` at source offset 80, the same as its generated
    // function ID in this fixture. Those identifiers must not share an owner.
    const source =
        'class Box<T> {} '
        'extension BoxOps<T> on Box<T> { '
        '                                '
        'int score([int extra = 3]) => (T == int ? 10 : 0) + extra; '
        'T operator +(T value) => value; '
        '} '
        'int main() { '
        'final box = Box<int>(); '
        'return box.score() + BoxOps(box).score(4) + (box + 5); '
        '}';
    final program = Compiler().compile({
      'binding': {'main.dart': source},
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:binding/main.dart', 'main'),
      32,
    );
  });
}
