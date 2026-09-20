import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

// dart compile exe benchmark/external_calls.dart -o external_calls.exe
// external_calls.exe [iterations] [samples]
const _bridge = 'package:external/bridge.dart';
const _library = 'package:external/main.dart';

class _Token implements $Instance {
  @override
  Object get $value => throw StateError('Token was unwrapped');
  @override
  Object get $reified => throw StateError('Token was reified');
  @override
  int $getRuntimeType(Runtime runtime) => throw UnimplementedError();
  @override
  $Value? $getProperty(Runtime runtime, String identifier) =>
      throw UnimplementedError();
  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) =>
      throw UnimplementedError();
}

Program _compile(int arity) {
  final compiler = Compiler();
  compiler.defineBridgeTopLevelFunction(
    BridgeFunctionDeclaration(
      _bridge,
      'capture',
      BridgeFunctionDef(
        returns: const BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.int)),
        params: [
          for (var i = 0; i < arity; i++)
            BridgeParameter(
              'a$i',
              const BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.dynamic)),
              false,
            ),
        ],
      ),
    ),
  );
  return compiler.compile({
    'external': {
      'main.dart':
          '''
      import '$_bridge';
      int main(int n, Object token) {
        var sum = 0;
        for (var i = 0; i < n; i++) {
          sum += capture(token, i, token${arity == 6 ? ', 3, 4, 5' : ''});
        }
        return sum;
      }
    ''',
    },
  });
}

void main(List<String> args) {
  final iterations = args.isEmpty ? 1000000 : int.parse(args[0]);
  final samples = args.length < 2 ? 5 : int.parse(args[1]);
  if (iterations < 1 || samples < 1) {
    throw ArgumentError('Positive iterations and samples required');
  }
  var checksum = 0;
  print('external_calls iterations=$iterations samples=$samples');
  for (final arity in [3, 6]) {
    // Both registration paths execute this exact program.
    final program = _compile(arity);
    final token = _Token();
    final expected =
        iterations * (iterations - 1) ~/ 2 + (arity == 6 ? iterations * 12 : 0);
    $Value small(Object? first, Object? index, Object? third) {
      if (!identical(first, token) || !identical(third, token)) {
        throw StateError('Bridge changed token identity');
      }
      return $int((index as $int).$value);
    }

    $Value overflow(
      Object? first,
      Object? index,
      Object? third,
      Object? fourth,
      Object? fifth,
      Object? sixth,
    ) {
      if (!identical(first, token) || !identical(third, token)) {
        throw StateError('Bridge changed token identity');
      }
      return $int(
        (index as $int).$value +
            (fourth as $int).$value +
            (fifth as $int).$value +
            (sixth as $int).$value,
      );
    }

    for (final direct in [false, true]) {
      final runtime = Runtime.ofProgram(program);
      if (direct) {
        runtime.registerBridgeFuncRegisters(
          _bridge,
          'capture',
          arity == 3
              ? (runtime, r, s, c) => small(r, s, c)
              : (runtime, r, s, c) {
                  final rest = c as List<Object?>;
                  return overflow(r, s, rest[0], rest[1], rest[2], rest[3]);
                },
        );
      } else {
        runtime.registerBridgeFunc(
          _bridge,
          'capture',
          arity == 3
              ? (runtime, target, args) => small(args[0], args[1], args[2])
              : (runtime, target, args) => overflow(
                  args[0],
                  args[1],
                  args[2],
                  args[3],
                  args[4],
                  args[5],
                ),
        );
      }
      for (var warm = 0; warm < 5; warm++) {
        checksum +=
            runtime.executeLib(
                  _library,
                  'main',
                  arguments: {'n': 1000, 'token': token},
                )
                as int;
      }
      final times = <double>[];
      for (var sample = 0; sample < samples; sample++) {
        final watch = Stopwatch()..start();
        final result = runtime.executeLib(
          _library,
          'main',
          arguments: {'n': iterations, 'token': token},
        );
        watch.stop();
        if (result != expected) {
          throw StateError(
            'arity=$arity direct=$direct returned $result, expected $expected',
          );
        }
        checksum += result as int;
        times.add(watch.elapsedMicroseconds / 1000);
      }
      final raw = List<double>.of(times);
      times.sort();
      final median = times[times.length ~/ 2];
      print(
        'arity=$arity ${direct ? 'registers' : 'legacy'} '
        'median_ms=${median.toStringAsFixed(3)} '
        'min_ms=${times.first.toStringAsFixed(3)} '
        'max_ms=${times.last.toStringAsFixed(3)} '
        'ns/iteration=${(median * 1000000 / iterations).toStringAsFixed(2)} '
        'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
      );
    }
  }
  print('checksum=$checksum');
}
