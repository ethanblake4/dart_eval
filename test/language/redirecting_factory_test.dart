import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _declarations = '''
abstract class Text {
  factory Text(String value, {String label}) = TextImpl.named;
  Object get value;
  Object get label;
  int get extra;
}
class TextImpl implements Text {
  final Object value;
  final Object label;
  final int extra;
  TextImpl.named(this.value, {this.extra = 7, this.label = 'default'});
}
abstract class Number {
  factory Number(int value) = NumberImpl;
  num get value;
}
class NumberImpl implements Number {
  final num value;
  NumberImpl(this.value);
}
abstract class Generic<T> {
  factory Generic(T value, [String label]) = GenericImpl<T>.named;
  Object? get value;
  Object get label;
}
class GenericImpl<T> implements Generic<T> {
  final Object? value;
  final Object label;
  GenericImpl.named(this.value, [this.label = 'generic']);
}
''';

void _run(String body, Object expected) {
  final program = Compiler().compile({
    'redirecting_factory': {'main.dart': '$_declarations\n$body'},
  });
  for (final runtime in [
    Runtime.ofProgram(program),
    Runtime(program.write().buffer),
  ]) {
    expect(
      runtime.executeLib('package:redirecting_factory/main.dart', 'main'),
      expected,
    );
  }
}

void main() {
  test('exported factory types resolve in the factory library', () {
    final program = Compiler().compile({
      'redirecting_factory': {
        'main.dart': '''
import 'target.dart';
class OwnType { final int value; OwnType(this.value); }
abstract class Factory {
  factory Factory(OwnType value) = Implementation;
  Object get value;
}
int main() => (Factory(OwnType(7)).value as OwnType).value;
''',
        'target.dart': '''
import 'main.dart' show Factory;
class Implementation implements Factory {
  final Object value;
  Implementation(this.value);
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:redirecting_factory/main.dart', 'main'),
        7,
      );
    }
  });

  test('inherited defaults bypass factory checks only when omitted', () {
    _run('''
class Defaults {
  final int value;
  Defaults({value}) : value = value ?? 2;
  factory Defaults.redirect({int value}) = Defaults;
}
int main() {
  final make = Defaults.redirect;
  dynamic dynamicMake = make;
  dynamic value = null;
  var rejected = 0;
  try { Defaults.redirect(value: value); } on TypeError { rejected++; }
  try { dynamicMake(value: null); } on TypeError { rejected++; }
  Defaults dynamicDefault = dynamicMake();
  return Defaults.redirect().value + make().value + dynamicDefault.value +
      make(value: 3).value + rejected;
}
''', 11);
  });

  test('redirect target determines erased versus primitive factory slots', () {
    _run('''
abstract class Bounded<T extends int> {
  factory Bounded(T value) = BoundedImpl<T>;
  int get value;
}
class BoundedImpl<T extends int> implements Bounded<T> {
  final int value;
  BoundedImpl(this.value);
}
int main() {
  final make = Bounded<int>.new;
  dynamic dynamicMake = make;
  Bounded<int> dynamicValue = dynamicMake(3);
  return Bounded<int>(1).value + make(2).value + dynamicValue.value;
}
''', 6);
  });

  test('redirect chains use terminal storage for inherited null defaults', () {
    _run('''
abstract class First {
  factory First([int value]) = Second;
  Object? get value;
}
abstract class Second implements First {
  factory Second([int value]) = Last;
}
class Last implements Second {
  final dynamic value;
  Last([this.value]);
}
int main() {
  final make = First.new;
  dynamic dynamicMake = make;
  var total = 0;
  if (First().value == null) total++;
  if (make().value == null) total++;
  if ((dynamicMake() as First).value == null) total++;
  return total + First(4).value as int;
}
''', 7);
  });

  test('redirect chains preserve erased intermediate generic slots', () {
    _run('''
abstract class First {
  factory First([int value]) = Second<int>;
  int get value;
}
abstract class Second<T extends int> implements First {
  factory Second([T value]) = Last<T>;
}
class Last<T extends int> implements Second<T> {
  final int value;
  Last([this.value = 1]);
}
int main() {
  final make = First.new;
  dynamic dynamicMake = make;
  return First().value + make().value +
      (dynamicMake() as First).value + First(4).value;
}
''', 7);
  });

  test('redirected constructors preserve field initializer effect order', () {
    _run('''
String trace = '';
String mark(String value) { trace += value; return value; }
class Base {
  String field = mark('f');
  String initialized;
  Base.redirect() : this.named(mark('a'));
  Base.named(String value) : initialized = mark('i') { mark('b'); }
}
class Derived extends Base {
  String own = mark('d');
  Derived() : super.redirect() { mark('c'); }
}
String main() {
  Base.redirect();
  final base = trace;
  trace = '';
  Derived();
  return base + ':' + trace;
}
''', 'afib:dafibc');
  });

  test('late field initializers observe initializer-list effects', () {
    _run(r'''
String trace = '';
int state = 0;
int mark(String name, int value) { trace += name; state = value; return value; }
class Fields {
  int eager = mark('e', 1);
  late int snapshot = state;
  late final int deferred = mark('l', 3);
  int initialized;
  Fields() : initialized = mark('i', 2);
  Fields.overridden() : initialized = mark('i', 2), snapshot = 4;
}
String main() {
  final first = Fields();
  final snapshot = first.snapshot;
  final deferred = first.deferred;
  final result = '$trace:$snapshot:${first.initialized}:$deferred';
  trace = '';
  final second = Fields.overridden();
  second.deferred;
  return '$result:$trace:${second.snapshot}:${second.initialized}';
}
''', 'eil:2:2:3:eil:4:2');
  });

  test(
    'redirect chains inherit constant defaults from their source library',
    () {
      final program = Compiler().compile({
        'redirecting_factory': {
          'main.dart': '''
import 'target.dart';
abstract class Factory {
  factory Factory([List<int> values]) = Intermediate;
  List<int> get values;
}
int main() {
  final make = Factory.new;
  dynamic dynamicMake = make;
  return Factory().values.first + make().values.first +
      (dynamicMake() as Factory).values.first;
}
''',
          'target.dart': '''
import 'main.dart';
const _values = <int>[7];
abstract class Intermediate implements Factory {
  factory Intermediate([List<int> values]) = Implementation;
}
class Implementation implements Intermediate {
  final List<int> values;
  Implementation([this.values = _values]);
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:redirecting_factory/main.dart', 'main'),
          21,
        );
      }
    },
  );

  test('factory checks its own narrower signature before forwarding', () {
    _run('''
int main() {
  var rejected = 0;
  dynamic integer = 42;
  dynamic fraction = 3.5;
  try { Text(integer); } on TypeError { rejected++; }
  try { Text('ok', label: integer); } on TypeError { rejected++; }
  try { Number(fraction); } on TypeError { rejected++; }
  final text = Text('ok');
  if (text.value != 'ok' || text.label != 'default' || text.extra != 7) {
    return -1;
  }
  return rejected + Number(4).value.toInt();
}
''', 7);
  });

  test('factory tear-offs retain own ABI and inherit target defaults', () {
    _run('''
int main() {
  final text = Text.new;
  dynamic dynamicText = text;
  dynamic dynamicNumber = Number.new;
  var rejected = 0;
  try { dynamicText(42); } on TypeError { rejected++; }
  try { dynamicText('ok', label: 42); } on TypeError { rejected++; }
  try { dynamicNumber(3.5); } on TypeError { rejected++; }
  if (text('ok').label != 'default' || text('ok').extra != 7) return -1;
  Number valid = dynamicNumber(4);
  return rejected + valid.value.toInt();
}
''', 7);
  });

  test('generic redirect checks applied factory type arguments', () {
    _run('''
int main() {
  dynamic value = 42;
  var rejected = 0;
  try { Generic<String>(value); } on TypeError { rejected++; }
  dynamic make = Generic<String>.new;
  try { make(42); } on TypeError { rejected++; }
  final valid = make('ok');
  return valid.value == 'ok' && valid.label == 'generic' ? rejected : -1;
}
''', 2);
  });

  test('redirect target extra parameters do not widen factory call shape', () {
    for (final expression in [
      "Text(42)",
      "Text('ok', extra: 2)",
      "Number(3.5)",
    ]) {
      expect(
        () => Compiler().compile({
          'redirecting_factory': {
            'main.dart': '$_declarations\nvoid main() { $expression; }',
          },
        }),
        throwsA(isA<CompileError>()),
      );
    }
  });
}
