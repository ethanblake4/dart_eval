import 'dart:collection';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('ListBase bridge results preserve guest identity and mutation', () {
    final program = Compiler().compile({
      'sources': {
        'main.dart': '''
          import 'dart:collection';

          class Token {}
          final token = Token();
          final replacement = Token();

          class GuestList extends ListBase<Object> {
            final List<Object?> values;
            GuestList(Object value) : values = [value];
            int get length => values.length;
            set length(int value) => values.length = value;
            Object operator [](int index) => values[index] as Object;
            void operator []=(int index, Object value) => values[index] = value;
            Iterable<R> map<R>(R Function(Object) f) =>
                values.cast<Object>().map<R>(f);
            Object transform(Object Function(Object) f) => f(values.first!);
            int checked(int Function(int) f) => f(7);
          }
          class TokenList extends ListBase<Token> {
            final List<Token?> values;
            TokenList(Token value) : values = [value];
            int get length => values.length;
            set length(int value) => values.length = value;
            Token operator [](int index) => values[index] as Token;
            void operator []=(int index, Token value) => values[index] = value;
            Iterable<R> map<R>(R Function(Token) f) =>
                values.cast<Token>().map<R>(f);
            void setRange(int start, int end, Iterable<Token> source,
                [int skipCount = 0]) =>
                values.setRange(start, end, source, skipCount);
            void ignore(Iterable<Token> source) {}
          }

          GuestList make() => GuestList(token);
          TokenList makeTokens() => TokenList(token);
          Object tokenValue() => token;
          Object replacementValue() => replacement;
          bool main() {
            final list = make();
            if (!identical(list[0], token) || !identical(list.last, token)) {
              return false;
            }
            list[0] = replacement;
            return identical(list.first, replacement) &&
                identical(list.last, replacement);
          }
          bool inserted() {
            final list = make();
            list.insert(0, replacement);
            return list.length == 2 && identical(list[0], replacement) &&
                identical(list.last, token);
          }
          bool typedInserted() {
            final list = makeTokens();
            list.insert(0, replacement);
            return list.length == 2 && identical(list[0], replacement) &&
                identical(list.last, token);
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      const library = 'package:sources/main.dart';
      expect(runtime.executeLib(library, 'main'), isTrue);
      expect(runtime.executeLib(library, 'inserted'), isTrue);
      expect(runtime.executeLib(library, 'typedInserted'), isTrue);
      final list = runtime.executeLib(library, 'make') as ListBase<Object?>;
      final token = runtime.executeLib(library, 'tokenValue');
      final replacement = runtime.executeLib(library, 'replacementValue');
      expect(list[0], same(token));
      expect(list.first, same(token));
      expect(list.last, same(token));
      list[0] = replacement;
      expect(list.first, same(replacement));
      expect(list.last, same(replacement));
      final bridge = list as $Bridge;
      expect(
        bridge.$_invoke('transform', [
          $Function((runtime, target, r, s, c) => r as $Value?),
        ]),
        same(replacement),
      );
      expect(
        () => bridge.$_invoke('checked', [
          $Function((runtime, target, r, s, c) => $String('wrong result')),
        ]),
        throwsA(isA<TypeError>()),
      );
      final tokens =
          runtime.executeLib(library, 'makeTokens') as ListBase<Object?>;
      tokens.setRange(0, 1, [replacement]);
      expect(tokens.first, same(replacement));
      expect(
        () => tokens.setRange(0, 1, ['wrong element']),
        throwsA(isA<TypeError>()),
      );
      final tokenBridge = tokens as $Bridge;
      expect(
        tokenBridge.$_invoke('ignore', [
          $Iterable.wrap([$String('unread wrong element')]),
        ]),
        isNull,
      );
      final typedStrings = $Iterable.wrap(
        [$String('wrong element')],
        runtimeTypeId: runtime.internParameterizedType(CoreTypes.iterable, [
          runtime.lookupType(CoreTypes.string),
        ]),
        runtime: runtime,
      );
      expect(
        () => tokenBridge.$_invoke('ignore', [typedStrings]),
        throwsA(isA<TypeError>()),
      );
    }
  });
}
