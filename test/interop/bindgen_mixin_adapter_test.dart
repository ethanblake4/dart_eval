import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _native = r'''
enum Level { info, warning }
mixin ProbeMixin {
  int get seed => 2;
  int inherited({Level level = Level.info}) => seed + 10 + level.index;
  void fill(List<int> values) { values.add(seed); }
}
class Native with ProbeMixin {}
mixin Stored { int value = 0; }
class Base {}
mixin Constrained on Base {}
mixin ExplicitObject on Object {}
mixin SuperRequired { String describe() => super.toString(); }
mixin Generic<T> { T? get value => null; }
base mixin Restricted {}
mixin InterfaceRequired implements Base {}
mixin StaticMember { static int get value => 0; }
mixin PrivateRequired { int get _value; }
mixin GenericMethod { T identity<T>(T value) => value; }
class Pretend {}
''';

BindgenConfig _config(String uri, String name, String options) =>
    BindgenConfig.parse('''
version: 1
libraries:
  - uri: $uri
    classes:
      $name:
        file: native.dart
        $options
      Level:
        file: native.dart
        include: true
  - uri: dart:core
    registry:
      file: unused.dart
      class: CoreTypes
    classes:
      int:
        handMaintained: true
      List:
        handMaintained: true
      Object:
        handMaintained: true
''')..resolveDefaults();

void main() {
  late Directory directory;
  late File source;
  late Bindgen bindgen;
  setUp(() {
    directory = Directory('test').absolute.createTempSync('mixin_adapter_');
    source = File(p.join(directory.path, 'native.dart'))
      ..writeAsStringSync(_native);
    bindgen = Bindgen();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Future<String?> generate(BindgenConfig config) => bindgen.parse(
    source,
    'native.dart',
    source.uri.toString(),
    false,
    config: config,
    libraryConfig: config.libraries.first,
  );

  test(
    'generated native adapter preserves guest dispatch and serialization',
    () async {
      final generated = await generate(
        _config(source.uri.toString(), 'ProbeMixin', '''mode: both
        mixinAdapter: true'''),
      );
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(
        r"""
import 'native.dart';
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
const uri = 'package:mixin_probe/native.dart';
const guest = '''
import 'package:mixin_probe/native.dart';
class Base { int base() => 100; }
class Plain extends Base with ProbeMixin {}
class Guest extends Base with ProbeMixin {
  int get seed => 7;
  void fill(List<int> values) { super.fill(values); values.add(30); }
}
int main() {
  final values = <int>[];
  final value = Guest();
  value.fill(values);
  if (values.length != 2 || values[0] != 7 || values[1] != 30) return -1;
  if (value.inherited(level: Level.warning) != 18) return -2;
  return Plain().inherited() * 10000 + value.inherited() * 100 + value.base();
}
''';
void main() {
  final declaration = $ProbeMixin$bridge.$declaration;
  final enumDef = $Level.$declaration;
  final compiler = Compiler()..defineBridgeClass(declaration)..defineBridgeEnum(enumDef);
  final program = compiler.compile({'probe': {'main.dart': guest}});
  final encoded = program.write();
  for (final runtime in [Runtime.ofProgram(program), Runtime(encoded.buffer)]) {
    $ProbeMixin$bridge.configureForRuntime(runtime);
    $Level.configureForRuntime(runtime);
    final result = runtime.executeLib('package:probe/main.dart', 'main');
    if (result != 121800) throw StateError('guest result $result');
    final wrapped = $ProbeMixin.wrap(Native());
    final inherited = wrapped.$getProperty(runtime, 'inherited') as $Closure;
    // Explicit enum argument also checks existing native-value wrapping.
    final native = inherited.call(runtime, null, $Level.wrap(Level.warning), null, null);
    if (native?.$value != 13) throw StateError('wrapper result $native');
  }
  if ($ProbeMixin$bridge().inherited() != 12) throw StateError('native fallback');
  for (final control in [
    (flag: false, bridge: false, adapter: false),
    (flag: true, bridge: false, adapter: false),
    (flag: false, bridge: true, adapter: true),
    (flag: true, bridge: true, adapter: false),
  ]) {
    final invalid = BridgeClassDef(
      BridgeClassType(declaration.type.type, isMixinClass: control.flag),
      constructors: control.adapter ? declaration.constructors : {},
      methods: declaration.methods, getters: declaration.getters,
      bridge: control.bridge, wrap: !control.bridge);
    Object? failure;
    try {
      (Compiler()..defineBridgeClass(invalid)..defineBridgeEnum(enumDef))
          .compile({'probe': {'main.dart': guest}});
    } catch (error) { failure = error; }
    final expected = control.flag && control.bridge
        ? 'needs an unnamed adapter' : 'is not a mixin';
    if (failure == null || !failure.toString().contains(expected)) {
      throw StateError('invalid adapter admitted: $control, $failure');
    }
  }
}
"""
            .replaceAll(
              'package:mixin_probe/native.dart',
              source.uri.toString(),
            ),
      );
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('opaque mixins keep their existing wrapper contract', () async {
    final generated = await generate(
      _config(source.uri.toString(), 'ProbeMixin', 'opaque: true'),
    );
    expect(generated, contains('Opaque dart_eval wrapper'));
    expect(generated, contains('bridge: false'));
    expect(generated, isNot(contains('isMixinClass: true')));
    expect(generated, isNot(contains('with ProbeMixin')));
  });

  test('unsupported mixins fail with explicit diagnostics', () async {
    for (final (name, reason) in [
      ('Stored', 'instance fields'),
      ('Constrained', 'on constraints'),
      ('ExplicitObject', 'on constraints'),
      ('SuperRequired', 'super requirements'),
      ('Generic', 'generic mixins'),
      ('Restricted', 'base'),
      ('InterfaceRequired', 'interface requirements'),
      ('StaticMember', 'static members'),
      ('PrivateRequired', 'private abstract'),
      ('GenericMethod', 'generic methods'),
      ('Pretend', 'genuine mixin'),
    ]) {
      await expectLater(
        generate(
          _config(source.uri.toString(), name, '''mode: bridge
        mixinAdapter: true'''),
        ),
        throwsA(
          predicate<Object>((error) => error.toString().contains(reason)),
        ),
      );
    }
    await expectLater(
      generate(
        _config(source.uri.toString(), 'ProbeMixin', 'mixinAdapter: true'),
      ),
      throwsA(
        predicate<Object>((error) => error.toString().contains('non-opaque')),
      ),
    );
  });
}
