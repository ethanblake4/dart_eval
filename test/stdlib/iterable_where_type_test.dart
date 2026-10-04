import 'package:dart_eval/dart_eval.dart';
import 'package:test/test.dart';

void main() {
  for (final entry in ['main', 'bridgeMain']) {
    test('whereType $entry filters with the requested runtime type', () {
      final program = Compiler().compile({
        'probe': {
          'main.dart': '''
          class Token {}
          class Child extends Token {}
          class Values extends Iterable<Object?> {
            final List<Object?> values;
            Values(this.values);
            Iterator<Object?> get iterator => values.iterator;
            Iterable<T> filtered<T>() => super.whereType<T>();
          }
          Iterable<T> filter<T>(Iterable<Object?> values) => values.whereType<T>();
          String join(String first, [String? second, String? third]) =>
              [first, second, third].whereType<String>()
                  .where((part) => part.isNotEmpty).join('/');
          bool check(Iterable<Object?> source, Token token) {
            final strings = filter<String>(source).toList();
            if (strings is! List<String> || strings.length != 1 || strings.single != 'x') return false;
            final nullable = source.whereType<String?>().toList();
            if (nullable is! List<String?> || nullable.length != 2 || nullable.first != null) return false;
            final tokens = source.whereType<Token>().toList();
            if (tokens is! List<Token> || !identical(tokens.single, token)) return false;
            final objects = source.whereType<Object>().toList();
            if (objects.length != 4 || objects.any((e) => e == null)) return false;
            final all = source.whereType<dynamic>().toList();
            if (all.length != 5 || all.first != null) return false;
            final numbers = source.whereType<num>().toList();
            if (numbers is! List<num> || numbers.length != 2) return false;
            numbers.add(2.5);
            dynamic checked = strings;
            try { checked.add(null); return false; } on TypeError {}
            dynamic checkedNumbers = numbers;
            try { checkedNumbers.add('wrong'); return false; } on TypeError {}
            return true;
          }
          bool main() {
            if (join('a') != 'a' || join('a', '', 'b') != 'a/b') return false;
            final token = Child();
            final values = <Object?>[null, 'x', 1, 1.5, token];
            if (!check(values, token)) return false;
            int reads = 0;
            final lazy = values.map<Object?>((value) { reads++; return value; })
                .whereType<String>();
            if (reads != 0) return false;
            final result = lazy.toList();
            return reads == 5 && result.single == 'x';
          }
          bool bridgeMain() {
            final token = Child();
            final inherited = Values([null, 'x', 1, 1.5, token]);
            final strings = inherited.filtered<String>().toList();
            if (strings is! List<String> || strings.single != 'x') return false;
            final nullable = inherited.filtered<String?>().toList();
            if (nullable is! List<String?> || nullable.length != 2 || nullable.first != null) return false;
            final tokens = inherited.filtered<Token>().toList();
            return tokens is List<Token> && identical(tokens.single, token);
          }
        ''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:probe/main.dart', entry), isTrue);
        expect(runtime.bridgeCallTypeArguments, isEmpty);
      }
    });
  }
}
