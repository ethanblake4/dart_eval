import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('factory subclasses retain their own and inherited field storage', () {
    final program = Compiler().compile({
      'layout': {
        'main.dart': '''
class Base {
  int value = 55;
  Base();
  factory Base.redirect() = Derived;
  factory Base.create() => Derived();
}
class Derived extends Base {
  int own = 7;
  Derived();
}
int check(Base value) {
  final before = value.value;
  value.value = 66;
  final derived = value as Derived;
  return before + value.value + derived.own;
}
int main() {
  final redirected = Base.redirect();
  final created = Base.create();
  final before = redirected.value + created.value;
  redirected.value = 66;
  created.value = 66;
  return before + redirected.value + created.value +
      (redirected as Derived).own + (created as Derived).own +
      check(Base.redirect()) + check(Base.create());
}
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:layout/main.dart', 'main'), 512);
    }
  });

  test(
    'deferred cyclic redirects access inherited fields after loading',
    () async {
      final program = Compiler().compile({
        'layout': {
          'main.dart': '''
import 'derived.dart' deferred as lib;
class Base {
  int value = 55;
  Base();
  factory Base.redirect() = lib.Derived;
}
Future<int> main() => lib.loadLibrary().then((_) {
  final value = Base.redirect();
  final before = value.value;
  value.value = 66;
  return before + value.value;
});
''',
          'derived.dart': '''
import 'main.dart' as main;
class Derived extends main.Base {
  Derived();
}
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        final result = await runtime.executeLib(
          'package:layout/main.dart',
          'main',
        );
        expect(result is $Value ? result.$value : result, 121);
      }
    },
  );
}
