import 'support/comparison.dart';

// The original Particle workload: 64 moving objects, indexed update loops,
// and an energy reduction after all ticks.
// dart compile exe benchmark/particles.dart -o .dart_tool/particles-baseline.exe
// .dart_tool/particles-baseline.exe [ticks] [samples]
const _source = r'''
class Particle {
  double x;
  double y;
  double vx;
  double vy;

  Particle(this.x, this.y, this.vx, this.vy);

  void tick(double dt) {
    x += vx * dt;
    y += vy * dt;
    if (x > 100.0) {
      vx = -vx;
    }
    if (y > 100.0) {
      vy = -vy;
    }
  }

  double energy() => x * x + y * y;
}

double run(int n) {
  final items = <Particle>[];
  for (var j = 0; j < 64; j++) {
    items.add(Particle(j * 0.5, j * 0.25, 1.25, -0.75));
  }
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < items.length; j++) {
      items[j].tick(0.016);
    }
  }
  var sum = 0.0;
  for (var j = 0; j < items.length; j++) {
    sum += items[j].energy();
  }
  return sum;
}

double main(int n) => run(n);
''';

void main(List<String> args) => runComparison(
  args,
  name: 'particles',
  source: _source,
  parameter: 'n',
  unit: 'tick',
  iterations: 10000,
  warmupIterations: 100,
  defaultSamples: 15,
);
