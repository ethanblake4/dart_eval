import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('default sort dispatches guest Comparable and validates operands', () {
    final program = Compiler().compile({
      'probe': {
        'main.dart': '''
      class Item implements Comparable<Item> {
        final int value;
        Item(this.value);
        int compareTo(Item other) => value.compareTo(other.value);
      }
      class Pretender { int compareTo(Pretender other) => 0; }
      int main() {
        final items = [Item(3), Item(1), Item(2)];
        items.sort();
        if (items[0].value != 1 || items[2].value != 3) return -1;
        final numbers = [3, 1, 2];
        numbers.sort();
        final strings = ['c', 'a', 'b'];
        strings.sort();
        if (numbers[0] != 1 || strings[0] != 'a') return -2;
        final dates = [DateTime(2024), DateTime(2022), DateTime(2023)];
        dates.sort();
        if (dates[0].year != 2022) return -5;
        items.sort((Item a, Item b) => b.value.compareTo(a.value));
        if (items[0].value != 3) return -3;
        try {
          [Pretender(), Pretender()].sort();
          return -4;
        } on TypeError {
          return 42;
        }
      }
    ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:probe/main.dart', 'main'), 42);
    }
  });
}
