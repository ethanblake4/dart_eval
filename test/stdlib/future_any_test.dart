@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Future.any delegates races and keeps typed guest and native values',
    () async {
      final directory = Directory.systemTemp.createTempSync('eval_future_any_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/value.txt')
        ..writeAsStringSync('native');
      final path = file.path.replaceAll('\\', '/');
      final program = Compiler().compile({
        'probe': {
          'main.dart':
              '''
          import 'dart:io';

          class Token { final int value; Token(this.value); }
          Future<T> first<T>(Future<T> future) =>
              Future.any<T>(<Future<T>>[future]);

          Future<bool> main() async {
            final winner = await Future.any<int>(<Future<int>>[
              Future<int>.delayed(Duration(milliseconds: 30), () => 9),
              Future<int>.value(5),
            ]);
            if (winner != 5) return false;

            final token = Token(4);
            final selected = await Future.any<Token>(<Future<Token>>[
              Future<Token>.value(token),
              Future<Token>.delayed(Duration(milliseconds: 10), () => Token(7)),
            ]);
            if (!identical(selected, token) || selected.value != 4) return false;

            final nullable = Future.any<String?>(<Future<String?>>[
              Future<String?>.value(null),
              Future<String?>.value('late'),
            ]);
            if (await nullable != null || nullable is! Future<String?>) {
              return false;
            }

            final widened = await first<num>(Future<int>.value(3));
            if (widened != 3) return false;

            final mixed = await Future.any<String>(<Future<String>>[
              Future<String>.delayed(Duration(milliseconds: 100), () => 'guest'),
              File('$path').readAsString(),
            ]);
            if (mixed != 'native') return false;

            final expectedTrace = StackTrace.current;
            try {
              await Future.any<int>(<Future<int>>[
                Future<int>.error('failure', expectedTrace),
                Future<int>.delayed(Duration(milliseconds: 30), () => 1),
              ]);
              return false;
            } catch (error, trace) {
              if (error != 'failure' ||
                  trace.toString() != expectedTrace.toString()) {
                return false;
              }
            }

            final empty = await Future.any<int>(<Future<int>>[]).timeout(
              Duration(milliseconds: 10),
              onTimeout: () => -1,
            );
            return empty == -1;
          }
        ''',
        },
      });

      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        runtime.grant(FilesystemPermission.any);
        final result =
            await (runtime.executeLib('package:probe/main.dart', 'main')
                    as Future)
                .timeout(Duration(seconds: 10));
        expect((result as $Value).$value, isTrue);
      }
    },
  );
}
