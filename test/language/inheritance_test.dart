import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

TypedProgram compile(String source) => Compiler().compileTyped({
  'typed': {'main.dart': source},
}, entrypoint: 'package:typed/main.dart');

void check(String source, Object? expected) {
  final program = compile(source);
  expect(TypedMachine.run(program), expected);
  expect(TypedMachine.run(TypedProgram.read(program.write().buffer)), expected);
}

void main() {
  test('constructor fields and mutation survive serialized linking', () {
    check('''
      class Counter {
        int value;
        Counter(this.value);
        int add(int amount) { value = value + amount; return value; }
      }
      int main() {
        final counter = Counter(7);
        counter.value = 12;
        return counter.add(4) + counter.value;
      }
    ''', 32);
  });

  test('default constructors initialize fields', () {
    check('''
      class Counter { int value = 9; }
      int main() => Counter().value;
    ''', 9);
  });

  test('dynamic dispatch chooses the receiver class', () {
    check('''
      class First { int value(int n) => n + 1; }
      class Second { int value(int n) => n + 10; }
      int apply(dynamic receiver, int n) => receiver.value(n);
      int main() => apply(First(), 2) + apply(Second(), 3);
    ''', 16);
  });

  test('reassignment clears the previous exact receiver type', () {
    check('''
      class A { int m() => 1; }
      class B extends A { int m() => 2; }
      A choose() => B();
      int main() {
        A a = A();
        a = choose();
        return a.m();
      }
    ''', 2);
  });

  test('unrelated methods with the same name keep their own arity', () {
    check('''
      class First { int value(int n) => n + 1; }
      class Second { int value(int a, int b) => a * 10 + b; }
      int main() {
        dynamic first = First();
        dynamic second = Second();
        int a = first.value(2);
        int b = second.value(3, 4);
        return a + b;
      }
    ''', 37);
  });

  test('bound method tear-offs retain their receiver', () {
    check('''
      class Counter {
        int value;
        Counter(this.value);
        int add(int n) => value + n;
      }
      int main() {
        final counter = Counter(7);
        final add = counter.add;
        return add(4);
      }
    ''', 11);
  });

  test('dynamic calls invoke function fields and custom getters', () {
    final program = compile('''
      class Base { Function fn; Base(this.fn); }
      class Child extends Base {
        Child(Function fn) : super(fn);
        Function get callback => fn;
      }
      int main(Function fn) {
        dynamic child = Child(fn);
        int first = child.fn(4);
        int second = child.callback(7);
        return first + second;
      }
    ''');
    for (final p in [program, TypedProgram.read(program.write().buffer)]) {
      expect(
        TypedMachine.run(p, objectArguments: [(int value) => value + 1]),
        13,
      );
    }
  });

  test('method recursion preserves boxed arguments and scalar locals', () {
    check('''
      class Counter {
        int sum(int n) { if (n == 0) return 0; return n + sum(n - 1); }
      }
      int main() => Counter().sum(10);
    ''', 55);
  });

  test('virtual calls preserve repeated operands and overflow arguments', () {
    check('''
      class Counter {
        int combine(int a, int b, int c, int d) => a * 1000 + b * 100 + c * 10 + d;
      }
      int main() {
        final counter = Counter();
        var a = 2;
        var b = 3;
        return counter.combine(b, a, b, a) + a + b;
      }
    ''', 3237);
  });

  test('custom getters and void setters execute in typed frames', () {
    check('''
      class Counter {
        int stored = 0;
        int get value => stored + 1;
        set value(int n) { stored = n * 2; }
      }
      int main() { final counter = Counter(); counter.value = 7; return counter.value; }
    ''', 15);
  });

  test('inheritance resolves fields and overridden methods', () {
    check('''
      class Base {
        int value;
        Base(this.value);
        int read() => value;
      }
      class Child extends Base {
        Child(int value) : super(value);
        int read() => super.read() + 4;
      }
      int main() { final child = Child(8); return child.read() + child.value; }
    ''', 20);
  });

  test('inherited this preserves identity when returned and passed', () {
    check('''
      class Base {
        Object self() => this;
        Object throughCall() => identity(this);
      }
      class Child extends Base {}
      Object identity(Object value) => value;
      bool main() {
        dynamic child = Child();
        return child.self() == child && child.throughCall() == child;
      }
    ''', true);
  });

  test('concrete child resolves an inherited method', () {
    check('''
      class Base { int value = 6; int read() => value; }
      class Child extends Base {}
      int main() => Child().read();
    ''', 6);
  });

  test('super skips a superclass that inherits the requested method', () {
    check('''
      class Base { int value = 6; int read() => value; }
      class Middle extends Base {}
      class Child extends Middle { int read() => super.read() + 2; }
      int main() => Child().read();
    ''', 8);
  });

  test(
    'explicit this dispatches overrides while super keeps its field view',
    () {
      check('''
      class Base {
        int value = 2;
        int read() => this.value;
      }
      class Child extends Base {
        int value = 9;
        int readParent() => super.read();
      }
      int main() => Child().readParent();
    ''', 9);
    },
  );

  test('implicit fields dispatch to the most derived getter', () {
    check('''
      class Base { int value = 2; int read() => value; }
      class Child extends Base { int value = 9; }
      int main() => Child().read();
    ''', 9);
  });

  test('super field reads and writes use the lexical superclass', () {
    check('''
      class Base { int value = 2; }
      class Middle extends Base {}
      class Child extends Middle {
        int value = 9;
        int update() { super.value = 5; return super.value * 10 + value; }
      }
      int main() => Child().update();
    ''', 59);
  });

  test('super custom getter and setter bypass derived overrides', () {
    check('''
      class Base {
        int stored = 2;
        int get value => stored + 1;
        set value(int n) { stored = n * 2; }
      }
      class Child extends Base {
        int value = 9;
        int update() { super.value = 5; return super.value * 10 + value; }
      }
      int main() => Child().update();
    ''', 119);
  });

  test('super getter uses a mixin member before the superclass', () {
    check('''
      class Base { int get value => 1; }
      mixin Extra { int get value => 3; }
      class Combined extends Base with Extra {
        int read() => super.value;
      }
      int main() => Combined().read();
    ''', 3);
  });

  test('virtual receiver survives loop phis across different classes', () {
    check('''
      class First { int value(int n) => n + 1; }
      class Second { int value(int n) => n + 3; }
      int main() {
        final first = First(); final second = Second();
        dynamic receiver = first;
        var sum = 0;
        for (var i = 0; i < 10; i++) {
          if (i % 2 == 0) { receiver = first; } else { receiver = second; }
          int value = receiver.value(i);
          sum += value;
        }
        return sum;
      }
    ''', 65);
  });
}
