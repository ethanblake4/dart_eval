import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('covariant collection arguments retain nullable joins', () {
    final nullableProgram = Compiler().compile({
      'nullable_join': {
        'main.dart': '''
          class Box<T> {
            final T value;
            Box(this.value);
          }
          bool main() {
            final pair = [Box<Null>(null), Box<int>(1)];
            final mixed = [Box<Null>(null), Box<int>(1), Box<bool>(true)];
            dynamic mutable = mixed;
            bool checked = false;
            try { mutable.add('wrong'); } on TypeError { checked = true; }
            return pair is List<Box<int?>> && pair.first.value == null &&
                mixed is List<Box<Object?>> && mixed.first.value == null &&
                checked;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(nullableProgram),
      Runtime(nullableProgram.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:nullable_join/main.dart', 'main'),
        true,
      );
    }
  });

  final program = Compiler().compile({
    'boundary': {
      'main.dart': '''
        class Token {
          final int value;
          Token(this.value);
          String toString() => 'token';
        }
        bool main() {
          final token = Token(7);
          final mapped = <String, Token>{'key': token}.map<int, Token>(
            (key, value) => MapEntry(key.length, value));
          dynamic values = mapped.values;
          dynamic mutable = mapped;
          bool checked = false;
          try { mutable[3] = 'wrong'; } on TypeError { checked = true; }
          return identical(values.first, token) &&
              values.first.toString() == 'token' &&
              mapped is Map<int, Token> && values is Iterable<Token> && checked;
        }
        int native(dynamic values) => values.first + values.last +
            values.single + values.elementAt(0) +
            values.map((value) => value + 1).first +
            values.where((value) => value > 0).first;
      ''',
    },
  });

  for (final (mode, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('serialized', Runtime(program.write().buffer)),
  ]) {
    test('$mode map transforms preserve guest identity and type checks', () {
      expect(runtime.executeLib('package:boundary/main.dart', 'main'), true);
    });

    test(
      '$mode iterable reads box native values and reject invalid elements',
      () {
        runtime.executeLib('package:boundary/main.dart', 'main');
        final backing = <Object?>[3];
        final values = $Iterable.wrap(
          backing,
          runtime: runtime,
          runtimeTypeId: runtime.internParameterizedType(CoreTypes.iterable, [
            runtime.lookupType(CoreTypes.int),
          ]),
        );
        expect(values.$value, same(backing));
        Object? read() => runtime.executeLib(
          'package:boundary/main.dart',
          'native',
          arguments: {'values': values},
        );
        expect(read(), 19);
        backing[0] = 'wrong';
        expect(
          () => values.$getProperty(runtime, 'first'),
          throwsA(isA<TypeError>()),
        );
      },
    );
  }
}
