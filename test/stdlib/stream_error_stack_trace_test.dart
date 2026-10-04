import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('Stream.error forwards native and guest stack traces', () async {
    final program = Compiler().compile({
      'stream_error_trace': {
        'main.dart': '''
          import 'dart:async';

          class GuestTrace implements StackTrace {
            @override
            String toString() => 'guest trace marker';
          }

          Future<bool> matches(StackTrace expected) async {
            try {
              await Stream<int>.error(StateError('stream failure'), expected)
                  .first;
            } on StateError catch (error, trace) {
              return error.message == 'stream failure' &&
                  trace.toString() == expected.toString();
            }
            return false;
          }

          Future<bool> main() async {
            final nativeTrace = StackTrace.fromString('native trace marker');
            return await matches(nativeTrace) && await matches(GuestTrace());
          }
        ''',
      },
    });

    for (final (kind, runtime) in [
      ('fresh', Runtime.ofProgram(program)),
      ('serialized', Runtime(program.write().buffer)),
    ]) {
      final result =
          await (runtime.executeLib(
                    'package:stream_error_trace/main.dart',
                    'main',
                  )
                  as Future)
              .timeout(const Duration(seconds: 10));
      expect((result as $Value).$value, isTrue, reason: kind);
    }
  });
}
