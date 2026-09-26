import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _entrypoint = 'package:string_predicates/main.dart';

Program _compile(String source) => Compiler().compile({
  'string_predicates': {'main.dart': source},
});

void _expectResult(String source, Object expected) {
  final program = _compile(source);
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(runtime.executeLib(_entrypoint, 'main'), expected);
  }
}

void main() {
  test('String emptiness and prefix checks use native bytecodes', () {
    final program = _compile('''
      bool inspect(String text, String prefix) =>
          text.isNotEmpty && !text.isEmpty && text.startsWith(prefix);
      bool main() =>
          inspect('alphabet', 'alpha') &&
          !inspect('alphabet', 'beta') &&
          ''.isEmpty && !''.isNotEmpty;
    ''');
    final names = [
      for (final (_, instruction) in program.typedProgram.instructions)
        instruction.name,
    ];
    expect(
      names,
      containsAll([
        'eStringIsEmptyR',
        'eStringIsNotEmptyR',
        'eStringStartsWithRS',
      ]),
    );
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib(_entrypoint, 'main'), isTrue);
    }
  });

  test('nonzero startsWith offset retains dispatch', () {
    _expectResult('''
      bool main() {
        final text = 'zebra';
        return text.startsWith('eb', 1) &&
            !text.startsWith('eb');
      }
    ''', true);
  });

  test('Pattern-typed prefix does not select the String intrinsic', () {
    final program = _compile('''
      bool main(String text, Pattern prefix) => text.startsWith(prefix);
    ''');
    expect(
      program.typedProgram.instructions.map((entry) => entry.$2.name),
      isNot(contains('eStringStartsWithRS')),
    );
  });

  test('nullable String receivers retain null dispatch', () {
    _expectResult('''
      bool nullable(String? text) => text?.isEmpty == null;
      bool main() => nullable(null) && !nullable('');
    ''', true);
  });

  test('dynamic String receiver retains member dispatch', () {
    _expectResult('''
      bool main() {
        dynamic text = 'prefix';
        return text.isNotEmpty && text.startsWith('pre');
      }
    ''', true);
  });

  test('custom receiver retains its getters and method', () {
    _expectResult('''
      class Custom {
        bool get isEmpty => true;
        bool get isNotEmpty => false;
        bool startsWith(String prefix) => prefix == 'custom';
      }
      bool main() {
        final custom = Custom();
        return custom.isEmpty && !custom.isNotEmpty &&
            custom.startsWith('custom');
      }
    ''', true);
  });
}
