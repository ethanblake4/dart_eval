import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const source = r'''
int assigned(bool continued) {
  int? value;
  var round = 0;
  do {
    round++;
    value = round - 1;
    if (continued) continue;
  } while (value == 0 || (value >= 2 && round < 3));
  return round;
}
int bigInteger() {
  BigInt? value;
  var round = 0;
  final limit = BigInt.from(2);
  do {
    value = BigInt.from(round++);
  } while (value == BigInt.zero || (value >= limit));
  return round;
}
bool verify() => assigned(false) == 2 && assigned(true) == 2 &&
  bigInteger() == 2;
void main() { if (!verify()) throw StateError('do assignment promotion'); }
''';

void main() {
  test('do condition sees assignment on every incoming edge', () {
    final program = Compiler().compile({
      'do_assignment': {'main.dart': source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:do_assignment/main.dart', 'verify'),
        true,
      );
    }
  });
  for (final body in [
    '',
    'if (skip) continue; value = 1;',
    'if (!skip) value = 1;',
    'value = 1; if (skip) value = null;',
  ]) {
    test('nullable condition predecessor remains rejected: $body', () {
      expect(
        () => Compiler().compile({
          'do_assignment': {
            'main.dart':
                '''
void invalid(bool skip) {
  int? value;
  do { $body } while (value == 0 || (value >= 2));
}
void main() {}
''',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    });
  }
  test('unassigned nullable BigInt remains rejected', () {
    expect(
      () => Compiler().compile({
        'do_assignment': {
          'main.dart': r'''
void invalid() {
  BigInt? value;
  do {} while (value == BigInt.zero || (value >= BigInt.one));
}
void main() {}
''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
