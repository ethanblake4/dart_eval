import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('generic Iterator subclasses and native iterators survive encoding', () {
    final program = Compiler().compile({
      'iterator_probe': {
        'main.dart': '''
class Single<E> extends Iterator<E> {
  Single(this.value);
  final E value;
  bool used = false;
  E get current => value;
  bool moveNext() {
    if (used) return false;
    used = true;
    return true;
  }
}
int main() {
  final guest = Single<int>(7);
  if (!guest.moveNext() || guest.current != 7 || guest.moveNext()) return -1;
  final native = <int>[11, 13].iterator;
  if (!native.moveNext() || native.current != 11) return -2;
  if (!native.moveNext() || native.current != 13 || native.moveNext()) return -3;
  return 1;
}
''',
      },
    });
    expect(
      identical($Iterator.$declaration, $Iterator$bridge.$declaration),
      isTrue,
    );
    expect($Iterator.$declaration.bridge, isTrue);
    expect($Iterator.$declaration.wrap, isFalse);
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:iterator_probe/main.dart', 'main'), 1);
    }
  });

  test('Iterator getter rejects a value outside its declared generic type', () {
    expect(
      () => Compiler().compile({
        'iterator_probe': {
          'main.dart': '''
class Wrong extends Iterator<int> {
  int get current => 'wrong';
  bool moveNext() => true;
}
int main() => Wrong().current;
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
