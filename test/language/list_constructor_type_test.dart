import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
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
