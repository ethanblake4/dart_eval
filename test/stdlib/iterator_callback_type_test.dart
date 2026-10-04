import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test('iterator witnesses survive generic native and guest callbacks', () {
    final program = Compiler().compile({
      'probe': {
        'main.dart': '''
bool advance(Iterator<int> value) => value.moveNext();
bool check<T>(Iterable<Iterable<T>> values) {
  final iterators = values.map((e) => e.iterator).toList();
  return iterators.every((e) => e.moveNext()) &&
      iterators.every((e) => e.current is T);
}
class Single<T> extends Iterator<T> {
  Single(this.value);
  final T value;
  T get current => value;
  bool moveNext() => true;
}
bool main(dynamic nativeCallback) {
  if (!check<int>(<Iterable<int>>[<int>[1], <int>[2]])) return false;
  if (!check<String>(<Iterable<String>>[<String>['x']])) return false;
  if (!<Iterator<int>>[<int>[3].iterator].every(advance)) return false;
  if (!<Iterator<int>>[Single<int>(4)].every(advance)) return false;
  if (!<Iterator<int>>[<int>[5].iterator].every(nativeCallback)) return false;
  dynamic wrong = <String>['wrong'].iterator;
  try { advance(wrong); return false; } on TypeError {}
  dynamic wrongGuest = Single<String>('wrong');
  try { advance(wrongGuest); return false; } on TypeError {}
  return true;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:probe/main.dart',
          'main',
          arguments: {
            'nativeCallback': (Iterator<Object?> value) => value.moveNext(),
          },
        ),
        isTrue,
      );
    }
  });

  test('incompatible iterator type is rejected at compile time', () {
    expect(
      () => Compiler().compile({
        'probe': {
          'main.dart': '''
Iterator<int> main() => <String>['x'].iterator;
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
