import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:test/test.dart';

void main() {
  test('serialized controller accepts lifecycle callback setters', () async {
    final program = Compiler().compile({
      'fixture': {
        'main.dart': r'''
import 'dart:async';
var calls = 0;
class Hooks {
  void pause() { calls += 1; }
  void resume() { calls += 10; }
  void listen() { calls += 100; }
  Future<void> cancel() async {
    await Future<void>.delayed(Duration(milliseconds: 1));
    calls += 1000;
  }
  Future<void> fail() async {
    await Future<void>.delayed(Duration(milliseconds: 1));
    throw StateError('cancel failed');
  }
  void incompatible(int value) {}
}
Future<int> main() async {
  calls = 0;
  final controller = StreamController<int>();
  final hooks = Hooks();
  controller.onPause = hooks.pause;
  controller.onResume = hooks.resume;
  controller.onListen = hooks.listen;
  controller.onCancel = hooks.cancel;
  final subscription = controller.stream.listen((value) {});
  subscription.pause();
  subscription.resume();
  await subscription.cancel();
  await controller.close();
  return calls;
}
Future<int> clear() async {
  calls = 0;
  final controller = StreamController<int>();
  final hooks = Hooks();
  controller.onPause = hooks.pause;
  controller.onResume = hooks.resume;
  controller.onListen = hooks.listen;
  controller.onCancel = hooks.cancel;
  controller.onPause = null;
  controller.onResume = null;
  controller.onListen = null;
  controller.onCancel = null;
  final subscription = controller.stream.listen((value) {});
  subscription.pause();
  subscription.resume();
  await subscription.cancel();
  await controller.close();
  return calls;
}
Future<bool> error() async {
  final controller = StreamController<int>();
  controller.onCancel = Hooks().fail;
  final subscription = controller.stream.listen((value) {});
  try {
    await subscription.cancel();
  } on StateError catch (e) {
    await controller.close();
    return e.message == 'cancel failed';
  }
  return false;
}
bool incompatible() {
  final controller = StreamController<int>();
  dynamic callback = Hooks().incompatible;
  try {
    controller.onPause = callback;
  } on TypeError {
    return controller.onPause == null;
  }
  return false;
}
''',
      },
    });
    final runtime = Runtime(program.write().buffer);
    expect(
      await runtime.executeLib('package:fixture/main.dart', 'main'),
      $int(1111),
    );
    expect(
      await runtime.executeLib('package:fixture/main.dart', 'clear'),
      $int(0),
    );
    expect(
      await runtime.executeLib('package:fixture/main.dart', 'error'),
      $bool(true),
    );
    expect(
      runtime.executeLib('package:fixture/main.dart', 'incompatible'),
      isTrue,
    );
  });
}
