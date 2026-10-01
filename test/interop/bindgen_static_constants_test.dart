import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('compact static constants preserve names and runtime values', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_const_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'native.dart'))
      ..writeAsStringSync('''
class Palette {
  static const int red = 7;
  static const int blue = 11;
  static const String label = 'color';
  static int mutable = 3;
}
''');
    final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:bindgen/native.dart
    classes:
      Palette:
        include: true
        compactStaticConstants: true
''')..resolveDefaults();
    final generated = (await Bindgen().parse(
      source,
      'native.dart',
      'package:bindgen/native.dart',
      false,
      config: config,
      libraryConfig: config.libraries.single,
    ))!;
    expect(generated, contains("'red': BridgeFieldDef("));
    expect(generated, contains("'blue': BridgeFieldDef("));
    expect(generated, contains("'label': BridgeFieldDef("));
    expect(generated, contains('Palette.mutable*g'));
    expect(generated, isNot(contains('static \$Value? \$red(')));
    expect(generated, isNot(contains('static \$Value? \$blue(')));
    expect(
      RegExp(
        r'for \(final entry in _compactConstants\d+\.entries\)',
      ).allMatches(generated).length,
      2,
    );

    File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
    File(p.join(directory.path, 'run.dart')).writeAsStringSync(r"""
import 'native.dart';
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

void check(bool condition) {
  if (!condition) throw StateError('Static constant assertion failed');
}

Object? value(Object? result) => result is $Value ? result.$value : result;

void main() {
  final compiler = Compiler()
    ..entrypoints.add('package:main/main.dart')
    ..defineBridgeClass($Palette.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    int sum() => Palette.red + Palette.blue;
    String label() => Palette.label;
    int mutable() => Palette.mutable;
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    Palette.mutable = 3;
    $Palette.configureForRuntime(runtime);
    check(value(runtime.executeLib('package:main/main.dart', 'sum')) == 18);
    check(value(runtime.executeLib('package:main/main.dart', 'label')) == 'color');
    check(value(runtime.executeLib('package:main/main.dart', 'mutable')) == 3);
    Palette.mutable = 5;
    check(value(runtime.executeLib('package:main/main.dart', 'mutable')) == 5);
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
