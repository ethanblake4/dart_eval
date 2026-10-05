import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const guest = r'''
class Ref {}
class Notifier<T> {}
typedef Build<N, R> = R Function(Ref ref, N notifier);
class View<N extends Notifier<S>, S, R> {
  View(Build<N, R>? build) : callback = build;
  final Build<N, R>? callback;
  R run(Ref ref, N notifier) => callback!(ref, notifier);
}
int build(Ref ref, Notifier<int> notifier) => 42;
int main() => View<Notifier<int>, int, int>(build).run(Ref(), Notifier<int>());
''';

void expectBoth(String source, Object expected) {
  final program = Compiler().compile({
    'fixture': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib('package:fixture/main.dart', 'main'), expected);
  }
}

void main() {
  test('constructor initializer retains callback class parameters', () {
    expectBoth(guest, 42);
  });

  test('initializer preserves a generic callback bound by its class', () {
    expectBoth(r'''
class View<R extends num> {
  View(U Function<U extends R>(U) build) : callback = build;
  final T Function<T extends R>(T) callback;
}
T identity<T extends num>(T value) => value;
int main() => View<num>(identity).callback<int>(7);
''', 7);
  });

  test('initializer rejects incompatible callback parameters', () {
    expect(
      () => Compiler().compile({
        'fixture': {
          'main.dart': r'''
class View<T> {
  View(int Function(String) build) : callback = build;
  final int Function(T) callback;
}
void main() {}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('initializer rejects incompatible generic callback bounds', () {
    expect(
      () => Compiler().compile({
        'fixture': {
          'main.dart': r'''
class View<R extends num> {
  View(U Function<U extends int>(U) build) : callback = build;
  final T Function<T extends R>(T) callback;
}
void main() {}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });

  test('stored callbacks retain runtime signature and cast checks', () {
    expectBoth(r'''
class View<T> {
  View(int Function(T) build) : callback = build;
  final int Function(T) callback;
}
int correct(int value) => value;
bool main() {
  dynamic callback = View<int>(correct).callback;
  if (callback is! int Function(int)) return false;
  if (callback is int Function(String)) return false;
  try {
    callback as int Function(String);
    return false;
  } catch (e) {
    return true;
  }
}
''', true);
  });
}
