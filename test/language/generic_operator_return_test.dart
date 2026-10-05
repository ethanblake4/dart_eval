import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('operator result retains the enclosing class parameter', () {
    final program = Compiler().compile({
      'operator_return': {
        'main.dart': r'''
class Pair<T> {
  Pair(this.first, this.last);
  final T first;
  final T last;
}
class Items<T extends num> {
  Items(this.value);
  final T value;
  Items<T> operator +(Items<T> other) => other;
  Items<T> moved() {
    final Pair<Items<T>> lists = Pair<Items<T>>(this, this);
    return lists.last + lists.first;
  }
  Items<T> checked(dynamic other) => this + other;
  Items<U> combine<U extends num>(Items<U> other) => other + other;
}
bool main() {
  final items = Items<int>(7);
  if (items.moved() is! Items<int> || items.moved().value != 7) return false;
  if (items.combine<double>(Items<double>(1.5)) is! Items<double>) return false;
  try {
    items.checked(Items<double>(1.5));
    return false;
  } on TypeError {}
  return true;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:operator_return/main.dart', 'main'), true);
    }
  });

  test('operator return still rejects a different type argument', () {
    expect(
      () => Compiler().compile({
        'operator_negative': {
          'main.dart': r'''
class Items<T extends num> {
  Items();
  Items<double> operator +(Items<T> other) => Items<double>();
  Items<T> wrong() => this + this;
}
void main() {}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
