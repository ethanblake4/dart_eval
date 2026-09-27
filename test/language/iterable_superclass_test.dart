import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void check(String source, int expected) {
  final program = Compiler().compile({
    'iterable_superclass': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(
      runtime.executeLib('package:iterable_superclass/main.dart', 'main'),
      expected,
    );
  }
}

void main() {
  test('guest Iterable inherits methods backed by a guest iterator', () {
    check(r'''
      class ValuesIterator implements Iterator<int> {
        ValuesIterator(this.values);
        final List<int> values;
        int index = -1;

        int get current => values[index];
        bool moveNext() {
          if (index + 1 == values.length) return false;
          index++;
          return true;
        }
      }

      class Values extends Iterable<int> {
        Iterator<int> get iterator => ValuesIterator([2, 4, 6]);
      }

      int main() {
        final values = Values();
        if (values.length != 3 || values.first != 2) return -1;
        if (!values.contains(4) || values.contains(5)) return -2;
        if (values.elementAt(2) != 6) return -3;
        final mapped = values.map((value) => value + 1).toList();
        if (mapped.length != 3 || mapped[0] != 3 || mapped[2] != 7) {
          return -4;
        }
        return values.toList().last;
      }
    ''', 6);
  });

  test('IterableBase typedef forwards the Iterable superclass', () {
    check(r'''
      import 'dart:collection';

      class ValuesIterator implements Iterator<int> {
        int index = 0;
        int get current => index;
        bool moveNext() {
          if (index == 3) return false;
          index++;
          return true;
        }
      }

      class Values extends IterableBase<int> {
        Iterator<int> get iterator => ValuesIterator();
      }

      int main() {
        final values = Values();
        return values.length * 100 + values.first * 10 + values.last;
      }
    ''', 313);
  });

  test('overridden length can call inherited super.length', () {
    check(r'''
      class ValuesIterator implements Iterator<int> {
        int index = 0;
        int get current => index;
        bool moveNext() {
          if (index == 2) return false;
          index++;
          return true;
        }
      }

      class Values extends Iterable<int> {
        Iterator<int> get iterator => ValuesIterator();
        int get length => super.length + 10;
      }

      int main() => Values().length;
    ''', 12);
  });

  test('inherited Iterable methods accept a wrapped list iterator', () {
    check(r'''
      class Values extends Iterable<int> {
        Iterator<int> get iterator => <int>[2, 4, 6].iterator;
      }

      int main() {
        final values = Values();
        return values.length * 100 + values.first * 10 + values.last;
      }
    ''', 326);
  });

  test('Iterable.withIterator accepts a guest iterator', () {
    check(r'''
      class ValuesIterator implements Iterator<int> {
        int index = 0;
        int get current => index;
        bool moveNext() {
          if (index == 3) return false;
          index++;
          return true;
        }
      }

      int main() {
        final values = Iterable<int>.withIterator(() => ValuesIterator());
        return values.length * 100 + values.first * 10 + values.last;
      }
    ''', 313);
  });

  test('inherited map can return guest objects', () {
    check(r'''
      class Item {
        Item(this.value);
        final int value;
      }

      class ItemIterator implements Iterator<Item> {
        int index = 0;
        Item get current => Item(index);
        bool moveNext() {
          if (index == 2) return false;
          index++;
          return true;
        }
      }

      class Items extends Iterable<Item> {
        Iterator<Item> get iterator => ItemIterator();
      }

      int main() => Items().map((item) => Item(item.value + 10)).toList()[1].value;
    ''', 12);
  });

  test('inherited followedBy accepts a guest iterable', () {
    check(r'''
      class ValuesIterator implements Iterator<int> {
        ValuesIterator(this.start);
        final int start;
        int index = 0;
        int get current => start + index - 1;
        bool moveNext() {
          if (index == 2) return false;
          index++;
          return true;
        }
      }

      class Values extends Iterable<int> {
        Values(this.start);
        final int start;
        Iterator<int> get iterator => ValuesIterator(start);
      }

      int main() {
        final combined = Values(1).followedBy(Values(3)).toList();
        return combined[0] * 1000 + combined[1] * 100 +
            combined[2] * 10 + combined[3];
      }
    ''', 1234);
  });
}
