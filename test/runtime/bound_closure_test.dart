import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _library = 'package:bound_closure/main.dart';

void _expectBoundResult(String source, Object expected) {
  final program = Compiler().compile({
    'bound_closure': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_library, 'main'), expected);
  }
}

void main() {
  test('bound methods keep their receiver and all positional arguments', () {
    _expectBoundResult('''
      class Counter {
        Counter(this.base);
        final int base;
        int touched = 0;
        int zero() => base + 1;
        int one(int a) => base + a;
        int two(int a, int b) => base + a * 10 + b;
        int many(int a, int b, int c, int d) =>
            base + a * 1000 + b * 100 + c * 10 + d;
        void touch(int value) { touched = value + 1; }
      }
      int main() {
        final counter = Counter(10);
        dynamic unknown = counter;
        final callbacks = <Function>[
          counter.zero, unknown.one, counter.two, unknown.many,
          counter.touch,
        ];
        final sum = (callbacks[0]() as int) +
            (callbacks[1](2) as int) +
            (callbacks[2](3, 4) as int) +
            (callbacks[3](1, 2, 3, 4) as int);
        callbacks[4](6);
        return sum + counter.touched;
      }
    ''', 1318);
  });

  test('named arguments retain order and omitted defaults', () {
    _expectBoundResult('''
      class Formatter {
        int format(int head, {int z = 3, int a = 4}) =>
            head * 10000 + z * 100 + a;
        int optional(int first, [int second = 5]) => first * 100 + second;
      }
      int main() {
        final formatter = Formatter();
        dynamic unknown = formatter;
        final callbacks = <Function>[
          formatter.format, unknown.format, formatter.optional,
        ];
        return (callbacks[0](1, z: 7, a: 8) as int) +
            (callbacks[1](2, a: 8, z: 7) as int) +
            (callbacks[1](3, a: 9) as int) +
            (callbacks[2](4) as int);
      }
    ''', 62130);
  });

  test('a base-typed tear-off invokes the derived receiver', () {
    _expectBoundResult('''
      class Base {
        Base(this.bias);
        final int bias;
        int score(int value) => bias + value;
      }
      class Child extends Base {
        Child() : super(4);
        @override
        int score(int value) => bias * 10 + value;
      }
      int main() {
        Base view = Child();
        dynamic unknown = view;
        final callbacks = <Function>[view.score, unknown.score];
        return (callbacks[0](2) as int) * 100 +
            (callbacks[1](3) as int);
      }
    ''', 4243);
  });

  test('bound calls reject covariant and generic parameter mismatches', () {
    _expectBoundResult('''
      class Base {
        int accept(num value) => 0;
      }
      class Child extends Base {
        @override
        int accept(covariant int value) => value + 1;
      }
      class Box<T> {
        T keep(T value) => value;
      }
      int main() {
        Base view = Child();
        Box<num> box = Box<int>();
        final callbacks = <Function>[view.accept, box.keep];
        var score = (callbacks[0](2) as int) + (callbacks[1](3) as int);
        try { callbacks[0](2.5); } on TypeError { score += 10; }
        try { callbacks[1](3.5); } on TypeError { score += 100; }
        return score;
      }
    ''', 116);
  });

  test('bound callback failures unwind through caller catch and finally', () {
    _expectBoundResult('''
      int finalizations = 0;
      class Worker {
        int run(String text) {
          if (text == 'bad') throw 'boom';
          return text.length;
        }
      }
      int invoke(Function callback, String text) {
        final prefix = 10;
        try {
          return prefix + (callback(text) as int);
        } catch (error) {
          return prefix + (error as String).length * 2;
        } finally {
          finalizations++;
        }
      }
      int main() {
        final callbacks = <Function>[Worker().run];
        return invoke(callbacks[0], 'ok') * 100 +
            invoke(callbacks[0], 'bad') * 10 + finalizations;
      }
    ''', 1382);
  });
}
