import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/src/eval/compiler/errors.dart';
import 'package:test/test.dart';

String _source(String version) {
  final afterGuard = version == '3.8' ? 'int?' : 'int';
  return '''
// @dart = $version
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
class C {
  final int? _value;
  C(this._value);
}
int? nullable(C? c) {
  c?._value!;
  c?._value.check<Exactly<int?>>();
  return c?._value;
}
int main() {
  final c = C(1);
  if (c._value != null) {
    c?._value.check<Exactly<$afterGuard>>();
    c?.._value.check<Exactly<int>>();
  }
  c?._value!;
  c._value.check<Exactly<$afterGuard>>();
  c._value!;
  c._value.check<Exactly<int>>();
  final d = C(2);
  d?.._value!.._value.check<Exactly<int>>();
  d._value.check<Exactly<$afterGuard>>();
  final result = (C(3)?.._value!.._value.check<Exactly<int>>())
      ._value.check<Exactly<$afterGuard>>();
  return c._value! + d._value! + result! + (nullable(null) ?? 0) +
      (nullable(C(4)) ?? 0);
}
''';
}

void main() {
  test(
    'extension guards preserve pins and invalidate written receiver proofs',
    () {
      const source = r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T { T check<R extends Exactly<T>>() => this; }
extension P on List<int> {
  int operator [](int index) => first + index + 20;
  void operator []=(int index, int value) { this[0] = value + 30; }
}
extension Q on List<int> {
  int? operator [](int index) => null;
  void operator []=(int index, int value) { this[0] = value + 60; }
}
class C { C follow(Object? ignored) => this; }
class Holder { final C? _child; Holder(this._child); }
extension Named on C { C touch(Object? ignored) => this; }
int main() {
  final values = <int>[2];
  final read = P(values)?[3];
  P(values)?[0] = 8;
  Q(values)?[0] ??= 7;
  C? source = C();
  final chain = Named(source)?.touch(source = null).follow(
    source..check<Exactly<C?>>(),
  );
  final skipped = P(null)?[throw 'index evaluated'];
  final holder = Holder(C());
  holder.._child?.follow(null).._child.check<Exactly<C?>>();
  holder.._child!.._child.check<Exactly<C>>();
  return read! + values[0] + (chain != null ? 100 : 0) +
      (source == null ? 1000 : 0) + (skipped == null ? 10000 : 0);
}
''';
      final program = Compiler().compile({
        'extension_guard_boundary': {'main.dart': source},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(
          runtime.executeLib(
            'package:extension_guard_boundary/main.dart',
            'main',
          ),
          11192,
        );
      }
      expect(
        () => Compiler().compile({
          'extension_guard_boundary': {
            'main.dart': source.replaceFirst(
              "P(null)?[throw 'index evaluated']",
              'P(null)[0]',
            ),
          },
        }),
        throwsA(isA<CompileError>()),
      );
    },
  );

  test('nested field proofs retain their root and reject unstable paths', () {
    final program = Compiler().compile({
      'nested_field_flow': {
        'main.dart': r'''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T { T check<R extends Exactly<T>>() => this; }
class Leaf<T> {
  final T? _value;
  Leaf(this._value);
}
class Envelope<T> {
  final Leaf<T> _leaf;
  Envelope(this._leaf);
  T? read() {
    if (_leaf._value == null) return null;
    return _leaf._value.check<Exactly<T>>();
  }
}
class MutableEnvelope {
  Leaf<int> _changing;
  MutableEnvelope(this._changing);
}
int remembered(Envelope<int> envelope) {
  final ready = (envelope._leaf)._value != null;
  if (!ready) return 0;
  return envelope._leaf._value.check<Exactly<int>>();
}
int replaced() {
  var envelope = Envelope(Leaf<int>(2));
  final ready = envelope._leaf._value != null;
  envelope = Envelope(Leaf<int>(null));
  if (ready) envelope._leaf._value.check<Exactly<int?>>();
  return envelope._leaf._value ?? 0;
}
int unstable(MutableEnvelope envelope) {
  if (envelope._changing._value != null) {
    envelope._changing._value.check<Exactly<int?>>();
    envelope._changing = Leaf<int>(null);
  }
  return envelope._changing._value ?? 0;
}
int main() => remembered(Envelope(Leaf<int>(3))) +
    remembered(Envelope(Leaf<int>(null))) + replaced() +
    unstable(MutableEnvelope(Leaf<int>(4))) +
    Envelope(Leaf<String>('ok')).read()!.length;
''',
      },
    });
    for (final runtime in [
      Runtime.ofProgram(program),
      Runtime(program.write().buffer),
    ]) {
      expect(
        runtime.executeLib('package:nested_field_flow/main.dart', 'main'),
        5,
      );
    }
  });
  test(
    'coalescing field proofs do not survive a nullable RHS or receiver write',
    () {
      final program = Compiler().compile({
        'field_flow': {
          'main.dart': '''
typedef Exactly<T> = T Function(T);
extension StaticType<T> on T {
  T check<R extends Exactly<T>>() => this;
}
class C {
  final int? _value;
  C(this._value);
}
int inspect(C c) {
  c._value ?? 0;
  c._value.check<Exactly<int?>>();
  c._value ?? (c = C(null))._value;
  c._value.check<Exactly<int?>>();
  return c._value ?? 0;
}
int main() => inspect(C(1)) + inspect(C(null));
''',
        },
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:field_flow/main.dart', 'main'), 1);
      }
    },
  );
  for (final version in ['3.8', '3.9']) {
    test('Dart $version null-aware access retains versioned field facts', () {
      final program = Compiler().compile({
        'field_flow': {'main.dart': _source(version)},
      });
      for (final runtime in [
        Runtime.ofProgram(program),
        Runtime(program.write().buffer),
      ]) {
        expect(runtime.executeLib('package:field_flow/main.dart', 'main'), 10);
      }
    });
  }
}
