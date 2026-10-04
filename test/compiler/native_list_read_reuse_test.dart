import 'dart:collection';

import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

class _ObservedList extends ListBase<int> {
  int reads = 0;
  @override
  int get length => 1;
  @override
  set length(int value) => throw UnsupportedError('fixed length');
  @override
  int operator [](int index) => ++reads;
  @override
  void operator []=(int index, int value) =>
      throw UnsupportedError('read only');
}

Program _compile(String source) => Compiler().compile({
  'list_read_reuse': {'main.dart': source},
});

Iterable<Runtime> _runtimes(Program program) => [
  Runtime.ofProgram(program),
  Runtime(program.write().buffer),
];

void main() {
  test(
    'fresh literal and filled lists reuse successful reads in branch arms',
    () {
      for (final allocation in ['<int>[value]', 'List<int>.filled(1, value)']) {
        final program = _compile('''
int main(int value) {
  final values = $allocation;
  final alias = values;
  final index = 0;
  return value > values[index] ? value : alias[index];
}
''');
        expect(
          program.typedProgram.instructions.where(
            (entry) => entry.$2.name == 'rListIndexCA',
          ),
          hasLength(1),
        );
        for (final runtime in _runtimes(program)) {
          expect(
            runtime.executeLib(
              'package:list_read_reuse/main.dart',
              'main',
              arguments: {'value': 17},
            ),
            17,
          );
        }
      }
    },
  );

  test('host list reads retain observable indexing effects', () {
    final program = _compile(r'''
int main(List<int> values) {
  final index = 0;
  final first = values[index];
  return first > 0 ? values[index] : 0;
}
''');
    for (final runtime in _runtimes(program)) {
      final values = _ObservedList();
      expect(
        runtime.executeLib(
          'package:list_read_reuse/main.dart',
          'main',
          arguments: {'values': values},
        ),
        2,
      );
      expect(values.reads, 2);
    }
  });

  test('alias writes and mutating calls end fresh list read reuse', () {
    final program = _compile(r'''
void change(List<int> values) { values[0] = 11; }
int main() {
  final values = <int>[7];
  final alias = values;
  final index = 0;
  final first = values[index];
  alias[index] = 9;
  final second = values[index];
  change(alias);
  return first * 100 + second * 10 + values[index];
}
''');
    for (final runtime in _runtimes(program)) {
      expect(
        runtime.executeLib('package:list_read_reuse/main.dart', 'main'),
        801,
      );
    }
  });

  test('joins and loop backedges retain intervening writes', () {
    final program = _compile(r'''
int main(bool write) {
  final values = List<int>.filled(1, 7);
  final index = 0;
  final first = values[index];
  if (write) values[index] = 9;
  var total = first + values[index];
  for (var i = 0; i < 3; i++) {
    total += values[index];
    values[index] = values[index] + 1;
  }
  return total + values[index];
}
''');
    for (final runtime in _runtimes(program)) {
      for (final write in [false, true]) {
        expect(
          runtime.executeLib(
            'package:list_read_reuse/main.dart',
            'main',
            arguments: {'write': write},
          ),
          write ? 58 : 48,
        );
      }
    }
  });

  test('out of bounds reads keep their original throwing position', () {
    final program = _compile(r'''
int main(int value) {
  final values = List<int>.filled(0, value);
  final index = 0;
  return value > values[index] ? value : values[index];
}
''');
    for (final runtime in _runtimes(program)) {
      expect(
        () => runtime.executeLib(
          'package:list_read_reuse/main.dart',
          'main',
          arguments: {'value': 17},
        ),
        throwsA(anything),
      );
    }
  });
}
