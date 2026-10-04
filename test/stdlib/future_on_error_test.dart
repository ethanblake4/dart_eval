import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Future.onError checks error types, filters and forwards stack traces',
    () async {
      final program = Compiler().compile({
        'future_on_error': {
          'main.dart': r'''
            import 'dart:async';

            Future<String> main() async {
              final recovered = await Future<String>.error(
                FormatException('selected', 'input'),
                StackTrace.fromString('selected stack marker'),
              ).onError<FormatException>(
                (error, stackTrace) =>
                    '${error.message}:${stackTrace.toString().contains('marker')}',
                test: (error) => error.message == 'selected',
              );

              var mismatchRethrown = false;
              try {
                await Future<String>.error(StateError('wrong type'))
                    .onError<FormatException>(
                      (error, stackTrace) => 'not handled',
                    );
              } on StateError catch (error) {
                mismatchRethrown = error.message == 'wrong type';
              }

              var rejectedRethrown = false;
              try {
                await Future<String>.error(FormatException('filtered'))
                    .onError<FormatException>(
                      (error, stackTrace) => 'not handled',
                      test: (error) => false,
                    );
              } on FormatException catch (error) {
                rejectedRethrown = error.message == 'filtered';
              }

              return '$recovered/$mismatchRethrown/$rejectedRethrown';
            }
          ''',
        },
      });

      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        final result = runtime.executeLib(
          'package:future_on_error/main.dart',
          'main',
        );
        expect(result, isA<Future>(), reason: mode);
        expect(
          (await (result as Future).timeout(const Duration(seconds: 10))
                  as $Value)
              .$value,
          'selected:true/true/true',
          reason: mode,
        );
      }
    },
  );
}
