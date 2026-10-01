import 'package:dart_eval/dart_eval.dart';

// Compile this host with dart compile exe, then run [handlers] [records] [samples].
// Compilation and native checksum calculation remain outside timed execution.
class NativeHandler {
  NativeHandler(this.bias, this.weight);
  final int bias;
  final int weight;
  int normalize(int value) => (value + bias) & 255;
  int score(int value) => value * weight;
}

int nativeChecksum(int handlers, int records) {
  var checksum = 0;
  for (var i = 0; i < records; i++) {
    final kind = i % handlers;
    final handler = NativeHandler(kind + 1, kind % 7 + 1);
    checksum += handler.score(handler.normalize(i & 255));
  }
  return checksum;
}

String sourceFor(int handlers) {
  final source = StringBuffer(r'''
abstract class Handler {
  int normalize(int value);
  int score(int value);
}
int process(Handler handler, int value) => handler.score(handler.normalize(value));
''');
  for (var i = 0; i < handlers; i++) {
    source.writeln('''
class Handler$i extends Handler {
  final int bias;
  Handler$i(this.bias);
  int normalize(int value) => (value + bias) & 255;
  int score(int value) => value * (${i % 7} + 1);
}
''');
  }
  source.writeln('Handler create(int kind, int bias) { switch (kind) {');
  for (var i = 0; i < handlers; i++) {
    source.writeln('case $i: return Handler$i(bias);');
  }
  source.writeln('default: throw StateError("unknown handler"); } }');
  source.writeln('''
int main(int records) {
  var checksum = 0;
  for (var i = 0; i < records; i++) {
    final handler = create(i % $handlers, (i % $handlers) + 1);
    checksum += process(handler, i & 255);
  }
  return checksum;
}
''');
  return source.toString();
}

void main(List<String> args) {
  final handlers = args.isEmpty ? 32 : int.parse(args[0]);
  final records = args.length < 2 ? 100000 : int.parse(args[1]);
  final samples = args.length < 3 ? 7 : int.parse(args[2]);
  if (handlers < 1 || records < 1 || samples < 7) {
    throw ArgumentError('Positive handlers/records and at least seven samples');
  }
  final program = Compiler().compileTyped({
    'many_handlers': {'main.dart': sourceFor(handlers)},
  }, entrypoint: 'package:many_handlers/main.dart');
  if (nativeChecksum(1, 4) != 10 ||
      nativeChecksum(2, 4) != 20 ||
      nativeChecksum(8, 4) != 50) {
    throw StateError('Native reference checksum mismatch');
  }
  final expected = nativeChecksum(handlers, records);
  print(
    'handlers=$handlers records=$records functions=${program.functions.length} '
    'descriptors=${program.closures.length}',
  );
  for (final (label, selected) in [
    ('fresh', program),
    ('serialized', TypedProgram.read(program.write().buffer)),
  ]) {
    final coldWatch = Stopwatch()..start();
    final coldResult = TypedMachine.run(selected, intArguments: [1]);
    coldWatch.stop();
    if (coldResult != nativeChecksum(handlers, 1)) {
      throw StateError('$label cold checksum mismatch');
    }
    print('$label cold_one_record_us=${coldWatch.elapsedMicroseconds}');
    for (var warm = 0; warm < 2; warm++) {
      final result = TypedMachine.run(selected, intArguments: [1000]);
      if (result != nativeChecksum(handlers, 1000)) {
        throw StateError('$label warmup checksum mismatch');
      }
    }
    final times = <double>[];
    for (var sample = 0; sample < samples; sample++) {
      final watch = Stopwatch()..start();
      final result = TypedMachine.run(selected, intArguments: [records]);
      watch.stop();
      if (result != expected) {
        throw StateError('$label checksum $result != $expected');
      }
      times.add(watch.elapsedMicroseconds / 1000);
    }
    final raw = List<double>.of(times);
    times.sort();
    print(
      '$label median_ms=${times[times.length ~/ 2]} raw_ms=${raw.join(',')} '
      'checksum=$expected',
    );
  }
}
