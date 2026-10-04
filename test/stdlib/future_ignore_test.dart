import 'dart:async';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Future.ignore consumes an unhandled error in fresh and encoded runtimes',
    () async {
      final program = Compiler().compile({
        'future_ignore': {
          'main.dart': r'''
          import 'dart:async';

          Future<String> main() async {
            Future<int>.error(StateError('ignored')).ignore();
            await Future<void>.delayed(Duration.zero);
            return 'completed';
          }
        ''',
        },
      });

      for (final (mode, runtime) in [
        ('fresh', Runtime.ofProgram(program)),
        ('serialized', Runtime(program.write().buffer)),
      ]) {
        final result = runtime.executeLib(
          'package:future_ignore/main.dart',
          'main',
        );
        expect(result, isA<Future>(), reason: mode);
        final completed = await (result as Future).timeout(
          const Duration(seconds: 10),
        );
        expect((completed as $Value).$value, 'completed', reason: mode);
      }
    },
  );
}
