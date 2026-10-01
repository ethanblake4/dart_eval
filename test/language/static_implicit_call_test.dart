import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  for (final declaration in [
    'class C { Function get call => () => 1; }',
    'class C { Function call = () => 1; }',
  ]) {
    for (final invocation in ['c()', '(c)()']) {
      test('implicit call rejects $declaration through $invocation', () {
        expect(
          () => Compiler().compile({
            'static_call': {
              'main.dart':
                  '$declaration void main() { final c = C(); $invocation; }',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      });
    }
  }
  test('a call getter shadows an extension call method', () {
    expect(
      () => Compiler().compile({
        'static_call': {'main.dart': _shadowedSource},
      }),
      throwsA(isA<CompileError>()),
    );
  });
  test('a type parameter bound does not make a getter callable', () {
    expect(
      () => Compiler().compile({
        'static_call': {'main.dart': _getterBoundSource},
      }),
      throwsA(isA<CompileError>()),
    );
  });
  test('legitimate implicit and explicit calls remain available', () {
    final program = Compiler().compile({
      'static_call': {'main.dart': _positiveSource},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:static_call/main.dart', 'verify'),
        true,
      );
    }
  });
}

const _shadowedSource = r'''
class C { Function get call => () => 1; }
extension Callable on C { int call() => 2; }
void main() { final c = C(); c(); }
''';
const _getterBoundSource = r'''
class C { Function get call => () => 1; }
void invoke<T extends C>(T value) { value(); }
void main() { invoke(C()); }
''';
const _positiveSource = r'''
abstract class Contract { int call(int x); }
class Method implements Contract { int call(int x) => x + 1; }
class Inherited extends Method {}
mixin Callable { int call(int x) => x + 2; }
class Mixed with Callable {}
class Getter { Function get call => () => 3; }
class Field { Function call = () => 4; }
class Empty {}
extension CallableExtension on Empty { int call(int x) => x + 5; }
int bounded<T extends Contract>(T value) => value(2);
int chained<T extends U, U extends Contract>(T value) => value(2);
abstract class Recursive<T extends Recursive<T>> { int call(int x); }
class RecursiveMethod implements Recursive<RecursiveMethod> {
  int call(int x) => x + 1;
}
int recursive<T extends Recursive<T>>(T value) => value(2);
int boundedFunction<T extends Function>(T value) => value(2);
Never neverValue() => throw StateError('never');
void bottomControl() { neverValue()(); }
bool verify() {
  final method = Method();
  Contract contract = method;
  final inherited = Inherited();
  final mixed = Mixed();
  if (method(2) != 3 || (method)(2) != 3 || contract(2) != 3) return false;
  if (inherited(2) != 3 || mixed(2) != 4 || bounded(method) != 3) return false;
  if (chained<Method, Contract>(method) != 3 || recursive(RecursiveMethod()) != 3) return false;
  Function bare = (int x) => x + 1;
  int Function(int) typed = (int x) => x + 1;
  dynamic dynamicMethod = method;
  if (bare(2) != 3 || typed(2) != 3 || dynamicMethod(2) != 3) return false;
  if (boundedFunction(bare) != 3) return false;
  final getter = Getter();
  final field = Field();
  if (getter.call() != 3 || (getter.call)() != 3) return false;
  if (field.call() != 4 || (field.call)() != 4) return false;
  final empty = Empty();
  if (empty(2) != 7 || (empty)(2) != 7) return false;
  return true;
}
void main() { if (!verify()) throw StateError('static call control'); }
''';
