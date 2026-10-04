import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  test('native map retains method types, guest identity and lazy checks', () {
    final program = Compiler().compile({
      'probe': {
        'main.dart': '''
          class Token { final String text; Token(this.text); }
          class Tokens extends Iterable<Token> {
            final List<Token> values;
            Tokens(this.values);
            Iterator<Token> get iterator => values.iterator;
            List<Token> mapped() => super.map<Token>((e) => e).toList();
          }
          List<T> collect<T>(Iterable<T> values) => values.map<T>((e) => e).toList();
          bool main() {
            final token = Token('x');
            final inferred = ['x'].map(Token.new).toList();
            if (inferred is! List<Token> || inferred.single.text != 'x') return false;
            final identities = collect<Token>([token]);
            if (!identical(identities.single, token)) return false;
            final inherited = Tokens([token]).mapped();
            if (inherited is! List<Token> || !identical(inherited.single, token)) return false;
            final widened = [1].map<num>((e) => e).toList();
            widened.add(2.5);
            dynamic checked = widened;
            try { checked.add('wrong'); return false; } on TypeError {}
            if (widened is! List<num> || widened[1] != 2.5) return false;

            int calls = 0;
            dynamic wrong = 'wrong';
            final lazy = [1].map<int>((e) { calls++; return wrong; });
            if (calls != 0) return false;
            try { lazy.toList(); return false; } on TypeError {}
            if (calls != 1) return false;

            final nested = [token].map<Token>((e) {
              final inner = [1].map<String>((n) => 'inner').toList();
              if (inner.single != 'inner') throw StateError('nested map');
              return e;
            }).toList();
            return nested is List<Token> && identical(nested.single, token);
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      final result = runtime.executeLib('package:probe/main.dart', 'main');
      expect(result, isTrue);
      expect(runtime.bridgeCallTypeArguments, isEmpty);
    }
  });
}
