import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/src/eval/runtime/typed/typed_transfer.dart';
import 'package:test/test.dart';

const library = 'package:isolate_fixture/main.dart';

Future<void> fixture(String source, Object? expected) async {
  final program = Compiler().compile({
    'isolate_fixture': {'main.dart': source},
  });
  for (final (label, runtime) in [
    ('fresh', Runtime.ofProgram(program)),
    ('encoded', Runtime(program.write().buffer)),
  ]) {
    final result = await (runtime.executeLib(library, 'main') as Future)
        .timeout(const Duration(seconds: 8));
    expect(
      result is $Value ? result.$reified : result,
      expected,
      reason: label,
    );
  }
}

void main() {
  test(
    'Uint64List views retain buffer aliases across worker transfer',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      import 'dart:typed_data';
      void work(List<dynamic> args) {
        final view = args[1] as Uint64List;
        final buffer = args[2] as ByteBuffer;
        view[0] = 29;
        Isolate.exit(args[0], [view, buffer, args[3]]);
      }
      Future<int> main() async {
        final data = Uint64List.fromList([3, 7, 11]);
        final view = Uint64List.view(data.buffer, 8, 1);
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) {
          final received = message[0] as Uint64List;
          final buffer = message[1] as ByteBuffer;
          int score = 0;
          if (received.length == 1 && received.offsetInBytes == 8) score++;
          if (received[0] == 29 && buffer.asUint64List()[1] == 29) score++;
          received[0] = 41;
          if (buffer.asUint64List()[1] == 41 && message[2][0] == 41) score++;
          if (identical(received, message[2])) score++;
          if (data[1] == 7 && view[0] == 7) score++;
          port.close();
          done.complete(score);
        };
        await Isolate.spawn(work, [port.sendPort, view, data.buffer, view]);
        return await done.future;
      }
    ''', 5);
    },
  );

  test(
    'late fields retain unset, assigned null and lazy final state',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      int initializations = 0;
      class Box {
        late int unset;
        late final int finalUnset;
        late final int? nullable;
        late final int assigned;
        late final int lazy = ++initializations;
        Box() { nullable = null; assigned = 9; }
      }
      void work(List<dynamic> args) {
        final box = args[1] as Box;
        int score = 0;
        try { box.unset; } catch (e) { score++; }
        box.unset = 3;
        if (box.unset == 3) score++;
        box.finalUnset = 5;
        if (box.finalUnset == 5) score++;
        try { box.finalUnset = 6; } catch (e) { score++; }
        if (box.nullable == null) score++;
        if (initializations == 0 && box.lazy == 1 && box.lazy == 1 &&
            initializations == 1) score++;
        try { box.assigned = 10; } catch (e) { if (box.assigned == 9) score++; }
        Isolate.exit(args[0], score);
      }
      Future<int> main() async {
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        await Isolate.spawn(work, [port.sendPort, Box()]);
        final score = await done.future;
        return score + (initializations == 0 ? 1 : 0);
      }
    ''', 8);
    },
  );

  test(
    'late captured locals retain shared cells and lazy initializer cycles',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      void work(List<dynamic> args) {
        Isolate.exit(args[0], args[1]() + args[2]());
      }
      Future<int> main() async {
        late int unset;
        late final int finalUnset;
        late final int? nullable = null;
        late int assigned = 5;
        int initializations = 0;
        late int Function() initialize;
        late int lazy = initialize();
        initialize = () { initializations++; lazy = 4; return 7; };
        int first() {
          int score = 0;
          try { unset; } catch (e) { score++; }
          unset = 3;
          finalUnset = 9;
          if (nullable == null) score++;
          if (assigned == 5) score++;
          assigned = 6;
          if (initializations == 0 && lazy == 7 && lazy == 7 &&
              initializations == 1) score++;
          return score;
        }
        int second() {
          int score = 0;
          if (unset == 3 && assigned == 6 && finalUnset == 9) score++;
          try { finalUnset = 10; } catch (e) { score++; }
          try { nullable = 1; } catch (e) { score++; }
          return score;
        }
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        // Materialize an initialized late cell before sending it.
        assigned;
        await Isolate.spawn(work, [port.sendPort, first, second]);
        final score = await done.future;
        return score + (assigned == 5 && initializations == 0 ? 1 : 0);
      }
    ''', 8);
    },
  );

  test(
    'RangeError constructor forms retain fields and text after transfer',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      void work(List<dynamic> args) => Isolate.exit(args[0], args[1]);
      Future<int> main() async {
        final errors = [RangeError('message'), RangeError.value(7, 'value', 'outside'),
          RangeError.range(7, 0, 5, 'range', 'outside')];
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) {
          port.close();
          int score = 0;
          for (int i = 0; i < errors.length; i++) {
            final original = errors[i];
            final copy = message[i] as RangeError;
            if (copy.toString() == original.toString() && copy.message == original.message &&
                copy.invalidValue == original.invalidValue && copy.name == original.name &&
                copy.start == original.start && copy.end == original.end) score++;
          }
          done.complete(score);
        };
        await Isolate.spawn(work, [port.sendPort, errors]);
        return await done.future;
      }
    ''', 3);
    },
  );

  test(
    'inherited method retains the most derived virtual dispatch receiver',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      class Base {
        SendPort? port;
        int value() => 1;
        void work(int message) => Isolate.exit(port, value() + message);
      }
      class Derived extends Base { int value() => 9; }
      Future<int> main() async {
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) async {
          await Future.delayed(Duration(milliseconds: 1));
          port.close(); done.complete(message);
        };
        final box = Derived();
        box.port = port.sendPort;
        await Isolate.spawn(box.work, 3);
        return await done.future;
      }
    ''', 12);
    },
  );
  test(
    'transfer retains Type, guest map equality and collection write restrictions',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      class Key {
        final int value;
        Key(this.value);
        bool operator ==(Object other) => other is Key && other.value == value;
        int get hashCode => value;
      }
      void work(List<dynamic> args) {
        final expectedType = List<int>;
        int score = args[1] == expectedType ? 1 : 0;
        final map = args[2] as Map<Key, int>;
        score += map[Key(3)]!;
        try { args[3][0] = 2; } catch (e) { score += 10; }
        try { args[4].add(2); } catch (e) { score += 100; }
        try { args[5][0] = 2; } catch (e) { score += 1000; }
        score += (args[6] as Set<Key>).length * 10000;
        Isolate.exit(args[0], score);
      }
      Future<int> main() async {
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        final identity = Set<Key>.identity()..add(Key(1))..add(Key(1));
        await Isolate.spawn(work, <dynamic>[port.sendPort, List<int>, {Key(3): 3},
          const [1], List<int>.filled(1, 1), List<int>.unmodifiable([1]), identity]);
        return await done.future;
      }
    ''', 21114);
    },
  );

  test(
    'bound member receiver may point back to the transferred member',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      class Box {
        dynamic callback;
        SendPort? port;
        void work(int value) {
          Isolate.exit(port, callback == work ? value : 0);
        }
      }
      Future<int> main() async {
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        final box = Box();
        box.callback = box.work;
        box.port = port.sendPort;
        await Isolate.spawn(box.callback, 7);
        return await done.future;
      }
    ''', 7);
    },
  );

  test(
    'worker transfers configuration, callback, bytes, port and fresh globals',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      import 'dart:typed_data';
      int global = 3;
      class Config {
        final int Function(Uint8List) callback;
        final Uint8List bytes;
        final SendPort port;
        Config(this.callback, this.bytes, this.port);
      }
      int sum(Uint8List bytes) => bytes[0] + bytes[1] + global;
      void work(Config config) {
        Isolate.exit(config.port, config.callback(config.bytes));
      }
      Future<int> main() async {
        global = 100;
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        await Isolate.spawn(work, Config(sum, Uint8List.fromList([4, 5]), port.sendPort),
          debugName: 'guest-worker', errorsAreFatal: true);
        return await done.future;
      }
    ''', 12);
    },
  );

  test(
    'captured cells, cycles, aliases and bound receiver stay child-local',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      class Box {
        int value = 1;
        Box? next;
        int bump() => ++value;
      }
      class Config {
        final int Function() callback;
        final SendPort port;
        Config(this.callback, this.port);
      }
      void work(Config config) => Isolate.exit(config.port, config.callback());
      Future<int> main() async {
        final box = Box();
        box.next = box;
        final aliases = [box, box];
        final bump = box.bump;
        int count = 0;
        int next() => ++count;
        int callback() {
          bump();
          next();
          return next() * 100 + aliases[1].next!.value * 10 +
            (identical(aliases[0], aliases[1]) ? 1 : 0);
        }
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        await Isolate.spawn(work, Config(callback, port.sendPort));
        final child = await done.future;
        return child + box.value * 1000 + count * 10000;
      }
    ''', 1221);
    },
  );

  test('native resources and custom plugin bootstrap fail before transfer', () {
    final program = Compiler().compile({
      'isolate_fixture': {'main.dart': 'int main() => 0;'},
    });
    final runtime = Runtime.ofProgram(program)..initialize();
    expect(
      () => TypedTransfer.encode(runtime, $Object(File('unused'))),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => TypedTransfer.encode(runtime, $Object(_FakeSendPort(runtime))),
      throwsA(isA<UnsupportedError>()),
    );
    runtime.registerBridgeFuncRegisters('custom', 'f', (_, r, s, c) => null);
    expect(runtime.guestIsolateProgram, throwsA(isA<UnsupportedError>()));
  });

  test(
    'instantiated generic callback retains checked signature after transfer',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      T id<T>(T value) => value;
      T bad<T>() { dynamic value = 'wrong'; return value; }
      class Config {
        final dynamic callback;
        final dynamic badCallback;
        final SendPort port;
        Config(this.callback, this.badCallback, this.port);
      }
      void work(Config config) {
        int result = config.callback(7);
        try { config.callback('wrong'); } catch (e) { result += 10; }
        try { config.badCallback(); } catch (e) { result += 100; }
        Isolate.exit(config.port, result);
      }
      Future<int> main() async {
        final done = Completer<int>();
        final port = RawReceivePort();
        port.handler = (dynamic message) { port.close(); done.complete(message); };
        await Isolate.spawn(work, Config(id<int>, bad<int>, port.sendPort));
        return await done.future;
      }
    ''', 117);
    },
  );

  test('busy native worker is killed while parent timer progresses', () async {
    await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      void work(SendPort port) {
        port.send(1);
        while (true) {}
      }
      Future<int> main() async {
        final ready = Completer<int>();
        final exited = Completer<int>();
        final port = RawReceivePort();
        final exitPort = RawReceivePort();
        port.handler = (dynamic message) { port.close(); ready.complete(message); };
        exitPort.handler = (dynamic message) { exitPort.close(); exited.complete(2); };
        final worker = await Isolate.spawn(work, port.sendPort, onExit: exitPort.sendPort);
        await ready.future;
        await Future.delayed(Duration(milliseconds: 20));
        worker.kill(priority: Isolate.immediate);
        return await exited.future;
      }
    ''', 2);
  });

  test(
    'caught guest errors use result port and uncaught errors use VM error port',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      void caught(SendPort port) {
        try { throw StateError('caught'); } catch (e, s) {
          Isolate.exit(port, [e, s]);
        }
      }
      void uncaught(SendPort port) { throw StateError('uncaught'); }
      Future<int> main() async {
        final caughtDone = Completer<int>();
        final errorDone = Completer<int>();
        final exitDone = Completer<int>();
        final port = RawReceivePort();
        final errors = RawReceivePort();
        final exits = RawReceivePort();
        port.handler = (dynamic message) {
          port.close();
          caughtDone.complete(message[0] is StateError && message[0].toString().contains('caught') &&
            message[1] is StackTrace && message[1].toString().isNotEmpty ? 1 : 0);
        };
        errors.handler = (dynamic message) {
          errors.close();
          final error = RemoteError(message[0], message[1]);
          errorDone.complete(error.toString().contains('uncaught') ? 2 : 0);
        };
        exits.handler = (dynamic message) { exits.close(); exitDone.complete(4); };
        await Isolate.spawn(caught, port.sendPort);
        final result = await caughtDone.future;
        await Isolate.spawn(uncaught, port.sendPort,
          onError: errors.sendPort, onExit: exits.sendPort, errorsAreFatal: true);
        return result + await errorDone.future + await exitDone.future;
      }
    ''', 7);
    },
  );

  test(
    'timeout kills delayed worker and emits one exit without a result',
    () async {
      await fixture('''
      import 'dart:async';
      import 'dart:isolate';
      Future<void> work(SendPort port) async {
        await Future.delayed(Duration(milliseconds: 200));
        Isolate.exit(port, 100);
      }
      Future<int> main() async {
        final done = Completer<int>();
        final exitDone = Completer<int>();
        final port = RawReceivePort();
        final exits = RawReceivePort();
        int count = 0;
        port.handler = (dynamic message) { count++; done.complete(message); };
        exits.handler = (dynamic message) { exits.close(); exitDone.complete(1); };
        final worker = await Isolate.spawn(work, port.sendPort, onExit: exits.sendPort);
        try { await done.future.timeout(Duration(milliseconds: 20)); }
        on TimeoutException { worker.kill(priority: Isolate.immediate); }
        final result = await exitDone.future;
        port.close();
        return result + count * 10;
      }
    ''', 1);
    },
  );

  test(
    'Flow and Timeline run callbacks once and propagate result and error',
    () async {
      await fixture('''
      import 'dart:developer';
      class Box { final int value; Box(this.value); }
      Future<int> main() async {
        int count = 0;
        final flow = Flow.begin();
        Timeline.startSync('outer', flow: flow);
        final box = Timeline.timeSync<Box>('inner', () { count++; return Box(7); },
          flow: Flow.step(flow.id));
        Timeline.finishSync();
        try { Timeline.timeSync<int>('error', () { count++; throw StateError('expected'); },
          flow: Flow.end(flow.id)); } catch (e) { count++; }
        final asyncResult = await Timeline.timeSync<Future<int>>('async', () async {
          count++;
          return 1;
        });
        return count * 10 + box.value + asyncResult;
      }
    ''', 48);
    },
  );
}

final class _FakeSendPort implements SendPort {
  _FakeSendPort(this.runtime);
  final Runtime runtime;
  @override
  void send(Object? message) {}
}
