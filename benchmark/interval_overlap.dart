import 'support/comparison.dart';

// Check collisions and booked time in a sorted stream of appointments.
// Durations are at most 80 minutes and starts are at least 12 minutes apart,
// so only the six previous appointments can overlap a new one.
// dart compile exe benchmark/interval_overlap.dart -o .dart_tool/interval_overlap.exe
// .dart_tool/interval_overlap.exe [appointments] [samples]
const _source = r'''
int main(int appointments) {
  final starts = List<int>.filled(appointments, 0);
  final ends = List<int>.filled(appointments, 0);
  var state = 123456789;
  var nextStart = 0;

  for (var i = 0; i < appointments; i++) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    nextStart += 12 + state % 12;
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    starts[i] = nextStart;
    ends[i] = nextStart + 20 + ((state >> 8) % 61);
  }

  var bookedMinutes = 0;
  var lastEnd = 0;
  var conflicts = 0;
  var conflictMinutes = 0;
  for (var i = 0; i < appointments; i++) {
    final start = starts[i];
    final end = ends[i];
    final coveredFrom = start > lastEnd ? start : lastEnd;
    final coveredTo = end > lastEnd ? end : lastEnd;
    bookedMinutes += coveredTo - coveredFrom;
    lastEnd = coveredTo;

    final first = i > 6 ? i - 6 : 0;
    for (var j = first; j < i; j++) {
      final overlapStart = start > starts[j] ? start : starts[j];
      final overlapEnd = end < ends[j] ? end : ends[j];
      if (overlapEnd > overlapStart) {
        conflicts++;
        conflictMinutes += overlapEnd - overlapStart;
      }
    }
  }
  return bookedMinutes + conflicts * 997 + conflictMinutes * 31;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'interval_overlap',
  source: _source,
  parameter: 'appointments',
  unit: 'appointment',
  iterations: 100000,
  warmupIterations: 1000,
);
