import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:leaf/main.dart';

Program _compile(String source) => Compiler().compile({
  'leaf': {'main.dart': source},
});

void _expectResult(String source, Object? expected) {
  final program = _compile(source);
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('leaf parameter uses direct fields and method', () {
    final program = _compile('''
      class Leaf {
        Leaf(this.value);
        int value;
        int add(int amount) { value += amount; return value; }
      }
      int apply(Leaf leaf) {
        leaf.value = leaf.value + 3;
        return leaf.add(4) + leaf.value;
      }
      int main() => apply(Leaf(2));
    ''');
    expect(
      program.typedProgram.callSites.map((site) => site.name),
      isNot(contains('add')),
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib(_entrypoint, 'main'), 18);
    }
  });

  test('inherited field access and super method use the owning link', () {
    _expectResult('''
      class Base {
        Base(this.value);
        int value;
        int read() => value;
      }
      class Leaf extends Base {
        Leaf(int value) : super(value);
        int read() => super.read() + 2;
      }
      int apply(Leaf leaf) {
        leaf.value += 3;
        return leaf.value * 10 + leaf.read();
      }
      int main() => apply(Leaf(4));
    ''', 79);
  });

  test('subclass and interface getter overrides stay virtual', () {
    _expectResult('''
      class Base { int get value => 1; }
      class Derived extends Base { int get value => 5; }
      abstract class Readable { int get value; }
      class First implements Readable { int get value => 2; }
      class Second implements Readable { int get value => 7; }
      int fromBase(Base value) => value.value;
      int fromInterface(Readable value) => value.value;
      int main() =>
          fromBase(Base()) * 1000 + fromBase(Derived()) * 100 +
          fromInterface(First()) * 10 + fromInterface(Second());
    ''', 1527);
  });

  test('covariant generic setter rejects a narrowed value', () {
    _expectResult('''
      class Box<T> {
        T? stored;
        set value(T value) { stored = value; }
      }
      bool apply(Box<Object> box) {
        dynamic invalid = 3;
        try {
          box.value = invalid;
        } on TypeError {
          return box.stored == null;
        }
        return false;
      }
      bool main() => apply(Box<String>());
    ''', true);
  });

  test('nullable leaf method dispatch retains null behavior', () {
    _expectResult('''
      class Leaf { String toString() => 'leaf'; }
      String render(Leaf? leaf) => leaf.toString();
      bool main() => render(null) == 'null' && render(Leaf()) == 'leaf';
    ''', true);
  });
}
