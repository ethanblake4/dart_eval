import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('ground type tests avoid environment resolution', () {
    final program = Compiler().compile({
      'ground_type_check': {
        'main.dart': '''
          bool isNumber(dynamic value) => value is int;
          bool isTextList(dynamic value) => value is List<String>;
          bool main() => isNumber(3) && !isNumber('3') &&
              isTextList(<String>['a']) && !isTextList(<int>[1]);
        ''',
      },
    });
    final names = [
      for (final (_, instruction) in program.typedProgram.instructions)
        instruction.name,
    ];
    expect(names, contains('eIsGroundTypeR'));
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:ground_type_check/main.dart', 'main'),
        isTrue,
      );
    }
  });

  test('generic class and callable tests keep their type environments', () {
    final program = Compiler().compile({
      'ground_type_check': {
        'main.dart': '''
          class Box<T> {
            bool accepts(dynamic value) => value is T;
            T cast(dynamic value) => value as T;
            bool acceptsNested(dynamic value) =>
                value is Map<String, T Function(T)>;
          }
          bool accepts<U>(dynamic value) => value is U;
          U cast<U>(dynamic value) => value as U;
          String echo(String value) => value;
          int addOne(int value) => value + 1;
          bool main() {
            final strings = Box<String>();
            if (!strings.accepts('ok') || strings.accepts(4)) return false;
            if (!strings.acceptsNested(<String, String Function(String)>{
              'value': echo,
            })) return false;
            if (strings.acceptsNested(<String, int Function(int)>{
              'value': addOne,
            })) return false;
            if (strings.cast('yes') != 'yes') return false;
            if (!accepts<int>(2) || accepts<int>('bad')) return false;
            if (cast<int>(3) != 3) return false;
            var rejected = 0;
            try { strings.cast(4); } on TypeError { rejected++; }
            try { cast<int>('bad'); } on TypeError { rejected++; }
            return rejected == 2;
          }
        ''',
      },
    });
    final names = [
      for (final (_, instruction) in program.typedProgram.instructions)
        instruction.name,
    ];
    expect(names, contains('eIsTypeR'));
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:ground_type_check/main.dart', 'main'),
        isTrue,
      );
    }
  });
}
