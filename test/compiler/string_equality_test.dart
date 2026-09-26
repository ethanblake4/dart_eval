import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:string_equality/main.dart';

void _expectGuest(String source, Object expected) {
  final program = Compiler().compile({
    'string_equality': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('native equality compares runtime strings and Unicode by value', () {
    final program = Compiler().compile({
      'string_equality': {
        'main.dart': '''
          int main(String left, String right) {
            var result = 0;
            if (left == right) result += 1;
            if (left != right) result += 2;
            return result;
          }
        ''',
      },
    });
    final cases = [
      (String.fromCharCodes([97, 98]), String.fromCharCodes([97, 98]), 1),
      (String.fromCharCodes([97, 98]), String.fromCharCodes([97, 99]), 2),
      (
        String.fromCharCodes([0x1f642, 0x03bb]),
        String.fromCharCodes([0x1f642, 0x03bb]),
        1,
      ),
      (
        String.fromCharCodes([0x1f642, 0x03bb]),
        String.fromCharCodes([0x1f642, 0x03bc]),
        2,
      ),
    ];
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      for (final (left, right, expected) in cases) {
        expect(
          runtime.executeLib(
            _entrypoint,
            'main',
            arguments: {'left': left, 'right': right},
          ),
          expected,
          reason: '$left compared with $right',
        );
      }
    }
  });

  test('right operand mutation preserves the captured left value', () {
    _expectGuest('''
      bool main() {
        String value = 'before';
        String mutate() {
          value = 'after';
          return 'before';
        }
        final equal = value == mutate();
        value = 'before';
        final notEqual = value != mutate();
        return equal && !notEqual && value == 'after';
      }
    ''', true);
  });

  test('nullable, dynamic, and custom equality keep their semantics', () {
    _expectGuest('''
      class Pretend {
        bool operator ==(Object other) => other is String;
        int get hashCode => 0;
      }
      bool nullable(String? value) => value == 'text';
      bool dynamicEqual(dynamic value) => value == 'text';
      bool custom(Pretend value) => value == 'text';
      bool main() =>
          !nullable(null) && nullable('text') &&
          dynamicEqual(Pretend()) && custom(Pretend()) &&
          !dynamicEqual('other');
    ''', true);
  });

  test('non-nullable String parameters use native comparison bytecodes', () {
    for (final (operator, opcode) in [
      ('==', 'eStringEqRS'),
      ('!=', 'eStringNeRS'),
    ]) {
      final program = Compiler().compileTyped({
        'string_equality': {
          'main.dart':
              'bool main(String left, String right) => left $operator right;',
        },
      }, entrypoint: _entrypoint);
      final names = [
        for (final (_, instruction) in program.instructions) instruction.name,
      ];
      expect(names, contains(opcode));
      expect(names, isNot(contains('rBoxString')));
      expect(names, isNot(contains('eEqRS')));
    }
  });
}
