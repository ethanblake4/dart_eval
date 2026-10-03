@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:test/test.dart';

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
        final configFile = File('.dart_tool/package_config.json');
        final packageConfig =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final packages = (packageConfig['packages'] as List)
            .cast<Map<String, dynamic>>();
        const dependencyNames = {
          'http',
          'http_parser',
          'async',
          'meta',
          'web',
          'string_scanner',
          'typed_data',
          'collection',
          'source_span',
          'path',
          'term_glyph',
        };
        final sources = <DartSource>[];
        for (final package in packages.where(
          (package) => dependencyNames.contains(package['name']),
        )) {
          final name = package['name'] as String;
          final root = Directory.fromUri(
            Uri.parse('${package['rootUri']}/lib/'),
          );
          for (final file in root.listSync(recursive: true).whereType<File>()) {
            if (!file.path.endsWith('.dart')) continue;
            final path = file.path
                .substring(root.path.length)
                .replaceAll('\\', '/');
            sources.add(DartSource.file('package:$name/$path', file));
          }
        }
        sources.add(
          DartSource('package:probe/main.dart', '''
        import 'package:http/http.dart' as http;

        Future<String> main() async {
          final response = await http.get(Uri.parse('$url'));
          return response.body;
        }
      '''),
        );

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
