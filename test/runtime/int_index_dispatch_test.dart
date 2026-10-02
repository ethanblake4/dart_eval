import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
class Indexed {
  int reads = 0;
  int operator [](int index) {
    reads++;
    return index + 5;
  }
}

int read(dynamic receiver, int index) => receiver[index] as int;

int main() {
  final list = <int>[for (var i = 0; i < 600; i++) i * 2];
  final map = <int, int>{512: 17};
  final guest = Indexed();
  var receiverCalls = 0;
  var indexCalls = 0;
  dynamic receiver() { receiverCalls++; return guest; }
  int index() { indexCalls++; return 512; }

  final result = read(list, 512) + read(map, 512) +
      (receiver()[index()] as int);
  if (receiverCalls != 1 || indexCalls != 1 || guest.reads != 1) {
    throw StateError('indexed expressions ran more than once');
  }
  var rangeErrors = 0;
  for (final bad in [-1, 600]) {
    try { read(list, bad); } on RangeError { rangeErrors++; }
  }
  if (rangeErrors != 2) throw StateError('list bounds were not checked');
  return result;
}
''';

void main() {
  test('integer index dispatch preserves maps, guest methods and bounds', () {
    final program = Compiler().compile({
      'int_index': {'main.dart': _source},
    });
    expect(
      program.typedProgram.instructions.map((entry) => entry.$2.name),
      contains('callIndexInt'),
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:int_index/main.dart', 'main'), 1558);
    }
  });
}
