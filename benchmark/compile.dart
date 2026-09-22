import 'package:dart_eval/dart_eval.dart';

// Measures compiler throughput on a representative mixed feature set.
// Run with: dart compile exe benchmark/compile.dart -o compile.exe
// Then: compile.exe [samples]
const _source = '''
class Shape {
  const Shape(this.name, this.sides);
  final String name;
  final int sides;
  double area() => 0.0;
  String describe() => '\$name with \$sides sides';
}

class Polygon extends Shape {
  const Polygon(super.name, super.sides, this.vertices);
  final List<double> vertices;
  @override
  double area() {
    var total = 0.0;
    for (var i = 0; i + 3 < vertices.length; i += 2) {
      final x1 = vertices[i];
      final y1 = vertices[i + 1];
      final x2 = vertices[i + 2];
      final y2 = vertices[i + 3];
      total += x1 * y2 - x2 * y1;
    }
    if (total < 0) total = -total;
    return total * 0.5;
  }
}

mixin Labeled on Shape {
  String label() => '[\${describe()}]';
}

class Square extends Polygon with Labeled {
  Square(double side)
      : assert(side > 0),
        super('square', 4, const [0, 0, 1, 0, 1, 1, 0, 1]);
  double sideOf() => vertices.isEmpty ? 0.0 : vertices[0];
}

enum Rank { low, medium, high }

int fib(int n) => n < 2 ? n : fib(n - 1) + fib(n - 2);

Map<String, List<int>> group(Iterable<int> values) {
  final result = <String, List<int>>{};
  for (final v in values) {
    result.putIfAbsent(v.isEven ? 'even' : 'odd', () => []).add(v);
  }
  return result;
}

List<int> naturals(int limit) {
  final out = <int>[];
  for (var i = 0; i < limit; i++) {
    out.add(i);
  }
  return out;
}

Future<T> retry<T>(T Function() action, {int attempts = 3}) async {
  Object? last;
  for (var i = 0; i < attempts; i++) {
    try {
      return action();
    } catch (e) {
      last = e;
    }
  }
  throw last!;
}

extension IntX on int {
  int get squared => this * this;
  bool divisibleBy(int d) => d != 0 && this % d == 0;
}

T foldLeft<T, E>(Iterable<E> items, T seed, T Function(T, E) combine) {
  var acc = seed;
  for (final item in items) {
    acc = combine(acc, item);
  }
  return acc;
}

int main() {
  final square = Square(2.0);
  final shapes = <Shape>[square, const Polygon('tri', 3, [0, 0, 1, 0, 0, 1])];
  var total = 0.0;
  for (final s in shapes) {
    total += s.area();
    switch (s.sides) {
      case 3:
        total += 0.5;
      case 4:
        total += 1.0;
      default:
        break;
    }
  }
  final sums = foldLeft<int, int>([1, 2, 3, 4], 0, (a, b) => a + b);
  final odds = group([1, 2, 3, 4, 5])['odd']!;
  return total.round() + sums + odds.length + fib(10) + 4.squared;
}
''';

void main(List<String> args) {
  final samples = args.isEmpty ? 9 : int.parse(args[0]);
  final warmup = args.length > 1 ? int.parse(args[1]) : 1;
  if (samples < 1) throw ArgumentError('Positive sample count required');
  for (var i = 0; i < warmup; i++) {
    Compiler().compileTyped({
      'compile_bench': {'main.dart': _source},
    }, entrypoint: 'package:compile_bench/main.dart');
  }
  final times = <int>[];
  var checksum = 0;
  for (var i = 0; i < samples; i++) {
    final watch = Stopwatch()..start();
    final program = Compiler().compileTyped({
      'compile_bench': {'main.dart': _source},
    }, entrypoint: 'package:compile_bench/main.dart');
    watch.stop();
    checksum += program.code.length;
    times.add(watch.elapsedMicroseconds);
  }
  times.sort();
  final median = times[times.length ~/ 2];
  print(
    'compiler samples=$samples code_bytes=${checksum ~/ times.length} '
    'median_us=$median min_us=${times.first} max_us=${times.last} '
    'raw_us=${times.join(',')}',
  );
}
