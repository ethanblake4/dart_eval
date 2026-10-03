import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('late receiver facts survive reads and expire on captured writes', () {
    final program = Compiler().compile({
      'late_facts': {
        'main.dart': '''
          class C {
            final Object _field;
            C(this._field);
          }
          extension IntTag on int { String get tag => 'int'; }
          extension ObjectTag on Object { String get tag => 'object'; }
          String deferred() {
            var c = C(1);
            if (c._field is int) {
              late var tag = c._field.tag;
              c = C('changed');
              return tag;
            }
            return 'missed';
          }
          String main() {
            late final c = C(1);
            if (c._field is int) return c._field.tag + ':' + deferred();
            return 'missed';
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:late_facts/main.dart', 'main'),
        'int:object',
      );
    }
  });

  test(
    'late initializers share captured state across retries and handlers',
    () {
      final program = Compiler().compile({
        'late_local': {
          'main.dart': '''
        int main() {
          int calls = 0;
          int source = 1;
          late int retry = () {
            calls++;
            if (calls == 1) throw 'retry';
            return source;
          }();
          source = 7;
          try { retry; } catch (_) { source = 9; }
          if (retry != 9 || calls != 2) return 1;
          source = 20;
          if (retry != 9 || calls != 2) return 2;

          late int retained = () {
            retained = 42;
            throw 'written';
          }();
          try { retained; } catch (_) {}
          if (retained != 42) return 3;
          late final int once;
          try { once = 5; } finally { source = once; }
          try { once = 6; return 4; } catch (_) {}
          return source == 5 && once == 5 ? 0 : 5;
        }
      ''',
        },
      });
      for (final candidate in [program, Program.read(program.write().buffer)]) {
        expect(
          Runtime.ofProgram(
            candidate,
          ).executeLib('package:late_local/main.dart', 'main'),
          0,
        );
      }
    },
  );
}
