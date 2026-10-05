import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'native callback types and defaults use their declaring libraries',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('qualification_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final model = File(p.join(directory.path, 'model.dart'))
        ..writeAsStringSync('''
class Item {
  final int value;
  const Item(this.value);
}
typedef Builder = Item Function(Item);
class Defaults {
  static const home = Item(7);
}
''');
      final api = File(p.join(directory.path, 'api.dart'))
        ..writeAsStringSync('''
import 'model.dart' as m;
typedef Callback = int Function(m.Item);
int invoke(Callback callback) => callback(const m.Item(8));
int build(m.Builder callback) => callback(const m.Item(8)).value;
Callback Function() callbackReturn() => () => (item) => item.value;
class Factory {
  Factory();
  Callback Function() get callback => callbackReturn();
}
void acceptAsync(Future<List<m.Item>> Function() callback) {}
bool defaultIdentity([m.Item value = m.Defaults.home]) => identical(value, m.Defaults.home);
int builders([Map<String, m.Builder> values = const <String, m.Builder>{}]) => values.length;
''');
      final collision = File(p.join(directory.path, 'collision.dart'))
        ..writeAsStringSync('''
class Item {}
class Defaults {}
''');
      final config = BindgenConfig.parse('''
libraries:
  - uri: ${model.uri}
    classes:
      Item:
        file: model.eval.dart
  - uri: ${api.uri}
    classes:
      Factory:
        file: factory.eval.dart
    functions: [invoke, build, callbackReturn, acceptAsync, defaultIdentity, builders]
''')..resolveDefaults();
      final generator = Bindgen();
      for (final library in config.libraries) {
        final output = await generator.parseLibrary(
          library.uri,
          config,
          library,
        );
        for (final entry in output.entries) {
          if (library == config.libraries.last &&
              entry.key == 'functions.dart') {
            expect(
              entry.value,
              contains('defaultValueSource: "m.Defaults.home"'),
            );
          }
          File(p.join(directory.path, entry.key)).writeAsStringSync('''
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
${library == config.libraries.last ? "import '${collision.uri}';" : ''}
${entry.value}
''');
        }
      }
      File(p.join(directory.path, 'run.dart')).writeAsStringSync('''
import 'package:dart_eval/dart_eval.dart';
import 'model.eval.dart';
import 'functions.dart';
import 'factory.eval.dart';
import 'api.dart' as native;
void main() {
  if (native.invoke((item) => item.value) != 8 || !native.defaultIdentity() || native.builders() != 0) {
    throw StateError('native baseline');
  }
  final compiler = Compiler()
    ..defineBridgeClass(\$Item.\$declaration)
    ..defineBridgeClass(\$Factory.\$declaration)
    ..defineBridgeTopLevelFunction(\$callbackReturnFn.\$declaration)
    ..defineBridgeTopLevelFunction(\$invokeFn.\$declaration)
    ..defineBridgeTopLevelFunction(\$buildFn.\$declaration)
    ..defineBridgeTopLevelFunction(\$defaultIdentityFn.\$declaration)
    ..defineBridgeTopLevelFunction(\$buildersFn.\$declaration);
  final program = compiler.compile({'main': {'main.dart': """
    import '${api.uri}';
    import '${model.uri}';
    int callback(Item value) => value.value;
    Item identity(Item value) => value;
    bool main() {
      final getter = Factory().callback;
      final callback = getter();
      return invoke(identityValue) == 8 && build(identity) == 8 &&
          callbackReturn()()(Item(9)) == 9 && callback(Item(10)) == 10;
    }
    int identityValue(Item value) => value.value;
    bool returnedNegative() {
      dynamic callback = callbackReturn()();
      try { callback('wrong'); } on TypeError { return true; }
      return false;
    }
    dynamic badReturn(Item value) => 'wrong';
    bool returnNegative() {
      dynamic callback = badReturn;
      try { build(callback); } on TypeError { return true; }
      return false;
    }
    int wrong(String value) => 0;
    bool negative() { dynamic callback = wrong; try { invoke(callback); } on TypeError { return true; } return false; }
  """}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    \$Item.configureForRuntime(runtime);
    \$Factory.configureForRuntime(runtime);
    \$callbackReturnFn.configureForRuntime(runtime);
    \$invokeFn.configureForRuntime(runtime);
    \$buildFn.configureForRuntime(runtime);
    \$defaultIdentityFn.configureForRuntime(runtime);
    \$buildersFn.configureForRuntime(runtime);
    if (runtime.executeLib('package:main/main.dart', 'main') != true) throw StateError('parity');
    if (\$defaultIdentityFn.callRegisters(runtime, null, null, null)?.\$value != true ||
        \$buildersFn.callRegisters(runtime, null, null, null)?.\$value != 0) throw StateError('defaults');
    if (runtime.executeLib('package:main/main.dart', 'returnNegative') != true) throw StateError('callback return');
    if (runtime.executeLib('package:main/main.dart', 'returnedNegative') != true) throw StateError('returned callback argument');
    if (runtime.executeLib('package:main/main.dart', 'negative') != true) {
      throw StateError('accepted incompatible callback');
    }
  }
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
