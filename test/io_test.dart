@TestOn('vm')

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:test/test.dart';

void main() {
  group('dart:io tests', () {
    late Compiler compiler;

    setUp(() {
      compiler = Compiler();
    });

    test('HttpClient get() permission denied', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';
            import 'dart:convert';

            Future<String> main() async {
              final client = HttpClient();
              final request = await client.getUrl(Uri.parse('https://example.com'));
              final response = await request.close();
              final body = await response.transform(utf8.decoder).join();
              return body;
            }
          '''
        }
      });

      expect(
          () => runtime
              .executeLib(
                'package:example/main.dart',
                'main',
              )
              .$value,
          throwsA(isA<Exception>()));
    });

    test('HttpClient get()', () async {
      final runtime = compiler.compileWriteAndLoad({
        'example': {
          'main.dart': '''
            import 'dart:io';
            import 'dart:convert';

            Future<String> main() async {
              final client = HttpClient();
              final request = await client.getUrl(Uri.parse('https://example.com'));
              final response = await request.close();
              final body = await response.transform(utf8.decoder).join();
              return body;
            }
          '''
        }
      });

      runtime.grant(NetworkPermission.url('https://example.com'));

      final result = (await runtime.executeLib(
        'package:example/main.dart',
        'main',
      ))
          .$value;

      expect(result, contains('Example Domain'));
    });
  });
}
