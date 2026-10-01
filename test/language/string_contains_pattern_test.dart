import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('String.contains accepts native patterns and honors startIndex', () {
    final program = Compiler().compile({
      'patterns': {'main.dart': _source},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:patterns/main.dart', 'witness'), true);
    }
  });
}

const _source = r'''
bool rejectsIndex(int start) {
  try {
    'abc'.contains(RegExp('b'), start);
    return false;
  } on RangeError {
    return true;
  }
}

bool witness() {
  const text = 'abcabc';
  final Pattern pattern = RegExp('bc');
  dynamic dynamicPattern = pattern;
  return text.contains(pattern) &&
      text.contains(pattern, 3) &&
      !text.contains(pattern, 5) &&
      text.contains(dynamicPattern) &&
      text.contains('bc', 3) &&
      !text.contains('bc', 5) &&
      text.contains('', text.length) &&
      text.contains(RegExp(r'$'), text.length) &&
      rejectsIndex(-1) && rejectsIndex(4);
}

void main() {
  if (!witness()) throw StateError('String.contains pattern contract');
}
''';
