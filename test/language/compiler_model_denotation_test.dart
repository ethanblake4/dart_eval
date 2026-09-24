import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('generic tear-off owners distinguish same-named class methods', () {
    expect(
      eval('''
      class A { T id<T>(T value) => value; }
      class B { U id<U>(U value) => value; }
      bool main() {
        int Function(int) a = A().id;
        String Function(String) b = B().id;
        return a(3) == 3 && b('ok') == 'ok';
      }
    '''),
      true,
    );
  });

  test('a generic function context preserves generic callable parameters', () {
    expect(
      eval('''
      T identity<T>(T value) => value;
      bool main() {
        T Function<T>(T) direct = identity;
        final value = identity;
        T Function<T>(T) copied = value;
        return direct<int>(3) == 3 && copied<String>('ok') == 'ok';
      }
    '''),
      true,
    );
  });

  test('runtime generic optional specialization reports its limitation', () {
    expect(
      () => eval('''
      T? optional<T>([T? value]) => value;
      main() { final generic = optional; return generic<int>; }
    '''),
      throwsA(
        isA<CompileError>().having(
          (error) => error.toString(),
          'message',
          contains(
            'Instantiating a runtime function with optional parameters is not supported',
          ),
        ),
      ),
    );
    expect(
      eval('''
      T? optional<T>([T? value]) => value;
      bool main() {
        final selected = optional<int>;
        return selected() == null && selected(3) == 3;
      }
    '''),
      true,
    );
  });

  test('extension namespaces support static reads writes and calls', () {
    final program = Compiler().compile({
      'denotation': {
        'extension.dart': '''
          extension E on int {
            static int value = 1;
            static int get current => value;
            static set current(int next) { value = next; }
            static int twice(int value) => value * 2;
            int add(int value) => this + value;
          }
        ''',
        'main.dart': '''
          import 'extension.dart' as ext;
          bool main() {
            ext.E.current = 3;
            final twice = ext.E.twice;
            return ext.E.value == 3 && ext.E.current == 3 &&
                twice(2) == 4 && ext.E.twice(3) == 6 && ext.E.add(2, 3) == 5;
          }
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:denotation/main.dart', 'main'),
      true,
    );
  });

  test('terminating interpolations and rethrows retain valid SSA values', () {
    expect(
      eval(r'''
      int main() {
        try {
          try { throw 3; } catch (_) { rethrow; }
        } catch (value) {
          try { return '${throw value}'.length; } catch (again) { return again; }
        }
        return 0;
      }
    '''),
      3,
    );
  });

  test('explicit static generic tear-offs retain erased type arguments', () {
    expect(
      eval('''
      class A { static Type selected<T>() => T; }
      bool main() { final selected = A.selected<int>; return selected() == int; }
    '''),
      true,
    );
  });

  test('generic function values can be explicitly instantiated', () {
    expect(
      eval('''
      T identity<T>(T value) => value;
      bool main() {
        final generic = identity;
        final selected = generic<int>;
        return selected is int Function(int) && selected(3) == 3;
      }
    '''),
      true,
    );
  });

  test(
    'runtime generic adapters retain named arguments and captured values',
    () {
      expect(
        eval('''
      T identity<T>({required T value}) => value;
      T other<T>({required T value}) => throw 'wrong callable';
      bool main() {
        var generic = identity;
        final selected = generic<int>;
        generic = other;
        return selected(value: 3) == 3;
      }
    '''),
        true,
      );
    },
  );

  test('contextual generic method tear-offs preserve runtime overrides', () {
    expect(
      eval('''
      class A { T identity<T>(T value) => value; }
      class B extends A { T identity<T>(T value) => ((value as int) + 1) as T; }
      A make() => B();
      bool main() {
        final receiver = make();
        int Function(int) selected = receiver.identity;
        return selected is int Function(int) && selected(3) == 4;
      }
    '''),
      true,
    );
  });

  test('bound generic tear-offs retain distinct type arguments', () {
    final program = Compiler().compile({
      'denotation': {
        'main.dart': '''
      Type selected<T>() => T;
      bool main() {
        final integer = selected<int>;
        final string = selected<String>;
        return integer() == int && string() == String;
      }
    ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:denotation/main.dart', 'main'), true);
    }
  });

  test('explicit generic tear-offs carry their instantiated runtime type', () {
    expect(
      eval('''
      T identity<T>(T value) => value;
      bool main() {
        final identityInt = identity<int>;
        return identityInt is int Function(int) && identityInt(3) == 3;
      }
    '''),
      true,
    );
  });

  test('context specializes an exact receiver generic method tear-off', () {
    expect(
      eval('''
      class C { T identity<T>(T value) => value; }
      bool main() {
        int Function(int) identity = C().identity;
        return identity is int Function(int) && identity(3) == 3;
      }
    '''),
      true,
    );
  });

  test('explicit tear-off arguments survive an otherwise nongeneric shape', () {
    expect(
      eval('''
      Type selected<T>() => T;
      bool main() { final selectedInt = selected<int>; return selectedInt() == int; }
    '''),
      true,
    );
  });

  test('explicit generic instance tear-off uses the exact override', () {
    expect(
      eval('''
      class A { T identity<T>(T value) => value; }
      class B extends A { T identity<T>(T value) => ((value as int) + 1) as T; }
      bool main() {
        A receiver = B();
        final identity = receiver.identity<int>;
        return identity is int Function(int) && identity(3) == 4;
      }
    '''),
      true,
    );
  });

  test('extension tear-offs allow an inferred return type', () {
    expect(
      eval('''
      extension E on int { add(int value) => this + value; }
      main() { final add = 2.add; return add(3); }
    '''),
      5,
    );
  });

  test(
    'denotation reads instantiate generic function tear-offs from context',
    () {
      expect(
        eval('''
      T identity<T>(T value) => value;
      class Functions { static T identity<T>(T value) => value; }
      bool main() {
        double Function(double) top = identity;
        double Function(double) member = Functions.identity;
        return top(2.0) is double && member(3.0) is double;
      }
    '''),
        true,
      );
    },
  );

  test('extension method tear-offs are materialized as bound closures', () {
    expect(
      eval('''
      extension Offset on int {
        T identity<T>(T value) => value;
        int add(int value) => this + value;
      }
      bool main() {
        double Function(double) identity = 1.identity;
        final add = 2.add;
        return identity(3.0) is double && add(4) == 6;
      }
    '''),
      true,
    );
  });

  test('native property receivers keep their representation', () {
    expect(eval('int main() => [1, 2].length;'), 2);
    expect(eval("int main() => 'abc'.length;"), 3);
  });

  test('receiver classification preserves prefix and value chains', () {
    final program = Compiler().compile({
      'denotation': {
        'values.dart': '''
          class Value {
            final int number;
            Value(this.number);
            int read() => number;
            static Value make() => Value(3);
          }
          class Holder {
            final Value value;
            Holder(this.value);
          }
          Holder make() => Holder(Value(4));
        ''',
        'main.dart': '''
          import 'values.dart' as values;
          int main() {
            final holder = values.make();
            return holder.value.read() * 100 +
                holder.value.number * 10 + values.Value.make().number;
          }
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:denotation/main.dart', 'main'),
      443,
    );
  });

  test('explicit extension receivers retain their member selection', () {
    expect(
      eval('''
      class Value {
        int number = 1;
        int read() => 2;
      }
      extension Selected on Value {
        int get number => 3;
        set number(int next) { this.number = next + 1; }
        int read() => 4;
      }
      main() {
        final value = Value();
        Selected(value).number = 5;
        return Selected(value).number * 100 +
            Selected(value).read() * 10 + value.number;
      }
    '''),
      346,
    );
  });

  test('an imported extension application keeps its explicit selection', () {
    final program = Compiler().compile({
      'denotation': {
        'values.dart': '''
          class Value {
            int get number => 1;
            int read() => 2;
          }
          extension Selected on Value {
            int get number => 3;
            int read() => 4;
          }
        ''',
        'main.dart': '''
          import 'values.dart' as values;
          main() {
            final value = values.Value();
            return values.Selected(value).number * 10 +
                values.Selected(value).read();
          }
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:denotation/main.dart', 'main'),
      34,
    );
  });

  test('a method sharing an extension name is an ordinary value receiver', () {
    expect(
      eval('''
      class Value { int get number => 1; }
      class Factory { Value Selected() => Value(); }
      extension Selected on Value { int get number => 3; }
      int main() => Factory().Selected().number;
    '''),
      1,
    );
  });

  test('prefixed setter supplies the context type for a shorthand value', () {
    final program = Compiler().compile({
      'denotation': {
        'values.dart': '''
          enum Choice { first, second }
          Choice _value = Choice.first;
          int get value => _value.index;
          set value(Choice next) { _value = next; }
        ''',
        'main.dart': '''
          import 'values.dart' as values;
          int main() {
            values.value = .second;
            return values.value;
          }
        ''',
      },
    });
    expect(
      Runtime.ofProgram(
        program,
      ).executeLib('package:denotation/main.dart', 'main'),
      1,
    );
  });
}
