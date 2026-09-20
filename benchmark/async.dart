import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

// dart compile exe benchmark/async.dart -o async.exe
// async.exe [iterations] [samples]
const _bridge = 'package:async_benchmark/bridge.dart';
const _library = 'package:async_benchmark/main.dart';

Program _compile() {
  final compiler = Compiler();
  compiler.defineBridgeTopLevelFunction(
    const BridgeFunctionDeclaration(
      _bridge,
      'nativeCompleted',
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
        params: [
          BridgeParameter(
            'value',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
            false,
          ),
        ],
      ),
    ),
  );
  return compiler.compile({
    'async_benchmark': {
      'main.dart':
          '''
        import '$_bridge';

        int syncFunction(int n) {
          var sum = 0;
          for (var i = 0; i < n; i++) {
            sum += i;
          }
          return sum;
        }

        Future<int> asyncWithoutAwait(int n) async {
          var sum = 0;
          for (var i = 0; i < n; i++) {
            sum += i;
          }
          return sum;
        }

        Future<int> awaitCompleted(int n) async {
          var sum = 0;
          for (var i = 0; i < n; i++) {
            sum += await i;
          }
          return sum;
        }

        Future<int> awaitNativeFuture(int n) async {
          var sum = 0;
          for (var i = 0; i < n; i++) {
            sum += await nativeCompleted(i);
          }
          return sum;
        }

        Future<int> awaitCallback(int n, Function callback) async {
          var sum = 0;
          for (var i = 0; i < n; i++) {
            sum += await callback(i);
          }
          return sum;
        }
      ''',
    },
  });
}

int _integer(Object? value) => switch (value) {
  int value => value,
  $int value => value.$value,
  _ => throw StateError('Expected integer result, got $value'),
};

Future<int> _invoke(
  Runtime runtime,
  String name,
  int iterations, {
  $Closure? callback,
}) async {
  final result = runtime.executeLib(
    _library,
    name,
    arguments: {'n': iterations, 'callback': ?callback},
  );
  return _integer(result is Future ? await result : result);
}

Future<void> main(List<String> args) async {
  final iterations = args.isEmpty ? 100001 : int.parse(args[0]);
  final samples = args.length < 2 ? 3 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }

  final program = _compile();
  final callback = $Closure((runtime, target, r, s, c) {
    return $Future.wrap(Future<$Value?>.value(r as $Value?));
  });
  final cases = <(String, Runtime, $Closure?)>[
    for (final name in [
      'syncFunction',
      'asyncWithoutAwait',
      'awaitCompleted',
      'awaitNativeFuture',
      'awaitCallback',
    ])
      (
        name,
        Runtime.ofProgram(program),
        name == 'awaitCallback' ? callback : null,
      ),
  ];
  for (final (_, runtime, _) in cases) {
    runtime.registerBridgeFuncRegisters(_bridge, 'nativeCompleted', (
      runtime,
      r,
      s,
      c,
    ) {
      return $Future.wrap(Future<$Value?>.value(r as $Value?));
    });
  }

  var checksum = 0;
  final warmupIterations = iterations < 1001 ? iterations : 1001;
  print('typed_async iterations=$iterations samples=$samples');
  for (final (name, runtime, caseCallback) in cases) {
    final expected = iterations * (iterations - 1) ~/ 2;
    final warmupExpected = warmupIterations * (warmupIterations - 1) ~/ 2;
    for (var warmup = 0; warmup < 5; warmup++) {
      final result = await _invoke(
        runtime,
        name,
        warmupIterations,
        callback: caseCallback,
      );
      if (result != warmupExpected) {
        throw StateError('$name warmup returned $result');
      }
      checksum += result;
    }

    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = await _invoke(
        runtime,
        name,
        iterations,
        callback: caseCallback,
      );
      watch.stop();
      if (result != expected) {
        throw StateError('$name returned $result, expected $expected');
      }
      checksum += result;
      times.add(watch.elapsedMicroseconds / 1000);
    }
    final raw = List<double>.of(times);
    times.sort();
    final median = times[times.length ~/ 2];
    print(
      '$name median_ms=${median.toStringAsFixed(3)} '
      'min_ms=${times.first.toStringAsFixed(3)} '
      'max_ms=${times.last.toStringAsFixed(3)} '
      'ns/iteration=${(median * 1000000 / iterations).toStringAsFixed(2)} '
      'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
    );
  }
  print('checksum=$checksum');
}
