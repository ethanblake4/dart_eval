@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:test/test.dart';

import '../../benchmark/support/http_native.dart';

void main() {
  test(
    'compiles and executes package:http sources without HttpPlugin',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requestCount = 0;
      server.listen((request) async {
        requestCount++;
        request.response.write('native fetch works');
        await request.response.close();
      });

      try {
        final url = 'http://127.0.0.1:${server.port}/hello';
        final sources = httpNativeSources(url);

        final program = Compiler().compileSources(sources);
        final runtime = Runtime(program.write().buffer);
        await expectLater(
          runtime.executeLib('package:probe/main.dart', 'main'),
          throwsA(isA<Exception>()),
        );
        expect(requestCount, 0);

        runtime.grant(NetworkPermission.url(url));
        final result = await runtime.executeLib(
          'package:probe/main.dart',
          'main',
        );
        expect(result.$reified, 'native fetch works');
        expect(requestCount, 1);
      } finally {
        await server.close(force: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
