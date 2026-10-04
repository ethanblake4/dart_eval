import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _source = '''
bool main() {
  final smallestInt = <int>[42, 17, 99, 5].reduce(
    (a, b) => Comparable.compare(a, b) < 0 ? a : b,
  );
  final smallestString = <String>['quiver', 'dart', 'eval'].reduce(
    (a, b) => Comparable.compare(a, b) < 0 ? a : b,
  );
  if (smallestInt != 5 || smallestString != 'dart') return false;

  try {
    Comparable.compare(1, 'incompatible');
    return false;
  } on TypeError {
    return true;
  }
}
''';

void main() {
  final program = Compiler().compile({
    'probe': {'main.dart': _source},
  });

  for (final (label, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('encoded', Runtime(program.write().buffer)),
  ]) {
    test('$label Comparable.compare supports native minimum reductions', () {
      expect(runtime.executeLib('package:probe/main.dart', 'main'), isTrue);
    });
  }
}
