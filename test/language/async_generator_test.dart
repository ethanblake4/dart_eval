import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

const _library = 'package:async_generator/main.dart';

Iterable<(String, Runtime)> _runtimes(String source) sync* {
  final program = Compiler().compile({
    'async_generator': {'main.dart': source},
  });
  yield ('fresh', Runtime.ofProgram(program));
  yield ('serialized', Runtime(program.write().buffer));
}

void main() {
  test(
    'async* starts on listen and isolates captured invocation state',
    () async {
      for (final (kind, runtime) in _runtimes('''
      int starts = 0;
      int readStarts() => starts;
      Stream<int> values(int seed) async* {
        starts++;
        int next() => ++seed;
        yield next();
        await 0;
        yield next();
      }
    ''')) {
        final first =
            runtime.executeLib(_library, 'values', arguments: {'seed': 4})
                as Stream;
        final second =
            runtime.executeLib(_library, 'values', arguments: {'seed': 8})
                as Stream;
        expect(runtime.executeLib(_library, 'readStarts'), 0, reason: kind);
        final result = first.toList();
        expect(runtime.executeLib(_library, 'readStarts'), 0, reason: kind);
        expect(await result, [$int(5), $int(6)], reason: kind);
        expect(await second.toList(), [$int(9), $int(10)], reason: kind);
        expect(() => first.listen((_) {}), throwsStateError, reason: kind);
      }
    },
  );

  test(
    'typed methods and inferred closures compose yield* and await for',
    () async {
      for (final (kind, runtime) in _runtimes('''
      class Source<T> {
        Source(this.value);
        final T value;
        Stream<T> values() async* { yield value; }
        Stream<S> method<S>(S item) async* { yield item; }
      }
      Future<int> main() async {
        final make = () async* {
          yield 1;
          yield* Source<int>(2).values();
          await for (final n in Source<int>(3).values()) { yield n; }
        };
        if (make() is! Stream<int>) return -1;
        if (Source<int>(0).method<String>('x') is! Stream<String>) return -2;
        var result = 0;
        await for (final n in make()) { result = result * 10 + n; }
        return result;
      }
    ''')) {
        expect(
          await runtime.executeLib(_library, 'main'),
          $int(123),
          reason: kind,
        );
      }
    },
  );

  test('yield* forwards errors and bare return waits for finally', () async {
    for (final (kind, runtime) in _runtimes('''
      int finishes = 0;
      int readFinishes() => finishes;
      Stream<int> values() async* {
        try {
          yield 1;
          yield* Stream<int>.error('delegated');
          yield 2;
          return;
        } finally {
          await 0;
          finishes++;
        }
      }
    ''')) {
      final events = <Object?>[];
      final stream = runtime.executeLib(_library, 'values') as Stream;
      final done = Completer<void>();
      stream.listen(events.add, onError: events.add, onDone: done.complete);
      await done.future;
      expect(events, [$int(1), $String('delegated'), $int(2)], reason: kind);
      expect(runtime.executeLib(_library, 'readFinishes'), 1, reason: kind);
    }
  });

  test(
    'cancel skips catch and runs asynchronous finally while paused',
    () async {
      for (final (kind, runtime) in _runtimes('''
      int state = 0;
      int readState() => state;
      Stream<int> values() async* {
        try {
          yield 1;
          state = 10;
          yield 2;
        } catch (e) {
          state = 100;
        } finally {
          await 0;
          state++;
        }
      }
    ''')) {
        final first = Completer<void>();
        final stream = runtime.executeLib(_library, 'values') as Stream;
        late StreamSubscription<Object?> subscription;
        subscription = stream.listen((value) {
          expect(value, $int(1), reason: kind);
          subscription.pause();
          first.complete();
        });
        await first.future;
        expect(runtime.executeLib(_library, 'readState'), 0, reason: kind);
        await subscription.cancel();
        expect(runtime.executeLib(_library, 'readState'), 1, reason: kind);
      }
    },
  );

  test('cleanup errors complete cancel with an error', () async {
    for (final (kind, runtime) in _runtimes('''
      Stream<int> values() async* {
        try { yield 1; } finally { await 0; throw 'cleanup'; }
      }
    ''')) {
      final cancelled = Completer<void>();
      final stream = runtime.executeLib(_library, 'values') as Stream;
      late StreamSubscription<Object?> subscription;
      subscription = stream.listen((_) {
        cancelled.complete(subscription.cancel());
      });
      await expectLater(
        cancelled.future,
        throwsA($String('cleanup')),
        reason: kind,
      );
    }
  });

  test('cancellation waits for nested yield* and await-for cleanup', () async {
    for (final (kind, runtime) in _runtimes('''
      int finishes = 0;
      int readFinishes() => finishes;
      Stream<int> inner() async* {
        try { yield 1; yield 2; } finally { await 0; finishes++; }
      }
      Stream<int> delegate() async* {
        try { yield* inner(); } finally { await 0; finishes += 10; }
      }
      Stream<int> iterate() async* {
        try {
          await for (final n in delegate()) { yield n; }
        } finally { finishes += 100; }
      }
    ''')) {
      final cancelled = Completer<void>();
      final stream = runtime.executeLib(_library, 'iterate') as Stream;
      late StreamSubscription<Object?> subscription;
      subscription = stream.listen((_) {
        cancelled.complete(subscription.cancel());
      });
      await cancelled.future;
      expect(runtime.executeLib(_library, 'readFinishes'), 111, reason: kind);
    }
  });

  test(
    'guest Stream implementations dispatch listen for yield* and await for',
    () async {
      for (final (kind, runtime) in _runtimes('''
      import 'dart:async';
      class Subscription<T> implements StreamSubscription<T> {
        Subscription(this.inner);
        final StreamSubscription<T> inner;
        Future<void> cancel() => inner.cancel();
        void pause([Future<void>? signal]) => inner.pause(signal);
        void resume() => inner.resume();
        bool get isPaused => inner.isPaused;
        void onData(void Function(T)? f) => inner.onData(f);
        void onError(Function? f) => inner.onError(f);
        void onDone(void Function()? f) => inner.onDone(f);
        Future<E> asFuture<E>([E? value]) => inner.asFuture<E>(value);
      }
      class View<T> extends StreamView<T> {
        View(Stream<T> source) : super(source);
        StreamSubscription<T> listen(void Function(T)? onData,
            {Function? onError, void Function()? onDone, bool? cancelOnError}) {
          return Subscription<T>(super.listen(onData, onError: onError,
              onDone: onDone, cancelOnError: cancelOnError));
        }
      }
      Stream<int> inner([bool fail = false]) async* {
        yield 1;
        if (fail) throw StateError('guest');
        yield 2;
      }
      Stream<int> values() async* {
        yield* View<int>(inner());
        await for (final n in View<int>(inner())) { yield n + 2; }
      }
      Stream<int> errors() async* {
        yield* View<int>(inner(true));
        yield 3;
        try {
          await for (final n in View<int>(inner(true))) { yield n; }
        } on StateError { yield 4; }
      }
      int stage = 0;
      int readStage() => stage;
      Stream<int> controlledInner() async* {
        stage = 1;
        try { yield 1; stage = 2; yield 2; }
        finally { await 0; stage = 3; }
      }
      Stream<int> controlled(bool iterate) async* {
        final stream = View<int>(controlledInner());
        if (iterate) {
          await for (final n in stream) { yield n; }
        } else { yield* stream; }
      }
    ''')) {
        final stream = runtime.executeLib(_library, 'values') as Stream;
        expect(await stream.toList(), [
          $int(1),
          $int(2),
          $int(3),
          $int(4),
        ], reason: kind);
        final events = <Object?>[];
        final done = Completer<void>();
        final errors = runtime.executeLib(_library, 'errors') as Stream;
        errors.listen(
          events.add,
          onError: (Object error, StackTrace trace) {
            expect(error, isA<$StateError>(), reason: kind);
            expect(trace.toString(), isNotEmpty, reason: kind);
            events.add('error');
          },
          onDone: done.complete,
        );
        await done.future;
        expect(events, [
          $int(1),
          'error',
          $int(3),
          $int(1),
          $int(4),
        ], reason: kind);
        for (final iterate in [false, true]) {
          final first = Completer<void>();
          final second = Completer<void>();
          final controlled =
              runtime.executeLib(
                    _library,
                    'controlled',
                    arguments: {'iterate': iterate},
                  )
                  as Stream;
          late StreamSubscription<Object?> subscription;
          subscription = controlled.listen((event) {
            subscription.pause();
            (event == $int(1) ? first : second).complete();
          });
          await first.future;
          await Future<void>.delayed(Duration.zero);
          expect(runtime.executeLib(_library, 'readStage'), 1, reason: kind);
          subscription.resume();
          await second.future;
          await subscription.cancel();
          expect(runtime.executeLib(_library, 'readStage'), 3, reason: kind);
        }
      }
    },
  );

  test('asyncExpand accepts async* callbacks', () async {
    for (final (kind, runtime) in _runtimes('''
      Stream<int> inner() async* { yield 1; yield 2; }
      Stream<int> values() async* {
        yield* inner().asyncExpand((n) async* { yield n; yield n + 10; });
      }
    ''')) {
      final stream = runtime.executeLib(_library, 'values') as Stream;
      expect(await stream.toList(), [
        $int(1),
        $int(11),
        $int(2),
        $int(12),
      ], reason: kind);
    }
  });

  test(
    'Future.value infers the stream element from values and futures',
    () async {
      for (final (kind, runtime) in _runtimes('''
      Stream<int> values() async* {
        final Stream<int> first = Future.value(2).asStream();
        final Stream<int> second = Future.value(Future<int>.value(3)).asStream();
        yield* first;
        yield* second;
      }
    ''')) {
        final stream = runtime.executeLib(_library, 'values') as Stream;
        expect(await stream.toList(), [$int(2), $int(3)], reason: kind);
      }
    },
  );

  test('pause blocks yields while an outstanding await can finish', () async {
    for (final (kind, runtime) in _runtimes('''
      int stage = 0;
      int readStage() => stage;
      Stream<int> values() async* {
        await Future<void>.delayed(Duration(milliseconds: 5));
        stage = 1;
        yield 1;
        stage = 2;
        yield 2;
      }
    ''')) {
      final events = <Object?>[];
      final first = Completer<void>();
      final stream = runtime.executeLib(_library, 'values') as Stream;
      final subscription = stream.listen((event) {
        events.add(event);
        if (!first.isCompleted) first.complete();
      });
      await Future<void>.delayed(Duration.zero);
      subscription.pause();
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(runtime.executeLib(_library, 'readStage'), 1, reason: kind);
      expect(events, isEmpty, reason: kind);
      subscription.resume();
      await first.future;
      await subscription.cancel();
      expect(events.first, $int(1), reason: kind);
    }
  });
}
