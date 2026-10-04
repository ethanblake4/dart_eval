import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('bridge arguments retain generic host types', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_generic_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'native.dart'))
      ..writeAsStringSync('''
abstract class Reader {
  Reader();
  int readList(List<int> values);
  T transform<T>(T Function(T) callback, T value);
}
class ObjectStore {
  final Object? key;
  ObjectStore(this.key);
  bool containsKey(Object? candidate) => identical(key, candidate);
  dynamic echo(dynamic value) => value;
  int onlyInt(int value) => value;
}
''');
    final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:bindgen/native.dart
    classes:
      Reader:
        include: true
        mode: bridge
      ObjectStore:
        include: true
''')..resolveDefaults();
    final generated = (await Bindgen().parse(
      source,
      'native.dart',
      'package:bindgen/native.dart',
      false,
      config: config,
      libraryConfig: config.libraries.single,
    ))!;
    File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/runtime.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_interop.dart';
$generated
''');
    File(p.join(directory.path, 'run.dart')).writeAsStringSync(r"""
import 'native.dart';
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';

void check(bool condition) {
  if (!condition) throw StateError('Generic bridge argument assertion failed');
}

void main() {
  final compiler = Compiler()
    ..entrypoints.add('package:main/main.dart')
    ..defineBridgeClass($Reader$bridge.$declaration)
    ..defineBridgeClass($ObjectStore.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    class Guest extends Reader {
      Guest();
      int readList(List<int> values) => values.first;
      T transform<T>(T Function(T) callback, T value) => callback(value);
    }
    class Token {}
    Object makeToken() => Token();
    bool lookup() {
      final token = Token();
      final store = ObjectStore(token);
      if (!store.containsKey(token) || !identical(store.echo(token), token)) {
        return false;
      }
      dynamic wrong = token;
      try {
        store.onlyInt(wrong);
        return false;
      } on TypeError {
        return true;
      }
    }
    Reader make() => Guest();
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    $Reader$bridge.configureForRuntime(runtime);
    $ObjectStore.configureForRuntime(runtime);
    final reader = runtime.executeLib('package:main/main.dart', 'make') as Reader;
    check(reader.readList([5]) == 5);
    final token = runtime.executeLib('package:main/main.dart', 'makeToken');
    check(identical(reader.transform<Object>((value) => value, token), token));
    check(runtime.executeLib('package:main/main.dart', 'lookup') == true);
  }
}
""");
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      p.join(directory.path, 'run.dart'),
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
