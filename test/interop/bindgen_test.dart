import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:dart_eval/src/eval/bindgen/config.dart';
import 'package:test/test.dart';

void main() {
  test('renamed wrappers preserve SDK names and evaluated lifecycle', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_rename_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'native.dart'))
      ..writeAsStringSync('''
class Image {
  Image(this.width);
  final int width;
  static void Function(Image)? onCreate;
  static void Function(Image)? onDispose;
  static Image create(int width) {
    final image = Image(width);
    onCreate?.call(image);
    return image;
  }
  List<StackTrace>? debugGetOpenHandleStackTraces() => [StackTrace.current];
  void dispose() => onDispose?.call(this);
}
''');
    final config = BindgenConfig.parse(r'''
libraries:
  - uri: dart:core
    classes:
      int:
        handMaintained: true
        file: package:dart_eval/stdlib/core.dart
      List:
        handMaintained: true
        file: package:dart_eval/stdlib/core.dart
      StackTrace:
        handMaintained: true
        file: package:dart_eval/stdlib/core.dart
  - uri: package:bindgen/native.dart
    classes:
      Image:
        wrapperName: $UiImage
        overrideLibrary: package:bindgen/native.dart
''')..resolveDefaults();
    final generated = (await Bindgen().parse(
      source,
      'native.eval.dart',
      'package:bindgen/native.dart',
      false,
      config: config,
      libraryConfig: config.libraries.last,
    ))!;
    expect(generated, isNot(contains(r'$Image')));
    File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
$generated
''');
    File(p.join(directory.path, 'run.dart')).writeAsStringSync(r"""
import 'native.eval.dart';
import 'native.dart' as native;
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
void main() {
  final compiler = Compiler()..defineBridgeClass($UiImage.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    int main() {
      final image = Image(4);
      image.debugGetOpenHandleStackTraces();
      image.dispose();
      return image.width + Image(3).width;
    }
  '''}});
  final runtime = Runtime.ofProgram(program);
  $UiImage.configureForRuntime(runtime);
  int disposedWidth = 0;
  native.Image.onDispose = (image) { disposedWidth = image.width; };
  final result = runtime.executeLib('package:main/main.dart', 'main');
  if ((result != 7 && result != $int(7)) || disposedWidth != 4) {
    throw StateError('Wrong renamed lifecycle result: $result');
  }
}
""");
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      p.join(directory.path, 'run.dart'),
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'generated unary and binary minus dispatch through distinct keys',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_minus_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class Vector {
  Vector(this.x);
  final int x;
  int operator -() => -x;
  int operator -(Vector other) => x - other.x;
}
''');
      final config = BindgenConfig.parse('''
libraries:
  - uri: dart:core
    classes:
      int:
        handMaintained: true
        file: package:dart_eval/stdlib/core.dart
  - uri: package:bindgen/native.dart
    classes:
      Vector:
        overrideLibrary: package:bindgen/native.dart
''')..resolveDefaults();
      final generated = (await Bindgen().parse(
        source,
        'native.eval.dart',
        'package:bindgen/native.dart',
        false,
        config: config,
        libraryConfig: config.libraries.last,
      ))!;
      expect(generated, contains("'unary-': BridgeMethodDef("));
      expect(generated, contains("'-': BridgeMethodDef("));
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(r"""
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
void main() {
  final compiler = Compiler()..defineBridgeClass($Vector.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    int main() {
      final a = Vector(5);
      return -a + (a - Vector(2));
    }
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    $Vector.configureForRuntime(runtime);
    final result = runtime.executeLib('package:main/main.dart', 'main');
    if (result != -2 && result != $int(-2)) {
      throw StateError('Wrong unary/binary minus result: $result');
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

  test(
    'nullable iterable bridge getters export once and preserve null',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_nullable_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class NullableSource<T> {
  NullableSource();
  Iterable<T>? get items => null;
  Iterator<T>? get cursor => null;
  Iterable<T>? values() => null;
}
''');
      final config = BindgenConfig.parse('''
version: 1
defaults:
  mode: bridge
libraries:
  - uri: package:bindgen/native.dart
    classes:
      NullableSource:
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
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(r"""
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/src/eval/bridge/runtime_bridge.dart' show BridgeData;
import 'package:dart_eval/stdlib/core.dart';

class Probe<T> extends $NullableSource$bridge<T> {
  $Value? response;
  int reads = 0;
  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    reads++;
    return response;
  }
}
void check(bool condition) {
  if (!condition) throw StateError('Nullable bridge export assertion failed');
}
void main() {
  final compiler = Compiler()
    ..entrypoints.add('package:main/main.dart')
    ..defineBridgeClass($NullableSource$bridge.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    class Cursor implements Iterator<int> {
      int index = -1;
      bool moveNext() { index++; return index < 2; }
      int get current => index + 4;
    }
    class Items implements Iterable<int> {
      Iterator<int> get iterator => Cursor();
      dynamic noSuchMethod(Invocation invocation) => throw StateError('unused');
    }
    Iterable<int> main() => Items();
    Iterator<int> cursor() => Cursor();
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    final probe = Probe<int>();
    // The overridden getters only need the defining runtime.
    Runtime.bridgeData[probe] = BridgeData(runtime, 0, null);
    for (final value in <$Value?>[null, const $null()]) {
      probe.response = value;
      probe.reads = 0;
      check(probe.items == null && probe.reads == 1);
      probe.reads = 0;
      check(probe.cursor == null && probe.reads == 1);
      probe.response = $Function((runtime, target, r, s, c) => value);
      probe.reads = 0;
      check(probe.values() == null && probe.reads == 1);
    }
    probe.response = runtime.executeLib('package:main/main.dart', 'main') as $Value;
    probe.reads = 0;
    check(probe.items!.join(',') == '4,5' && probe.reads == 1);
    probe.response = runtime.executeLib('package:main/main.dart', 'cursor') as $Value;
    probe.reads = 0;
    final iterator = probe.cursor!;
    check(probe.reads == 1);
    check(iterator.moveNext() && iterator.current == 4);
    check(iterator.moveNext() && iterator.current == 5);
    check(!iterator.moveNext());
    final strings = Probe<String>()..response = $List.wrap([$String('a'), $String('b')]);
    Runtime.bridgeData[strings] = BridgeData(runtime, 0, null);
    check(strings.items!.join(',') == 'a,b' && strings.reads == 1);
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
  test('nested async wrappers retain their generic receiver type', () async {
    final directory = Directory(
      'test',
    ).absolute.createTempSync('bindgen_async_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final source = File(p.join(directory.path, 'native.dart'))
      ..writeAsStringSync('''
class AsyncBox<T> {
  AsyncBox(this.value);
  final T value;
  Stream<Future<T>> get stream => Stream.value(Future.value(value));
  Future<Stream<T>> get future => Future.value(Stream.value(value));
  List<Future<T>> get list => [Future.value(value)];
}
''');
    final generated = (await Bindgen().parse(
      source,
      'native.dart',
      'package:bindgen/native.dart',
      true,
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
import 'package:dart_eval/stdlib/core.dart';
Future<void> main() async {
  final compiler = Compiler()..defineBridgeClass($AsyncBox.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    Future<bool> main() async {
      final box = AsyncBox<int>(3);
      final inner = await box.stream.first;
      final stream = await box.future;
      return await inner == 3 && await stream.first == 3 &&
          await box.list.first == 3;
    }
  '''}});
  for (final runtime in [Runtime.ofProgram(program), Runtime(program.write().buffer)]) {
    $AsyncBox.configureForRuntime(runtime);
    final result = await runtime.executeLib('package:main/main.dart', 'main');
    if (result != $bool(true)) throw StateError('Nested async metadata was erased: $result');
  }
}
""");
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      p.join(directory.path, 'run.dart'),
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 2)));
  test(
    'generated register bridges execute scalars and retain overflow callbacks',
    () async {
      final directory = Directory(
        'test',
      ).absolute.createTempSync('bindgen_register_');
      addTearDown(() => directory.deleteSync(recursive: true));
      final source = File(p.join(directory.path, 'native.dart'))
        ..writeAsStringSync('''
class Host {
  Host(int value) : _value = value;
  final int _value;
  static int count = 0;
  static int total(int a, int b, int c) => a + b + c;
  static int many(int a, int b, int c, int d) => a + b + c + d;
  static void setCount(int value) { count = value; }
  static int Function(int)? _callback;
  static void retain(int a, int b, int Function(int) callback, int d) {
    _callback = callback;
  }
  static int invoke(int value) => _callback!(value);
  static final List<void Function()> listeners = [];
  static void addListener(void Function() callback) { listeners.add(callback); }
  static void removeListener(void Function() callback) { listeners.remove(callback); }
  static void optionalListener(void Function()? callback) {
    if (callback != null) listeners.add(callback);
  }
}
int triple(int a, int b, int c) => a + b + c;
int addDefault(int a, {int b = 5}) => a + b;
String? optionalText([String? value = 'default']) => value;
void assign(int value) { Host.count = value; }
''');
      final generated = (await Bindgen().parse(
        source,
        'native.dart',
        'package:bindgen/native.dart',
        true,
      ))!;
      expect(generated, contains('registerBridgeFuncRegisters'));
      expect(generated, contains(r'(r as $int).$value'));
      expect(generated, contains(r'(c as $int).$value'));
      expect(generated, contains(r'(_arg3 as $int).$value'));
      expect(generated, isNot(contains('runtime.registerBridgeFunc(')));
      expect(
        generated,
        contains(r'final _arg2 = (c as List<Object?>)[0] as $Value?;'),
      );
      File(p.join(directory.path, 'native.eval.dart')).writeAsStringSync('''
import 'native.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
$generated
''');
      File(p.join(directory.path, 'run.dart')).writeAsStringSync(r'''
import 'native.dart';
import 'native.eval.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
void check(bool condition) { if (!condition) throw StateError('Bridge assertion failed'); }
void main() {
  final runtime = Runtime.ofProgram(Compiler().compile({'main': {'main.dart': 'int main() => 0;'}}));
  $Host.configureForRuntime(runtime);
  $tripleFn.configureForRuntime(runtime);
  $addDefaultFn.configureForRuntime(runtime);
  $assignFn.configureForRuntime(runtime);
  $optionalTextFn.configureForRuntime(runtime);
  check(($optionalTextFn.callRegisters(runtime, null, false, false) as $String).$value == 'default');
  check($optionalTextFn.callRegisters(runtime, const $null(), false, false) is $null);
  check(($optionalTextFn.callRegisters(runtime, null, false, false) as $String).$value == 'default');
  check(($tripleFn.callRegisters(runtime, $int(1), $int(2), $int(3)) as $int).$value == 6);
  check(($Host.$total(runtime, $int(2), $int(3), $int(4)) as $int).$value == 9);
  check(($Host.$many(runtime, $int(1), $int(2), [$int(3), $int(4)]) as $int).$value == 10);
  check(($addDefaultFn.callRegisters(runtime, $int(2), null, 'unused stale register') as $int).$value == 7);
  $Host.$setCount(runtime, $int(8), 'unused stale register', false);
  check(Host.count == 8);
  $Host.set$count(runtime, $int(9), 'unused stale register', false);
  check(($Host.$count(runtime, 'unused', 12, false) as $int).$value == 9);
  $assignFn.callRegisters(runtime, $int(10), false, 'unused');
  check(Host.count == 10);
  check($Host.$new(runtime, $int(3), false, 'unused') is $Host);
  final overflow = <Object?>[$Function((runtime, target, r, s, c) => $int((r as $int).$value + 7)), $int(0)];
  $Host.$retain(runtime, $int(1), $int(2), overflow);
  overflow.fillRange(0, overflow.length, null);
  check(Host.invoke(4) == 11);
  var notifications = 0;
  final listener = $Function((runtime, target, r, s, c) {
    notifications++;
    return null;
  });
  $Host.$addListener(runtime, listener, null, null);
  Host.listeners.single();
  check(notifications == 1);
  $Host.$removeListener(runtime, listener, null, null);
  check(Host.listeners.isEmpty);
  $Host.$optionalListener(runtime, const $null(), null, null);
  $Host.$optionalListener(runtime, null, null, null);
  check(Host.listeners.isEmpty);
  $Host.$optionalListener(runtime, listener, null, null);
  $Host.$removeListener(runtime, listener, null, null);
  check(Host.listeners.isEmpty);
}
''');
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        p.join(directory.path, 'run.dart'),
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
