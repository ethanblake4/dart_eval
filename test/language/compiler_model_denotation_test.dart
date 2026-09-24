import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
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
