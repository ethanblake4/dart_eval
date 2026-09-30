@TestOn('vm')
library;

import 'dart:io';
import 'dart:convert' as convert;

import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_security.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart'
    show TypedRuntimeInterop;
import 'package:dart_eval/stdlib/async.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/stdlib/convert.dart';
import 'package:test/test.dart';

void main() {
  test('native futures retain their declared payload types', () async {
    final directory = Directory.systemTemp.createTempSync('eval_future_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/value.txt')
      ..writeAsStringSync('bridge');
    final path = file.path.replaceAll('\\', '/');
    final program = Compiler().compile({
      'native_future': {
        'main.dart':
            '''
          import 'dart:io';
          import 'dart:async';
          Future<int> main() async {
            final file = File('$path');
            final text = file.readAsString();
            final bytes = file.readAsBytes();
            final completer = Completer<String?>();
            completer.complete(null);
            if (text is! Future<String>) return -1;
            if (bytes is! Future<List<int>>) return -2;
            if (completer.future is! Future<String?>) return -3;
            if (await completer.future != null) return -4;
            return (await text).length + (await bytes).length;
          }
        ''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      runtime.grant(FilesystemPermission.any);
      final result = await runtime.executeLib(
        'package:native_future/main.dart',
        'main',
      );
      expect(result.$value, 12);
      final codec = $Utf8Codec.wrap(convert.utf8);
      final decode =
          codec.$getProperty(runtime, 'decodeStream') as EvalCallable;
      final decoded =
          decode.call(
                runtime,
                null,
                $Stream.wrap(
                  Stream<List<int>>.fromIterable([
                    [65, 66, 67],
                  ]),
                ),
                null,
                1,
              )
              as $Future;
      expect(
        decoded.$getRuntimeType(runtime),
        runtime.internParameterizedType(CoreTypes.future, [
          runtime.lookupType(CoreTypes.string),
        ]),
      );
      expect((await decoded.$value).$value, 'ABC');
    }
  });
}
