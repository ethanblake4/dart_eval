import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
int reads = 0;
int guards = 0;
class Box {
  int get value { reads++; return 7; }
}
int guarded(Object? value) {
  if (value case Box(value: var number) when ++guards > 0) {
    return number;
  }
  return 0;
}
int list(Object? value) => switch (value) {
  [] => 10,
  [var first] => first as int,
  _ => 0,
};
int record(Object value) => switch (value) {
  (int number,) => number,
  _ => 0,
};
int scalar(num value) {
  if (value case int _ && var number) {
    value.check<Exactly<int>>();
    number.check<Exactly<int>>();
    return number;
  }
  return 0;
}
int nested(Object value) {
  if (value case num _ && (int _ && var number)) {
    value.check<Exactly<int>>();
    number.check<Exactly<int>>();
    return number;
  }
  return 0;
}
int field((Object,) value) {
  if (value case (int _ && num _,)) {
    value.check<Exactly<(int,)>>();
    return value.$1;
  }
  return 0;
}
int main() {
  var result = guarded('wrong') + guarded(null) + guarded(Box());
  result += list(null) + list('wrong') + list(<int>[]) +
      list(<int>[3]) + list(<int>[1, 2]);
  result += record('wrong') + record((2, 'wrong')) + record((4,));
  result += scalar(2) + scalar(2.5) + nested(3) + field((4,));
  var number = 5;
  if (1 case var number when false) {
    result += 100;
  } else {
    result += number;
  }
  if (guards != 1 || reads != 1) throw StateError('eager pattern or guard');
  return result;
}
''';

const _snapshotSource = r'''
int main() {
  Object value = 1;
  var matched = 0;
  switch (value) {
    case int _ when ((value = 'changed') == 'never'):
      throw StateError('guard accepted');
    case var original:
      matched = original as int;
  }
  if (value != 'changed' || matched != 1) throw StateError('changed subject');
  if (() case ()) {} else { throw StateError('empty record missed'); }
  if ((1,) case ()) throw StateError('wrong record shape');
  if ('wrong' case ()) throw StateError('non-record matched');
  return matched;
}
''';

const _interfaceSource = r'''
abstract class Tagged { String get label; }
class Base {}
class Derived extends Base implements Tagged {
  String get label => 'hello';
}
int marker(Base value) {
  if (value case Tagged(label: var label)) return label.length;
  return 0;
}
int main() {
  String? text = 'text';
  var sum = 0;
  if (text case final String text) sum += text.length;
  for (final thing in [2.5, 'ab', Object()]) {
    if (thing case final double thing) {
      sum += 1;
    } else if (thing case final String thing) {
      sum += 2;
    } else if (thing case final Object thing) {
      sum += 3;
    }
  }
  return sum + marker(Base()) + marker(Derived());
}
''';

const _nonListSource = r'''
int reads = 0;
class HasLength {
  int get length { reads++; return 0; }
}
bool matches(HasLength value) => switch (value) {
  [] => true,
  _ => false,
};
int main() {
  if (matches(HasLength()) || reads != 0) {
    throw StateError('list pattern accepted a non-list or read its length');
  }
  return 0;
}
''';

void main() {
  test('list patterns reject unrelated static types before reading length', () {
    final program = Compiler().compile({
      'pattern_flow': {'main.dart': _nonListSource},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:pattern_flow/main.dart', 'main'), 0);
    }
  });
  test(
    'object interfaces expose getters and typed patterns can shadow subjects',
    () {
      final program = Compiler().compile({
        'pattern_flow': {'main.dart': _interfaceSource},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:pattern_flow/main.dart', 'main'),
          15,
        );
      }
    },
  );
  test('pattern tests guard reads, guards, and refined bindings', () {
    final program = Compiler().compile({
      'pattern_flow': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:pattern_flow/main.dart', 'main'), 38);
    }
  });
  test('failed guards preserve the switch snapshot and record shapes', () {
    final program = Compiler().compile({
      'pattern_flow': {'main.dart': _snapshotSource},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:pattern_flow/main.dart', 'main'), 1);
    }
  });
}
