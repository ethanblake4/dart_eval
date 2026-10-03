import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('guest formatting happens once at constructor and write boundaries', () {
    final program = Compiler().compile({
      'buffer': {
        'main.dart': '''
int formats = 0;
class Printable {
  String toString() => 'v' + (++formats).toString();
}
class Failing {
  String toString() { formats++; throw 'format'; }
}
bool main() {
  final value = Printable();
  final buffer = StringBuffer(value);
  Object? nullable = value;
  dynamic widened = value;
  buffer.write(nullable);
  buffer.write(widened);
  buffer.write(null);
  if (buffer.toString() != 'v1v2v3null' || formats != 3) return false;
  var failures = 0;
  try { StringBuffer(Failing()); } on String { failures++; }
  try { buffer.write(Failing()); } on String { failures++; }
  return failures == 2 && formats == 5 && buffer.toString() == 'v1v2v3null';
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:buffer/main.dart', 'main'), true);
    }
  });
  test(
    'StringBuffer subclasses dispatch write overrides through base types',
    () {
      final program = Compiler().compile({
        'buffer': {
          'main.dart': '''
class CustomBuffer extends StringBuffer {
  int writes = 0;
  CustomBuffer() : super();
  @override
  void write(Object? value) {
    writes++;
    super.write('[' + value.toString() + ']');
  }
}
void append(StringBuffer buffer) => buffer.write('b');
String main() {
  final buffer = CustomBuffer();
  buffer.write('a');
  append(buffer);
  final native = StringBuffer('start');
  append(native);
  return buffer.writes.toString() + ':' + buffer.toString() + ':' + native.toString();
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib('package:buffer/main.dart', 'main'),
          '2:[a][b]:startb',
        );
      }
    },
  );
  test(
    'StringBuffer writes native strings alongside boxed and null values',
    () {
      final program = Compiler().compile({
        'buffer': {
          'main.dart': '''
        String main(String text) {
          final buffer = StringBuffer();
          buffer.write(text + '!');
          buffer.write(text.substring(1));
          Object boxed = 'boxed';
          buffer.write(boxed);
          buffer.write(null);
          buffer.write(42);
          return buffer.toString();
        }
      ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib(
            'package:buffer/main.dart',
            'main',
            arguments: {'text': 'abc'},
          ),
          'abc!bcboxednull42',
        );
      }
      // Only the Object assignment needs a wrapper; substring and native
      // StringBuffer writes keep their strings unboxed.
      expect(
        program.typedProgram.instructions.where(
          (entry) => entry.$2.name == 'rBoxString',
        ),
        hasLength(1),
      );
    },
  );
}
