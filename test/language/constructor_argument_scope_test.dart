import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

const _support = r'''
// @dart=3.0
class Item {
  final int value;
  Item(this.value);
}
class Box<T> {
  final T value;
  Box(this.value);
  Box.named(this.value);
  factory Box.redirect(T value) = Box<T>;
}
class Reordered<A, B> {
  final B value;
  Reordered(this.value);
}
''';

const _source = r'''
// @dart=3.0
import 'support.dart' as _support;
class Item {
  final int value;
  Item(this.value);
}
_support.Box<T> lexical<T>(T value) => _support.Box<T>(value);
bool verify() {
  final implicit = _support.Box<_support.Item>(_support.Item(1));
  final explicit = new _support.Box<_support.Item>(_support.Item(2));
  final named = _support.Box<_support.Item>.named(_support.Item(3));
  final redirect = _support.Box<_support.Item>.redirect(_support.Item(4));
  final reordered = _support.Reordered<String, _support.Item>(_support.Item(5));
  final local = _support.Box<Item>(Item(6));
  final generic = lexical<Item>(Item(7));
  return implicit.value is _support.Item && implicit.value.value == 1 &&
      explicit.value is _support.Item && explicit.value.value == 2 &&
      named.value is _support.Item && named.value.value == 3 &&
      redirect.value is _support.Item && redirect.value.value == 4 &&
      reordered.value is _support.Item && reordered.value.value == 5 &&
      local.value is Item && local.value.value == 6 &&
      generic.value is Item && generic.value.value == 7;
}
void main() {
  if (!verify()) throw StateError('constructor caller type argument scope');
}
''';

void main() {
  test('explicit constructor type arguments resolve in the caller library', () {
    final program = Compiler().compile({
      'constructor_scope': {'main.dart': _source, 'support.dart': _support},
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:constructor_scope/main.dart', 'verify'),
        true,
      );
    }
  });
}
