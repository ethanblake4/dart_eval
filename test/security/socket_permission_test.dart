@TestOn('vm')
library;

import 'dart:io';

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/socket.dart';
import 'package:dart_eval/src/eval/shared/stdlib/io/socket_hooks.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('Socket checks the destination before connecting', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    var accepted = 0;
    final subscription = server.listen((socket) {
      accepted++;
      socket.add([42]);
      socket.close();
    });
    final runtime = Compiler().compileWriteAndLoad({
      'example': {
        'main.dart':
            '''
          import 'dart:io';

          Future<void> main() async {
            final socket = await Socket.connect('127.0.0.1', ${server.port});
            if (socket.isBroadcast) throw StateError('unexpected broadcast');
            final first = await socket.first;
            if (first.first != 42) throw StateError('unexpected data');
            socket.destroy();
          }
        ''',
      },
    });

    try {
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        throwsA(isA<Exception>()),
      );
      expect(accepted, 0);

      runtime.grant(NetworkPermission.url('127.0.0.1:${server.port + 1}'));
      expect(
        () => runtime.executeLib('package:example/main.dart', 'main'),
        throwsA(isA<Exception>()),
      );
      expect(accepted, 0);

      runtime.grant(NetworkPermission.url('127.0.0.1:${server.port}'));
      await runtime.executeLib('package:example/main.dart', 'main');
      expect(accepted, 1);
    } finally {
      await subscription.cancel();
      await server.close();
    }
  });

  test('Socket.startConnect checks permission before opening a socket', () {
    final runtime = Compiler().compileWriteAndLoad({
      'example': {
        'main.dart': '''
          import 'dart:io';

          void main() {
            Socket.startConnect('127.0.0.1', 54321);
          }
        ''',
      },
    });

    expect(
      () => runtime.executeLib('package:example/main.dart', 'main'),
      throwsA(isA<Exception>()),
    );

    expect(
      () => socketStartConnect(runtime, null, [
        $InternetAddress.wrap(InternetAddress.loopbackIPv4),
        $int(54321),
      ]),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('//127.0.0.1:54321'),
        ),
      ),
    );
  });

  test('host permissions cover sockets without granting an HTTP scheme', () {
    expect(
      NetworkPermission.url('127.0.0.1').match('//127.0.0.1:8080'),
      isTrue,
    );
    expect(
      NetworkPermission.url('https://127.0.0.1:8080').match('//127.0.0.1:8080'),
      isFalse,
    );
  });
}
