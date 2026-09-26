import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:leaf/main.dart';

Program _compile(String source) => Compiler().compile({
  'leaf': {'main.dart': source},
});

void _expectResult(String source, Object? expected) {
  _expectProgramResult(_compile(source), expected);
}

void _expectProgramResult(Program program, Object? expected) {
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
      isNot(contains(anyOf('add', 'value='))),
    );
    _expectProgramResult(program, 18);
  });

  test(
    'mutable double fields use direct writes from a leaf and its methods',
    () {
      final program = _compile('''
      class Leaf {
        Leaf(this.value);
        double value;
        void increase(double amount) { value = value + amount; }
      }
      double apply(Leaf leaf) {
        leaf.value = leaf.value + 2.5;
        leaf.increase(1.25);
        return leaf.value;
      }
      double main() => apply(Leaf(1.5));
    ''');
      expect(
        program.typedProgram.callSites.map((site) => site.name),
        isNot(contains('value=')),
      );
      expect(
        program.typedProgram.instructions.map((entry) => entry.$2.name),
        contains(anyOf('setPropertyRF', 'setPropertySF', 'setPropertyCF')),
      );
      _expectProgramResult(program, 5.25);
    },
  );

  test('inherited mutable double field writes reach the owning link', () {
    final program = _compile('''
      class Base {
        Base(this.value);
        double value;
      }
      class Leaf extends Base {
        Leaf(double value) : super(value);
        void increase(double amount) { value = value + amount; }
      }
      double apply(Leaf leaf) {
        leaf.value = leaf.value + 2.5;
        leaf.increase(1.25);
        return leaf.value;
      }
      double main() => apply(Leaf(3));
    ''');
    expect(
      program.typedProgram.callSites.map((site) => site.name),
      isNot(contains('value=')),
    );
    _expectProgramResult(program, 6.75);
  });

  test('a real overriding setter takes precedence over inherited storage', () {
    _expectResult('''
      class Base {
        double value = 0;
      }
      class Leaf extends Base {
        set value(double next) { super.value = next * 2; }
      }
      double apply(Leaf leaf) {
        leaf.value = 2.5;
        return leaf.value;
      }
      double main() => apply(Leaf());
    ''', 5.0);
  });

  test('late final double fields still reject a second write', () {
    final program = _compile('''
      class Leaf {
        late final double value;
        void assign(double next) { value = next; }
      }
      bool main() {
        final leaf = Leaf();
        leaf.assign(1.5);
        try {
          leaf.assign(2.5);
          return false;
        } on StateError {
          return leaf.value == 1.5;
        }
      }
    ''');
    expect(
      program.typedProgram.instructions.map((entry) => entry.$2.name),
      contains('setLateFinalPropertyRS'),
    );
    _expectProgramResult(program, true);
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

  test('implicit generic field setter checks the receiver type', () {
    _expectResult('''
      class Box<T> {
        Box(this.value);
        T value;
      }
      bool rejects(Box<Object> box, dynamic invalid) {
        try {
          box.value = invalid;
        } on TypeError {
          return true;
        }
        return false;
      }
      bool main() {
        Box<Object> alias = Box<String>('safe');
        dynamic invalid = 42;
        var directRejected = false;
        try {
          alias.value = invalid;
        } on TypeError {
          directRejected = true;
        }
        final directSafe = directRejected && alias.value == 'safe';
        final other = Box<int>(7);
        final aliasSafe = rejects(alias, invalid) && alias.value == 'safe';
        final otherSafe = rejects(other, 'wrong') && other.value == 7;
        return directSafe && aliasSafe && otherSafe;
      }
    ''', true);
  });

  test('narrowed overriding field checks a base-typed write', () {
    _expectResult('''
      class Base {
        covariant Object value = 'base';
      }
      class Leaf extends Base {
        @override
        String value = 'safe';
      }
      bool main() {
        Base alias = Leaf();
        dynamic invalid = 42;
        var rejected = false;
        try {
          alias.value = invalid;
        } on TypeError {
          rejected = true;
        }
        return rejected && alias.value == 'safe';
      }
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
