import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

const _source = r'''
String render(String? value) => 'value=$value';
class ChangingText {
  int reads = 0;
  String? get value {
    reads++;
    return reads == 1 ? 'first' : null;
  }
}
String property(ChangingText text) {
  if (text.value != null) return '<${text.value}>';
  return 'none';
}
bool verify() {
  final text = ChangingText();
  return render(null) == 'value=null' && render('hello') == 'value=hello' &&
      property(text) == '<null>' && text.reads == 2;
}
void main() {
  if (!verify()) throw StateError('nullable string interpolation');
}
''';

void main() {
  test('nullable string interpolation converts each observed value', () {
    final program = Compiler().compile({
      'nullable_string': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:nullable_string/main.dart', 'verify'),
        true,
      );
    }
  });

  test(
    'interpolation concatenation preserves conversion and evaluation order',
    () {
      final program = Compiler().compile({
        'nullable_string': {
          'main.dart': r'''
String trace = '';
int conversions = 0;

class Printable {
  String toString() {
    conversions++;
    trace += 'p';
    return 'printable';
  }
}

class Failing {
  String toString() {
    trace += 'f';
    throw 'format';
  }
}

String emit(String label, String value) {
  trace += label;
  return value;
}

bool main(String long) {
  trace = '';
  final pieces = '${emit('a', 'A')}${emit('b', 'éλ🙂')}${emit('c', '')}$long';
  if (pieces != 'Aéλ🙂' + long || trace != 'abc') return false;

  Object? nullable;
  if ('$nullable' != 'null') return false;

  trace = '';
  conversions = 0;
  final printable = Printable();
  if ('$printable$printable' != 'printableprintable' ||
      conversions != 2 || trace != 'pp') return false;

  trace = '';
  var mutable = 'before';
  String change() {
    mutable = 'after';
    trace += 'm';
    return 'middle';
  }
  final changed = mutable + change() + 'end';
  if (changed != 'beforemiddleend' || mutable != 'after' || trace != 'm') {
    return false;
  }

  trace = '';
  var laterRan = false;
  String later() {
    laterRan = true;
    return 'later';
  }
  var caught = false;
  try {
    '${Failing()}${later()}';
  } on String {
    caught = true;
  }
  if (!caught || laterRan || trace != 'f') return false;

  const left = 'constant';
  const right = ' pieces';
  return identical('$left$right', 'constant pieces');
}
''',
        },
      });
      final long = '0123456789' * 128;
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib(
            'package:nullable_string/main.dart',
            'main',
            arguments: {'long': long},
          ),
          true,
        );
      }
    },
  );

  test('string concatenation rejects a nullable operand', () {
    expect(
      () => Compiler().compile({
        'nullable_string_invalid': {
          'main.dart':
              "String invalid(String? value) => 'prefix' + value; void main() {}",
        },
      }),
      throwsA(isA<CompileError>()),
    );
  });
}
