import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart'
    show TypedInterop;
import 'package:test/test.dart';

import '../support/dynamic_fixtures.dart';

void main() {
  test('StreamTransformerBase guest subclasses transform streams', () async {
    const library = 'package:transformer_base/main.dart';
    final program = Compiler().compile({
      'transformer_base': {
        'main.dart': r'''
          import 'dart:async';

          class Stringify extends StreamTransformerBase<int, String> {
            Stream<String> bind(Stream<int> stream) =>
                stream.map((value) => 'value:$value');
          }

          Stream<String> main() => Stringify().bind(
                Stream<int>.fromIterable([1, 2]),
              );
        ''',
      },
    });

    for (final (mode, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      final stream = runtime.executeLib(library, 'main') as Stream;
      final values = await stream
          .map((value) => TypedInterop.exportExternal(value, runtime: runtime))
          .toList();
      expect(values, ['value:1', 'value:2'], reason: mode);
    }
  });

  test('NullableIterableExtensions.nonNulls returns typed non-null values', () {
    for (final (mode, result) in runDynamicFixture(r'''
      bool main() {
        final Iterable<int> values = <int?>[1, null, 2].nonNulls;
        return values is Iterable<int> && values.join(',') == '1,2';
      }
    ''')) {
      expect(result, const DynamicFixtureResult.value(true), reason: mode);
    }
  });
}
