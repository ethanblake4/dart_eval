import 'package:dart_eval/dart_eval.dart';

// A registry of typed processing stages, as used by middleware and ETL code.
String pipelineSource(int stages) {
  final source = StringBuffer('''
typedef Stage = List<int> Function(List<int>);
''');
  for (var i = 0; i < stages; i++) {
    source.writeln(
      'List<int> stage$i(List<int> values) => '
      'values.map((value) => value + $i).toList();',
    );
  }
  source.writeln('final List<Stage> stages = [');
  for (var i = 0; i < stages; i++) {
    source.writeln('stage$i,');
  }
  source.writeln('''];
int main() {
  var values = <int>[1, 2, 3];
  for (final stage in stages) values = stage(values);
  var total = 0;
  for (final value in values) total += value;
  return total;
}
''');
  return source.toString();
}

void main(List<String> args) {
  final samples = args.isEmpty ? 15 : int.parse(args[0]);
  final count = args.length < 2 ? 64 : int.parse(args[1]);
  if (samples < 7 || count < 1) {
    throw ArgumentError('At least seven samples and one stage required');
  }
  final sources = {
    'pipeline': {'main.dart': pipelineSource(count)},
  };
  const library = 'package:pipeline/main.dart';
  final warmup = Compiler().compile(sources);
  final result = Runtime(warmup.write().buffer).executeLib(library, 'main');
  final expected = 6 + 3 * count * (count - 1) ~/ 2;
  if (result != expected) throw StateError('Expected $expected, got $result');
  final times = <int>[];
  var bytes = 0;
  for (var i = 0; i < samples; i++) {
    final watch = Stopwatch()..start();
    final program = Compiler().compileTyped(sources, entrypoint: library);
    watch.stop();
    bytes = program.code.length;
    times.add(watch.elapsedMicroseconds);
  }
  times.sort();
  print(
    'compile_pipeline stages=$count samples=$samples code_bytes=$bytes '
    'median_us=${times[times.length ~/ 2]} min_us=${times.first} max_us=${times.last}',
  );
  print('checksum=$result');
}
