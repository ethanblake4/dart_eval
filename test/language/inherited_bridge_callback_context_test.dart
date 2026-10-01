import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('inherited bridge callback contexts use the declaring owner view', () {
    final program = Compiler().compile({
      'bridge_callback_context': {
        'main.dart': _source,
        'support.dart': _support,
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib(
          'package:bridge_callback_context/main.dart',
          'verify',
        ),
        true,
      );
    }
  });
}

const _support = r'''
class Item {
  Item(this.value);
  final int value;
}
class Values<T> extends Iterable<T> {
  Values(this.values);
  final List<T> values;
  Iterator<T> get iterator => values.iterator;
}
class Reordered<A, B> extends Values<B> {
  Reordered(List<B> values) : super(values);
}
class Concrete extends Reordered<String, Item> {
  Concrete(List<Item> values) : super(values);
}
typedef ItemValues = Reordered<String, Item>;
''';
const _source = r'''
import 'support.dart';
bool verify() {
  final values = <Item>[Item(1), Item(2)];
  final reordered = Reordered<String, Item>(values);
  if (reordered.map((item) => Item(item.value + 10)).toList()[1].value != 12) return false;
  final concrete = Concrete(values);
  if (concrete.map((item) => item.value + 20).toList().last != 22) return false;
  final alias = ItemValues(values);
  if (alias.map((item) => item.value + 30).toList().last != 32) return false;
  if (concrete.where((item) => item.value > 1).toList()[0].value != 2) return false;
  return true;
}
void main() { if (!verify()) throw StateError('bridge callback owner context'); }
''';
