@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval_http_bridge/http.dart';
import 'package:test/test.dart';

void main() {
  test('package:http GET compiles, checks permission, and fetches', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requestCount = 0;
    String? receivedHeader;
    server.listen((request) async {
      requestCount++;
      receivedHeader = request.headers.value('x-request');
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set('x-reply', request.headers.value('x-request') ?? '')
        ..write('hello from http');
      await request.response.close();
    });

    try {
      final url = 'http://127.0.0.1:${server.port}/hello';
      final compiler = Compiler()..addPlugin(HttpPlugin());
      final program = compiler.compile({
        'example': {
          'main.dart':
              '''
            import 'package:http/http.dart' as http;

            Future<String> main() async {
              final response = await http.get(
                Uri.parse('$url'),
                headers: {'x-request': 'present'},
              );
              return response.statusCode.toString() + ':' +
                  response.body + ':' + (response.headers['x-reply'] ?? 'missing');
            }
          ''',
        },
      });
      final runtime = Runtime(program.write().buffer)..addPlugin(HttpPlugin());

      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        throwsA(isA<Exception>()),
      );
      expect(requestCount, 0);

      runtime.grant(NetworkPermission.url(url));
      final result = await runtime.executeLib(
        'package:example/main.dart',
        'main',
      );
      expect(receivedHeader, 'present');
      expect(result.$value, '200:hello from http:present');
      expect(requestCount, 1);
    } finally {
      await server.close(force: true);
    }
  });

  test('redirects require permission for the destination', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var destinationRequests = 0;
    server.listen((request) async {
      if (request.uri.path == '/start') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/finish');
      } else {
        destinationRequests++;
        request.response.write('finished');
      }
      await request.response.close();
    });

    try {
      final baseUrl = 'http://127.0.0.1:${server.port}';
      final compiler = Compiler()..addPlugin(HttpPlugin());
      final runtime = Runtime(
        compiler
            .compile({
              'example': {
                'main.dart':
                    '''
            import 'package:http/http.dart' as http;

            Future<String> main() async {
              return (await http.get(Uri.parse('$baseUrl/start'))).body;
            }
          ''',
              },
            })
            .write()
            .buffer,
      )..addPlugin(HttpPlugin());

      runtime.grant(NetworkPermission.url('$baseUrl/start'));
      await expectLater(
        runtime.executeLib('package:example/main.dart', 'main'),
        throwsA(isA<Exception>()),
      );
      expect(destinationRequests, 0);

      runtime.grant(NetworkPermission.url('$baseUrl/finish'));
      final result = await runtime.executeLib(
        'package:example/main.dart',
        'main',
      );
      expect(result.$value, 'finished');
      expect(destinationRequests, 1);
    } finally {
      await server.close(force: true);
    }
  });
}
