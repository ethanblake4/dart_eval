import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
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
