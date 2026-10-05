import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _forward = '''
import 'dart:async';
class Forward<X> implements Future<X> {
  Forward(this.fut);
  final Future<X> fut;
  asStream() => fut.asStream();
  catchError(error, {test}) => fut.catchError(error, test: test);
  then<R>(body, {onError}) => fut.then(body, onError: onError);
  timeout(limit, {onTimeout}) => fut.timeout(limit, onTimeout: onTimeout);
  whenComplete(action) => fut.whenComplete(action);
}
''';

Future<void> _expectResult(String source, Object expected) async {
  final program = Compiler().compile({
    'bridge_sdk': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    final result = await runtime.executeLib(
      'package:bridge_sdk/main.dart',
      'main',
    );
    expect(result is $Value ? result.$value : result, expected);
  }
}

void main() {
  test('inherited bridge callback keeps class and method identities', () async {
    await _expectResult('''
$_forward
Future<String> forward<U>(U value) =>
    Forward<U>(Future<U>.value(value)).then<String>(
      (item) => item.toString(), onError: (error) => 'error');
Future<String> main() async => await forward<int>(7);
''', '7');
  });

  test(
    'bridge downward result inference stays fixed after arguments',
    () async {
      await _expectResult('''
extension Static<T> on T {
  void exactly<R extends T Function(T)>() {}
}
num main() {
  return <num>[2, 3].fold(1, (p, v) => p * v)
    ..exactly<num Function(num)>();
}
''', 6);
    },
  );

  test(
    'nested bridge inference resolves non-callback argument contexts',
    () async {
      await _expectResult('''
int main() {
  final result = <int>[3].fold(
      <int>[2].fold(1, (total, item) => total + item),
      (total, item) => total + item);
  return result;
}
''', 6);
    },
  );

  test('nested bridge receiver keeps concrete codec arguments', () async {
    await _expectResult('''
import 'dart:convert';
String main() {
  final codec = utf8.fuse(base64Url.fuse(utf8));
  return codec.decode(codec.encode('hello'));
}
''', 'hello');
  });

  for (final source in [
    "Future<String> main() => Forward<int>(Future<int>.value(7)).then<String>((value) => value);",
    "Future<int> main() => Forward<int>(Future<int>.value(7)).then<int>((String value) => 1);",
    "Future<R> reject<X, R>(Future<X> future) => future.then<R>((value) => 'wrong'); void main() { reject<int, int>(Future<int>.value(7)); }",
    "void main() { num value = <num>[2].fold('wrong', (p, v) => v); }",
    "void main() { int value = <int>[3].fold(<String>['wrong'].fold('', (total, item) => total + item), (total, item) => total); }",
    "R lexical<R>(R value) => <int>[1].fold<R>(value, (total, item) => 'wrong'); void main() { lexical<int>(1); }",
    "void main() { Set<int>.of(<String>['wrong']); }",
  ]) {
    test('bridge generic boundary rejects incompatible types: $source', () {
      expect(
        () => Compiler().compile({
          'bridge_sdk': {'main.dart': '$_forward\n$source'},
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
}
