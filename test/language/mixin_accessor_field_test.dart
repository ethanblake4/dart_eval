import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('abstract mixin accessors retain concrete field implementations', () {
    final program = Compiler().compile({
      'mixin_accessor': {
        'main.dart': r'''
mixin Reader {
  int get _value;
  set _value(int value);
  int read() => _value;
  void add() { _value += 3; }
  noSuchMethod(invocation) => throw StateError('unexpected forwarding');
}
mixin Storage { int _value = 4; }
class Own with Reader, Storage { int _value = 7; }
class Base { int _value = 11; }
class Inherited extends Base with Reader {}
bool main() {
  final own = Own();
  final inherited = Inherited();
  if (own.read() != 7 || inherited.read() != 11) return false;
  own.add();
  inherited.add();
  return own.read() == 10 && inherited.read() == 14;
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:mixin_accessor/main.dart', 'main'),
        true,
      );
    }
  });
}
