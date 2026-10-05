import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _runner = '''
import 'dart:async';
class Runner {
  FutureOr<T> run<T>(FutureOr<T> Function() body) => body();
  FutureOr<T> named<T>({required FutureOr<T> Function() body}) => body();
  FutureOr<T> bounded<T extends num>(FutureOr<T> Function() body) => body();
}
''';

void _expectResult(String source, Object expected) {
  final program = Compiler().compile({
    'callback': {'main.dart': '$_runner\n$source'},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:callback/main.dart', 'main'), expected);
  }
}

void main() {
  test('generic source method infers FutureOr callback return', () {
    _expectResult('int main() => Runner().run(() => 7) as int;', 7);
  });

  test(
    'block and named callbacks infer FutureOr payloads and respect bounds',
    () {
      _expectResult('''
bool main() {
  final runner = Runner();
  final first = runner.run(() { return 7; });
  final second = runner.named(body: () => 'ok');
  final third = runner.bounded(() => 2.5);
  final future = runner.run(() => Future<int>.value(3));
  return first == 7 && second == 'ok' && third == 2.5 && future is Future<int>;
}
''', true);
    },
  );

  test('callback context retains enclosing lexical generic parameters', () {
    _expectResult('''
class Box<S> {
  Box(this.value);
  final S value;
  FutureOr<S> run(FutureOr<S> Function() body) => body();
  bool check() => run(() => value) == value;
}
bool check<U>(U value) => Runner().run(() => value) == value;
bool bounded<U extends num>(U value) => Runner().bounded(() => value) == value;
bool main() => Box<int>(4).check() && check<String>('ok') && bounded<int>(5);
''', true);
  });

  test('explicit callback payload keeps dynamic return checks', () {
    _expectResult('''
bool main() {
  dynamic bad = 'wrong';
  try { Runner().run<int>(() => bad); } on TypeError { return true; }
  return false;
}
''', true);
  });

  test('downward bounded callback retains dynamic runtime checks', () {
    _expectResult('''
bool main() {
  dynamic bad = 'wrong';
  try { FutureOr<num> value = Runner().bounded(() => bad); } on TypeError { return true; }
  return false;
}
''', true);
  });

  for (final source in [
    "void main() { Runner().run<int>(() => 'wrong'); }",
    "void main() { Runner().bounded(() => 'wrong'); }",
    "void main() { Runner().bounded<String>(() => 'wrong'); }",
    "void main() { FutureOr<int> Function() f = () => 'wrong'; }",
    "class Box<S> { void run(FutureOr<S> Function() body) {} } void main() { Box<int>().run(() => 'wrong'); }",
    "void reject<U>() { Runner().run<U>(() => 1); } void main() { reject<String>(); }",
    "void reject<U extends num>() { Runner().bounded<U>(() => 'wrong'); } void main() { reject<int>(); }",
  ]) {
    test('strict callback rejection: $source', () {
      expect(
        () => Compiler().compile({
          'callback': {'main.dart': '$_runner\n$source'},
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
