import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart' show $Value;
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

Future<void> expectBoth(String source) async {
  final program = Compiler().compile({
    'pattern_loop': {'main.dart': source},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    final result = await runtime.executeLib(
      'package:pattern_loop/main.dart',
      'main',
    );
    expect(result is $Value ? result.$reified : result, 0);
  }
}

void main() {
  test(
    'for-in destructuring preserves scoped variables and per-iteration captures',
    () async {
      await expectBoth(_sync);
    },
  );
  test(
    'await-for and collection patterns preserve iteration captures',
    () async {
      await expectBoth(_async);
    },
  );
  test('for-in patterns provide the iterable inference context', () async {
    await expectBoth(_context);
  });
  test('final for-in pattern variables reject writes', () {
    expect(
      () => Compiler().compile({
        'pattern_loop': {
          'main.dart': '''
      void main() {
        for (final (number, text) in [(1, 'a')]) number = 2;
      }
    ''',
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}

const _sync = r'''
void check(bool value) {
  if (!value) throw StateError('for-in pattern mismatch');
}
class Entry {
  final int number;
  Entry(this.number);
}
extension Increment on int {
  int get incremented => this + 1;
}
class Rows<T> implements Iterable<(int, String)> {
  Iterator<(int, String)> get iterator => Cursor();
  dynamic noSuchMethod(Invocation invocation) => throw StateError('unused');
}
class Cursor implements Iterator<(int, String)> {
  int index = 0;
  bool moveNext() { index++; return index <= 3; }
  (int, String) get current => (index, 'row$index');
}
int main() {
  final captures = <int Function()>[];
  var total = 0;
  for (var (number, text) in [(1, 'a'), (2, 'bb'), (3, 'ccc')]) {
    number += 10;
    captures.add(() => number);
    if (text == 'bb') continue;
    total += number;
  }
  check(total == 24);
  check(captures.map((f) => f()).join(',') == '11,12,13');
  final finals = <String Function()>[];
  for (final (number, text) in Rows<bool>()) {
    check(number.incremented == number + 1);
    finals.add(() => '$number:$text');
    if (number == 2) break;
  }
  check(finals.map((f) => f()).join(',') == '1:row1,2:row2');
  var sum = 0;
  for (var [first, ...rest] in [[1, 2, 3], [4]]) {
    sum += first;
    sum += rest.length;
  }
  check(sum == 7);
  for (final Entry(:number) in [Entry(2), Entry(3)]) sum += number;
  for (var {'key': number} in [{'key': 4}]) sum += number;
  check(sum == 16);
  var number = 100;
  for (var (number, text) in [(1, 'outer')]) {
    for (final (number, text) in [(2, 'inner')]) {
      check(number == 2 && text == 'inner');
    }
    check(number == 1 && text == 'outer');
  }
  check(number == 100);
  final elements = [for (final (number, text) in Rows<bool>()) '$number:$text'];
  check(elements.join(',') == '1:row1,2:row2,3:row3');
  var reached = false;
  var failed = false;
  try {
    for (var [int first, int second] in <dynamic>[[1]]) reached = true;
  } on StateError {
    failed = true;
  }
  check(failed && !reached);
  var badType = false;
  try {
    for (var (int _) in <dynamic>['bad']) reached = true;
  } on StateError { badType = true; }
  check(badType && !reached);
  for (var (int _) in <dynamic>[1, 2]) {}
  return 0;
}

''';

const _async = r'''
import 'dart:async';
extension NextValue on int {
  int get next => this + 1;
}
class GenericRows<T> implements Iterable<(int, String)> {
  Iterator<(int, String)> get iterator => RowIterator();
  dynamic noSuchMethod(Invocation invocation) => throw StateError('unused');
}
class RowIterator implements Iterator<(int, String)> {
  bool advanced = false;
  bool moveNext() {
    if (advanced) return false;
    advanced = true;
    return true;
  }
  (int, String) get current => (3, 'three');
}
Future<int> main() async {
  final captures = <int Function()>[];
  await for (var (number, text) in Stream.fromIterable([(1, 'a'), (2, 'b')])) {
    number += 10;
    captures.add(() => number);
  }
  if (captures.map((f) => f()).join(',') != '11,12') {
    throw StateError('await-for capture mismatch');
  }
  final elements = [
    await for (final [first, second] in Stream.fromIterable([[1, 2], [3, 4]]))
      first + second,
  ];
  if (elements.join(',') != '3,7') throw StateError('async collection mismatch');
  await for (final (number, text) in Stream.fromIterable(GenericRows<bool>())) {
    if (number.next != 4 || text != 'three') throw StateError('stream element type');
  }
  return 0;
}

''';

const _context = r'''
int main() {
  for (final (double number, String text) in [(1, 'a')]) {
    if (number != 1.0 || text != 'a') throw StateError('record context');
  }
  for (var [double number] in [[1]]) {
    if (number != 1.0) throw StateError('list context');
  }
  return 0;
}

''';
