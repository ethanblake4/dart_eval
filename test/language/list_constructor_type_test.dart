import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test(
    'typed list constructors reject invalid elements during construction',
    () {
      const source = '''
      int main() {
        dynamic wrong = 'wrong';
        var calls = 0;
        try {
          List<int>.generate(3, (i) {
            calls++;
            return i == 1 ? wrong : i;
          });
          return -1;
        } catch (_) {}
        if (calls != 2) return -2;
        try {
          List<int>.unmodifiable(<dynamic>[1, wrong]);
          return -3;
        } catch (_) {}
        dynamic missing = null;
        try {
          List<int>.generate(1, (i) => missing);
          return -4;
        } catch (_) {}
        try {
          List<int>.unmodifiable(<dynamic>[missing]);
          return -5;
        } catch (_) {}
        try {
          List<int>.filled(1, wrong);
          return -6;
        } catch (_) {}
        try {
          List<int>.from(<dynamic>[wrong]);
          return -7;
        } catch (_) {}
        dynamic elements = <dynamic>[wrong];
        try {
          List<int>.of(elements);
          return -8;
        } catch (_) {}
        return 0;
      }
    ''';
      for (final (mode, result) in runDynamicFixture(source)) {
        expect(result, const DynamicFixtureResult.value(0), reason: mode);
      }
    },
  );

  test('typed list constructors accept nullable and subtype elements', () {
    const source = '''
      int main() {
        final generated = List<num?>.generate(
          3, (i) => i == 0 ? null : i, growable: false);
        final immutable = List<num?>.unmodifiable(<dynamic>[null, 1, 2.5]);
        if (generated is! List<num?> || immutable is! List<num?>) return -1;
        if (generated[0] != null || generated[2] != 2 ||
            immutable[0] != null || immutable[2] != 2.5) return -2;
        try {
          generated.add(3);
          return -3;
        } catch (_) {}
        try {
          immutable[1] = 3;
          return -4;
        } catch (_) {}
        return 0;
      }
    ''';
    for (final (mode, result) in runDynamicFixture(source)) {
      expect(result, const DynamicFixtureResult.value(0), reason: mode);
    }
  });

  test('list constructors retain explicit and receiver type arguments', () {
    final program = Compiler().compile({
      'list_constructor_type': {
        'main.dart': '''
          class Maker<T> {
            List<T> make() => List<T>.empty(growable: true);
          }
          bool isIntList(dynamic value) => value is List<int>;
          int main() {
            if (!isIntList(List<int>.empty())) return -1;
            if (!isIntList(List<int>.filled(1, 2))) return -2;
            if (!isIntList(List<int>.from([2]))) return -3;
            if (!isIntList(List<int>.of([2]))) return -4;
            if (!isIntList(List<int>.generate(1, (i) => i))) return -5;
            if (!isIntList(List<int>.unmodifiable([2]))) return -6;
            if (isIntList(List<double>.empty())) return -7;
            if (isIntList(List.empty())) return -8;
            dynamic mutable = Maker<int>().make();
            if (!isIntList(mutable)) return -9;
            mutable.add(3);
            try {
              mutable.add('wrong');
              return -10;
            } catch (_) {}
            return mutable.length == 1 && mutable[0] == 3 ? 0 : -11;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:list_constructor_type/main.dart', 'main'),
        0,
      );
    }
  });
}
