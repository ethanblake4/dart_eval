import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('late error names survive inherited private access and encoding', () {
    final program = Compiler().compile({
      'late_fields': {
        'main.dart': '''
        late final int top;
        class Base { late final int _value; }
        class Child extends Base {}
        bool fails(Function action, String message) {
          try { action(); } catch (error) {
            return error is Error && error.toString() == message;
          }
          return false;
        }
        bool main() {
          dynamic child = Child();
          if (!fails(() => child._value,
              "LateInitializationError: Field '_value' has not been initialized.")) return false;
          child._value = 7;
          if (!fails(() => child._value = 8,
              "LateInitializationError: Field '_value' has already been initialized.")) return false;
          if (!fails(() => top,
              "LateInitializationError: Field 'top' has not been initialized.")) return false;
          top = 9;
          return child._value == 7 && top == 9 && fails(() => top = 10,
              "LateInitializationError: Field 'top' has already been initialized.");
        }
      ''',
      },
    });
    for (final candidate in [program, Program.read(program.write().buffer)]) {
      expect(
        Runtime.ofProgram(
          candidate,
        ).executeLib('package:late_fields/main.dart', 'main'),
        true,
      );
    }
  });
  test('discarded property reads preserve getter side effects', () {
    final program = Compiler().compile({
      'late_fields': {
        'main.dart': '''
        int calls = 0;
        class Counter {
          int get value { calls++; return calls; }
        }
        int main() {
          final counter = Counter();
          counter.value;
          counter.value;
          return calls;
        }
      ''',
      },
    });
    for (final candidate in [program, Program.read(program.write().buffer)]) {
      expect(
        Runtime.ofProgram(
          candidate,
        ).executeLib('package:late_fields/main.dart', 'main'),
        2,
      );
    }
  });
  test('late field state survives reads and distinguishes assigned null', () {
    final program = Compiler().compile({
      'late_fields': {
        'main.dart': '''
        class Fields {
          late int mutable;
          late final int? once;
          late final int initialized;
          Fields() : initialized = 7;
        }
        int main() {
          final a = Fields();
          final b = Fields();
          int result = 0;
          try { a.mutable; } catch (e) { result += 1; }
          try { a.once; } catch (e) { result += 2; }
          a.mutable = 3;
          a.mutable = 5;
          a.once = null;
          if (a.once == null) result += 4;
          try { a.once = 9; } catch (e) { result += 8; }
          if (a.once == null) result += 16;
          try { a.initialized = 10; } catch (e) { result += 32; }
          try { b.mutable; } catch (e) { result += 64; }
          b.once = 11;
          return result + a.mutable + a.initialized + b.once!;
        }
      ''',
      },
    });
    for (final candidate in [program, Program.read(program.write().buffer)]) {
      expect(
        Runtime.ofProgram(
          candidate,
        ).executeLib('package:late_fields/main.dart', 'main'),
        150,
      );
    }
  });

  test(
    'late final assignments commit only after their expression succeeds',
    () {
      final program = Compiler().compile({
        'late_fields': {
          'main.dart': '''
        class Parent {
          late final int value;
        }
        class Child extends Parent {
          Child(int input) { value = input; }
        }
        int fail() { throw 'failed'; }
        int main() {
          final value = Parent();
          try { value.value = fail(); } catch (e) {}
          value.value = 17;
          return value.value + Child(6).value;
        }
      ''',
        },
      });
      for (final candidate in [program, Program.read(program.write().buffer)]) {
        expect(
          Runtime.ofProgram(
            candidate,
          ).executeLib('package:late_fields/main.dart', 'main'),
          23,
        );
      }
    },
  );
}
