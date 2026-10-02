import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('map spread evidence adds no runtime instructions', () {
    Program program(String spreads) => Compiler().compile({
      'spread_kind': {
        'main.dart':
            '''
          int main() {
            Map<int, int> typed = {1: 2};
            dynamic unknown = typed;
            final value = {$spreads};
            return value.length;
          }
        ''',
      },
    });
    final mapFirst = program('...typed, ...unknown');
    final dynamicFirst = program('...unknown, ...typed');
    expect(
      dynamicFirst.typedProgram.instructions.length,
      lessThanOrEqualTo(mapFirst.typedProgram.instructions.length),
    );
  });
  test('later map spreads determine kind without evaluating guards early', () {
    final program = Compiler().compile({
      'spread_kind': {
        'main.dart': '''
          int calls = 0;
          dynamic mapping() { calls++; return <int, int>{1: calls}; }
          int main() {
            final Map<int, int> typed = {2: 3};
            final ordinary = {...mapping(), ...typed};
            if (ordinary[1] != 1 || ordinary[2] != 3 || calls != 1) return -1;
            final guarded = {if (false) ...mapping() else ...typed};
            if (guarded[2] != 3 || calls != 1) return -2;
            final loop = {for (int i = 0; i < 2; i++) ...mapping(), ...typed};
            if (loop[1] != 3 || loop[2] != 3 || calls != 3) return -3;
            final skipped = {for (int i = 0; i < 0; i++) ...mapping(), ...typed};
            if (skipped[2] != 3 || calls != 3) return -4;
            if (ordinary is! Map<dynamic, dynamic>) return -5;
            final shadowed = {for (var typed = <int>[7]; typed.isNotEmpty; typed = <int>[]) ...typed};
            if (shadowed is! Set<int> || !shadowed.contains(7)) return -6;
            return 0;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:spread_kind/main.dart', 'main'), 0);
    }
  });
  test('later typed calls and globals determine map spread kind', () {
    final program = Compiler().compile({
      'spread_kind': {
        'main.dart': '''
          Map<int, int> global = {2: 3};
          Map<int, int> get getter => {3: 4};
          Map<int, int> makeMap() => {4: 5};
          int main() {
            dynamic first = <int, int>{1: 2};
            final fromGlobal = {...first, ...global};
            final fromGetter = {...first, ...getter};
            final fromCall = {...first, ...makeMap()};
            dynamic makeMap = () => <int>{6};
            final shadowed = {...<int>{5}, ...makeMap()};
            return fromGlobal[2] == 3 &&
                    fromGetter[3] == 4 &&
                    fromCall[4] == 5 &&
                    shadowed is Set<int> && shadowed.contains(6) ? 0 : -1;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:spread_kind/main.dart', 'main'), 0);
    }
  });
}
