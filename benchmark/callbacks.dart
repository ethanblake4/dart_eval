import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

// dart compile exe benchmark/callbacks.dart -o callbacks.exe
// callbacks.exe [base iterations] [samples]
const _library = 'package:callbacks/main.dart';
const _source = r'''
  int voidCount = 0;

  Function voidCallback() => () { voidCount = voidCount + 1; };
  int readVoidCount() => voidCount;

  Function valueCallback() {
    var value = 0;
    return () { value = value + 1; return value; };
  }

  Function oneArgumentCallback() {
    var value = 0;
    return (int delta) { value = value + delta; return value; };
  }

  Function defaultCallback() => ([int value = 3]) => value + 1;

  class Counter {
    int value = 0;
    int next() { value = value + 1; return value; }
  }

  Function boundCallback() => Counter().next;
''';

void main(List<String> args) {
  final baseIterations = args.isEmpty ? 100000 : int.parse(args[0]);
  final samples = args.length < 2 ? 9 : int.parse(args[1]);
  if (baseIterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }

  final program = Compiler().compile({
    'callbacks': {'main.dart': _source},
  });
  final runtime = Runtime.ofProgram(program);
  EvalCallable callback(String name) =>
      runtime.executeLib(_library, name) as EvalCallable;
  final voidCallback = callback('voidCallback');
  final valueCallback = callback('valueCallback');
  final oneArgumentCallback = callback('oneArgumentCallback');
  final defaultCallback = callback('defaultCallback');
  final boundCallback = callback('boundCallback');
  const empty = <$Value?>[];
  final delta = <$Value?>[$int(3)];

  var checksum = 0;
  var voidExpected = 0;
  var valueExpected = 0;
  var oneArgumentExpected = 0;
  var boundExpected = 0;
  const warmupCalls = 1000;
  print(
    'native_to_guest_callbacks base_iterations=$baseIterations '
    'samples=$samples',
  );

  void warm(
    String name,
    EvalCallable fn,
    List<$Value?> arguments,
    int expectedDelta,
    void Function(int) updateExpected,
  ) {
    $Value? last;
    for (var i = 0; i < warmupCalls; i++) {
      last = fn.call(
          runtime,
          null,
          arguments.isEmpty ? null : arguments[0],
          arguments.length > 1 ? arguments[1] : null,
          arguments.length < 3 ? arguments.length : arguments.sublist(2),
        );
    }
    updateExpected(expectedDelta * warmupCalls);
    if (name == 'captured-void') {
      if (last != null) throw StateError('$name returned $last');
    } else if (name == 'default-adapter') {
      if ((last as $int).$value != 4) {
        throw StateError('$name returned ${last.$value}');
      }
    }
  }

  warm('captured-void', voidCallback, empty, 1, (delta) {
    voidExpected += delta;
  });
  warm('captured-value', valueCallback, empty, 1, (delta) {
    valueExpected += delta;
  });
  warm('one-argument', oneArgumentCallback, delta, 3, (delta) {
    oneArgumentExpected += delta;
  });
  warm('default-adapter', defaultCallback, empty, 0, (_) {});
  warm('bound-member', boundCallback, empty, 1, (delta) {
    boundExpected += delta;
  });

  for (final workload in [
    (
      'captured-void',
      voidCallback,
      empty,
      baseIterations * 3,
      () => voidExpected,
      (int calls) => voidExpected += calls,
    ),
    (
      'captured-value',
      valueCallback,
      empty,
      baseIterations * 3,
      () => valueExpected,
      (int calls) => valueExpected += calls,
    ),
    (
      'one-argument',
      oneArgumentCallback,
      delta,
      baseIterations,
      () => oneArgumentExpected,
      (int calls) => oneArgumentExpected += calls * 3,
    ),
    (
      'default-adapter',
      defaultCallback,
      empty,
      baseIterations,
      () => 4,
      (int calls) {},
    ),
    (
      'bound-member',
      boundCallback,
      empty,
      baseIterations * 3,
      () => boundExpected,
      (int calls) => boundExpected += calls,
    ),
  ]) {
    final (name, fn, arguments, calls, expected, advance) = workload;
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      $Value? last;
      final watch = Stopwatch()..start();
      for (var i = 0; i < calls; i++) {
        last = fn.call(
          runtime,
          null,
          arguments.isEmpty ? null : arguments[0],
          arguments.length > 1 ? arguments[1] : null,
          arguments.length < 3 ? arguments.length : arguments.sublist(2),
        );
      }
      watch.stop();
      advance(calls);
      final actual = name == 'captured-void'
          ? runtime.executeLib(_library, 'readVoidCount') as int
          : (last as $int).$value;
      if (actual != expected()) {
        throw StateError('$name returned $actual, expected ${expected()}');
      }
      checksum = (checksum * 31 + actual + calls) & 0x7fffffff;
      times.add(watch.elapsedMicroseconds / 1000);
    }
    final raw = List<double>.of(times);
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      '$name calls=$calls '
      'median_ms=${median.toStringAsFixed(3)} '
      'min_ms=${times.first.toStringAsFixed(3)} '
      'max_ms=${times.last.toStringAsFixed(3)} '
      'ns/call=${(median * 1000000 / calls).toStringAsFixed(2)} '
      'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
    );
  }
  print('checksum=$checksum');
}
