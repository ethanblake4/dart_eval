import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'configured bridge method hooks receive their native receiver',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_hook_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
abstract class FilterBase<E> extends Iterable<E> {
  FilterBase();
  Iterator<E> get iterator;
  Iterable<R> select<R>() => whereType<R>();
}
''');
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:bindgen_hook/native.dart
    classes:
      FilterBase:
        mode: bridge
        hooks: package:dart_eval/stdlib/core.dart
        methods:
          select:
            hook: iterableWhereType
  - uri: dart:core
    classes:
      Iterable:
        handMaintained: true
      Iterator:
        handMaintained: true
      Object:
        handMaintained: true
''')..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'native.dart',
        'package:bindgen_hook/native.dart',
        false,
        config: config,
        libraryConfig: config.libraries.first,
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
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';

void main() {
  final compiler = Compiler()
    ..defineBridgeClass($FilterBase$bridge.$declaration);
  final program = compiler.compile({'probe': {'main.dart': '''
    import 'package:bindgen_hook/native.dart';
    class Token {}
    class Values extends FilterBase<Object?> {
      final List<Object?> values;
      Values(this.values);
      Iterator<Object?> get iterator => values.iterator;
      Iterable<T> selected<T>() => super.select<T>();
    }
    bool main() {
      final token = Token();
      final values = Values([null, 'x', 1, token]);
      final strings = values.selected<String>().toList();
      if (strings is! List<String> || strings.single != 'x') return false;
      final nullable = values.selected<String?>().toList();
      if (nullable is! List<String?> || nullable.length != 2 || nullable.first != null) return false;
      final tokens = values.selected<Token>().toList();
      if (tokens is! List<Token> || !identical(tokens.single, token)) return false;
      dynamic checked = strings;
      try { checked.add(null); return false; } on TypeError {}
      return true;
    }
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    $FilterBase$bridge.configureForRuntime(runtime);
    if (runtime.executeLib('package:probe/main.dart', 'main') != true) {
      throw StateError('Bridge method hook failed');
    }
  }
}
""");
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
