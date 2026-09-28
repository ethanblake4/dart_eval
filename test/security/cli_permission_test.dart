import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/cli/run.dart';
import 'package:test/test.dart';

void main() {
  late Runtime runtime;

  setUp(() {
    runtime = Compiler().compileWriteAndLoad({
      'example': {'main.dart': 'void main() {}'},
    });
  });

  test('network permission allows any URL', () {
    expect(runtime.checkPermission('network', 'https://example.com'), isFalse);

    grantCliPermissions(runtime, ['network']);

    expect(runtime.checkPermission('network', 'https://example.com'), isTrue);
    expect(runtime.checkPermission('network', 'http://localhost:8080'), isTrue);
    expect(runtime.checkPermission('filesystem:read', 'example.txt'), isFalse);
  });

  test('multiple permission domains grant their full access', () {
    grantCliPermissions(runtime, ['filesystem', 'process']);

    expect(runtime.checkPermission('filesystem:read', 'example.txt'), isTrue);
    expect(runtime.checkPermission('filesystem:write', 'example.txt'), isTrue);
    expect(runtime.checkPermission('process:run', 'dart'), isTrue);
    expect(runtime.checkPermission('process:kill', 123), isTrue);
    expect(runtime.checkPermission('network', 'https://example.com'), isFalse);
  });

  test('specific permission domains do not grant adjacent access', () {
    grantCliPermissions(runtime, ['filesystem:read', 'process:run']);

    expect(runtime.checkPermission('filesystem:read', 'example.txt'), isTrue);
    expect(runtime.checkPermission('filesystem:write', 'example.txt'), isFalse);
    expect(runtime.checkPermission('process:run', 'dart'), isTrue);
    expect(runtime.checkPermission('process:kill', 123), isFalse);
  });

  test('run grants network access to an async program', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) {
      request.response.write('ok');
      request.response.close();
    });
    final directory = await Directory.systemTemp.createTemp('dart_eval_cli_');

    try {
      final program = Compiler().compile({
        'example': {
          'main.dart':
              '''
            import 'dart:io';

            Future<int> main() async {
              final client = HttpClient();
              final request = await client.getUrl(
                Uri.parse('http://127.0.0.1:${server.port}/'),
              );
              final response = await request.close();
              client.close(force: true);
              return response.statusCode;
            }
          ''',
        },
      });
      final file = File(
        '${directory.path}${Platform.pathSeparator}program.evc',
      );
      await file.writeAsBytes(program.write());

      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/dart_eval.dart',
        'run',
        file.path,
        '--library',
        'package:example/main.dart',
        '--permission',
        'network',
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('Program exited with result: 200'));
    } finally {
      await subscription.cancel();
      await server.close(force: true);
      await directory.delete(recursive: true);
    }
  });
}
