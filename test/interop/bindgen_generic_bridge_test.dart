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
import 'dart:convert';
import 'dart:async';
class Accumulator<E> {
  Accumulator();
  E reduce(E Function(E, E) callback, E left, E right) => callback(left, right);
}
class CallbackChecks {
  CallbackChecks();
  bool accept([bool Function(int)? callback]) => callback?.call(1) ?? false;
  void stream(StreamSubscription<int> Function(Stream<int>, bool) callback) {
    StreamTransformer<int, int>(callback);
  }
  bool nullableIterable(Iterable<int>? values) => values == null;
  void nullableSink(Sink<List<int>>? sink) { sink?.close(); }
  int voidFuture(FutureOr<int> Function(void) callback) => callback(null) as int;
  void voidReturn(FutureOr<void> Function(void) callback) { callback(null); }
  void generic(List<T> Function<T>(int) callback) {}
}
class SinkConsumer {
  SinkConsumer(Sink<List<int>> sink) { sink.add([7]); sink.close(); }
}
class CallbackSink<T> implements Sink<T> {
  final Sink<T> _sink;
  CallbackSink(void Function(List<T>) callback)
      : _sink = ChunkedConversionSink<T>.withCallback(callback);
  void add(T event) { _sink.add(event); }
  void close() { _sink.close(); }
}
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
class Mapper<E> {
  final List<E> items;
  Mapper(this.items);
  void setFirst(E value) { items[0] = value; }
  void writeWrong() { (items as dynamic)[0] = 'wrong'; }
  int readInts(List<int> values) => values.first;
  void writeWrongInt(List<int> values) { (values as dynamic)[0] = 'wrong'; }
  int nullableInts(List<int>? values) => values?.first ?? -1;
  int defaultInts([List<int> values = const [9]]) => values.first;
  Iterable<R> map<R>(R Function(E) callback) => items.map(callback);
  Iterable<R> eager<R>(R Function(E) callback) => [callback(items.first)];
  Iterable<List<R>> groups<R>(R Function(E) callback) =>
      items.map((e) => [callback(e)]);
  Iterable<E> values() => items;
  Iterable<R> unchecked<R>(Object? value) => <dynamic>[value] as dynamic;
}
''');
    final config = BindgenConfig.parse('''
version: 1
libraries:
  - uri: package:bindgen/native.dart
    classes:
      Accumulator:
        include: true
        mode: bridge
        nativeSuper: true
      CallbackChecks:
        include: true
      SinkConsumer:
        include: true
      CallbackSink:
        include: true
      Reader:
        include: true
        mode: bridge
      ObjectStore:
        include: true
      Mapper:
        include: true
  - uri: dart:core
    registry:
      file: lib/src/eval/shared/types.dart
      class: CoreTypes
    classes:
      Iterable:
        handMaintained: true
      Sink:
        handMaintained: true
      List:
        handMaintained: true
      Object:
        handMaintained: true
      bool:
        handMaintained: true
      int:
        handMaintained: true
  - uri: dart:async
    registry:
      file: lib/src/eval/shared/types.dart
      class: AsyncTypes
    classes:
      Stream:
        handMaintained: true
        overrideLibrary: dart:core
      StreamSubscription:
        handMaintained: true
''')..resolveDefaults();
    final generated = (await Bindgen().parse(
      source,
      'native.dart',
      'package:bindgen/native.dart',
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
    ..defineBridgeClass($Accumulator$bridge.$declaration)
    ..defineBridgeClass($SinkConsumer.$declaration)
    ..defineBridgeClass($CallbackSink.$declaration)
    ..defineBridgeClass($CallbackChecks.$declaration)
    ..defineBridgeClass($ObjectStore.$declaration)
    ..defineBridgeClass($Mapper.$declaration);
  final program = compiler.compile({'main': {'main.dart': '''
    import 'package:bindgen/native.dart';
    import 'dart:async';
    class Collecting implements Sink<List<int>> {
      List<int> values = [];
      int closes = 0;
      void add(List<int> chunk) { values.addAll(chunk); }
      void close() { closes++; }
    }
    class GuestAccumulator extends Accumulator<int> {
      GuestAccumulator();
    }
    bool sinkBoundary() {
      if (GuestAccumulator().reduce((a, b) => a + b, 2, 3) != 5) return false;
      final checks = CallbackChecks();
      if (!checks.accept((n) => n == 1) || checks.accept()) return false;
      if (!checks.nullableIterable(null)) return false;
      checks.nullableSink(null);
      if (checks.voidFuture((value) => 7) != 7) return false;
      checks.voidReturn((value) {});
      checks.stream((stream, cancel) => stream.listen((n) {}));
      final collecting = Collecting();
      SinkConsumer(collecting);
      if (collecting.values.single != 7 || collecting.closes != 1) return false;
      bool witnessed = false;
      final callback = CallbackSink<List<int>>((chunks) {
        witnessed = chunks is List<List<int>> && chunks.first is List<int>
            && chunks.first.single == 7;
      });
      final other = CallbackSink<String>((chunks) {});
      other.close();
      SinkConsumer(callback);
      final types = <String>[];
      void shared(List<Object> chunks) {
        if (chunks is List<int>) types.add('int');
        if (chunks is List<String>) types.add('String');
      }
      final ints = CallbackSink<int>(shared);
      final strings = CallbackSink<String>(shared);
      ints.add(1);
      strings.add('s');
      ints.close();
      strings.close();
      return witnessed && types.join(',') == 'int,String';
    }
    class Guest extends Reader {
      Guest();
      int readList(List<int> values) => values.first;
      T transform<T>(T Function(T) callback, T value) => callback(value);
    }
    class Token {}
    bool listArguments() {
      final token = Token();
      final items = <Token>[token];
      final mapper = Mapper<Token>(items);
      if (!identical(mapper.values().single, token)) return false;
      final replacement = Token();
      mapper.setFirst(replacement);
      if (!identical(items.single, replacement)) return false;
      try { mapper.writeWrong(); return false; } on TypeError {}
      if (!identical(items.single, replacement)) return false;
      final integers = <int>[5];
      if (mapper.readInts(integers) != 5) return false;
      try { mapper.writeWrongInt(integers); return false; } on TypeError {}
      if (integers.single != 5) return false;
      if (mapper.nullableInts(null) != -1 ||
          mapper.nullableInts(integers) != 5 ||
          mapper.defaultInts() != 9 ||
          mapper.defaultInts(integers) != 5) return false;
      dynamic wrong = <String>['wrong'];
      try { mapper.readInts(wrong); return false; } on TypeError {}
      try { mapper.defaultInts(wrong); return false; } on TypeError {}
      try { mapper.nullableInts(wrong); return false; } on TypeError {}
      return true;
    }
    List<T> mapped<T>(Mapper<T> mapper) => mapper.map<T>((e) => e).toList();
    bool mapResults() {
      final token = Token();
      final mapper = Mapper<Token>([token]);
      final tokens = mapped<Token>(mapper);
      if (tokens is! List<Token> || !identical(tokens.single, token)) return false;
      final groups = mapper.groups<Token>((e) => e);
      // Iterate after another method has supplied a different type context.
      final ints = Mapper<int>([1]);
      final widened = ints.map<num>((e) => e).toList();
      widened.add(2.5);
      if (widened[1] != 2.5) return false;
      final grouped = groups.single;
      if (grouped is! List<Token> || !identical(grouped.single, token)) return false;
      dynamic checked = grouped;
      try { checked.add('wrong'); return false; } on TypeError {}
      Mapper<num> widerReceiver = ints;
      dynamic receiverOwned = widerReceiver.values().toList();
      if (receiverOwned is! List<int>) return false;
      try { receiverOwned.add(2.5); return false; } on TypeError {}
      int calls = 0;
      dynamic wrong = 'wrong';
      final lazy = ints.map<int>((e) { calls++; return wrong; });
      if (calls != 0) return false;
      try { lazy.toList(); return false; } on TypeError {}
      if (calls != 1) return false;
      final raw = ints.unchecked<int>('wrong');
      try { raw.toList(); return false; } on TypeError {}
      final nested = mapper.eager<Token>((e) {
        if (ints.map<String>((n) => 'inner').single != 'inner') {
          throw StateError('nested map');
        }
        return e;
      }).toList();
      return nested is List<Token> && identical(nested.single, token);
    }
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
    $Accumulator$bridge.configureForRuntime(runtime);
    $SinkConsumer.configureForRuntime(runtime);
    $CallbackSink.configureForRuntime(runtime);
    $CallbackChecks.configureForRuntime(runtime);
    $ObjectStore.configureForRuntime(runtime);
    $Mapper.configureForRuntime(runtime);
    final reader = runtime.executeLib('package:main/main.dart', 'make') as Reader;
    check(reader.readList([5]) == 5);
    final token = runtime.executeLib('package:main/main.dart', 'makeToken');
    check(identical(reader.transform<Object>((value) => value, token), token));
    check(runtime.executeLib('package:main/main.dart', 'lookup') == true);
    check(runtime.executeLib('package:main/main.dart', 'sinkBoundary') == true);
    check(runtime.executeLib('package:main/main.dart', 'mapResults') == true);
    check(runtime.executeLib('package:main/main.dart', 'listArguments') == true);
    check(runtime.bridgeCallTypeArguments.isEmpty);
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
