import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dart_eval/src/eval/bindgen/bindgen.dart';
import 'package:test/test.dart';

void main() {
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
  final overflow = <Object?>[$Function((runtime, target, args) => $int((args.single as $int).$value + 7)), $int(0)];
  $Host.$retain(runtime, $int(1), $int(2), overflow);
  overflow.fillRange(0, overflow.length, null);
  check(Host.invoke(4) == 11);
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
