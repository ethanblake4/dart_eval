import 'dart:typed_data';

import 'package:dart_eval/src/eval/runtime/typed/typed.dart';

// A storage/dispatch reference using the same compact bytecode. Its smaller
// switch deliberately favors the reference; it is not the legacy word VM.
@pragma('vm:never-inline')
Object genericReference(TypedProgram program, int iterations) {
  final r = List<Object?>.filled(6, null);
  r[0] = iterations;
  final code = program.code;
  var pc = 0;
  while (true) {
    switch (code[pc++]) {
      case TypedOp.aConstant:
        final index = code[pc] | (code[pc + 1] << 8);
        pc += 2;
        r[0] = program.integers[index];
        break;
      case TypedOp.bFromA:
        r[1] = r[0];
        break;
      case TypedOp.fConstant:
        final index = code[pc] | (code[pc + 1] << 8);
        pc += 2;
        r[2] = program.doubles[index];
        break;
      case TypedOp.gConstant:
        final index = code[pc] | (code[pc + 1] << 8);
        pc += 2;
        r[3] = program.doubles[index];
        break;
      case TypedOp.aAddB:
        r[0] = (r[0] as int) + (r[1] as int);
        break;
      case TypedOp.aXorB:
        r[0] = (r[0] as int) ^ (r[1] as int);
        break;
      case TypedOp.bDecrement:
        r[1] = (r[1] as int) - 1;
        break;
      case TypedOp.fAddG:
        r[2] = (r[2] as double) + (r[3] as double);
        break;
      case TypedOp.eBPositive:
        r[4] = (r[1] as int) > 0;
        break;
      case TypedOp.jumpETrue:
        final address =
            code[pc] |
            (code[pc + 1] << 8) |
            (code[pc + 2] << 16) |
            (code[pc + 3] << 24);
        pc += 4;
        if (r[4] as bool) pc = address;
        break;
      case TypedOp.aReturn:
        return r[0]!;
      case TypedOp.fReturn:
        return r[2]!;
      default:
        throw StateError('Unsupported reference opcode');
    }
  }
}

@pragma('vm:never-inline')
int nativeIntegers(int iterations) {
  var result = 0;
  var count = iterations;
  do {
    result += count;
    count--;
  } while (count > 0);
  return result;
}

@pragma('vm:never-inline')
double nativeDoubles(int iterations) {
  var result = 0.0;
  var count = iterations;
  do {
    result += 0.25;
    count--;
  } while (count > 0);
  return result;
}

@pragma('vm:never-inline')
int nativeMixed(int iterations) {
  var result = 0, count = iterations;
  var floating = 0.0;
  do {
    result ^= count;
    floating += 0.25;
    count--;
  } while (count > 0);
  // The return mirrors the bytecode's int result. Keep the double observable in
  // a guard that cannot be folded across this function boundary.
  if (floating < 0) throw StateError('negative accumulator');
  return result;
}

TypedProgram loopProgram(
  List<int> body, {
  bool floating = false,
  bool mixed = false,
}) {
  final bytes = <int>[
    TypedOp.bFromA,
    TypedOp.aConstant,
    0,
    0,
    if (floating || mixed) ...[
      TypedOp.fConstant,
      0,
      0,
      TypedOp.gConstant,
      1,
      0,
    ],
  ];
  final header = bytes.length;
  bytes.addAll([
    ...body,
    TypedOp.bDecrement,
    TypedOp.eBPositive,
    TypedOp.jumpETrue,
    header & 255,
    (header >> 8) & 255,
    (header >> 16) & 255,
    (header >> 24) & 255,
    floating ? TypedOp.fReturn : TypedOp.aReturn,
  ]);
  return TypedProgram(
    Uint8List.fromList(bytes),
    integers: [0],
    doubles: [0.0, 0.25],
    functions: const [
      TypedFunction(0, argumentKinds: [TypedArgumentKind.integer]),
    ],
  );
}

int _sink = 0;
void measure(
  String name,
  Object Function() run,
  Object expected,
  int iterations,
  int instructionsPerIteration,
  int samples,
) {
  final times = <double>[];
  for (var sample = 0; sample < samples; sample++) {
    final watch = Stopwatch()..start();
    final value = run();
    watch.stop();
    if (value != expected) {
      throw StateError('$name returned $value; expected $expected');
    }
    _sink ^= value.hashCode;
    times.add(watch.elapsedMicroseconds / 1000);
  }
  final raw = List<double>.of(times);
  times.sort();
  final median = times[times.length ~/ 2];
  final nsPerIteration = median * 1000000 / iterations;
  print(
    '$name median_ms=${median.toStringAsFixed(3)} '
    'min_ms=${times.first.toStringAsFixed(3)} '
    'max_ms=${times.last.toStringAsFixed(3)} '
    'ns/iteration=${nsPerIteration.toStringAsFixed(2)} '
    'ns/bytecode=${(nsPerIteration / instructionsPerIteration).toStringAsFixed(2)} '
    'raw_ms=${raw.map((value) => value.toStringAsFixed(3)).join(',')}',
  );
}

void main(List<String> args) {
  final iterations = args.isEmpty ? 5000000 : int.parse(args[0]);
  final samples = args.length < 2 ? 7 : int.parse(args[1]);
  if (iterations <= 0 || samples < 1) {
    throw ArgumentError('Positive iterations/samples required');
  }
  print(
    'typed_dispatch instructions=${TypedOp.instructions.length} iterations=$iterations samples=$samples',
  );
  final integers = loopProgram([TypedOp.aAddB]);
  final doubles = loopProgram([TypedOp.fAddG], floating: true);
  final mixed = loopProgram([TypedOp.aXorB, TypedOp.fAddG], mixed: true);
  for (final (name, program, native, instructionCount) in [
    ('integer', integers, nativeIntegers, 4),
    ('double', doubles, nativeDoubles, 4),
    ('mixed', mixed, nativeMixed, 5),
  ]) {
    for (var warm = 0; warm < 12; warm++) {
      TypedMachine.run(program, intArguments: [100000]);
      genericReference(program, 100000);
      native(100000);
    }
    final expected = native(iterations);
    measure(
      '$name native',
      () => native(iterations),
      expected,
      iterations,
      1,
      samples,
    );
    measure(
      '$name typed',
      () => TypedMachine.run(program, intArguments: [iterations])!,
      expected,
      iterations,
      instructionCount,
      samples,
    );
    measure(
      '$name object-reference',
      () => genericReference(program, iterations),
      expected,
      iterations,
      instructionCount,
      samples,
    );
  }
  print('checksum=$_sink');
}
