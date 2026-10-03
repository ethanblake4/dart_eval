import 'support/comparison.dart';

// Apply one sensor's calibration to a stream of integer readings.
const calibrationSource = r'''
int calibrate(int readings, int gain, int bias) {
  var sample = 1;
  var total = 0;
  for (var i = 0; i < readings; i++) {
    sample = (sample * 25173 + 13849) & 65535;
    total += ((gain * 7 + bias * 3) * sample + (gain ^ bias) * 17) & 65535;
  }
  return total;
}

int main(int readings) => calibrate(readings, 13, 5);
''';

void main(List<String> args) => runComparison(
  args,
  name: 'sensor_calibration',
  source: calibrationSource,
  parameter: 'readings',
  unit: 'reading',
  iterations: 100000,
  warmupIterations: 100,
  defaultSamples: 15,
);
