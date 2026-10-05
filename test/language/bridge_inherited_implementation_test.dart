import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

Program compile(String source) => Compiler().compile({
  'bridge_implementation': {'main.dart': source},
});

void check(String source, Object expected) {
  final program = compile(source);
  for (final candidate in [program, Program.read(program.write().buffer)]) {
    expect(
      Runtime.ofProgram(
        candidate,
      ).executeLib('package:bridge_implementation/main.dart', 'main'),
      expected,
    );
  }
}

void main() {
  test('inherited guest getter satisfies interface above bridged base', () {
    check('''
      import 'dart:collection';
      abstract class Contract { int get start; }
      class Progression extends IterableBase<int> {
        int get start => 4;
        Iterator<int> get iterator => [start, 5].iterator;
      }
      class Range extends Progression implements Contract {}
      int main() {
        Contract range = Range();
        return range.start + Range().toList().last;
      }
    ''', 9);
  });

  test(
    'guest implementations retain virtual dispatch and native iteration',
    () {
      check('''
      import 'dart:collection';
      abstract class Contract {
        int get start;
        set start(int value);
        int score();
      }
      class Progression extends IterableBase<int> {
        int value = 4;
        int get start => value;
        set start(int next) { value = next; }
        int score() => start + 1;
        Iterator<int> get iterator => [start, score()].iterator;
      }
      class Range extends Progression implements Contract {}
      class Override extends Range {
        int get start => super.start + 10;
        set start(int next) { super.start = next + 1; }
        int score() => super.score() + 100;
      }
      int inspect(Contract range) {
        range.start = 2;
        return range.start * 1000 + range.score();
      }
      int main() {
        final range = Override();
        return inspect(range) + range.toList().last;
      }
    ''', 13228);
    },
  );

  for (final (declaration, member) in [
    ('int get missing;', 'missing'),
    ('set missing(int value);', 'missing'),
    ('int missing();', 'missing'),
  ]) {
    test('bridged ancestor does not supply $declaration', () {
      expect(
        () => compile('''
          import 'dart:collection';
          abstract class Contract { $declaration }
          class Progression extends IterableBase<int> {
            Iterator<int> get iterator => [1].iterator;
          }
          class Invalid extends Progression implements Contract {}
          void main() {}
        '''),
        throwsA(
          isA<CompileError>().having(
            (error) => error.message,
            'message',
            'Missing concrete implementation of $member',
          ),
        ),
      );
    });
  }
}
