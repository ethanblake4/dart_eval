import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

void main() {
  test(
    'value-class members initialize typed fields and preserve overrides',
    () {
      final program = Compiler().compile({
        'value_lowering': {'main.dart': _source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:value_lowering/main.dart', 'main'),
          true,
        );
      }
    },
  );

  test(
    'generated value constructor checks required fields and their types',
    () {
      for (final arguments in ['', "item: 'bad'"]) {
        expect(
          () => Compiler().compile({
            'value_lowering': {
              'main.dart':
                  '''
const valueClass = 'valueClass';
@valueClass class Count { final int item; }
main() => Count($arguments);
''',
            },
          }),
          throwsA(isA<CompileError>()),
        );
      }
    },
  );
}

const _source = r'''
const valueClass = 'valueClass';
@valueClass
class Packet<T> {
  final T item;
  final String? label;
  final int version = 1;
  static int ignored = 0;
}
class Child extends Packet<int> {
  Child() : super(item: 9, label: 'n');
}
@valueClass
class Manual {
  final int item;
  Manual(this.item);
  bool operator ==(Object other) => other is Manual;
  int get hashCode => 17;
}
class Plain {
  final int item;
  Plain(this.item);
}
bool main() {
  final first = Packet<int>(item: 9, label: 'n');
  final equal = Packet<int>(item: 9, label: 'n');
  final different = Packet<int>(item: 9, label: null);
  Packet.ignored = 3;
  return first.item == 9 && first.version == 1 && first == equal &&
      first.hashCode == equal.hashCode && first != different &&
      first != Packet<num>(item: 9, label: 'n') && first != Child() &&
      Manual(1) == Manual(2) && Manual(1).hashCode == 17 &&
      Plain(1) != Plain(1);
}
''';
