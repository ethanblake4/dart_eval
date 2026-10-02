import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:generator_context/main.dart';

Iterable<(String, Runtime)> _runtimes(String source) sync* {
  final program = Compiler().compile({
    'generator_context': {'main.dart': source},
  });
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

void main() {
  test('generic generator contexts use the closure type parameters', () async {
    for (final (kind, runtime) in _runtimes(r'''
      Future<bool> main() async {
        final Iterable<T> Function<T>(T) sync = <X>(value) sync* {
          yield value;
          return;
        };
        final Stream<T> Function<T>({required T value}) async =
            <X>({required value}) async* {
          yield value;
          return;
        };
        final Iterable<T> Function<T>() syncCast = <X>() sync* {
          yield 1 as X;
          return;
        };
        final Stream<T> Function<T>() asyncCast = <X>() async* {
          yield 1 as X;
          return;
        };
        withReturn() sync* { yield 1; return; }
        final literal = () async* { yield 1; return; };
        if (sync<String>('s') is! Iterable<String>) return false;
        if (async<String>(value: 's') is! Stream<String>) return false;
        if (syncCast<int>() is! Iterable<int>) return false;
        if (asyncCast<int>() is! Stream<int>) return false;
        if (withReturn is! Iterable<int> Function()) return false;
        if (literal is! Stream<int> Function()) return false;
        final values = await async<String>(value: 's').toList();
        final castValues = await asyncCast<int>().toList();
        return sync<String>('s').single == 's' && values.single == 's' &&
            syncCast<int>().single == 1 && castValues.single == 1;
      }
    ''')) {
      expect(
        await runtime.executeLib(_library, 'main'),
        $bool(true),
        reason: kind,
      );
    }
  });

  test('yield* uses unknown and explicit dynamic stream contexts', () async {
    for (final (kind, runtime) in _runtimes(r'''
      Type observed = Object;
      class A implements Stream<dynamic> {
        final Stream<dynamic> stream = (() async* {})();
        void checkThisIsA() {}
        listen(onData, {onError, onDone, cancelOnError}) => stream.listen(
          onData, onError: onError, onDone: onDone,
          cancelOnError: cancelOnError);
        noSuchMethod(invocation) => super.noSuchMethod(invocation);
      }
      T make<T>() { observed = T; return A() as T; }
      T contextType<T>(T value) { observed = T; return value; }
      dynamic dynamicReturn() async* {
        yield* make()..checkThisIsA();
        if (observed != dynamic) throw StateError('dynamic return');
      }
      Stream<dynamic> explicitReturn() async* {
        yield* contextType(A());
        if (observed != Stream<dynamic>) throw StateError('explicit return');
      }
      dynamic inferredReturn() {
        final g = () async* {
          yield* make()..checkThisIsA();
          if (observed != dynamic) throw StateError('inferred return');
        };
        return g();
      }
      dynamic schemaReturn() {
        T invoke<T>(Stream<T> Function() g) => g() as T;
        final result = invoke(() async* {
          yield* make()..checkThisIsA();
          if (observed != dynamic) throw StateError('schema return');
        });
        return result;
      }
      Future<bool> main() async {
        await for (final value in dynamicReturn()) {}
        await for (final value in explicitReturn()) {}
        await for (final value in inferredReturn()) {}
        await for (final value in schemaReturn()) {}
        return true;
      }
    ''')) {
      expect(
        await runtime.executeLib(_library, 'main'),
        $bool(true),
        reason: kind,
      );
    }
  });
}
