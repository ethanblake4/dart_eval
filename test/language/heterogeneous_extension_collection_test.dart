import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('heterogeneous generic extension results retain their shared owner', () {
    final program = Compiler().compile({
      'heterogeneous': {
        'wrapper.dart': '''
          class Wrapper<T> {
            final T value;
            Wrapper(this.value);
          }
        ''',
        'mapping.dart': '''
          import 'wrapper.dart';
          extension Mapping<R> on Wrapper<R> {
            Wrapper<S> map<S>(S Function(R) callback) =>
                Wrapper<S>(callback(value));
            Wrapper<S> cast<S>() => Wrapper<S>(value as S);
            Wrapper<R> same() => this;
            Wrapper<List<R>> items() => Wrapper<List<R>>([value]);
            Type get argument => R;
          }
          extension Either on Wrapper {
            Wrapper<dynamic> operator |(Wrapper other) => this;
          }
          extension Choice<R> on Iterable<Wrapper<R>> {
            Wrapper<R> choice() => first;
          }
          extension StringItems on Wrapper<List<String>> {
            Wrapper<String> joined() => Wrapper<String>(value.join());
          }
        ''',
        'values.dart': '''
          import 'wrapper.dart';
          import 'mapping.dart' show Mapping, Either, Choice, StringItems;
          import 'callbacks.dart' show selector, sequence, identity;
          final Wrapper<num> number = Wrapper<num>(2);
          final quoted =
              (Wrapper<String>('text') | Wrapper<String>('other')).cast<String>();
          final retained = quoted.same();
          final joined = [
            Wrapper<int>(65).map((_) => String.fromCharCode(65)),
            Wrapper<int>(66).map((_) => 'B'),
          ].choice().items().joined();
          final fromTearoff = Wrapper<int>(67).map(String.fromCharCode);
          final parsed = Wrapper<String>('4').map(int.parse);
          final value = 12;
          final unknown = Wrapper<String>('identity').map((value) => value);
          final selected = Wrapper<String>('7').map(selector);
          final sequenced = selected.items().map(sequence);
          final generic = identity;
        ''',
        'callbacks.dart': '''
          typedef Selector = int Function();
          Selector selector(String input) => () => int.parse(input);
          Selector sequence(Iterable<Selector> selectors) => selectors.first;
          T identity<T>(T value) => value;
        ''',
        'main.dart': '''
          import 'wrapper.dart';
          import 'values.dart';
          import 'mapping.dart' show Mapping, Choice;
          final literal = [
            Wrapper<String>('null').map((_) => null),
            Wrapper<String>('false').map((_) => false),
            Wrapper<String>('true').map((_) => true),
            number,
            quoted,
          ].choice();
          int main() {
            if (retained is! Wrapper<String>) return -2;
            if (joined.value != 'A' || joined.argument != String) return -3;
            if (fromTearoff.argument != String || parsed.argument != int) return -4;
            if (unknown.argument != dynamic) return -5;
            if (sequenced.value() != 7) return -6;
            if (generic<int>(3) != 3 || generic<String>('ok') != 'ok') return -7;
            return literal.value == null ? 1 : -1;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(runtime.executeLib('package:heterogeneous/main.dart', 'main'), 1);
    }
  });
}
