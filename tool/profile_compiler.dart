import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_eval/dart_eval.dart';

import '../benchmark/compile.dart' show compileSource;
import '../benchmark/compile_pipeline.dart' show pipelineSource;

// AOT: dart compile exe tool/profile_compiler.dart -o profile_compiler.exe
// Usage: profile_compiler.exe [small|mixed|pipeline|source.dart] [samples] [fresh|cached]
// An optional fourth argument writes raw timings and medians as JSON.
void main(List<String> args) {
  final workload = args.isEmpty ? 'mixed' : args[0];
  final samples = args.length < 2 ? 15 : int.parse(args[1]);
  final mode = args.length < 3 ? 'fresh' : args[2];
  if (samples < 1 || !{'fresh', 'cached'}.contains(mode)) {
    throw ArgumentError('Positive samples and fresh or cached mode required');
  }
  final source = switch (workload) {
    'small' => 'int main() => 42;',
    'mixed' => compileSource,
    'pipeline' => pipelineSource(64),
    _ => File(workload).readAsStringSync(),
  };
  final sources = {
    'profile': {'main.dart': source},
  };
  final timings = <String, List<int>>{};
  void record(String phase, int time) =>
      timings.putIfAbsent(phase, () => []).add(time);
  T measure<T>(String phase, T Function() action) {
    final watch = Stopwatch()..start();
    final result = action();
    watch.stop();
    record(phase, watch.elapsedMicroseconds);
    return result;
  }

  var plainCompiler = Compiler();
  var profiledCompiler = Compiler(onPhase: record);
  var bytes = 0;
  var emittedFunctions = 0;
  var programHash = '';
  for (var i = -3; i < samples; i++) {
    if (mode == 'fresh') {
      plainCompiler = Compiler();
      profiledCompiler = Compiler(onPhase: record);
    }
    // Alternate ordering to reduce systematic warm-cache bias.
    late Program plain;
    late Program profiled;
    void compilePlain() => plain = measure(
      'compile without profiling',
      () => plainCompiler.compile(sources),
    );
    void compileProfiled() => profiled = measure(
      'compile with profiling',
      () => profiledCompiler.compile(sources),
    );
    if (i.isEven) {
      compilePlain();
      compileProfiled();
    } else {
      compileProfiled();
      compilePlain();
    }
    final encoded = measure('serialization', profiled.write);
    bytes = encoded.length;
    emittedFunctions = profiled.typedProgram.functions.length;
    if (i == samples - 1) programHash = sha256.convert(encoded).toString();
    if (i == 0 && !const ListEquality().equals(plain.write(), encoded)) {
      throw StateError('Profiling changed the serialized program');
    }
    final decoded = measure(
      'decode and validation',
      () => Program.read(encoded.buffer),
    );
    measure(
      'runtime setup from program',
      () => Runtime.ofProgram(decoded).initialize(),
    );
    measure(
      'runtime setup from bytes',
      () => Runtime(encoded.buffer).initialize(),
    );
    if (i < 0) timings.clear();
  }
  final medians = {
    for (final entry in timings.entries)
      entry.key: (List<int>.of(entry.value)..sort())[entry.value.length ~/ 2],
  };
  print('$workload $mode samples=$samples program_bytes=$bytes');
  print('program_sha256=$programHash');
  final preparedFunctions = profiledCompiler.ssaFunctionGraphs.length;
  print(
    'prepared_functions=$preparedFunctions emitted_functions=$emittedFunctions',
  );
  for (final entry in medians.entries) {
    print('${entry.key}: ${entry.value} us');
  }
  if (args.length > 3) {
    File(args[3]).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'workload': workload,
        'mode': mode,
        'samples': samples,
        'program_bytes': bytes,
        'program_sha256': programHash,
        'prepared_functions': preparedFunctions,
        'emitted_functions': emittedFunctions,
        'median_us': medians,
        'raw_us': timings,
      }),
    );
  }
}
