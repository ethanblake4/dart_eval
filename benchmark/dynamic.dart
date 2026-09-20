import 'dart:math' as math;
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';

const _library = 'package:dynamic_benchmark/main.dart';

final class _Case {
  const _Case(this.name, this.source, {this.hostSeed = false});

  final String name;
  final String source;
  final bool hostSeed;
}

const _cases = [
  _Case('conversion-stable', '''
    int main(int n) {
      var sum = 0;
      for (var i = 0; i < n; i++) {
        dynamic value = i & 7;
        int checked = value;
        sum += checked;
      }
      return sum;
    }
  '''),
  _Case('conversion-host', '''
      int main(int n, dynamic seed) {
        var sum = 0;
        for (var i = 0; i < n; i++) {
          int checked = seed;
          sum += checked;
        }
        return sum;
      }
    ''', hostSeed: true),
  _Case('receiver-stable', '''
    class A { int apply(int value) => value + 1; }
    int main(int n) {
      dynamic receiver = A();
      var sum = 0;
      for (var i = 0; i < n; i++) { sum += receiver.apply(i); }
      return sum;
    }
  '''),
  _Case('receiver-alternating', '''
    class A { int apply(int value) => value + 1; }
    class B { int apply(int value) => value + 3; }
    int main(int n) {
      dynamic first = A();
      dynamic second = B();
      var sum = 0;
      for (var i = 0; i < n; i++) {
        dynamic receiver = i.isEven ? first : second;
        sum += receiver.apply(i);
      }
      return sum;
    }
  '''),
  _Case('named-default-binding', '''
    class A {
      int apply(int value, {int add = 2, int scale = 3}) =>
          value * scale + add;
    }
    int main(int n) {
      dynamic receiver = A();
      var sum = 0;
      for (var i = 0; i < n; i++) {
        sum += receiver.apply(i, scale: 2);
      }
      return sum;
    }
  '''),
  _Case('generic-type-check', '''
    int main(int n) {
      dynamic integers = <int>[1];
      dynamic strings = <String>['x'];
      var matches = 0;
      for (var i = 0; i < n; i++) {
        dynamic value = i.isEven ? integers : strings;
        if (value is List<int>) matches++;
      }
      return matches;
    }
  '''),
  _Case('function-type-check', '''
    int addOne(int value) => value + 1;
    String stringify(String value) => value;
    int main(int n) {
      dynamic integers = addOne;
      dynamic strings = stringify;
      var matches = 0;
      for (var i = 0; i < n; i++) {
        dynamic value = i.isEven ? integers : strings;
        if (value is int Function(int)) matches++;
      }
      return matches;
    }
  '''),
  _Case('collection-write-proven', '''
    int main(int n) {
      final values = <int>[];
      for (var i = 0; i < n; i++) { values.add(i); }
      return values.length + values[n - 1];
    }
  '''),
  _Case('collection-write-dynamic-receiver', '''
    int main(int n) {
      dynamic values = <int>[];
      for (var i = 0; i < n; i++) { values.add(i); }
      return values.length + values[n - 1];
    }
  '''),
  _Case('collection-write-unknown-value', '''
    int main(int n, dynamic seed) {
      final values = <int>[];
      for (var i = 0; i < n; i++) { values.add(seed); }
      return values.length + values[n - 1];
    }
  ''', hostSeed: true),
  _Case('failed-conversion', '''
    int main(int n) {
      dynamic value = 'bad';
      var failures = 0;
      for (var i = 0; i < n; i++) {
        try {
          int checked = value;
          failures += checked;
        } on TypeError {
          failures++;
        }
      }
      return failures;
    }
  '''),
];

int _expectedChecksum(String name, int n) => switch (name) {
  'conversion-stable' =>
    (n ~/ 8) * 28 + List.generate(n % 8, (i) => i).fold(0, (a, b) => a + b),
  'conversion-host' => n * 7,
  'receiver-stable' => n * (n - 1) ~/ 2 + n,
  'receiver-alternating' => n * (n - 1) ~/ 2 + ((n + 1) ~/ 2) + (n ~/ 2) * 3,
  'named-default-binding' => n * (n + 1),
  'generic-type-check' => (n + 1) ~/ 2,
  'function-type-check' => (n + 1) ~/ 2,
  'collection-write-proven' => n * 2 - 1,
  'collection-write-dynamic-receiver' => n * 2 - 1,
  'collection-write-unknown-value' => n + 7,
  'failed-conversion' => n,
  _ => throw StateError('Missing checksum for $name'),
};

void main(List<String> arguments) {
  final iterations = arguments.isEmpty ? 100000 : int.parse(arguments[0]);
  final samples = arguments.length < 2 ? 15 : int.parse(arguments[1]);
  final allowUnsupported =
      arguments.length > 2 && arguments[2] == 'allow-unsupported';
  if (iterations < 1 || samples < 2) {
    throw ArgumentError('iterations must be positive and samples at least 2');
  }
  print(
    'dynamic iterations=$iterations samples=$samples '
    'dart=${Platform.version.split(' ').first}',
  );
  var combined = 0;
  var failures = 0;
  for (final benchmark in _cases) {
    try {
      final compileWatch = Stopwatch()..start();
      final program = Compiler().compile({
        'dynamic_benchmark': {'main.dart': benchmark.source},
      });
      compileWatch.stop();
      final bytes = program.write();
      final loadWatch = Stopwatch()..start();
      final runtime = Runtime(bytes.buffer);
      loadWatch.stop();
      final warmupWatch = Stopwatch()..start();
      final warmupIterations = math.max(1, iterations ~/ 10);
      final warmup = runtime.executeLib(
        _library,
        'main',
        arguments: {'n': warmupIterations, if (benchmark.hostSeed) 'seed': 7},
      );
      warmupWatch.stop();
      if (warmup is! int ||
          warmup != _expectedChecksum(benchmark.name, warmupIterations)) {
        throw StateError('${benchmark.name}: bad warmup checksum $warmup');
      }
      final rawValues = <int>[];
      int? expected;
      for (var sample = 0; sample < samples; sample++) {
        final watch = Stopwatch()..start();
        final result = runtime.executeLib(
          _library,
          'main',
          arguments: {'n': iterations, if (benchmark.hostSeed) 'seed': 7},
        );
        watch.stop();
        if (result is! int ||
            result != _expectedChecksum(benchmark.name, iterations) ||
            (expected != null && result != expected)) {
          throw StateError('${benchmark.name}: unstable checksum $result');
        }
        expected = result;
        rawValues.add(watch.elapsedMicroseconds);
      }
      final sortedValues = [...rawValues]..sort();
      final medianUs = sortedValues[sortedValues.length ~/ 2];
      final p10 = sortedValues[(sortedValues.length * 0.1).floor()];
      final p90 = sortedValues[(sortedValues.length * 0.9).floor()];
      combined = (combined * 31 + expected!) & 0x7fffffff;
      print(
        '${benchmark.name} compile_us=${compileWatch.elapsedMicroseconds} '
        'load_us=${loadWatch.elapsedMicroseconds} '
        'warmup_us=${warmupWatch.elapsedMicroseconds} bytes=${bytes.length} '
        'median_us=$medianUs p10_us=$p10 p90_us=$p90 '
        'ns/op=${(medianUs * 1000 / iterations).toStringAsFixed(2)} '
        'checksum=$expected raw_us=${rawValues.join(',')}',
      );
    } catch (error) {
      failures++;
      final summary = error.toString().replaceAll(RegExp(r'\s+'), ' ');
      print('${benchmark.name} unsupported=$summary');
    }
  }
  print('combined_checksum=$combined');
  if (failures != 0 && !allowUnsupported) exitCode = 1;
}
