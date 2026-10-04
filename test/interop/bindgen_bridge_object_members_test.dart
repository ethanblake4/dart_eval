import 'dart:io';

import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'bridge Object delegates preserve native and guest key semantics',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bridge_object_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync(r'''
class IdentityBase { IdentityBase(); }
class ValueBase {
  final int value;
  ValueBase(this.value);
  @override int get hashCode => 1;
  @override bool operator ==(Object other) => other is ValueBase && other.value == value;
  @override String toString() => 'native$value';
}
class NativeChild extends ValueBase { NativeChild(super.value); }
class BrokenBase {
  BrokenBase();
  @override int get hashCode => throw StateError('native hash failure');
  @override String toString() => throw StateError('native string failure');
}
''');
      final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:bridge_object/native.dart
    defaults:
      mode: bridge
      implicitSupers: false
      includeObjectMembers: false
    classes:
      IdentityBase:
        overrideLibrary: package:bridge_object/native.dart
      ValueBase:
        overrideLibrary: package:bridge_object/native.dart
        getters:
          hashCode:
            include: true
        methods:
          toString:
            include: true
      NativeChild:
        overrideLibrary: package:bridge_object/native.dart
      BrokenBase:
        overrideLibrary: package:bridge_object/native.dart
  - uri: dart:core
    classes:
      Object:
        handMaintained: true
''')..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'native.dart',
        'package:bridge_object/native.dart',
        false,
        config: config,
        libraryConfig: config.libraries.first,
      ))!;
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(r"""
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
void main() {
  final compiler = Compiler()
    ..defineBridgeClass($IdentityBase$bridge.$declaration)
    ..defineBridgeClass($ValueBase$bridge.$declaration)
    ..defineBridgeClass($NativeChild$bridge.$declaration)
    ..defineBridgeClass($BrokenBase$bridge.$declaration);
  final program = compiler.compile({'probe': {'main.dart': '''
    import 'package:bridge_object/native.dart';
    class Identity extends IdentityBase {}
    class Native extends NativeChild { Native(int value): super(value); }
    class GuestBase extends ValueBase {
      final int key;
      GuestBase(this.key): super(0);
      int get hashCode => 2;
      bool operator ==(Object other) => other is GuestBase && other.key == key;
      String toString() => 'guest';
    }
    class Guest extends GuestBase { Guest(int key): super(key); }
    class Broken extends BrokenBase {}
    int brokenHash() => Broken().hashCode;
    String brokenString() => Broken().toString();
    bool main() {
      final first = Identity();
      final second = Identity();
      if (first.hashCode != first.hashCode || first == second) return false;
      final keys = {first: 1, second: 2};
      keys[first] = 3;
      if (keys.length != 2 || keys[first] != 3 || keys.remove(second) != 2) return false;
      if ({first, second}.length != 2 || !{first}.contains(first)) return false;
      final describe = first.toString;
      if (!(first == first) || describe() != first.toString()) return false;
      final a = Native(1), b = Native(1), c = Native(2);
      final native = {a: 1, b: 2, c: 3};
      if (native.length != 2 || native[a] != 2 || a.hashCode != 1 || a.toString() != 'native1') return false;
      final x = Guest(1), y = Guest(1), z = Guest(2);
      final guest = {x: 1, y: 2, z: 3};
      if (guest.length != 2 || guest[x] != 2 || x.hashCode != 2 || x.toString() != 'guest') return false;
      return true;
    }
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    $IdentityBase$bridge.configureForRuntime(runtime);
    $ValueBase$bridge.configureForRuntime(runtime);
    $NativeChild$bridge.configureForRuntime(runtime);
    $BrokenBase$bridge.configureForRuntime(runtime);
    if (runtime.executeLib('package:probe/main.dart', 'main') != true) throw StateError('keys');
    for (final (entry, marker) in [('brokenHash', 'native hash failure'), ('brokenString', 'native string failure')]) {
      Object? failure;
      try { runtime.executeLib('package:probe/main.dart', entry); } catch (error) { failure = error; }
      if (failure == null || !failure.toString().contains(marker)) throw StateError('lost native error $entry: $failure');
    }
  }
  final identity = $IdentityBase$bridge();
  if (identity.$bridgeGetObject('unsupported', hashCode: () => 0,
      equals: (_) => false, toString: () => 'unused') != null) {
    throw StateError('unknown property changed');
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
